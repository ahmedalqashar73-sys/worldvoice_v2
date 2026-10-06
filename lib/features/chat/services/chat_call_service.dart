import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ChatCallInfo {
  const ChatCallInfo({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerPhotoUrl,
    required this.recipientId,
    required this.chatId,
    required this.type,
    required this.channelId,
    required this.status,
  });

  final String id;
  final String callerId;
  final String callerName;
  final String callerPhotoUrl;
  final String recipientId;
  final String chatId;
  final String type;
  final String channelId;
  final String status;

  bool get isVideo => type == 'video';

  factory ChatCallInfo.fromJson(Map<String, dynamic> json) {
    return ChatCallInfo(
      id: (json['id'] ?? json['callId'] ?? '').toString(),
      callerId: (json['callerId'] ?? '').toString(),
      callerName: (json['callerName'] ?? 'WorldVoice').toString(),
      callerPhotoUrl: (json['callerPhotoUrl'] ?? '').toString(),
      recipientId: (json['recipientId'] ?? '').toString(),
      chatId: (json['chatId'] ?? '').toString(),
      type: (json['type'] ?? 'audio').toString(),
      channelId: (json['channelId'] ?? '').toString(),
      status: (json['status'] ?? 'ringing').toString(),
    );
  }
}

class ChatCallService {
  ChatCallService({http.Client? client}) : _client = client ?? http.Client();

  static const String _backend =
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');
  final http.Client _client;

  Uri _uri(String path) {
    final root = Uri.tryParse(_backend.trim());
    if (root == null || root.scheme != 'https' || !root.hasAuthority ||
        root.userInfo.isNotEmpty) {
      throw StateError('WorldVoice call backend is not configured.');
    }
    final basePath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    return root.replace(path: '$basePath$path', query: null, fragment: null);
  }

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to call.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authenticate call.');
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
      throw StateError(body['error']?.toString() ?? 'Call request failed.');
    }
    return body;
  }

  Future<ChatCallInfo> startCall({
    required String recipientId,
    required String chatId,
    required String type,
  }) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/calls/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipientId': recipientId,
        'chatId': chatId,
        'type': type,
      }),
    );
    final body = await _decode(response);
    return ChatCallInfo.fromJson({
      ...body,
      'id': body['callId'],
      'recipientId': recipientId,
      'chatId': chatId,
    });
  }

  Future<ChatCallInfo?> incoming() async {
    final token = await _token();
    final response = await _client.get(
      _uri('/calls/incoming'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    final raw = body['call'];
    if (raw is! Map) return null;
    return ChatCallInfo.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<String> status(String callId) async {
    final token = await _token();
    final response = await _client.get(
      _uri('/calls/$callId/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    return (body['status'] ?? 'ended').toString();
  }

  Future<Map<String, dynamic>> respond({
    required String callId,
    required String action,
  }) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/calls/$callId/respond'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );
    return _decode(response);
  }

  Future<void> end(String callId) async {
    final token = await _token();
    final response = await _client.post(
      _uri('/calls/$callId/end'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _decode(response);
  }

  void dispose() => _client.close();
}