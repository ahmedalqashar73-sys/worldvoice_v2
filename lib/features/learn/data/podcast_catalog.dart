/// Curated original Voice of America audio, credited to the source.
/////
///// Source-use terms: https://learningenglish.voanews.com/p/6861.html
///// Only original VOA Learning English conversation audio belongs here;
///// do not republish third-party photographs, music or news-agency media.
class PodcastDialogueLine {
  const PodcastDialogueLine({
    required this.speaker,
    required this.english,
    required this.arabic,
  });

  final String speaker;
  final String english;
  final String arabic;
}

class PodcastEpisode {
  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.level,
    required this.audioUrl,
    required this.sourceUrl,
    required this.duration,
    required this.dialogue,
  });

  final String id;
  final String title;
  final String titleAr;
  final String level;
  final String audioUrl;
  final String sourceUrl;
  final Duration duration;
  final List<PodcastDialogueLine> dialogue;

  String get credit => 'Audio: VOA Learning English · learningenglish.voanews.com';
}

const List<PodcastEpisode> academyPodcasts = [
  PodcastEpisode(
    id: 'voa-a1-welcome-01',
    title: 'Welcome! — Anna and Pete',
    titleAr: 'أهلًا بك! — آنا وبيت',
    level: 'A1',
    duration: Duration(seconds: 29),
    sourceUrl:
        'https://learningenglish.voanews.com/a/lets-learn-english-lesson-one/3111026.html',
    audioUrl:
        'https://voa-audio.voanews.eu/vle/2016/02/08/49485bf8-4277-47f6-9abe-617ee2473f8c.mp3',
    dialogue: [
      PodcastDialogueLine(
        speaker: 'Pete',
        english: 'Hi! Are you Anna?',
        arabic: 'مرحبًا! هل أنتِ آنا؟',
      ),
      PodcastDialogueLine(
        speaker: 'Anna',
        english: 'Yes! Hi there! Are you Pete?',
        arabic: 'نعم! أهلًا! هل أنت بيت؟',
      ),
      PodcastDialogueLine(
        speaker: 'Pete',
        english: 'I am Pete.',
        arabic: 'أنا بيت.',
      ),
      PodcastDialogueLine(
        speaker: 'Anna',
        english: 'Nice to meet you.',
        arabic: 'سعيدة بلقائك.',
      ),
      PodcastDialogueLine(
        speaker: 'Anna',
        english: "Let's try that again. I'm Anna. Nice to meet you.",
        arabic: 'لنجرب من جديد. أنا آنا. سعيدة بلقائك.',
      ),
      PodcastDialogueLine(
        speaker: 'Pete',
        english: "I'm Pete. Anna, is that A-N-A?",
        arabic: 'أنا بيت. آنا، هل يُكتب اسمك A-N-A؟',
      ),
      PodcastDialogueLine(
        speaker: 'Anna',
        english: 'No. A-N-N-A.',
        arabic: 'لا، A-N-N-A.',
      ),
      PodcastDialogueLine(
        speaker: 'Pete',
        english:
            'Well, Anna with two Ns. Welcome to 1400 Irving Street!',
        arabic: 'حسنًا، آنا بحرفَي N. أهلًا بك في 1400 شارع إرفينغ!',
      ),
      PodcastDialogueLine(
        speaker: 'Anna',
        english: 'My new apartment! Yes!',
        arabic: 'شقتي الجديدة! نعم!',
      ),
    ],
  ),
];
