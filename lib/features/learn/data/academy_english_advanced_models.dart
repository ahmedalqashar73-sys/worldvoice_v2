part 'academy_english_advanced_core.dart';
part 'academy_english_advanced_mastery.dart';

/// Authored English CEFR pilot lessons beyond A1. Each published lesson has
/// its own complete story, contextual vocabulary, grammar, listening and
/// assessable understanding. Higher planned units remain unpublished.
class EnglishAdvancedWord {
  const EnglishAdvancedWord(this.term, this.arabic);
  final String term;
  final String arabic;
}

class EnglishAdvancedLesson {
  const EnglishAdvancedLesson({
    required this.level,
    required this.number,
    required this.title,
    required this.titleArabic,
    required this.storyTitle,
    required this.storyTitleArabic,
    required this.paragraphs,
    required this.storyWords,
    required this.extraWords,
    required this.grammarTitle,
    required this.grammarArabic,
    required this.grammarExamples,
    required this.listening,
    required this.listeningQuestion,
    required this.listeningOptions,
    required this.listeningAnswer,
    required this.readingQuestion,
    required this.readingOptions,
    required this.readingAnswer,
    required this.writingCue,
    required this.writingAnswer,
  });
  final String level;
  final int number;
  final String title;
  final String titleArabic;
  final String storyTitle;
  final String storyTitleArabic;
  final List<String> paragraphs;
  /// Terms deliberately introduced within the story itself.
  final List<EnglishAdvancedWord> storyWords;
  /// Further distinct topic words taught outside the story.
  final List<EnglishAdvancedWord> extraWords;
  final String grammarTitle;
  final String grammarArabic;
  final List<String> grammarExamples;
  final String listening;
  final String listeningQuestion;
  final List<String> listeningOptions;
  final int listeningAnswer;
  final String readingQuestion;
  final List<String> readingOptions;
  final int readingAnswer;
  final String writingCue;
  final String writingAnswer;
  String get id => 'worldvoice.en.${level.toLowerCase()}.u1.l${number.toString().padLeft(2, '0')}';
  List<EnglishAdvancedWord> get vocabulary => [...storyWords, ...extraWords];
}

abstract final class EnglishAdvancedSyllabus {
  static const levels = <String>['A2', 'B1', 'B2', 'C1', 'C2'];
  static const paragraphTargets = <String, int>{
    'A2': 3, 'B1': 4, 'B2': 4, 'C1': 5, 'C2': 6,
  };
  static const vocabularyTargets = <String, int>{
    'A2': 24, 'B1': 30, 'B2': 36, 'C1': 42, 'C2': 50,
  };
  static const listeningRates = <String, double>{
    'A2': .44, 'B1': .51, 'B2': .57, 'C1': .63, 'C2': .68,
  };
  static const arabicTitles = <String, String>{
    'A2': 'المبتدئ المتقدم',
    'B1': 'المتوسط',
    'B2': 'فوق المتوسط',
    'C1': 'المتقدم',
    'C2': 'الإتقان',
  };

  /// The first two curated lessons of each higher level. Publishing more
  /// lessons is a separate content-review milestone; no fabricated lessons.
  static final lessons = <EnglishAdvancedLesson>[
    ...EnglishAdvancedCoreLessons.lessons,
    ...EnglishAdvancedMasteryLessons.lessons,
  ];

  static List<EnglishAdvancedLesson> forLevel(String level) =>
      lessons.where((lesson) => lesson.level == level).toList(growable: false);
}
