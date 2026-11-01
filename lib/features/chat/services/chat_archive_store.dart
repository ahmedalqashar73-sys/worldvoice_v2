import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local, per-account chat archive. Never deletes messages or uploads
/// private conversation identifiers into public user profile documents.
class ChatArchiveStore {
  ChatArchiveStore._(this.uid);
  final String uid;

  static final Map<String, ChatArchiveStore> _instances = {};
  static ChatArchiveStore of(String uid) =>
      _instances.putIfAbsent(uid, () => ChatArchiveStore._(uid));

  final ValueNotifier<Set<String>> archived = ValueNotifier(<String>{});
  Future<void>? _loading;

  String get _key => 'worldvoice_archived_chats_v1_$uid';

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      archived.value = prefs.getStringList(_key)?.toSet() ?? <String>{};
    } catch (_) {
      // An unavailable device preference must never interrupt messaging.
    }
  }

  bool contains(String chatId) => archived.value.contains(chatId);

  Future<void> setArchived(String chatId, bool value) async {
    if (chatId.isEmpty) return;
    await load();
    final prefs = await SharedPreferences.getInstance();
    final next = {...archived.value};
    if (value) {
      next.add(chatId);
    } else {
      next.remove(chatId);
    }
    if (!await prefs.setStringList(_key, next.toList()..sort())) {
      throw StateError('Could not save chat archive settings.');
    }
    archived.value = next;
  }
}
