import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'story_filter_presets.dart';
export 'story_filter_presets.dart';

/// Export the *actual* filtered pixels before posting to Cloudinary.
/// Rendering a ColorFiltered preview alone would leave the published media raw.
Future<XFile> exportStoryPhotoFilter(
  XFile original,
  StoryPhotoFilter filter,
) async {
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
  final image = img.bakeOrientation(decoded).convert(format: img.Format.uint8);
  final matrix = storyFilterMatrix(
    storyFilterFromName(data['filter'] as String),
  );
  for (final pixel in image) {
    final rgb = storyFilteredRgb(matrix, pixel.r, pixel.g, pixel.b);
    pixel.setRgb(rgb[0], rgb[1], rgb[2]);
  }
  // Keep fine details after a Story filter; compression here is the final
  // upload output, not just the preview shown inside the editor.
  return Uint8List.fromList(img.encodeJpg(image, quality: 94));
}
