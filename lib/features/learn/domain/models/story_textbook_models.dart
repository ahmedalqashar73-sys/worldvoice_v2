import 'story_library_models.dart';

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$field must be an object.');
  }
  return value;
}

String _text(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}

List<T> _items<T>(
  Map<String, dynamic> map,
  String field,
  T Function(Map<String, dynamic>) parse,
) {
  final raw = map[field];
  if (raw is! List) throw FormatException('$field must be a list.');
  return List<T>.unmodifiable(
    raw.map((item) => parse(_object(item, field))),
  );
}

enum StoryTextbookMotion { zoomInSlow, panLeft, panRight, fadeIn, parallax }

enum StoryTextbookSpeaker { narrator, female, male }

class StoryTextbookSegment {
  const StoryTextbookSegment({required this.speaker, required this.text});
  final StoryTextbookSpeaker speaker;
  final String text;

  String get speechText => text.replaceAll('**', '');

  factory StoryTextbookSegment.fromJson(Map<String, dynamic> map) {
    final speaker = switch (_text(map, 'speaker').toUpperCase()) {
      'NARRATOR' => StoryTextbookSpeaker.narrator,
      'FEMALE' => StoryTextbookSpeaker.female,
      'MALE' => StoryTextbookSpeaker.male,
      _ => throw const FormatException('Unknown story narrator.'),
    };
    return StoryTextbookSegment(speaker: speaker, text: _text(map, 'text'));
  }
}

class StoryTextbookParagraph {
  const StoryTextbookParagraph({
    required this.segments,
    required this.translationAr,
  });
  final List<StoryTextbookSegment> segments;
  final String translationAr;

  String get spokenText => segments.map((s) => s.speechText).join(' ');

  factory StoryTextbookParagraph.fromJson(Map<String, dynamic> map) {
    final segments = _items(map, 'segments', StoryTextbookSegment.fromJson);
    if (segments.isEmpty) {
      throw const FormatException('Paragraph must include spoken segments.');
    }
    return StoryTextbookParagraph(
      segments: segments,
      translationAr: _text(map, 'translation_ar'),
    );
  }
}

class StoryTextbookBlock {
  const StoryTextbookBlock({
    required this.imagePrompt,
    required this.animation,
    required this.paragraphs,
    this.image,
  });

  final String imagePrompt;
  final StoryTextbookMotion animation;
  final List<StoryTextbookParagraph> paragraphs;
  final String? image;

  factory StoryTextbookBlock.fromJson(Map<String, dynamic> map) {
    if (_text(map, 'type') != 'paragraph_group') {
      throw const FormatException('Unsupported textbook block.');
    }
    final animation = switch (_text(map, 'animation')) {
      'zoom_in_slow' => StoryTextbookMotion.zoomInSlow,
      'pan_left' => StoryTextbookMotion.panLeft,
      'pan_right' => StoryTextbookMotion.panRight,
      'fade_in' => StoryTextbookMotion.fadeIn,
      'parallax' => StoryTextbookMotion.parallax,
      _ => throw const FormatException('Unsupported illustration motion.'),
    };
    final image = map['image'];
    if (image != null && (image is! String || image.isEmpty)) {
      throw const FormatException('Invalid story illustration reference.');
    }
    final paragraphs =
        _items(map, 'paragraphs', StoryTextbookParagraph.fromJson);
    if (paragraphs.length < 2 || paragraphs.length > 3) {
      throw const FormatException('Every picture needs two or three paragraphs.');
    }
    return StoryTextbookBlock(
      imagePrompt: _text(map, 'image_prompt'),
      animation: animation,
      image: image as String?,
      paragraphs: paragraphs,
    );
  }
}

class StoryTextbookChapter {
  const StoryTextbookChapter({
    required this.number,
    required this.title,
    required this.titleAr,
    required this.blocks,
  });

  final int number;
  final String title;
  final String titleAr;
  final List<StoryTextbookBlock> blocks;

  int get paragraphCount =>
      blocks.fold(0, (total, block) => total + block.paragraphs.length);

  factory StoryTextbookChapter.fromJson(Map<String, dynamic> map) {
    final number = map['chapter'];
    if (number is! int || number < 1) {
      throw const FormatException('Invalid chapter number.');
    }
    final blocks = _items(map, 'blocks', StoryTextbookBlock.fromJson);
    if (blocks.length < 2 || blocks.length > 5) {
      throw const FormatException('Each chapter needs two to five pictures.');
    }
    final count =
        blocks.fold<int>(0, (total, block) => total + block.paragraphs.length);
    if (count < 5) {
      throw const FormatException('Every chapter needs at least five paragraphs.');
    }
    return StoryTextbookChapter(
      number: number,
      title: _text(map, 'title'),
      titleAr: _text(map, 'title_ar'),
      blocks: blocks,
    );
  }
}

class StoryTextbookWord {
  const StoryTextbookWord({
    required this.word,
    required this.meaningAr,
    required this.example,
  });
  final String word;
  final String meaningAr;
  final String example;

