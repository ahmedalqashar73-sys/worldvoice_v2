import 'academy_english_a1_vocabulary.dart';
import 'academy_english_a1_long_stories.dart';
import 'academy_english_a1_dialogues.dart';

/// One coherent beginner-language input across vocabulary, reading, dialogue
/// and teacher-led audio. It augments, rather than deletes, original A1 books.
abstract final class EnglishA1LearningLoop {
  static List<EnglishA1Word> _group(
          int unit, int lesson, EnglishA1WordKind kind) =>
      EnglishA1Vocabulary.wordsByKind(unit, lesson, kind);

  /// A supplementary story scene uses this lesson's nouns, verbs,
  /// adjectives and adverbs while the original author-written story remains.
  static EnglishA1StoryChapter chapterFor(int unit, int lesson) {
    final original = EnglishA1StorySyllabus.chapterFor(unit, lesson);
    final nouns = _group(unit, lesson, EnglishA1WordKind.noun);
    final verbs = _group(unit, lesson, EnglishA1WordKind.verb);
    final adjectives = _group(unit, lesson, EnglishA1WordKind.adjective);
    final adverbs = _group(unit, lesson, EnglishA1WordKind.adverb);
    final focus = EnglishA1StoryParagraph(
      'After the adventure, the friends make a new picture page. '
      'They write about the ' + nouns[0].term + ', the ' + nouns[1].term +
      ', the ' + nouns[2].term + ', and the ' + nouns[3].term + '. '
      'Maya says, "I can ' + verbs[0].term + ' ' + adverbs[0].term + '." '
      'Leo answers, "I can ' + verbs[1].term + ' ' + adverbs[1].term + '." '
      'They practise the words "' + adjectives[0].term + '" and "' +
      adjectives[1].term + '". They help each other and finish together.',
      'بعد المغامرة، يُعد الأصدقاء صفحة مصورة جديدة. '
      'يكتبون عن ' + nouns[0].arabic + ' و' + nouns[1].arabic + ' و' +
      nouns[2].arabic + ' و' + nouns[3].arabic + '. '
      'تقول مايا: «أستطيع ' + verbs[0].arabic + ' ' + adverbs[0].arabic +
      '». ويرد ليو: «وأنا أستطيع ' + verbs[1].arabic + ' ' +
      adverbs[1].arabic + '». ثم يتدرّبون على الوصف بكلمتي «' +
      adjectives[0].arabic + '» و«' + adjectives[1].arabic +
      '»، ويتعاونون حتى يكملوا الصفحة.',
    );
    return EnglishA1StoryChapter(original.title, original.titleArabic,
        <EnglishA1StoryParagraph>[...original.paragraphs, focus]);
  }

  /// A realistic opening dialogue is retained, followed by a short
  /// speaking exchange recycling terms the learner has just studied.
  static EnglishA1Dialogue materialFor(int unit, int lesson) {
    final base = EnglishA1DialogueCatalog.forLesson(unit, lesson);
    final nouns = _group(unit, lesson, EnglishA1WordKind.noun);
    final verbs = _group(unit, lesson, EnglishA1WordKind.verb);
    final adverbs = _group(unit, lesson, EnglishA1WordKind.adverb);
    final adjectives = _group(unit, lesson, EnglishA1WordKind.adjective);
    final dialogue = base.dialogue +
        '\nEmma: Which words do you know about the ' + nouns[0].term + '?' +
        '\nLearner: I know "' + nouns[1].term + '" and "' + nouns[2].term + '".' +
        '\nEmma: What can you do today?' +
        '\nLearner: I can ' + verbs[0].term + ' ' + adverbs[0].term +
        ', and I can ' + verbs[1].term + ' ' + adverbs[1].term + '.' +
        '\nEmma: Great! Can you say "' + adjectives[0].term +
        '" and "' + adjectives[1].term + '" clearly?';
    final nounsText = nouns.map((w) => w.term).join(', ');
    final verbsText = verbs.map((w) => w.term).join(', ');
    final adjectivesText = adjectives.map((w) => w.term).join(', ');
    final adverbsText = adverbs.map((w) => w.term).join(', ');
    final listening = base.listening +
        ' Welcome to the WorldVoice vocabulary podcast. '
        'Today we are learning English words connected to this lesson. '
        'First, listen to ten nouns: ' + nounsText + '. '
        'Next, practise ten action verbs: ' + verbsText + '. '
        'Now listen to ten describing words, or adjectives: ' + adjectivesText + '. '
        'Finally, here are ten adverbs: ' + adverbsText + '. '
        'Listen to the words again. Try to make your own short sentences. '
        'You can repeat the episode slowly whenever you need more practice.';
    return EnglishA1Dialogue(dialogue, listening);
  }
}
