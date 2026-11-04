/// Independent graded reading library. Existing lesson stories are untouched.
enum StoryLibrarySpeaker { female, male, narrator }

enum StoryLibraryAnimation { slowZoom, panLeft, panRight, fadeIn }

Map<String, dynamic> _asObject(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$path must be a JSON object.');
  }
  return value;
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

String? _optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('$key must be a string when supplied.');
  }
  return value.trim().isEmpty ? null : value.trim();
}

List<T> _readObjects<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) read,
) {
  final source = json[key];
  if (source is! List) {
    throw FormatException('$key must be a JSON array.');
  }
  return List<T>.unmodifiable(
    source.asMap().entries.map(
      (entry) => read(_asObject(entry.value, '$key[${entry.key}]')),
    ),
  );
}

class StoryLibraryLine {
  const StoryLibraryLine({
    required this.speaker,
    required this.text,
    this.audio,
  });

  final StoryLibrarySpeaker speaker;
  final String text;

  /// Optional owned asset path or server media URL (playback added in phase 4).
  final String? audio;

  factory StoryLibraryLine.fromJson(Map<String, dynamic> json) {
    final label = _requiredText(json, 'speaker')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .toUpperCase();
    final speaker = switch (label) {
      'FEMALE' => StoryLibrarySpeaker.female,
      'MALE' => StoryLibrarySpeaker.male,
      'NARRATOR' => StoryLibrarySpeaker.narrator,
      _ => throw FormatException('Unsupported speaker: $label'),
    };
    return StoryLibraryLine(
      speaker: speaker,
      text: _requiredText(json, 'text'),
      audio: _optionalText(json, 'audio'),
    );
  }
}

class StoryLibraryPage {
  const StoryLibraryPage({
    required this.page,
    required this.script,
    required this.translationAr,
    required this.imagePrompt,
    required this.animation,
    this.image,
  });

  final int page;
  final List<StoryLibraryLine> script;
  final String translationAr;
  final String imagePrompt;
  final StoryLibraryAnimation animation;

  /// Optional owned asset path or server media URL (rendered in phase 3).
  final String? image;

  factory StoryLibraryPage.fromJson(Map<String, dynamic> json) {
    final number = json['page'];
    if (number is! int || number < 1) {
      throw const FormatException('page must be a positive integer.');
    }
    final lines = _readObjects(json, 'script', StoryLibraryLine.fromJson);
    if (lines.isEmpty) {
      throw const FormatException('Every story page needs a script.');
    }
    final animationName = _requiredText(json, 'animation');
    final animation = switch (animationName) {
      'slow_zoom' => StoryLibraryAnimation.slowZoom,
      'pan_left' => StoryLibraryAnimation.panLeft,
      'pan_right' => StoryLibraryAnimation.panRight,
      'fade_in' => StoryLibraryAnimation.fadeIn,
      _ => throw FormatException('Unknown animation: $animationName'),
    };
    return StoryLibraryPage(
      page: number,
      script: lines,
      translationAr: _requiredText(json, 'translation_ar'),
      imagePrompt: _requiredText(json, 'image_prompt'),
      animation: animation,
      image: _optionalText(json, 'image'),
    );
  }
}

class StoryLibraryWord {
  const StoryLibraryWord({
    required this.word,
    required this.translationAr,
    required this.example,
  });

  final String word;
  final String translationAr;
  final String example;

  factory StoryLibraryWord.fromJson(Map<String, dynamic> json) {
    return StoryLibraryWord(
      word: _requiredText(json, 'word'),
      translationAr: _requiredText(json, 'translation_ar'),
      example: _requiredText(json, 'example'),
    );
  }
}

class StoryLibraryQuestion {
  const StoryLibraryQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanationAr,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanationAr;

  factory StoryLibraryQuestion.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    if (raw is! List || raw.length < 2) {
      throw const FormatException('Each question needs at least two options.');
    }
    final options = <String>[];
    for (final value in raw) {
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Question options must be non-empty strings.');
      }
      options.add(value.trim());
    }
    final correctIndex = json['correct_index'];
    if (correctIndex is! int || correctIndex < 0 ||
        correctIndex >= options.length) {
      throw const FormatException('correct_index is outside the options.');
    }
    return StoryLibraryQuestion(
      question: _requiredText(json, 'question'),
      options: List<String>.unmodifiable(options),
      correctIndex: correctIndex,
      explanationAr: _optionalText(json, 'explanation_ar'),
    );
  }
}

