import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/media/cloudinary_image_service.dart';

class HomePost {
  const HomePost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.mediaType,
    required this.mediaUrl,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.likedByMe,
    required this.createdAtMs,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String text;
  final String mediaType;
  final String mediaUrl;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool likedByMe;
  final int createdAtMs;

  bool get hasImage => mediaType == 'image' && mediaUrl.isNotEmpty;
  bool get hasVideo => mediaType == 'video' && mediaUrl.isNotEmpty;

  HomePost copyWith({
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? likedByMe,
  }) {
    return HomePost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      likedByMe: likedByMe ?? this.likedByMe,
      createdAtMs: createdAtMs,
    );
  }

  factory HomePost.fromJson(Map<String, dynamic> json) {
    return HomePost(
      id: (json['id'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorName: (json['authorName'] ?? 'WorldVoice').toString(),
      authorPhotoUrl: (json['authorPhotoUrl'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? '').toString(),
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomePostComment {
  const HomePostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.createdAtMs,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String text;
  final int createdAtMs;

  factory HomePostComment.fromJson(Map<String, dynamic> json) {
    return HomePostComment(
      id: (json['id'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorName: (json['authorName'] ?? 'WorldVoice').toString(),
      authorPhotoUrl: (json['authorPhotoUrl'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeFeedService {
  HomeFeedService({http.Client? client}) : _client = client ?? http.Client();

  static const String _backend =
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');
  final http.Client _client;

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authenticate the Home feed.');
    }
    return token;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = Uri.tryParse(_backend.trim());
    if (root == null ||
        root.scheme != 'https' ||
        !root.hasAuthority ||
        root.userInfo.isNotEmpty) {
      throw StateError('WorldVoice backend is not configured.');
    }
    final basePath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    return root.replace(
      path: '\$basePath\$path',
      queryParameters: query,
      fragment: null,
    );
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
        body['error']?.toString() ?? 'Home feed request failed.',
      );
    }
    return body;
  }

  Future<List<HomePost>> fetchFeed({int limit = 30}) async {
    final token = await _token();
    final response = await _client.get(
      _uri('/social/feed', {'limit': '\$limit'}),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    final raw = body['posts'];
    if (raw is! List) return const <HomePost>[];
    return raw
        .whereType<Map>()
        .map((value) => HomePost.fromJson(
              value.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .where((post) => post.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> createPost({
    required String text,
    File? media,
    String? mediaType,
  }) async {
    String mediaUrl = '';
    String mediaPublicId = '';
    final normalizedType =
        mediaType == 'image' || mediaType == 'video' ? mediaType! : '';

    if (media != null && normalizedType.isNotEmpty) {
      final upload = normalizedType == 'video'
          ? await CloudinaryImageService.uploadVideo(
              media,
              folder: 'worldvoice/posts',
            )
          : await CloudinaryImageService.uploadImage(
              media,
              folder: 'worldvoice/posts',
            );
      mediaUrl = upload.url;
      mediaPublicId = upload.publicId;
    }

    final token = await _token();
    final response = await _client.post(
      _uri('/social/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text.trim(),
        'mediaType': normalizedType,
        'mediaUrl': mediaUrl,
        'mediaPublicId': mediaPublicId,
      }),
    );
    await _decode(response);
  }

  Future<({bool liked, int likeCount})> toggleLike(HomePost post) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/social/posts/${post.id}/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    return (
      liked: body['liked'] == true,
      likeCount: (body['likeCount'] as num?)?.toInt() ?? post.likeCount,
    );
  }

  Future<List<HomePostComment>> fetchComments(String postId) async {
    final token = await _token();
    final response = await _client.get(
      _uri('/social/posts/\$postId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    final raw = body['comments'];
    if (raw is! List) return const <HomePostComment>[];
    return raw
        .whereType<Map>()
        .map((value) => HomePostComment.fromJson(
              value.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList(growable: false);
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/social/posts/\$postId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text.trim()}),
    );
    await _decode(response);
  }

  Future<void> recordShare(String postId) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/social/posts/\$postId/share'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _decode(response);
  }

  Future<void> deletePost(String postId) async {
    final token = await _token();
    final request = http.Request('DELETE', _uri('/social/posts/\$postId'))
      ..headers['Authorization'] = 'Bearer $token';
    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    await _decode(http.Response(body, streamed.statusCode));
  }

  void dispose() => _client.close();
}
