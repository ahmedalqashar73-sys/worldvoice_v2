import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/media/cloudinary_image_service.dart';

class ChatExtendedService {
  ChatExtendedService({http.Client? client}) : _client = client ?? http.Client();

  static const String _backend =
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');
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

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/chat/group/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name.trim(), 'memberIds': memberIds}),
    );
    final body = await _decode(response);
    final chatId = (body['chatId'] ?? '').toString();
    if (chatId.isEmpty) throw StateError('Group was not created.');
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
    );
    await _decode(response);
  }

  Future<void> sendMedia({
    required String chatId,
    required File file,
    required String mediaType,
  }) async {
    final type = mediaType == 'video' ? 'video' : 'image';
    final upload = type == 'video'
        ? await CloudinaryImageService.uploadVideo(file, folder: 'worldvoice/chat')
        : await CloudinaryImageService.uploadImage(file, folder: 'worldvoice/chat');
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
      }),
    );
    await _decode(response);
  }

  void dispose() => _client.close();
}