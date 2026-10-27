import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum StoryPhotoFilter { original, vivid, warm, cool, mono, vintage }

/// Export the *actual* filtered pixels before posting to Cloudinary.
/// Rendering a ColorFiltered preview alone would leave the published media raw.
Future<XFile> exportStoryPhotoFilter(
    XFile original, StoryPhotoFilter filter) async {
  if (filter == StoryPhotoFilter.original) return original;
  final bytes = await original.readAsBytes();
  final output = await compute(_filterImage, <String, Object>{
    'bytes': bytes,
    'filter': filter.name,
  });
  final directory = await getTemporaryDirectory();
  final path =
      '${directory.path}/wv_story_${DateTime.now().microsecondsSinceEpoch}.jpg';
  await File(path).writeAsBytes(output, flush: true);
  return XFile(path, mimeType: 'image/jpeg');
}

Uint8List _filterImage(Map<String, Object> data) {
  final bytes = data['bytes'] as Uint8List;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('This photo format cannot be filtered. Choose Original.');
  }
  final image = img.bakeOrientation(decoded);
  switch (data['filter'] as String) {
    case 'vivid':
      img.adjustColor(image, saturation: 1.24, contrast: 1.10);
    case 'warm':
      img.adjustColor(image, saturation: 1.10, hue: -7, exposure: .09);
    case 'cool':
      img.adjustColor(image, saturation: 1.04, hue: 9, contrast: 1.04);
    case 'mono':
      img.grayscale(image);
    case 'vintage':
      img.adjustColor(image, saturation: .60, contrast: .95, exposure: .05);
  }
  // Keep fine details after a Story filter; compression here is the final
  // upload output, not just the preview shown inside the editor.
  return Uint8List.fromList(img.encodeJpg(image, quality: 94));
}
