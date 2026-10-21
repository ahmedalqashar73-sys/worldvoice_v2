/// Safely prepare Spanish reading and podcast scripts for device TTS.
///
/// Android's native TTS engine typically rejects utterances longer than
/// approximately 4,000 characters. 2,400 UTF-16 code units leave room for
/// differences between installed voices and platform implementations.
/// No words are dropped; order is preserved across chunks.
abstract final class SpanishSpeechChunks {
  static List<String> split(String text, {int maxCharacters = 2400}) {
    if (maxCharacters < 8) {
      throw RangeError.range(maxCharacters, 8, null, 'maxCharacters');
    }
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return const <String>[];

    final chunks = <String>[];
    var current = '';
    for (final word in normalized.split(' ')) {
      // Ordinary Spanish words fit; this also supports anomalously long
      // words or URLs, without letting a single chunk exceed the limit.
      var remaining = word;
      while (remaining.isNotEmpty) {
        if (current.isEmpty) {
          final length = remaining.length < maxCharacters
              ? remaining.length : maxCharacters;
          current = remaining.substring(0, length);
          remaining = remaining.substring(length);
        } else if (current.length + 1 + remaining.length <= maxCharacters) {
          current = '$current $remaining';
          remaining = '';
        } else {
          chunks.add(current);
          current = '';
        }
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return List<String>.unmodifiable(chunks);
  }
}
