import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../rooms/data/room_backend_config.dart';

class GroupCallInfo {
  const GroupCallInfo({
    required this.id,
    required this.chatId,
    required this.groupName,
    required this.channelId,
    required this.type,
    required this.status,
    required this.ownerId,
    required this.memberIds,
    required this.joinedIds,
    required this.memberNames,
  });

  final String id;
  final String chatId;
  final String groupName;
  final String channelId;
  final String type;
  final String status;
  final String ownerId;
  final List<String> memberIds;
  final List<String> joinedIds;
  final Map<String, String> memberNames;
  bool get isVideo => type == 'video';
  bool get isActive => status == 'active';

  factory GroupCallInfo.fromJson(Map<String, dynamic> json) {
    List<String> ids(Object? value) => value is List
        ? value.map((id) => id.toString()).toList(growable: false)
        : const <String>[];
    final rawNames = json['memberNames'];
    return GroupCallInfo(
      id: (json['id'] ?? '').toString(),
      chatId: (json['chatId'] ?? '').toString(),
      groupName: (json['groupName'] ?? 'WorldVoice group').toString(),
      channelId: (json['channelId'] ?? '').toString(),
      type: (json['type'] ?? 'audio').toString(),
      status: (json['status'] ?? 'ended').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      memberIds: ids(json['memberIds']),
      joinedIds: ids(json['joinedIds']),
      memberNames: rawNames is Map
          ? rawNames.map((key, value) =>
                MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
    );
  }
}

class GroupCallService {
  GroupCallService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) {
    final url = Uri.tryParse(RoomBackendConfig.socialBaseUrl.trim());
    if (url == null || url.scheme != 'https' ||
        !url.hasAuthority || url.userInfo.isNotEmpty) {
      throw StateError('WorldVoice group call backend is not configured.');
    }
    final prefix = url.path.endsWith('/')
        ? url.path.substring(0, url.path.length - 1)
        : url.path;
    return url.replace(path: '$prefix$path', query: null, fragment: null);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to join a group call.');
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = body == null
        ? await _client.get(_uri(path), headers: headers)
            .timeout(RoomBackendConfig.socialRequestTimeout)
        : await _client.post(
            _uri(path), headers: headers, body: jsonEncode(body),
          ).timeout(RoomBackendConfig.socialRequestTimeout);
    Map<String, dynamic> result = const {};
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) result = data;
    } catch (_) {}
    if (response.statusCode < 200 ||
        response.statusCode >= 300 || result['ok'] != true) {
      throw StateError(
        (result['error'] ?? 'Group call request failed.').toString(),
      );
    }
    return result;
  }

  GroupCallInfo? _call(Map<String, dynamic> data) {
    final value = data['call'];
    return value is Map<String, dynamic> ? GroupCallInfo.fromJson(value) : null;
  }

  Future<GroupCallInfo> start(String chatId, String type) async {
    final result = await _request('/calls/group/start',
        body: {'chatId': chatId, 'type': type});
    return _call(result)!;
  }

  Future<GroupCallInfo?> incoming() async =>
      _call(await _request('/calls/group/incoming'));

  Future<GroupCallInfo?> status(String chatId) async =>
      _call(await _request('/calls/group/$chatId/status'));

  Future<GroupCallInfo> join(String chatId) async =>
      _call(await _request('/calls/group/$chatId/join', body: {}))!;

  Future<void> decline(String chatId) async {
    await _request('/calls/group/$chatId/decline', body: {});
  }

  Future<void> leave(String chatId) async {
    await _request('/calls/group/$chatId/leave', body: {});
  }

  Future<void> end(String chatId) async {
    await _request('/calls/group/$chatId/end', body: {});
  }

  void dispose() => _client.close();
}
