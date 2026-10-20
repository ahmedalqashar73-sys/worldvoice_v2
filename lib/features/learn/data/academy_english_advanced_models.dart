part 'academy_english_advanced_core.dart';
part 'academy_english_advanced_mastery.dart';
part 'academy_english_advanced_second.dart';
part 'academy_english_advanced_curriculum.dart';
part 'academy_english_advanced_dialogues.dart';
part 'academy_english_advanced_a2_additional.dart';
part 'academy_english_advanced_third_batch.dart';
part 'academy_english_advanced_upper_third.dart';
part 'academy_english_advanced_a2_6_7.dart';
part 'academy_english_advanced_a2_8_10.dart';
part 'academy_english_advanced_b1_4_6.dart';
part 'academy_english_advanced_b1_7_10.dart';
part 'academy_english_advanced_b2_4.dart';
part 'academy_english_advanced_b2_5.dart';

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
    this.unitNumber = 1,
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
  final int unitNumber;
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
  String get id => 'worldvoice.en.${level.toLowerCase()}.u$unitNumber.l${number.toString().padLeft(2, '0')}';
  List<EnglishAdvancedWord> get vocabulary => [...storyWords, ...extraWords];

  /// Three different story words the learner must type correctly.
  /// Begin with the authored fill-in-the-blank word, then sample the middle
  /// and end of the story's new vocabulary, avoiding duplicate answers.
  List<EnglishAdvancedWord> get spellingChallenge {
    final selected = <EnglishAdvancedWord>[];
    final candidates = <EnglishAdvancedWord>[
      ...storyWords.where((word) =>
          word.term.toLowerCase() == writingAnswer.toLowerCase()),
      storyWords[storyWords.length ~/ 2],
      storyWords.last,
      ...storyWords,
    ];
    final seen = <String>{};
    for (final word in candidates) {
      if (!seen.add(word.term.toLowerCase())) continue;
      selected.add(word);
      if (selected.length == 3) break;
    }
    return selected;
  }
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

  /// Every entry is a distinct authored session with its own story,
  /// graded listening, grammar and assessments. Unwritten slots stay locked.
  static final lessons = <EnglishAdvancedLesson>[
    ...EnglishAdvancedCoreLessons.lessons,
    ...EnglishAdvancedMasteryLessons.lessons,
    ...EnglishAdvancedSecondLessons.lessons,
    ...EnglishAdvancedA2Additional.lessons,
    ...EnglishAdvancedThirdBatch.lessons,
    ...EnglishAdvancedUpperThirdBatch.lessons,
    ...EnglishAdvancedA2FinalSixSeven.lessons,
    ...EnglishAdvancedA2FinalEightTen.lessons,
    ...EnglishAdvancedB1FourToSix.lessons,
    ...EnglishAdvancedB1SevenToTen.lessons,
    ...EnglishAdvancedB2FoodRecovery.lessons,
    ...EnglishAdvancedB2AdvertisingEthics.lessons,
  ];

  static List<EnglishAdvancedLesson> forLevel(String level) =>
      lessons.where((lesson) => lesson.level == level).toList(growable: false);

  static List<EnglishAdvancedLesson> forUnit(String level, int unit) =>
      lessons.where((lesson) => lesson.level == level && lesson.unitNumber == unit)
          .toList(growable: false);

  static List<EnglishAdvancedUnitOutline> unitsForLevel(String level) =>
      EnglishAdvancedCurriculum.unitsFor(level);

  static EnglishAdvancedLesson? findLesson(String level, int unit, int number) {
    for (final lesson in forUnit(level, unit)) {
      if (lesson.number == number) return lesson;
    }
    return null;
  }
}
