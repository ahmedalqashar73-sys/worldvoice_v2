// Standalone check intentionally runs with plain Dart before Flutter tests.
// ignore_for_file: avoid_relative_lib_imports, avoid_print
import '../lib/features/stories/services/story_filter_presets.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final original = storyFilterMatrix(StoryPhotoFilter.original);
  for (final rgb in [
    [0, 0, 0],
    [255, 255, 255],
    [40, 120, 230],
  ]) {
    check(
      storyFilteredRgb(original, rgb[0], rgb[1], rgb[2]).join(',') ==
          rgb.join(','),
      'Original must preserve every channel',
    );
  }
  final mono = storyFilteredRgb(
    storyFilterMatrix(StoryPhotoFilter.mono),
    200,
    90,
    40,
  );
  check(mono[0] == mono[1] && mono[1] == mono[2], 'Mono must be neutral gray');
  final warm = storyFilteredRgb(
    storyFilterMatrix(StoryPhotoFilter.warm),
    120,
    120,
    120,
  );
  final cool = storyFilteredRgb(
    storyFilterMatrix(StoryPhotoFilter.cool),
    120,
    120,
    120,
  );
  check(
    warm[0] > warm[2] && cool[2] > cool[0],
    'Warm/cool should shift neutral colors correctly',
  );
  check(
    storyFilterFromName('unknown_future_filter') == StoryPhotoFilter.original,
    'Unknown metadata must fall back safely',
  );
  for (final filter in StoryPhotoFilter.values) {
    check(
      storyFilterFromName(filter.name) == filter,
      'Persisted filter must round trip',
    );
    final matrix = storyFilterMatrix(filter);
    check(
      matrix.length == 20 && matrix.every((v) => v.isFinite),
      'Valid color matrix required',
    );
    check(matrix[18] == 1 && matrix[19] == 0, 'Filters must preserve alpha');
    for (final rgb in [
      [0, 0, 0],
      [255, 255, 255],
      [255, 0, 255],
    ]) {
      check(
        storyFilteredRgb(
          matrix,
          rgb[0],
          rgb[1],
          rgb[2],
        ).every((c) => c >= 0 && c <= 255),
        'Exported pixels must stay in 8-bit range',
      );
    }
  }
  print(
    'PASS: identity, grayscale, color temperature, metadata fallback, all 8 matrices and export bounds',
  );
}
