import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StoryItem {
  const StoryItem({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhotoUrl,
    required this.kind,
    required this.audience,
    required this.durationMs,
    required this.createdAtMs,
    required this.expiresAtMs,
    required this.mediaUrl,
    this.filter = 'original',
    this.liveId = '',
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerPhotoUrl;
  final String kind;
  final String audience;
  final int durationMs;
  final int createdAtMs;
  final int expiresAtMs;
  final String mediaUrl;
  final String filter;
  final String liveId;

  bool get isLiveShare => kind == 'live' && liveId.isNotEmpty;
  bool get isVideo => kind == 'video';
  bool get isCloseFriends => audience == 'close_friends';

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? 'WorldVoice').toString(),
      ownerPhotoUrl: (json['ownerPhotoUrl'] ?? '').toString(),
      kind: (json['kind'] ?? 'image').toString(),
      audience: (json['audience'] ?? 'everyone').toString(),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 7000,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      expiresAtMs: (json['expiresAtMs'] as num?)?.toInt() ?? 0,
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      filter: (json['filter'] ?? 'original').toString(),
      liveId: (json['liveId'] ?? '').toString(),
    );
  }
}

class StoryCloseFriendCandidate {
  const StoryCloseFriendCandidate({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.username,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String username;

  factory StoryCloseFriendCandidate.fromJson(Map<String, dynamic> json) {
    return StoryCloseFriendCandidate(
      uid: (json['uid'] ?? '').toString(),
      displayName: (json['displayName'] ?? 'WorldVoice').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }
}

class StoryCloseFriendState {
  const StoryCloseFriendState({required this.isVip, required this.userIds});

  final bool isVip;
  final Set<String> userIds;
}

class StoryService {
  StoryService({http.Client? client}) : _client = client ?? http.Client();

  // Stories now has its own Render service, separate from Teacher AI and
  // room economy. Existing custom endpoints remain overridable by dart-define.
  static const String _endpoint = String.fromEnvironment(
    'WORLDVOICE_STORY_BACKEND_URL',
    defaultValue: 'https://worldvoice-stories.onrender.com',
  );
  // Legacy social backend is a compatibility fallback for missing endpoints,
  // not the primary Stories uploader. Never fall back to Teacher AI.
  static const String _fallbackEndpoint = String.fromEnvironment(
    'WORLDVOICE_SOCIAL_BACKEND_URL',
    defaultValue: 'https://worldvoice-v2.onrender.com',
  );
  final http.Client _client;
  String? _activeEndpoint;

  // Keep the last authorized feed in memory when a user briefly leaves
  // Messages for Live/Rooms and returns. Scoped by Firebase uid, not shared
  // between accounts; expired Stories never remain in the cache.
  static String? _cachedFeedUser;
  static List<StoryItem> _cachedFeed = const <StoryItem>[];
  static DateTime? _cachedFeedAt;

  static List<StoryItem> cachedFeedFor(String? uid) {
    if (uid == null || uid != _cachedFeedUser) return const <StoryItem>[];
    final saved = _cachedFeedAt;
    if (saved == null ||
        DateTime.now().difference(saved) > const Duration(minutes: 3)) {
      return const <StoryItem>[];
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return _cachedFeed
        .where((story) => story.expiresAtMs > now)
        .toList(growable: false);
  }

  Uri _uri(String path, {String? base}) {
    final root = Uri.tryParse((base ?? _activeEndpoint ?? _endpoint).trim());
    if (root == null ||
        root.scheme != 'https' ||
        !root.hasAuthority ||
        root.userInfo.isNotEmpty) {
      throw StateError('WorldVoice story backend is not configured.');
    }
    final basePath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    return root.replace(path: '$basePath$path', query: null, fragment: null);
  }

  Future<http.Response> _storyGet(
    String path,
    String token, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final headers = <String, String>{'Authorization': 'Bearer $token'};
    final firstUrl = _uri(path).replace(queryParameters: query);
    final first = await _client
        .get(firstUrl, headers: headers)
        .timeout(timeout);
    // The Story API may live on either WorldVoice backend. Retry missing
    // routes, and for storage preflight only, a backend without media storage.
    // Never redirect auth failures or private Story reads to another host.
    final routeMissing = first.statusCode == 404 || first.statusCode == 405;
    var mediaStorageMissing = false;
    if (path == '/stories/storage-status' && first.statusCode == 503) {
      try {
        final decoded = jsonDecode(first.body);
        mediaStorageMissing =
            decoded is Map &&
            (decoded['code'] == 'STORY_STORAGE_NOT_READY' ||
                (decoded['error']?.toString().contains('storage') ?? false));
      } catch (_) {
        // A generic server error is not evidence of missing media storage.
      }
    }
    if (!routeMissing && !mediaStorageMissing) return first;
    final alternate = _uri(
      path,
      base: _fallbackEndpoint,
    ).replace(queryParameters: query);
    if (alternate.origin == firstUrl.origin &&
        alternate.path == firstUrl.path) {
      return first;
    }
    final second = await _client
        .get(alternate, headers: headers)
        .timeout(timeout);
    if (second.statusCode >= 200 && second.statusCode < 300) {
      _activeEndpoint = _fallbackEndpoint;
      return second;
    }
    return first;
  }

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to use Stories.');
    final token = await user.getIdToken().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw StateError(
        'Story sign-in timed out. Check your connection and retry.',
      ),
    );
    if (token == null || token.isEmpty) {
      throw StateError('Could not authenticate Stories.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) body = raw;
    } catch (_) {}
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['ok'] != true) {
      throw StateError(body['error']?.toString() ?? 'Story request failed.');
    }
    return body;
  }

  Future<List<StoryItem>> fetchFeed() async {
    final token = await _token();
    // Render Free may cold-start after inactivity; do not fail the feed
    // after its default 30-second request timeout.
    final response = await _storyGet(
      '/stories/feed',
      token,
      timeout: const Duration(seconds: 85),
    );
    final body = await _decode(response);
    final raw = body['stories'];
    if (raw is! List) return const <StoryItem>[];
    final stories = raw
        .whereType<Map>()
        .map(
          (item) => StoryItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where(
          (item) =>
              item.id.isNotEmpty &&
              (item.isLiveShare || item.mediaUrl.isNotEmpty) &&
              item.expiresAtMs > DateTime.now().millisecondsSinceEpoch,
        )
        .toList(growable: false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _cachedFeedUser = uid;
      _cachedFeed = stories;
      _cachedFeedAt = DateTime.now();
    }
    return stories;
  }

  /// Publishes a clickable Live story without uploading media.
  Future<void> shareLive(String liveId) async {
    final token = await _token();
    final response = await _client
        .post(
          _uri('/stories/live-share'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'liveId': liveId}),
        )
        .timeout(const Duration(seconds: 25));
    await _decode(response);
  }

  Future<String> uploadStory({
    required XFile file,
    required String kind,
    required String audience,
    required int durationMs,
    required String uploadId,
    String filter = 'original',
  }) async {
    final token = await _token();
    // Check the configured media storage provider before transferring video.
    // Missing storage used to fail only after a costly upload attempt.
    try {
      final readiness = await _storyGet(
        '/stories/storage-status',
        token,
        timeout: const Duration(seconds: 75),
      );
      await _decode(readiness);
    } on TimeoutException {
      throw StateError('Story storage check timed out. Please try again.');
    }
    final length = await file.length();
    final maxBytes = kind == 'video' ? 80 * 1024 * 1024 : 12 * 1024 * 1024;
    if (length == 0 || length > maxBytes) {
      throw StateError(
        length == 0
            ? 'The selected story file is empty.'
            : 'This story file is too large to upload.',
      );
    }
    final mime = _mimeType(file, kind);
    final request = http.StreamedRequest('POST', _uri('/stories/upload'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': mime,
      'X-Story-Kind': kind,
      'X-Story-Audience': audience,
      'X-Story-Duration-Ms': '$durationMs',
      'X-Story-Upload-Id': uploadId,
      'X-Story-Filter': filter,
    });
    request.contentLength = length;

    try {
      // Start the transport before streaming bytes into the request sink.
      // Uploading to an unread sink before calling send() can block forever.
      final sendFuture = _client.send(request);
      final writeFuture = () async {
        try {
          await request.sink.addStream(file.openRead());
        } finally {
          await request.sink.close();
        }
        return true;
      }();
      final completed = await Future.wait<Object>([
        sendFuture,
        writeFuture,
      ]).timeout(const Duration(minutes: 2));
      final streamed = completed.first as http.StreamedResponse;
      final body = await streamed.stream.bytesToString().timeout(
        const Duration(seconds: 30),
      );
      final response = http.Response(
        body,
        streamed.statusCode,
        headers: streamed.headers,
      );
      final decoded = await _decode(response);
      final storyId = (decoded['storyId'] ?? '').toString();
      if (storyId.isEmpty) {
        throw StateError('Story upload response missing its story identifier.');
      }
      return storyId;
    } on TimeoutException {
      throw StateError(
        'Story upload timed out. Check your connection and try again.',
      );
    }
  }

  Future<StoryItem> verifyPublishedStory(String storyId) async {
    final token = await _token();
    final response = await _storyGet(
      '/stories/status',
      token,
      query: <String, String>{'storyId': storyId},
    );
    // A deployed older Story backend may not yet have /stories/status.
    // In that case verify against its authenticated feed, never claim
    // success until the returned Story has a real playable media URL.
    if (response.statusCode == 404 || response.statusCode == 405) {
      final savedFeed = await fetchFeed();
      for (final story in savedFeed) {
        if (story.id == storyId && story.mediaUrl.isNotEmpty) {
          return story;
        }
      }
      throw StateError(
        'Story may be saved but is not visible in the feed yet. Retry verification.',
      );
    }
    final decoded = await _decode(response);
    final raw = decoded['story'];
    if (raw is! Map) {
      throw StateError('Story is saved, but its media is not available yet.');
    }
    final story = StoryItem.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (story.id != storyId || story.mediaUrl.isEmpty) {
      throw StateError('Story media could not be verified.');
    }
    return story;
  }

  String _mimeType(XFile file, String kind) {
    final explicit = file.mimeType?.trim().toLowerCase();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final path = file.path.toLowerCase();
    if (kind == 'video') {
      if (path.endsWith('.mov')) return 'video/quicktime';
      if (path.endsWith('.webm')) return 'video/webm';
      return 'video/mp4';
    }
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic') || path.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> _postStory(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final token = await _token();
    final response = await _client
        .post(
          _uri(path),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Future<Map<String, dynamic>> fetchStoryInteractions(
    String id, {
    String? viewCursor,
  }) async {
    final token = await _token();
    final response = await _storyGet(
      '/stories/interactions',
      token,
      query: <String, String>{'storyId': id, 'viewCursor': ?viewCursor},
    );
    return _decode(response);
  }

  Future<void> setStoryLiked(String id, {required bool liked}) async {
    await _postStory('/stories/like', <String, dynamic>{
      'storyId': id,
      'liked': liked,
    });
  }

  Future<void> commentOnStory(String id, String comment) async {
    await _postStory('/stories/comment', <String, dynamic>{
      'storyId': id,
      'text': comment,
    });
  }

  Future<Map<String, dynamic>> fetchStoryPreferences() async {
    final token = await _token();
    return _decode(await _storyGet('/stories/preferences', token));
  }

  Future<void> updateStoryPreferences({
    required bool allowReplies,
    required bool notifyActivity,
  }) async {
    await _postStory('/stories/preferences', <String, dynamic>{
      'allowReplies': allowReplies,
      'notifyActivity': notifyActivity,
    });
  }

  Future<List<Map<String, dynamic>>> fetchStoryNotifications() async {
    final token = await _token();
    final response = await _storyGet('/stories/notifications', token);
    final decoded = await _decode(response);
    final raw = decoded['events'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map(
          (event) => event.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  Future<void> registerStoryNotificationDevice(String token) async {
    await _postStory(
      '/stories/notifications/register-device',
      <String, dynamic>{'token': token},
    );
  }

  Future<void> recordView(String storyId) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/stories/view'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'storyId': storyId}),
    );
    await _decode(response);
  }

  Future<void> deleteStory(String storyId) async {
    final token = await _token();
    final request = http.Request('DELETE', _uri('/stories/$storyId'))
      ..headers['Authorization'] = 'Bearer $token';
    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    await _decode(http.Response(body, streamed.statusCode));
  }

  Future<StoryCloseFriendState> fetchCloseFriendState() async {
    final token = await _token();
    final response = await _client.get(
      _uri('/stories/close-friends'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    final rawIds = body['userIds'];
    final ids = rawIds is List
        ? rawIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet()
        : <String>{};
    return StoryCloseFriendState(isVip: body['isVip'] == true, userIds: ids);
  }

  Future<List<StoryCloseFriendCandidate>> fetchCloseFriendCandidates() async {
    final token = await _token();
    final response = await _client.get(
      _uri('/stories/close-friend-candidates'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    final raw = body['people'];
    if (raw is! List) return const <StoryCloseFriendCandidate>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => StoryCloseFriendCandidate.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => item.uid.isNotEmpty)
        .toList(growable: false);
  }

  Future<Set<String>> saveCloseFriends(Set<String> userIds) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/stories/close-friends'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userIds': userIds.toList(growable: false)}),
    );
    final body = await _decode(response);
    final raw = body['userIds'];
    if (raw is! List) return <String>{};
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
  }

  void dispose() {
    _client.close();
  }
}
