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
  const StoryCloseFriendState({
    required this.isVip,
    required this.userIds,
  });

  final bool isVip;
  final Set<String> userIds;
}

class StoryService {
  StoryService({http.Client? client}) : _client = client ?? http.Client();

  static const String _endpoint =
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');
  final http.Client _client;

  Uri _uri(String path) {
    final root = Uri.tryParse(_endpoint.trim());
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

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to use Stories.');
    final token = await user.getIdToken();
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
      throw StateError(
        body['error']?.toString() ?? 'Story request failed.',
      );
    }
    return body;
  }

  Future<List<StoryItem>> fetchFeed() async {
    final token = await _token();
    final response = await _client.get(
      _uri('/stories/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    final raw = body['stories'];
    if (raw is! List) return const <StoryItem>[];
    return raw
        .whereType<Map>()
        .map((item) => StoryItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .where((item) => item.id.isNotEmpty && item.mediaUrl.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> uploadStory({
    required XFile file,
    required String kind,
    required String audience,
    required int durationMs,
  }) async {
    final token = await _token();
    final length = await file.length();
    final mime = _mimeType(file, kind);
    final request = http.StreamedRequest('POST', _uri('/stories/upload'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': mime,
      'X-Story-Kind': kind,
      'X-Story-Audience': audience,
      'X-Story-Duration-Ms': '$durationMs',
    });
    request.contentLength = length;
    await request.sink.addStream(file.openRead());
    await request.sink.close();

    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    final response = http.Response(
      body,
      streamed.statusCode,
      headers: streamed.headers,
    );
    await _decode(response);
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
    final request = http.Request(
      'DELETE',
      _uri('/stories/$storyId'),
    )..headers['Authorization'] = 'Bearer $token';
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
    return StoryCloseFriendState(
      isVip: body['isVip'] == true,
      userIds: ids,
    );
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
        .map((item) => StoryCloseFriendCandidate.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
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
