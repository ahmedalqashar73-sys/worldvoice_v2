import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryImageService {
  CloudinaryImageService._();

  static const _cloudName = 'ypmmcyxm';
  static const _uploadPreset = 'worldvoice';

  static Uri _uploadUri(String resourceType) =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');

  static Future<CloudinaryUpload> uploadImage(
    File file, {
    required String folder,
  }) {
    return _upload(
      file,
      folder: folder,
      resourceType: 'image',
    );
  }

  /// Cloudinary treats audio files as the video resource type.
  static Future<CloudinaryUpload> uploadAudio(
    File file, {
    required String folder,
  }) {
    return _upload(
      file,
      folder: folder,
      resourceType: 'video',
    );
  }

  static Future<CloudinaryUpload> uploadVideo(
    File file, {
    required String folder,
  }) {
    return _upload(
      file,
      folder: folder,
      resourceType: 'video',
    );
  }

  static Future<CloudinaryUpload> uploadRaw(
    File file, {
    required String folder,
  }) {
    return _upload(
      file,
      folder: folder,
      resourceType: 'raw',
    );
  }
  /// Cloudinary supports PDF assets under the image resource type.
  /// Existing raw/upload PDF URLs must be re-uploaded if their public
  /// delivery is disabled (HTTP 401 on another device).
  static Future<CloudinaryUpload> uploadPdf(
    File file, {
    required String folder,
  }) {
    return _upload(
      file,
      folder: folder,
      resourceType: 'image',
    );
  }

  /// Check CDN delivery before publishing a URL to Firestore. The owner's
  /// phone may have a local copy even when the guest gets HTTP 401.
  static Future<void> ensurePublicDelivery(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' ||
        uri.host != 'res.cloudinary.com') {
      throw StateError('Cloudinary returned an invalid media URL.');
    }
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)
        ..headers['Range'] = 'bytes=0-0';
      final response = await client.send(request).timeout(
        const Duration(seconds: 20),
      );
      final statusCode = response.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw StateError(
          'Cloudinary blocks public delivery of this file (HTTP '
          '$statusCode). Enable PDF/ZIP delivery in Cloudinary '
          'Security settings or use an approved public upload preset.',
        );
      }
      if (statusCode < 200 || statusCode >= 300) {
        throw StateError(
          'Uploaded media cannot be viewed by guests (HTTP $statusCode).',
        );
      }
    } finally {
      client.close();
    }
  }


  static Future<CloudinaryUpload> _upload(
    File file, {
    required String folder,
    required String resourceType,
  }) async {
    final request = http.MultipartRequest('POST', _uploadUri(resourceType))
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Cloudinary upload failed');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    final publicId = json['public_id'] as String?;
    if (url == null || publicId == null) {
      throw StateError('Cloudinary returned an invalid upload response');
    }
    return CloudinaryUpload(url: url, publicId: publicId);
  }
}

class CloudinaryUpload {
  const CloudinaryUpload({required this.url, required this.publicId});
  final String url;
  final String publicId;
}
