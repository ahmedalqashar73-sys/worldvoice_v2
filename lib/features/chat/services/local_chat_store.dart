import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// The private transcript is never written to Firestore or the Render backend.
/// Each account/chat is AES-256-GCM encrypted under a device-keystore secret.
/// Uninstalling the app without an explicit backup permanently loses this data.
class LocalChatStore {
  LocalChatStore._(this.uid, this.chatId);

  final String uid;
  final String chatId;
  static final Map<String, LocalChatStore> _instances = {};
  static LocalChatStore of(String uid, String chatId) => _instances.putIfAbsent(
    '$uid:$chatId',
    () => LocalChatStore._(uid, chatId),
  );

  static const _secure = FlutterSecureStorage();
  static final _cipher = AesGcm.with256bits();
  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  List<Map<String, dynamic>>? _cached;
  Future<void>? _loading;
  Future<void> _serial = Future<void>.value();

  Future<Directory> _root() async {
    final base = await getApplicationSupportDirectory();
    final root = Directory(
      '${base.path}/worldvoice_private_chats/${uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}',
    );
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<File> _databaseFile() async {
    final root = await _root();
    final name = chatId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${root.path}/$name.wvc');
  }

  static final Map<String, Future<SecretKey>> _keys = {};
  Future<SecretKey> _key() => _keys.putIfAbsent(uid, _loadKey);

  Future<SecretKey> _loadKey() async {
    final keyName = 'worldvoice_chat_aes_v1_$uid';
    var stored = await _secure.read(key: keyName);
    if (stored == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      stored = base64Encode(bytes);
      await _secure.write(key: keyName, value: stored);
    }
    final bytes = base64Decode(stored);
    if (bytes.length != 32) {
      throw StateError('Invalid local chat encryption key');
    }
    return SecretKey(bytes);
  }

  Future<void> _load() async {
    if (_cached != null) return;
    final previousLoad = _loading;
    if (previousLoad != null) {
      await previousLoad;
      return;
    }
    final done = Completer<void>();
    _loading = done.future;
    try {
      final file = await _databaseFile();
      if (!await file.exists()) {
        _cached = <Map<String, dynamic>>[];
      } else {
        final encoded =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final box = SecretBox(
          base64Decode(encoded['cipher'] as String),
          nonce: base64Decode(encoded['nonce'] as String),
          mac: Mac(base64Decode(encoded['mac'] as String)),
        );
        final clear = await _cipher.decrypt(box, secretKey: await _key());
        final values = jsonDecode(utf8.decode(clear)) as List<dynamic>;
        _cached = values
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList();
      }
      done.complete();
    } catch (error, stack) {
      // Never overwrite a transcript we failed to decrypt.
      done.completeError(error, stack);
      rethrow;
    } finally {
      _loading = null;
    }
  }

  Future<List<Map<String, dynamic>>> messages() async {
    await _load();
    final copy = _cached!.map((e) => Map<String, dynamic>.from(e)).toList();
    copy.sort(
      (a, b) => (a['createdAt'] as int).compareTo(b['createdAt'] as int),
    );
    return copy;
  }

  Future<void> _persist() async {
    final clear = utf8.encode(jsonEncode(_cached));
    final box = await _cipher.encrypt(clear, secretKey: await _key());
    final file = await _databaseFile();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode({
        'nonce': base64Encode(box.nonce),
        'cipher': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      }),
      flush: true,
    );
    // Atomic replacement: never remove the last durable transcript first.
    await temp.rename(file.path);
    revision.value++;
  }

  Future<void> _mutate(
    FutureOr<void> Function(List<Map<String, dynamic>>) action,
  ) {
    final next = _serial.then((_) async {
      await _load();
      final previous = _cached!
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      try {
        await action(_cached!);
        await _persist();
      } catch (_) {
        // A failed disk write must never look like a saved delivery receipt.
        _cached = previous;
        rethrow;
      }
    });
    _serial = next.catchError((Object error, StackTrace stack) {
      debugPrint('WorldVoice private chat persistence failed: $error');
    });
    return next;
  }

  Future<void> upsert(Map<String, dynamic> message) => _mutate((items) {
    final index = items.indexWhere((item) => item['id'] == message['id']);
    if (index >= 0) {
      items[index] = {...items[index], ...message};
    } else {
      items.add(Map<String, dynamic>.from(message));
    }
  });

  Future<void> patch(String id, Map<String, dynamic> changes) =>
      _mutate((items) {
        final index = items.indexWhere((item) => item['id'] == id);
        if (index != -1) items[index] = {...items[index], ...changes};
      });

  Future<bool> patchIf(
    String id,
    Map<String, dynamic> expected,
    Map<String, dynamic> changes,
  ) async {
    var changed = false;
    await _mutate((items) {
      final index = items.indexWhere((m) => m['id'] == id);
      if (index < 0 ||
          expected.entries.any((e) => items[index][e.key] != e.value)) {
        return;
      }
      items[index] = {...items[index], ...changes};
      changed = true;
    });
    return changed;
  }

  Future<void> hide(String id) => patch(id, {'hidden': true});

  Future<void> clear() async {
    final items = await messages();
    await _mutate((records) => records.clear());
    final root = await getApplicationSupportDirectory();
    for (final item in items) {
      final value = item['filePath']?.toString() ?? '';
      if (value.isEmpty) continue;
      final path = File(value).absolute.path;
      final privateRoot = Directory(
        '${root.path}/worldvoice_private_chats',
      ).absolute.path;
      final incomingRoot = Directory(
        '${root.path}/worldvoice_peer_media',
      ).absolute.path;
      if (!path.startsWith('$privateRoot/') &&
          !path.startsWith('$incomingRoot/')) {
        continue;
      }
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Local cleanup is best effort; never restore erased chat history.
      }
    }
  }

  Future<File> saveAttachment(File original, String id) async {
    final root = await _root();
    final folder = Directory('${root.path}/media');
    if (!await folder.exists()) await folder.create(recursive: true);
    final extension = original.path
        .split('.')
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final output = File(
      '${folder.path}/${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.$extension',
    );
    return original.copy(output.path);
  }

  static String newId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32).toRadixString(16)}';
  }
}
