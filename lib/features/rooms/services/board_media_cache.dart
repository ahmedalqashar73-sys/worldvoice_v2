import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Keeps room media in each user's private app storage, instead of repeatedly
/// downloading the same PDF, photo or video. Shared URLs still come from the
/// room board so other participants can receive the media.
class BoardMediaCache {
  BoardMediaCache._();

  static const int maxFileBytes = 80 * 1024 * 1024;
  static const int maxCacheBytes = 250 * 1024 * 1024;

  static Future<Directory> _directory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}room_board_cache');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // Stable FNV-1a hash: unlike String.hashCode, unchanged across app launches.
  static String _filename(String url, String type) {
    const int mask = 0xffffffffffffffff;
    var hash = 0xcbf29ce484222325;
    for (final byte in url.codeUnits) {
      hash = ((hash ^ byte) * 0x100000001b3) & mask;
    }
    final extension = switch (type) {
      'pdf' => 'pdf',
      'image' => 'image',
      'video' => 'video',
      _ => 'media',
    };
    return '${hash.toRadixString(16)}.$extension';
  }

  static Future<File> _target(String url, String type) async {
    final directory = await _directory();
    return File('${directory.path}${Platform.pathSeparator}${_filename(url, type)}');
  }

  /// Seeds the cache from the owner's original local picker file. Uploading
  /// remains necessary to share with other devices.
  static Future<void> rememberLocalCopy({
    required String url,
    required String type,
    required File source,
  }) async {
    if (url.isEmpty || !await source.exists()) return;
    final size = await source.length();
    if (size <= 0 || size > maxFileBytes) return;
    final target = await _target(url, type);
    if (source.path != target.path) {
      await source.copy(target.path);
    }
    await _trim();
  }

  /// Reads a local cached copy first, downloading only on a cache miss.
  /// Failed/partial transfers never become cache hits.
  static Future<File> getFile(String url, String type) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      throw StateError('Invalid room media URL.');
    }
    final file = await _target(url, type);
    if (await file.exists() && await file.length() > 0) {
      // The modified time is also the least-recently-used eviction marker.
      await file.setLastModified(DateTime.now());
      return file;
    }

    final temporary = File('${file.path}.part');
    final client = http.Client();
    IOSink? sink;
    try {
      final request = http.Request('GET', uri);
      final response = await client.send(request).timeout(
        const Duration(seconds: 25),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Media download HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      if (response.contentLength != null &&
          response.contentLength! > maxFileBytes) {
        throw StateError('This file exceeds the 80 MB local cache limit.');
      }

      var total = 0;
      sink = temporary.openWrite();
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 25),
      )) {
        total += chunk.length;
        if (total > maxFileBytes) {
          throw StateError('This file exceeds the 80 MB local cache limit.');
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (total == 0) throw const FormatException('Downloaded an empty file.');
      // A different request may have populated the file while downloading.
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
      await _trim();
      return file;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<void> _trim() async {
    final directory = await _directory();
    final cached = <({File file, DateTime modified, int size})>[];
    var bytes = 0;
    await for (final entry in directory.list()) {
      if (entry is! File || entry.path.endsWith('.part')) continue;
      final stats = await entry.stat();
      bytes += stats.size;
      cached.add((file: entry, modified: stats.modified, size: stats.size));
    }
    if (bytes <= maxCacheBytes) return;
    cached.sort((a, b) => a.modified.compareTo(b.modified));
    for (final entry in cached) {
      if (bytes <= maxCacheBytes) break;
      try {
        await entry.file.delete();
        bytes -= entry.size;
      } catch (_) {
        // Storage cleanup must not prevent opening a successfully saved file.
      }
    }
  }
}
