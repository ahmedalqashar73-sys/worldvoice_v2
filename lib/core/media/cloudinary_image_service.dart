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