  factory StoryTextbookWord.fromJson(Map<String, dynamic> map) {
    return StoryTextbookWord(
      word: _text(map, 'word'),
      meaningAr: _text(map, 'meaning_ar'),
      example: _text(map, 'example'),
    );
  }
}

class StoryTextbookQuestion {
  const StoryTextbookQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });
  final String question;
  final List<String> options;
  final int answer;

  factory StoryTextbookQuestion.fromJson(Map<String, dynamic> map) {
    final raw = map['options'];
    if (raw is! List || raw.length != 4 ||
        raw.any((v) => v is! String || v.trim().isEmpty)) {
      throw const FormatException('Question must have four options.');
    }
    final answer = map['answer'];
    if (answer is! int || answer < 0 || answer >= 4) {
      throw const FormatException('Invalid question answer index.');
    }
    return StoryTextbookQuestion(
      question: _text(map, 'q'),
      options: List<String>.unmodifiable(raw.cast<String>()),
      answer: answer,
    );
  }
}

class StoryTextbookCharacter {
  const StoryTextbookCharacter({
    required this.name,
    required this.description,
  });
  final String name;
  final String description;

  factory StoryTextbookCharacter.fromJson(Map<String, dynamic> map) =>
      StoryTextbookCharacter(
        name: _text(map, 'name'),
        description: _text(map, 'description'),
      );
}

class StoryTextbookBook {
  const StoryTextbookBook({
    required this.language,
    required this.level,
    required this.id,
    required this.title,
    required this.titleAr,
    required this.moralAr,
    required this.artStyle,
    required this.coverImagePrompt,
    required this.characters,
    required this.chapters,
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
  final String coverImagePrompt;
  final List<StoryTextbookCharacter> characters;
  final List<StoryTextbookChapter> chapters;
  final List<StoryTextbookWord> vocabulary;
  final List<StoryTextbookQuestion> questions;

  Map<String, String> get meanings => {
    for (final word in vocabulary) word.word.toLowerCase(): word.meaningAr,
  };

  factory StoryTextbookBook.fromJson(Map<String, dynamic> json) {
    final language = _text(json, 'language');
    final level = _text(json, 'level');
    if (!StoryLibraryEntry.levels.contains(level)) {
      throw const FormatException('Unsupported CEFR level.');
    }
    final story = _object(json['story'], 'story');
    final chapters = _items(story, 'chapters', StoryTextbookChapter.fromJson);
    if (chapters.length != 2 ||
        chapters[0].number != 1 || chapters[1].number != 2) {
      throw const FormatException('Textbook story needs chapters 1 and 2.');
    }
    final words = _items(story, 'vocabulary', StoryTextbookWord.fromJson);
    final questions =
        _items(story, 'questions', StoryTextbookQuestion.fromJson);
    final characters =
        _items(story, 'character_sheet', StoryTextbookCharacter.fromJson);
    if (words.length < 20 || questions.length < 8 || characters.isEmpty) {
      throw const FormatException('Missing textbook story learning material.');
    }
    final vocabulary = {
      for (final word in words) word.word.toLowerCase(): word.meaningAr,
    };
    if (vocabulary.length != words.length) {
      throw const FormatException('Duplicate vocabulary entries.');
    }
    const wordRange = <String, (int, int)>{
      'A1': (25, 40),
      'A2': (40, 60),
      'B1': (60, 90),
      'B2': (90, 130),
      'C1': (130, 180),
      'C2': (150, 220),
    };
    final range = wordRange[level]!;
    for (final chapter in chapters) {
      for (final block in chapter.blocks) {
        for (final paragraph in block.paragraphs) {
          final text = paragraph.segments.map((s) => s.text).join(' ');
          final important = RegExp(r'\*\*([^*]+)\*\*')
              .allMatches(text).map((m) => m.group(1)!.toLowerCase()).toList();
          if (important.length < 2 || important.length > 4) {
            throw const FormatException(
              'Each paragraph needs two to four highlighted terms.');
          }
          if (important.any((word) => !vocabulary.containsKey(word))) {
            throw const FormatException('Highlighted term missing in vocabulary.');
          }
          final wordsCount = text.replaceAll('**', '').trim()
              .split(RegExp(r'\s+')).length;
          if (language != 'zh' &&
              (wordsCount < range.$1 || wordsCount > range.$2)) {
            throw FormatException(
              'Paragraph word count $wordsCount outside $level range.');
          }
        }
      }
    }
    return StoryTextbookBook(
      language: language,
      level: level,
      id: _text(story, 'id'),
      title: _text(story, 'title'),
      titleAr: _text(story, 'title_ar'),
      moralAr: _text(story, 'moral_ar'),
      artStyle: _text(story, 'art_style'),
      coverImagePrompt: _text(story, 'cover_image_prompt'),
      characters: characters,
      chapters: chapters,
      vocabulary: words,
      questions: questions,
    );
  }
}
