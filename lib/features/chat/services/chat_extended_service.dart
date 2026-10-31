import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../rooms/data/room_backend_config.dart';

import '../../../core/media/cloudinary_image_service.dart';
import '../../rooms/services/board_media_cache.dart';

class ChatExtendedService {
  ChatExtendedService({http.Client? client}) : _client = client ?? http.Client();

  static const String _backend =
      RoomBackendConfig.socialBaseUrl;
  final http.Client _client;

  Uri _uri(String path) {
    final root = Uri.tryParse(_backend.trim());
    if (root == null || root.scheme != 'https' || !root.hasAuthority ||
        root.userInfo.isNotEmpty) {
      throw StateError('WorldVoice chat backend is not configured.');
    }
    final basePath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    return root.replace(path: '$basePath$path', query: null, fragment: null);
  }

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to chat.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authenticate chat.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) body = raw;
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        body['ok'] != true) {
      throw StateError(body['error']?.toString() ?? 'Chat request failed.');
    }
    return body;
  }

  String _requestKey() {
    final random = Random();
    return List<int>.generate(24, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  final Map<String, String> _groupKeys = {};

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final members = [...memberIds]..sort();
    final identity = jsonEncode([name.trim(), members]);
    final key = _groupKeys.putIfAbsent(identity, _requestKey);
    final token = await _token();
    final response = await _client.post(
      _uri('/chat/group/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Idempotency-Key': key,
      },
      body: jsonEncode({'name': name.trim(), 'memberIds': memberIds}),
    ).timeout(RoomBackendConfig.socialRequestTimeout,
        onTimeout: () => throw StateError('The chat server is waking up or unavailable. Check whether the message arrived before retrying.'));
    final body = await _decode(response);
    final chatId = (body['chatId'] ?? '').toString();
    if (chatId.isEmpty) throw StateError('Group was not created.');
    _groupKeys.remove(identity);
    return chatId;
  }

  Future<void> sendText({
    required String chatId,
    required String text,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final token = await _token();
    final response = await _client.post(
      _uri('/chat/message'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Idempotency-Key': _requestKey(),
      },
      body: jsonEncode({'chatId': chatId, 'text': value}),
    ).timeout(RoomBackendConfig.socialRequestTimeout,
        onTimeout: () => throw StateError('The chat server is waking up or unavailable. Check whether the message arrived before retrying.'));
    await _decode(response);
  }

  Future<void> sendMedia({
    required String chatId,
    required File file,
    required String mediaType,
  }) async {
    final type = mediaType.trim().toLowerCase();
    if (!const <String>['image', 'video', 'audio', 'pdf'].contains(type)) {
      throw StateError('Unsupported chat attachment type.');
    }
    if (!await file.exists()) throw StateError('The attachment is unavailable.');
    final fileSize = await file.length();
    final maximum = (type == 'pdf' || type == 'audio')
        ? 20 * 1024 * 1024 : 80 * 1024 * 1024;
    if (fileSize <= 0 || fileSize > maximum) {
      throw StateError('The attachment is empty or exceeds the allowed size.');
    }
    final fileName = file.uri.pathSegments.last;
    if (type == 'pdf' && !fileName.toLowerCase().endsWith('.pdf')) {
      throw StateError('Choose a PDF document.');
    }

    final upload = switch (type) {
      'video' => await CloudinaryImageService.uploadVideo(
          file, folder: 'worldvoice/chat'),
      'audio' => await CloudinaryImageService.uploadAudio(
          file, folder: 'worldvoice/chat'),
      'pdf' => await CloudinaryImageService.uploadRaw(
          file, folder: 'worldvoice/chat'),
      _ => await CloudinaryImageService.uploadImage(
          file, folder: 'worldvoice/chat'),
    };
    final token = await _token();
    final response = await _client.post(
      _uri('/chat/media'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Idempotency-Key': _requestKey(),
      },
      body: jsonEncode({
        'chatId': chatId,
        'mediaType': type,
        'mediaUrl': upload.url,
        'mediaPublicId': upload.publicId,
        'fileName': fileName,
        'fileSize': fileSize,
      }),
    ).timeout(RoomBackendConfig.socialRequestTimeout,
        onTimeout: () => throw StateError(
            'The chat server is unavailable. Check before retrying.'));
    await _decode(response);
    // A successfully sent file remains on this phone. Recipients download
    // into their own bounded app-private cache when they open the message.
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await BoardMediaCache.rememberLocalCopy(
          url: upload.url, type: type, source: file,
          cacheScope: 'chat_$uid',
        );
      }
    } catch (_) {
      // Delivery succeeded; an optional local cache failure must not
      // mark the message as unsent or cause duplicate retries.
    }
  }

  void dispose() => _client.close();
}