import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Files imported into this library live on the current device only.
/// Other room members can watch them through screen sharing, but they do not
/// receive a copy of the original file.
class RoomDeviceMedia {
  const RoomDeviceMedia({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    required this.sizeBytes,
  });

  final String id;
  final String type;
  final String name;
  final String path;
  final int sizeBytes;

  factory RoomDeviceMedia.fromJson(Map<String, dynamic> json) =>
      RoomDeviceMedia(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        path: (json['path'] ?? '').toString(),
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'path': path,
        'sizeBytes': sizeBytes,
      };
}

class RoomDeviceMediaStore {
  static const int maxFileBytes = 150 * 1024 * 1024;

  Future<Directory> _mediaDirectory() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(
      root.path + Platform.pathSeparator + 'worldvoice_device_media',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _legacyCacheDirectory() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(
      root.path + Platform.pathSeparator + 'worldvoice_legacy_pdf_cache',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String get _prefsKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in before using your personal media library.');
    }
    return 'worldvoice_device_media_v1_' + uid;
  }

  Future<List<RoomDeviceMedia>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return const <RoomDeviceMedia>[];
    final json = jsonDecode(raw);
    if (json is! List) return const <RoomDeviceMedia>[];
    final records = json
        .whereType<Map>()
        .map((item) => RoomDeviceMedia.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
    final existing = <RoomDeviceMedia>[];
    for (final record in records) {
      if (record.path.isNotEmpty && await File(record.path).exists()) {
        existing.add(record);
      }
    }
    return existing;
  }

  Future<void> _save(List<RoomDeviceMedia> items) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((item) => item.toJson()).toList(growable: false)),
    );
    if (!success) {
      throw StateError('Could not save this device library.');
    }
  }

  Future<RoomDeviceMedia> importFile({
    required String sourcePath,
    required String name,
    required String type,
  }) async {
    if (!const <String>['pdf', 'video', 'image'].contains(type)) {
      throw ArgumentError.value(type, 'type', 'Unsupported media type');
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('The selected file is no longer available.');
    }
    final length = await source.length();
    if (length == 0 || length > maxFileBytes) {
      throw StateError(
        'Choose a nonempty file smaller than 150 MB to limit phone storage.',
      );
    }
    final directory = await _mediaDirectory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final extension = name.contains('.')
        ? name.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        : 'bin';
    final suffix = extension.isEmpty ? 'bin' : extension.substring(
      0, extension.length > 8 ? 8 : extension.length,
    ).toLowerCase();
    final dest = File(
      directory.path + Platform.pathSeparator + id + '.' + suffix,
    );
    await source.copy(dest.path);

    // Check a PDF signature before persisting the selection; an HTML error
    // page renamed as .pdf otherwise leaves the viewer spinning.
    if (type == 'pdf' && !await isPdf(dest)) {
      await dest.delete();
      throw StateError('This file is not a valid PDF.');
    }

    final media = RoomDeviceMedia(
      id: id,
      type: type,
      name: name,
      path: dest.path,
      sizeBytes: length,
    );
    try {
      final entries = await load();
      await _save(<RoomDeviceMedia>[media, ...entries]);
    } catch (_) {
      if (await dest.exists()) await dest.delete();
      rethrow;
    }
    return media;
  }

  Future<void> remove(RoomDeviceMedia media) async {
    final entries = await load();
    final owned = entries.any(
      (item) => item.id == media.id && item.path == media.path,
    );
    if (!owned) return;
    // Only remove copies that were created inside this application's private
    // directory. Never delete files from the user's Downloads or Gallery.
    final directory = await _mediaDirectory();
    final prefix = directory.absolute.path + Platform.pathSeparator;
    if (File(media.path).absolute.path.startsWith(prefix)) {
      final file = File(media.path);
      if (await file.exists()) await file.delete();
    }
    await _save(entries.where((item) => item.id != media.id).toList());
  }

  static Future<bool> isPdf(File file) async {
    if (!await file.exists() || await file.length() < 5) return false;
    final raf = await file.open(mode: FileMode.read);
    try {
      final bytes = await raf.read(5);
      return utf8.decode(bytes, allowMalformed: true) == '%PDF-';
    } finally {
      await raf.close();
    }
  }

  /// Older cloud-hosted PDFs are downloaded only when requested, with a
  /// timeout and an on-device cache. New imports never call this method.
  Future<File> cacheOlderPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      throw StateError('The old PDF link is not secure or is invalid.');
    }
    final directory = await _legacyCacheDirectory();
    final id = sha256.convert(utf8.encode(url)).toString();
    final file = File(
      directory.path + Platform.pathSeparator + id + '.pdf',
    );
    if (await isPdf(file)) return file;
    if (await file.exists()) await file.delete();

    final part = File(file.path + '.part');
    final client = http.Client();
    IOSink? sink;
    try {
      final response = await client.send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw StateError(
          'Old PDF download failed (HTTP ' +
              response.statusCode.toString() +
              '). Re-import the file from this phone.',
        );
      }
      if (response.contentLength != null &&
          response.contentLength! > maxFileBytes) {
        throw StateError('The PDF is too large for the local media library.');
      }
      sink = part.openWrite();
      var total = 0;
      await for (final bytes in response.stream.timeout(
        const Duration(seconds: 15),
      )) {
        total += bytes.length;
        if (total > maxFileBytes) {
          throw StateError('The PDF is too large for the local media library.');
        }
        sink.add(bytes);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (!await isPdf(part)) {
        throw StateError(
          'This link did not return a PDF. Re-import the original document.',
        );
      }
      return await part.rename(file.path);
    } finally {
      if (sink != null) await sink.close();
      client.close();
      if (await part.exists()) await part.delete();
    }
  }
}