class StoryLibraryBook {
  const StoryLibraryBook({
    required this.language,
    required this.level,
    required this.id,
    required this.title,
    required this.titleAr,
    required this.moralAr,
    required this.artStyle,
    required this.characterSheet,
    required this.pages,
    required this.vocabulary,
    required this.questions,
  });

  final String language;
  final String level;
  final String id;
  final String title;
  final String titleAr;
  final String moralAr;
  final String artStyle;
  final Map<String, String> characterSheet;
  final List<StoryLibraryPage> pages;
  final List<StoryLibraryWord> vocabulary;
  final List<StoryLibraryQuestion> questions;

  factory StoryLibraryBook.fromJson(
    Map<String, dynamic> json, {
    required String language,
    required String level,
  }) {
    final id = _requiredText(json, 'id');
    if (!RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$').hasMatch(id)) {
      throw FormatException('Invalid story id: $id');
    }
    final rawCharacters = _asObject(json['character_sheet'], 'character_sheet');
    final characters = <String, String>{};
    for (final entry in rawCharacters.entries) {
      if (entry.value is! String ||
          (entry.value as String).trim().isEmpty) {
        throw const FormatException('Character descriptions must be strings.');
      }
      characters[entry.key] = (entry.value as String).trim();
    }
    if (characters.isEmpty) {
      throw const FormatException('character_sheet must not be empty.');
    }
    final pages = _readObjects(json, 'pages', StoryLibraryPage.fromJson);
    if (pages.length < 8 || pages.length > 10) {
      throw const FormatException('A story must have 8 to 10 pages.');
    }
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].page != i + 1) {
        throw const FormatException('Page numbers must be sequential from 1.');
      }
    }
    final words = _readObjects(json, 'vocabulary', StoryLibraryWord.fromJson);
    if (words.isEmpty) {
      throw const FormatException('A story needs vocabulary.');
    }
    final questions =
        _readObjects(json, 'questions', StoryLibraryQuestion.fromJson);
    if (questions.length != 5) {
      throw const FormatException('A story needs exactly five questions.');
    }
    return StoryLibraryBook(
      language: language,
      level: level,
      id: id,
      title: _requiredText(json, 'title'),
      titleAr: _requiredText(json, 'title_ar'),
      moralAr: _requiredText(json, 'moral_ar'),
      artStyle: _requiredText(json, 'art_style'),
      characterSheet: Map<String, String>.unmodifiable(characters),
      pages: pages,
      vocabulary: words,
      questions: questions,
    );
  }
}

class StoryLibraryEntry {
  const StoryLibraryEntry({
    required this.id,
    required this.language,
    required this.level,
    required this.title,
    required this.titleAr,
    required this.asset,
    this.format = 'legacy',
  });

  final String id;
  final String language;
  final String level;
  final String title;
  final String titleAr;
  final String asset;
  final String format;

  static const levels = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  factory StoryLibraryEntry.fromJson(Map<String, dynamic> json) {
    final id = _requiredText(json, 'id');
    final language = _requiredText(json, 'language');
    final level = _requiredText(json, 'level');
    final asset = _requiredText(json, 'asset');
    final format = json['format'] ?? 'legacy';
    if (format != 'legacy' && format != 'textbook') {
      throw const FormatException('Unsupported story format.');
    }
    final prefix = 'assets/stories/$language/$level/';
    if (!RegExp(r'^[a-z]{2,3}$').hasMatch(language) ||
        !levels.contains(level) ||
        !RegExp(r'^[a-z0-9]+(?:[-_][a-z0-9]+)* ||
        asset != '$prefix$id.json') {
      throw const FormatException('Invalid story index entry.');
    }
    return StoryLibraryEntry(
      id: id,
      language: language,
      level: level,
      title: _requiredText(json, 'title'),
      titleAr: _requiredText(json, 'title_ar'),
      asset: asset,
    );
  }
}
).hasMatch(id) ||
        !asset.startsWith(prefix) ||
        asset != '$prefix$id.json') {
      throw const FormatException('Invalid story index entry.');
    }
    return StoryLibraryEntry(
      id: id,
      language: language,
      level: level,
      title: _requiredText(json, 'title'),
      titleAr: _requiredText(json, 'title_ar'),
      asset: asset,
      format: format as String,
    );
  }
}
