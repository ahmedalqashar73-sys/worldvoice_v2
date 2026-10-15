import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../rooms/data/room_backend_config.dart';

class EngagementService {
  static Future<Map<String, dynamic>> request(String path,
      {Map<String, dynamic>? body}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('SIGN_IN_REQUIRED');
    final base = RoomBackendConfig.economyBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/engagement/$path');
    if (uri.scheme != 'https' || !uri.hasAuthority) throw StateError('UNAVAILABLE');
    final token = await user.getIdToken();
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final response = await (body == null ? http.get(uri, headers: headers)
        : http.post(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('ENGAGEMENT_${response.statusCode}');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  // Coalesce visible seat/profile requests into one batch. No Firestore listeners.
  static final _pending = <String, Completer<Map<String, dynamic>>>{};
  static final _cache = <String, (DateTime, Map<String, dynamic>)>{};
  static Timer? _batch;
  static String? _viewer;
  static Future<Map<String, dynamic>> badge(String uid) {
    final viewer = FirebaseAuth.instance.currentUser?.uid;
    if (_viewer != viewer) { _cache.clear(); _viewer = viewer; }
    final cached = _cache[uid];
    if (cached != null && DateTime.now().difference(cached.$1).inSeconds < 60) {
      return Future.value(cached.$2);
    }
    final completer = _pending.putIfAbsent(uid, () => Completer<Map<String, dynamic>>());
    _batch ??= Timer(const Duration(milliseconds: 50), _flush);
    return completer.future;
  }
  static Future<void> _flush() async {
    _batch = null;
    final pending = Map<String, Completer<Map<String, dynamic>>>.from(_pending);
    _pending.clear();
    final ids = pending.keys.toList();
    for (var offset = 0; offset < ids.length; offset += 30) {
      final batch = ids.skip(offset).take(30).toList();
      try {
        final result = await request('badges?userIds=${Uri.encodeQueryComponent(batch.join(','))}');
        final badges = result['badges'] as Map;
        for (final uid in batch) {
          final value = Map<String, dynamic>.from(badges[uid] as Map? ?? {});
          if (_cache.length >= 200) _cache.remove(_cache.keys.first);
          _cache[uid] = (DateTime.now(), value);
          pending[uid]!.complete(value);
        }
      } catch (error, stack) {
        for (final uid in batch) { pending[uid]!.completeError(error, stack); }
      }
    }
  }
  static void invalidate(String uid) => _cache.remove(uid);
}
