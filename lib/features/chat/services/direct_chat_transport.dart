import 'dart:io';
import 'package:flutter/foundation.dart';
import 'chat_delivery_service.dart';
import 'local_chat_store.dart';

/// Conversation facade over the app-scoped encrypted delivery queue.
/// Closing a conversation does not stop pending uploads or incoming messages.
class DirectChatTransport {
  DirectChatTransport({
    required this.uid,
    required this.peerId,
    required this.chatId,
    required this.store,
  });
  final String uid, peerId, chatId;
  final LocalChatStore store;
  ChatDeliverySession? _session;
  final connected = ValueNotifier<bool>(false);
  final error = ValueNotifier<String?>(null);
  String? get lastError => error.value;
  bool get isOnline => connected.value;

  Future<void> start() async {
    await ChatDeliveryService.instance.setAccount(uid);
    _session = ChatDeliveryService.instance.session(uid, peerId, chatId);
    _session!.connected.addListener(_sync);
    _session!.status.addListener(_sync);
    _sync();
    _session!.wake();
  }

  void _sync() {
    connected.value = _session?.connected.value ?? false;
    error.value = _session?.status.value;
  }

  Future<void> queueText(String text, {String bubbleId = 'free'}) async {
    await store.upsert({
      'id': LocalChatStore.newId(),
      'senderId': uid,
      'type': 'text',
      'text': text,
      'bubbleId': bubbleId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'version': DateTime.now().microsecondsSinceEpoch,
      'edited': false,
      'withdrawn': false,
      'hidden': false,
      'delivered': false,
      'sent': false,
      'read': false,
    });
    _session?.wake();
  }

  Future<void> queueMedia(File original, String type) async {
    final length = await original.length();
    if (length == 0 || length > ChatDeliverySession.maxBytes) {
      throw StateError('File must be between 1 byte and 80 MB');
    }
    final id = LocalChatStore.newId();
    final local = await store.saveAttachment(original, id);
    await store.upsert({
      'id': id,
      'senderId': uid,
      'type': type,
      'text': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'version': DateTime.now().microsecondsSinceEpoch,
      'filePath': local.path,
      'fileName': original.uri.pathSegments.last,
      'fileSize': length,
      'edited': false,
      'withdrawn': false,
      'hidden': false,
      'delivered': false,
      'sent': false,
      'read': false,
    });
    _session?.wake();
  }

  Future<void> flush() async {
    await _session?.pump();
  }

  Future<void> edit(String id, String text) async {
    final items = await store.messages();
    if (!items.any(
      (m) => m['id'] == id && m['senderId'] == uid && m['type'] == 'text',
    )) {
      return;
    }
    await store.patch(id, {
      'text': text,
      'edited': true,
      'delivered': false,
      'sent': false,
      'deliveryId': '',
      'version': DateTime.now().microsecondsSinceEpoch,
    });
    _session?.wake();
  }

  Future<void> withdraw(String id) async {
    final items = await store.messages();
    if (!items.any((m) => m['id'] == id && m['senderId'] == uid)) return;
    await store.patch(id, {
      'withdrawn': true,
      'text': '',
      'filePath': '',
      'delivered': false,
      'sent': false,
      'deliveryId': '',
      'version': DateTime.now().microsecondsSinceEpoch,
    });
    _session?.wake();
  }

  Future<void> dispose() async {
    _session?.connected.removeListener(_sync);
    _session?.status.removeListener(_sync);
    error.dispose();
    connected.dispose();
  }
}
