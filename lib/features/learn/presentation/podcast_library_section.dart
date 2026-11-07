import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/academy_podcast_repository.dart';
import 'voa_originals_section.dart';
import 'a2_long_listening_section.dart';
import 'b1_voa_long_form_section.dart';
import 'nasa_advanced_podcast_section.dart';
import 'podcast_sentence_translation.dart';

/// Separate CEFR/language paths; never represent unrecorded plans as audio.
class PodcastLibrarySection extends StatefulWidget {
  const PodcastLibrarySection({super.key, this.initialA2Lessons});

  /// Optional preloaded catalog for deterministic widget tests. On devices,
  /// the actual VOA A2 catalog is loaded from the bundled JSON asset.
  final List<VoaOriginalLesson>? initialA2Lessons;

  @override
  State<PodcastLibrarySection> createState() => _PodcastLibrarySectionState();
}

class _PodcastLibrarySectionState extends State<PodcastLibrarySection> {
  final _repository = const AcademyPodcastRepository();
  late final Future<List<AcademyPodcastEntry>> _episodes =
      _repository.allEpisodes();
  late final Future<List<PodcastLanguage>> _languages =
      _repository.allLanguages();
  String _selectedLanguage = 'en';
  String _selectedLevel = 'A1';

  Widget _hero(bool ar) {
    final voaPilot = _selectedLanguage == 'en' &&
        (_selectedLevel == 'A1' ||
            _selectedLevel == 'A2' ||
            _selectedLevel == 'B1');
    final nasaOriginal = _selectedLanguage == 'en' &&
        const ['B2', 'C1', 'C2'].contains(_selectedLevel);
    return Container(
        key: const ValueKey('podcast-hero'),
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF113C2F), Color(0xFF1E7658)],
          ),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.podcasts_rounded,
                  color: Color(0xFFF1D98F), size: 26),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('WORLDVOICE  /  PODCAST',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Color(0xFFF1D98F),
                    fontSize: 12, letterSpacing: 1,
                    fontWeight: FontWeight.w900))),
            const Icon(Icons.graphic_eq_rounded,
                color: Color(0xFFBCE2CE), size: 28),
          ]),
          const SizedBox(height: 15),
          Text(ar
                  ? (voaPilot
                      ? 'بودكاست الإنجليزية · تعلّم بالاستماع'
                      : (nasaOriginal
                          ? 'البودكاست المتقدم · الإنجليزية'
                          : 'صوتان، حوار واحد، لغة جديدة'))
                  : (voaPilot
                      ? 'English podcast · Listen and learn'
                      : (nasaOriginal
                          ? 'Advanced English podcasts'
                          : 'Two voices. One new language')),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 21)),
          const SizedBox(height: 6),
          Text(
            ar
                ? (voaPilot
                    ? (_selectedLevel == 'B1'
                        ? 'استمع إلى الحلقات الطويلة وترجم الجملة التي تختارها إلى لغتك الأم.'
                        : 'استمع إلى التسجيلات الأصلية واقرأ المحادثات، مع ترجمة اختيارية لكل جملة.')
                    : (nasaOriginal
                        ? '30 حلقة طويلة لكل مستوى، مع النص الإنجليزي والترجمة عند الضغط لكل جملة.'
                        : 'محادثات تعليمية للاستماع والقراءة في وقت واحد.'))
                : (voaPilot
                    ? (_selectedLevel == 'B1'
                        ? 'Listen to long original recordings and translate individual sentences when needed.'
                        : 'Listen to original recordings and translate only the sentences you choose.')
                    : (nasaOriginal
                        ? '30 long episodes per level with optional sentence-by-sentence translation.'
                        : 'Read and listen to language conversations.')),
            style: const TextStyle(
                color: Color(0xFFE0EEE5), height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 17),
          Row(children: [
            _hostPill(nasaOriginal ? 'HOST' : (voaPilot && _selectedLevel == 'B1' ? 'HOST' : 'ANNA'), Icons.face_3_rounded,
                const Color(0xFFF2BDD6)),
            const SizedBox(width: 9),
            _hostPill(nasaOriginal ? 'GUEST' : (voaPilot ? 'GUEST' : 'DANIEL'), Icons.face_rounded,
                const Color(0xFFC1DBFF)),
            const Spacer(),
            const Icon(Icons.schedule_rounded,
                color: Color(0xFFF1D98F), size: 16),
            const SizedBox(width: 4),
            Text(voaPilot
                ? (_selectedLevel == 'A1' ? '15 EP' : '30 EP')
                : (nasaOriginal ? '30 EP' : '≈ 05:00'),
                style: TextStyle(color: Color(0xFFF1D98F),
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ]),
      );
  }

  Widget _hostPill(String name, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(name, textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      );

  Future<void> _openVoaLesson(VoaOriginalLesson lesson) async {
    if (!mounted) return;
    // VOA A2 lessons have dedicated audio + bilingual transcript assets just
    // like A1 originals 1–12. Open the full reader, not the legacy audio-only
    // fallback that sends learners to the website for its English text.
    if (lesson.level == 'A2' ||
        (lesson.level == 'A1' &&
            lesson.number >= 1 && lesson.number <= 12)) {
      final entry = AcademyPodcastEntry(
        id: lesson.id,
        level: lesson.level,
        language: 'en',
        title: lesson.title,
        titleAr: lesson.titleAr,
        status: 'published_audio',
        asset: 'assets/podcasts/en/${lesson.level}/${lesson.id}.json',
      );
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) =>
            PodcastReaderScreen(entry: entry, repository: _repository)));
      return;
    }
    final available = await _episodes;
    if (!mounted) return;
    final entry = available.where((item) =>
        item.id == lesson.existingEpisodeId).firstOrNull;
    if (entry != null) {
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) =>
            PodcastReaderScreen(entry: entry, repository: _repository)));
    } else {
      // Never hide the authentic VOA recording if a catalog item is missing.
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => VoaOriginalAudioScreen(lesson: lesson)));
    }
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      );

  Widget _episodeCard(AcademyPodcastEntry entry, int number, bool ar) {
    final theme = Theme.of(context);
    final enabled = entry.hasTranscript;
    final isPublished = entry.status == 'published' ||
        entry.status == 'published_audio';
    final deviceReadAloud = entry.language == 'en' &&
        entry.level == 'A1' &&
        entry.status == 'script_ready';
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: enabled
            ? const Color(0xFF398E6B).withValues(alpha: .55)
            : theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: ValueKey('podcast-episode-${entry.id}'),
        contentPadding: const EdgeInsets.fromLTRB(13, 8, 11, 8),
        onTap: enabled ? () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) =>
              PodcastReaderScreen(entry: entry, repository: _repository)),
        ) : null,
        leading: Container(
          width: 47, height: 47,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFDCF0E3)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(13),
          ),
          child: enabled
              ? const Icon(Icons.menu_book_rounded,
                  color: Color(0xFF166344), size: 23)
              : Text(number.toString().padLeft(2, '0'),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800)),
        ),
        title: Text(
          ar ? entry.titleAr ?? entry.title : entry.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isPublished
                ? (entry.status == 'published_audio'
                    ? (entry.level == 'A2'
                        ? (ar ? 'صوت بشري VOA · نص مختار · التزامن قيد المراجعة'
                            : 'VOA human voice · excerpt · sync pending')
                        : (ar ? 'VOA · صوت بشري · تزامن تجريبي'
                            : 'VOA human audio · provisional sync'))
                    : (ar ? 'صوت ونص متزامنان' : 'Audio + synced reading'))
                : enabled
                    ? (deviceReadAloud
                        ? (ar ? 'قراءة صوتية آلية من الجهاز · لا يوجد تسجيل بشري'
                            : 'Device voice read-aloud · No human recording')
                        : (ar ? 'اقرأ المحادثة · التسجيل لم يُضف بعد'
                            : 'Read transcript · No recording yet'))
                    : (ar ? 'قيد إعداد المحتوى' : 'In production'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11),
          ),
        ),
        trailing: Icon(
          enabled ? Icons.arrow_forward_ios_rounded
              : Icons.lock_clock_outlined,
          size: 16,
          color: enabled ? const Color(0xFF388B66)
              : theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _emptyLanguage(PodcastLanguage language, bool ar) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('podcast-pending-${language.code}'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.headphones_rounded,
              color: Color(0xFF27815B), size: 33),
        ),
        const SizedBox(height: 13),
        Text(
          ar ? 'مسار ${language.arabicName} · $_selectedLevel'
              : '${language.nativeName} · $_selectedLevel',
          style: const TextStyle(fontSize: 17,
              fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(ar
            ? 'نخطط لـ15 حلقة في هذا المستوى. لم ننشر تسجيلات بشرية لهذه اللغة بعد.'
            : 'Fifteen episodes are planned here. No human recordings have been published for this language.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.verified_user_outlined, size: 16,
              color: Color(0xFF27815B)),
          SizedBox(width: 6),
          Flexible(child: Text('Real voices only · No fake audio',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final voaOnly = _selectedLanguage == 'en' && _selectedLevel == 'A1';
    final voaA2 = _selectedLanguage == 'en' && _selectedLevel == 'A2';
    final voaB1 = _selectedLanguage == 'en' && _selectedLevel == 'B1';
    final nasaAdvanced = _selectedLanguage == 'en' &&
        const ['B2', 'C1', 'C2'].contains(_selectedLevel);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hero(ar),
      const SizedBox(height: 20),
      _sectionHeader(ar ? 'لغة البودكاست' : 'Podcast language'),
      FutureBuilder<List<PodcastLanguage>>(
        future: _languages,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(ar ? 'تعذّر تحميل اللغات' : 'Cannot load languages');
          }
          final languages = snapshot.data ?? const <PodcastLanguage>[];
          if (languages.isEmpty) {
            return const LinearProgressIndicator();
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final language in languages)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 7),
                  child: ChoiceChip(
                    key: ValueKey('podcast-language-${language.code}'),
                    label: Text('${language.flag}  ${ar ? language.arabicName : language.nativeName}'),
                    selected: _selectedLanguage == language.code,
                    onSelected: (_) => setState(() {
                      _selectedLanguage = language.code;
                      _selectedLevel = 'A1';
                    }),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _selectedLanguage == language.code
                          ? const Color(0xFF134B36) : scheme.onSurface),
                    selectedColor: const Color(0xFFCFECDC),
                    backgroundColor: scheme.surfaceContainerLow,
                    side: BorderSide(
                      color: _selectedLanguage == language.code
                          ? const Color(0xFF3C9670) : scheme.outlineVariant),
                  ),
                ),
            ]),
          );
        },
      ),
      const SizedBox(height: 17),
      _sectionHeader(ar ? 'المستوى' : 'CEFR level'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final level in AcademyPodcastRepository.levels)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 7),
              child: ChoiceChip(
                key: ValueKey('podcast-level-$level'),
                label: Text(level),
                selected: _selectedLevel == level,
                onSelected: (_) => setState(() => _selectedLevel = level),
                selectedColor: const Color(0xFFCAEADB),
                backgroundColor: scheme.surfaceContainerLow,
                side: BorderSide(color: _selectedLevel == level
                    ? const Color(0xFF39926D) : scheme.outlineVariant),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _selectedLevel == level
                      ? const Color(0xFF145039) : scheme.onSurface),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      if (voaA2) ...[
        A2LongListeningSection(initialLessons: widget.initialA2Lessons),
        VoaOriginalsSection(
          level: 'A2',
          initialLessons: widget.initialA2Lessons,
          onOpen: _openVoaLesson,
        ),
      ] else if (voaOnly) ...[
        VoaOriginalsSection(onOpen: _openVoaLesson),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          child: ExpansionTile(
            key: const ValueKey('podcast-a1-reading-practice'),
            initiallyExpanded: false,
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(ar ? 'نصوص WorldVoice التدريبية (صوت آلي)'
                : 'WorldVoice reading practice (device voice)'),
            subtitle: Text(ar
                ? 'مواد أصلية محفوظة منفصلة عن تسجيلات VOA.'
                : 'Original practice scripts kept separate from VOA recordings.'),
            children: [
            FutureBuilder<List<AcademyPodcastEntry>>(
              future: _episodes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(ar ? 'تعذر تحميل الحلقات.' : 'Could not load episodes.');
                }
                if (!snapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator()));
                }
                final current = snapshot.data!.where((entry) =>
                    entry.language == _selectedLanguage &&
                    entry.level == _selectedLevel).toList(growable: false);
                // Preserve the curriculum order (01–15) rather than moving all
                // audio recordings ahead of their text-only neighbors.
                final available = current.where((e) =>
                    e.hasTranscript && (!voaOnly ||
                        e.status == 'script_ready')).toList();
                final planned = current.where((e) => !e.hasTranscript).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                        ar ? 'حلقات $_selectedLevel' : 'Level $_selectedLevel',
                        style: const TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w900))),
                      Text(ar
                          ? '${available.length}/15 نصًا جاهزًا'
                          : '${available.length}/15 transcripts',
                          style: TextStyle(color: scheme.onSurfaceVariant,
                              fontSize: 11)),
                    ]),
                    const SizedBox(height: 10),
                    for (final entry in available)
                      _episodeCard(entry, current.indexOf(entry) + 1, ar),
                    if (available.isEmpty)
                      FutureBuilder<List<PodcastLanguage>>(
                        future: _languages,
                        builder: (context, state) {
                          final language = state.data?.where((entry) =>
                              entry.code == _selectedLanguage).firstOrNull ??
                              PodcastLanguage(
                                code: _selectedLanguage,
                                nativeName: _selectedLanguage,
                                arabicName: _selectedLanguage,
                                flag: '🎧',
                              );
                          return _emptyLanguage(language, ar);
                        },
                      ),
                    if (planned.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        color: scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                          side: BorderSide(color: scheme.outlineVariant)),
                        child: ExpansionTile(
                          key: ValueKey(
                              'podcast-planned-$_selectedLanguage-$_selectedLevel'),
                          leading: const Icon(Icons.library_books_outlined,
                              color: Color(0xFF438A69)),
                          title: Text(
                            ar ? '${planned.length} حلقة مخططة'
                                : '${planned.length} upcoming episodes',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: Text(ar
                              ? 'العناوين جاهزة للتخطيط، لم تُنشر التسجيلات بعد'
                              : 'Planned titles, not published recordings',
                              style: TextStyle(
                                  fontSize: 11, color: scheme.onSurfaceVariant)),
                          children: [
                            for (final entry in planned)
                              ListTile(
                                dense: true,
                                title: Text(ar
                                    ? entry.titleAr ?? entry.title : entry.title,
                                    style: const TextStyle(fontSize: 13)),
                                trailing: const Icon(Icons.schedule,
                                    size: 16, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            ],
          ),
        ),
      ] else if (voaB1) ...[
        const B1VoaLongSection(),
      ] else if (nasaAdvanced) ...[
        NasaLongPodcastSection(level: _selectedLevel),
      ] else
      FutureBuilder<List<AcademyPodcastEntry>>(
        future: _episodes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(ar ? 'تعذر تحميل الحلقات.' : 'Could not load episodes.');
          }
          if (!snapshot.hasData) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(25),
              child: CircularProgressIndicator()));
          }
          final current = snapshot.data!.where((entry) =>
              entry.language == _selectedLanguage &&
              entry.level == _selectedLevel).toList(growable: false);
          // Preserve the curriculum order (01–15) rather than moving all
          // audio recordings ahead of their text-only neighbors.
          final available = current.where((e) =>
              e.hasTranscript && (!voaOnly ||
                  e.status == 'script_ready')).toList();
          final planned = current.where((e) => !e.hasTranscript).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(
                  ar ? 'حلقات $_selectedLevel' : 'Level $_selectedLevel',
                  style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w900))),
                Text(ar
                    ? '${available.length}/15 نصًا جاهزًا'
                    : '${available.length}/15 transcripts',
                    style: TextStyle(color: scheme.onSurfaceVariant,
                        fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              for (final entry in available)
                _episodeCard(entry, current.indexOf(entry) + 1, ar),
              if (available.isEmpty)
                FutureBuilder<List<PodcastLanguage>>(
                  future: _languages,
                  builder: (context, state) {
                    final language = state.data?.where((entry) =>
                        entry.code == _selectedLanguage).firstOrNull ??
                        PodcastLanguage(
                          code: _selectedLanguage,
                          nativeName: _selectedLanguage,
                          arabicName: _selectedLanguage,
                          flag: '🎧',
                        );
                    return _emptyLanguage(language, ar);
                  },
                ),
              if (planned.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                    side: BorderSide(color: scheme.outlineVariant)),
                  child: ExpansionTile(
                    key: ValueKey(
                        'podcast-planned-$_selectedLanguage-$_selectedLevel'),
                    leading: const Icon(Icons.library_books_outlined,
                        color: Color(0xFF438A69)),
                    title: Text(
                      ar ? '${planned.length} حلقة مخططة'
                          : '${planned.length} upcoming episodes',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: Text(ar
                        ? 'العناوين جاهزة للتخطيط، لم تُنشر التسجيلات بعد'
                        : 'Planned titles, not published recordings',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                    children: [
                      for (final entry in planned)
                        ListTile(
                          dense: true,
                          title: Text(ar
                              ? entry.titleAr ?? entry.title : entry.title,
                              style: const TextStyle(fontSize: 13)),
                          trailing: const Icon(Icons.schedule,
                              size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 14),
    ]);
  }
}

class PodcastReaderScreen extends StatefulWidget {
  const PodcastReaderScreen({
    required this.entry,
    required this.repository,
    super.key,
  });

  final AcademyPodcastEntry entry;
  final AcademyPodcastRepository repository;

  @override
  State<PodcastReaderScreen> createState() => _PodcastReaderScreenState();
}

class _PodcastReaderScreenState extends State<PodcastReaderScreen> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scroll = ScrollController();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  AcademyPodcastEpisode? _episode;
  List<GlobalKey> _anchors = <GlobalKey>[];
  bool _audioLoaded = false;
  bool _downloaded = false;
  bool _downloading = false;
  bool _autoFollow = true;
  String? _error;
  // Sentence changes must not rebuild the entire (long) transcript.
  final ValueNotifier<int?> _activeLine = ValueNotifier<int?>(null);
  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  double _speed = 1.0;
  // Device TTS is separate from the real VOA MP3 player.
  bool _ttsSpeaking = false;
  final ValueNotifier<int> _ttsCue = ValueNotifier<int>(0);
  int _ttsSession = 0;
  double _ttsSpeed = 1.0;
  double _fontSize = 17.0;
  final Map<int, int> _answers = <int, int>{};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _error = null;
        _audioLoaded = false;
      });
    }
    await _positionSubscription?.cancel();
    await _stateSubscription?.cancel();
    _positionSubscription = null;
    _stateSubscription = null;
    _activeLine.value = null;
    _isPlaying.value = false;
    _ttsSession++;
    if (_ttsSpeaking) {
      unawaited(_tts.stop());
      _ttsSpeaking = false;
    }
    try {
      final loaded = await widget.repository.load(widget.entry);
      if (!mounted) return;
      setState(() {
        _episode = loaded;
        _anchors = List<GlobalKey>.generate(
            loaded.dialogue.length, (_) => GlobalKey());
      });
      if (!loaded.canStream) return;
      _positionSubscription = _player.positionStream.listen(_onPosition);
      _stateSubscription = _player.playerStateStream.listen((state) {
        // Only the play/pause icon listens to this, not the transcript.
        if (mounted) {
          _isPlaying.value = state.playing;
        }
      });
      final local = await _offlineAudioFile(loaded);
      final offline = await local.exists() && await local.length() > 100000;
      if (offline) {
        await _player.setFilePath(local.path);
      } else {
        try {
          await _player.setUrl(loaded.audioUrl!)
              .timeout(const Duration(seconds: 22));
        } catch (_) {
          final backup = Uri.tryParse(loaded.backupAudioUrl ?? '');
          if (backup == null || backup.scheme != 'https' ||
              backup.host.isEmpty) {
            rethrow;
          }
          await _player.setUrl(backup.toString())
              .timeout(const Duration(seconds: 22));
        }
      }
      if (mounted) {
        setState(() {
          _audioLoaded = true;
          _downloaded = offline;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل الحلقة أو ملف الصوت.';
        });
      }
    }
  }

  Future<File> _offlineAudioFile(AcademyPodcastEpisode episode) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/worldvoice_podcasts');
    return File('${dir.path}/${episode.id}.mp3');
  }

  bool _isMp3(List<int> bytes) {
    if (bytes.length < 100000) return false;
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      return true; // ID3 header
    }
    return bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0;
  }

  /// Explicit offline save; source audio is public-domain VOA content.
  /// Never claim success until the device has a valid downloaded MP3.
  Future<void> _saveOffline() async {
    final episode = _episode;
    if (episode == null || !episode.canStream ||
        _downloading || _downloaded) {
      return;
    }
    setState(() => _downloading = true);
    try {
      http.Response? saved;
      for (final url in [episode.audioUrl, episode.backupAudioUrl]) {
        if (url == null) continue;
        try {
          final uri = Uri.parse(url);
          if (uri.scheme != 'https') continue;
          final candidate = await http.get(uri)
              .timeout(const Duration(seconds: 75));
          if (candidate.statusCode == 200 &&
              _isMp3(candidate.bodyBytes)) {
            saved = candidate;
            break;
          }
        } catch (_) {
          // Use the alternative VOA bitrate if the first endpoint fails.
        }
      }
      if (saved == null) {
        throw const FormatException('Source did not return a valid MP3.');
      }
      final file = await _offlineAudioFile(episode);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(saved.bodyBytes, flush: true);
      if (!mounted) return;
      setState(() => _downloaded = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Localizations.localeOf(context).languageCode == 'ar'
            ? 'حُفظت الحلقة على الجهاز للاستماع دون إنترنت.'
            : 'Podcast saved on this device for offline playback.'),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر تنزيل الصوت. يمكنك تشغيله من رابط VOA الأصلي.'
            : 'Could not download the audio. Use the official VOA source.'),
      ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // Find a transcript sentence on demand, independently of the player.
  // Keeps the reading action available even to text-only A1 lessons.
  void _jumpToLine(int index) {
    if (!mounted || index < 0 || index >= _anchors.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final lineContext = _anchors[index].currentContext;
      if (lineContext == null) return;
      Scrollable.ensureVisible(lineContext,
          alignment: 0.12,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    });
  }

  void _onPosition(Duration position) {
    if (!mounted) return;
    final active = _episode?.lineAt(position);
    if (_activeLine.value == active) return;
    // Do not call setState: otherwise 44+ transcript paragraphs get rebuilt
    // whenever a new cue is spoken and older Android phones may show blanks.
    _activeLine.value = active;
    if (active != null) _followLine(active);
  }

  void _followLine(int active) {
    if (!_autoFollow || active < 0 || active >= _anchors.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoFollow || !_scroll.hasClients) return;
      final lineContext = _anchors[active].currentContext;
      if (lineContext == null) return;
      final render = lineContext.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final screenTop = render.localToGlobal(Offset.zero).dy;
        final screenBottom = screenTop + render.size.height;
        final viewport = MediaQuery.sizeOf(context).height;
        final safeTop = MediaQuery.paddingOf(context).top + kToolbarHeight + 20;
        final safeBottom = viewport - MediaQuery.paddingOf(context).bottom - 154;
        if (screenTop >= safeTop && screenBottom <= safeBottom) return;
      }
      Scrollable.ensureVisible(lineContext,
          alignment: 0.25,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    });
  }

  // Narrate the text-only English A1 script line by line using the device
  // voice. Each highlight starts when that line is sent to speech; we do
  // not fabricate timestamps for human recordings or claim exact word sync.
  Future<void> _readAloudFrom(int start) async {
    final episode = _episode;
    if (!mounted || episode == null || !episode.canReadAloud) return;
    final session = ++_ttsSession;
    final index = start.clamp(0, episode.dialogue.length - 1).toInt();
    setState(() => _ttsSpeaking = true);
    _ttsCue.value = index;
    try {
      await _tts.stop();
      if (!mounted || session != _ttsSession) return;
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(
          (0.46 * _ttsSpeed).clamp(0.20, 0.80).toDouble());
      await _tts.setPitch(1.0);
      for (var lineIndex = index;
          lineIndex < episode.dialogue.length && session == _ttsSession;
          lineIndex++) {
        if (!mounted || !_ttsSpeaking) return;
        // Only the bottom TTS player and the selected line repaint.
        _ttsCue.value = lineIndex;
        _activeLine.value = lineIndex;
        _followLine(lineIndex);
        final spoken = await _tts.speak(episode.dialogue[lineIndex].text);
        if (spoken == 0) {
          throw StateError('The device TTS engine did not start speech.');
        }
      }
      if (mounted && session == _ttsSession) {
        setState(() => _ttsSpeaking = false);
        _ttsCue.value = 0;
        _activeLine.value = null;
      }
    } catch (_) {
      if (!mounted || session != _ttsSession) return;
      setState(() => _ttsSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر تشغيل القراءة الآلية. تحقق من توفر صوت الإنجليزية على الجهاز.'
            : 'Device voice unavailable. Check English text-to-speech settings.'),
      ));
    }
  }

  void _stopReadAloud() {
    ++_ttsSession;
    unawaited(_tts.stop().catchError((_) {}));
    if (mounted) setState(() => _ttsSpeaking = false);
  }

  void _playPauseReadAloud() {
    if (_ttsSpeaking) {
      _stopReadAloud();
    } else {
      unawaited(_readAloudFrom(_ttsCue.value));
    }
  }

  Widget _readAloudPlayer(AcademyPodcastEpisode episode) {
    final scheme = Theme.of(context).colorScheme;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('podcast-device-tts-player'),
        padding: const EdgeInsets.fromLTRB(13, 8, 13, 13),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: _ttsCue,
          builder: (context, cue, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Row(children: [
            IconButton.filled(
              key: const ValueKey('podcast-device-tts-play-pause'),
              onPressed: _playPauseReadAloud,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1F7958),
                foregroundColor: Colors.white,
              ),
              icon: Icon(_ttsSpeaking
                  ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 9),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ar ? 'قراءة إنجليزية بصوت الجهاز (آلي)'
                    : 'English device voice (synthetic)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800,
                        fontSize: 12)),
                Text(ar
                    ? 'السطر ${cue + 1} من ${episode.dialogue.length}'
                    : 'Line ${cue + 1} of ${episode.dialogue.length}',
                    style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant)),
              ],
            )),
            IconButton(
              key: const ValueKey('podcast-device-tts-restart'),
              tooltip: ar ? 'البدء من أول المحادثة' : 'Start from first line',
              onPressed: () => unawaited(_readAloudFrom(0)),
              icon: const Icon(Icons.replay_rounded),
            ),
            DropdownButton<double>(
              key: const ValueKey('podcast-device-tts-speed'),
              value: _ttsSpeed,
              underline: const SizedBox.shrink(),
              items: const [0.75, 1.0, 1.25].map((value) =>
                DropdownMenuItem<double>(
                  value: value, child: Text('$value×'),
                )).toList(),
              onChanged: (value) {
                if (value == null) return;
                final resume = _ttsSpeaking;
                setState(() => _ttsSpeed = value);
                if (resume) unawaited(_readAloudFrom(_ttsCue.value));
              },
            ),
          ]),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: (cue + 1) / episode.dialogue.length,
            color: const Color(0xFF237D5C),
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ]),
        ),
      ),
    );
  }

  void _playPause() {
    if (!_audioLoaded) return;
    if (_player.playing) {
      unawaited(_player.pause());
    } else {
      if (_player.processingState == ProcessingState.completed) {
        unawaited(_player.seek(Duration.zero).then((_) => _player.play()));
      } else {
        unawaited(_player.play());
      }
    }
  }

  Future<void> _seekLine(PodcastDialogueLine line) async {
    if (!_audioLoaded || line.startMs == null) return;
    await _player.seek(Duration(milliseconds: line.startMs!));
    if (!_player.playing) {
      unawaited(_player.play());
    }
  }

  String _clock(Duration time) {
    final sec = time.inSeconds;
    final minutes = sec ~/ 60;
    final seconds = (sec % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    ++_ttsSession;
    // Text-only reader widget tests never initialize a native TTS engine.
    if (_ttsSpeaking) {
      unawaited(_tts.stop().catchError((_) {}));
    }
    _player.dispose();
    _scroll.dispose();
    _activeLine.dispose();
    _ttsCue.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Widget _audioPanel(AcademyPodcastEpisode episode) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final ready = _audioLoaded;
    return Container(
      key: const ValueKey('podcast-reader-header'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF153F31), Color(0xFF21694D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_stories_rounded,
                color: Color(0xFFF4D790), size: 21),
            const SizedBox(width: 7),
            const Expanded(child: Text(
              'WORLDVOICE · READ & LISTEN',
              style: TextStyle(color: Color(0xFFF4D790),
                  fontSize: 11, fontWeight: FontWeight.w900,
                  letterSpacing: .7),
              textDirection: TextDirection.ltr,
            )),
            Text(episode.level,
              style: const TextStyle(color: Color(0xFFF4D790),
                fontSize: 13, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 14),
          Text(ar ? episode.titleAr : episode.title,
              style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.face_3_rounded,
                color: Color(0xFFF3BED7), size: 20),
            const SizedBox(width: 4),
            Text(episode.hosts.isNotEmpty
                ? episode.hosts.first : 'Anna',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            const Icon(Icons.face_rounded,
                color: Color(0xFFC5DDFF), size: 20),
            const SizedBox(width: 4),
            Text(episode.hosts.length > 1
                ? episode.hosts[1] : 'Daniel',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.schedule, color: Color(0xFFF4D790), size: 16),
            const SizedBox(width: 5),
            Text(episode.canStream
                ? _clock(Duration(milliseconds: episode.durationMs!))
                : (episode.canReadAloud
                    ? (ar ? 'قراءة آلية' : 'Device voice')
                    : (ar ? 'نص فقط' : 'Text only')),
                textDirection: episode.canStream
                    ? TextDirection.ltr : null,
                style: const TextStyle(color: Color(0xFFF4D790),
                    fontWeight: FontWeight.w800)),
          ]),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('podcast-jump-to-transcript'),
              onPressed: () => _jumpToLine(_activeLine.value ?? 0),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(episode.isExcerpt
                  ? (ar ? 'انتقل إلى مقتطف المحادثة' : 'Jump to excerpt')
                  : (ar ? 'انتقل إلى نص المحادثة'
                      : 'Jump to transcript')),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF4D790),
              ),
            ),
          ),
          if (!ready) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(children: [
                const Icon(Icons.mic_off_outlined,
                    color: Color(0xFFF4D790), size: 19),
                const SizedBox(width: 9),
                Expanded(child: Text(
                  ar
                      ? (episode.canStream
                          ? (_error == null
                              ? 'جارٍ تحميل التسجيل البشري من VOA...'
                              : 'تعذر تحميل الصوت. افتح المصدر الأصلي أدناه.')
                          : (episode.canReadAloud
                              ? 'يمكن الاستماع بنطق آلي إنجليزي من جهازك. لا يوجد تسجيل بشري.'
                              : 'نص قابل للقراءة الآن. التسجيل البشري لم يتوفر بعد.'))
                      : (episode.canStream
                          ? (_error == null
                              ? 'Loading the human recording from VOA...'
                              : 'Audio could not load. Open the original source below.')
                          : (episode.canReadAloud
                              ? 'Listen with your device’s English synthetic voice. No human recording is available.'
                              : 'The transcript is ready. Human audio has not been published.')),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.5),
                )),
              ]),
            ),
          ],
          // The offline helper validates MP3 bytes. Lesson 8 is a video
          // audio stream and must not be offered an incompatible MP3 save.
          if (episode.canStream &&
              Uri.tryParse(episode.audioUrl ?? '')?.path.endsWith('.mp3') == true) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const ValueKey('podcast-save-offline'),
                onPressed: (_downloaded || _downloading)
                    ? null : _saveOffline,
                icon: Icon(_downloaded
                    ? Icons.download_done_rounded
                    : _downloading
                        ? Icons.hourglass_top_rounded
                        : Icons.download_rounded,
                    size: 18),
                label: Text(_downloaded
                    ? (ar ? 'محفوظ للاستماع دون إنترنت' : 'Available offline')
                    : _downloading
                        ? (ar ? 'جارٍ حفظ التسجيل' : 'Saving audio')
                        : (ar ? 'تنزيل تسجيل VOA' : 'Download VOA audio')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF4D790),
                  side: const BorderSide(color: Color(0xFFE4C779)),
                ),
              ),
            ),
          ],
          if (episode.isExcerpt) ...[
            const SizedBox(height: 8),
            Text(ar
                ? 'المحادثة المعروضة مقتطف أصلي مترجم وليست النص الكامل. استمع إلى التسجيل كاملًا، وافتح النص الكامل من VOA أدناه. لم يتم اعتماد توقيت الجمل.'
                : 'These are selected translated lines, not the full transcript. Listen to the complete official VOA recording and open the full transcript below. No line timings are certified.',
                style: const TextStyle(
                    color: Color(0xFFE0EEE5), fontSize: 11, height: 1.4)),
          ],
          if (episode.canStream && episode.syncStatus == 'provisional') ...[
            const SizedBox(height: 8),
            Text(ar
                ? 'تمييز الجمل تجريبي ومبني على مطابقة التسجيل الأصلي؛ قد يحتاج ضبطًا في بعض المواضع.'
                : 'Sentence highlighting is provisional, aligned from the original recording and pending listening review.',
                style: const TextStyle(
                    color: Color(0xFFF4D790), fontSize: 11, height: 1.4)),
          ] else if (episode.canStream && !episode.isPlayable) ...[
            const SizedBox(height: 8),
            Text(ar
                ? 'الصوت والنص الأصلي متاحان. تمييز الجملة تلقائيًا غير مفعل حتى مراجعة توقيتها مع التسجيل.'
                : 'Original audio and transcript are available. Automatic line highlighting awaits verified timestamps.',
                style: const TextStyle(
                    color: Color(0xFFE0EEE5), fontSize: 11, height: 1.4)),
          ],
          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                style: const TextStyle(color: Colors.white70)),
            ),
            if (episode.canStream)
              TextButton.icon(
                key: const ValueKey('podcast-retry-audio'),
                onPressed: _initialize,
                icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFFF4D790)),
                label: Text(ar ? 'إعادة محاولة تحميل الصوت' : 'Retry audio',
                  style: const TextStyle(color: Color(0xFFF4D790))),
              ),
          ],
        ],
      ),
    );
  }

  /// Fixed player remains on screen as the learner scrolls through the book.
  Widget _fixedPlayer(AcademyPodcastEpisode episode) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('podcast-sticky-player'),
        padding: const EdgeInsets.fromLTRB(13, 7, 13, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withValues(alpha: .09),
              offset: const Offset(0, -3)),
          ],
        ),
        child: StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final total = _player.duration ??
                Duration(milliseconds: episode.durationMs!);
            final maxMs = total.inMilliseconds > 0
                ? total.inMilliseconds : 1;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlaying,
                  builder: (context, playing, _) => IconButton.filled(
                    key: const ValueKey('podcast-play-pause'),
                    onPressed: _playPause,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1F7958),
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(playing
                        ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(episode.title, maxLines: 1,
                      textDirection: TextDirection.ltr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 12)),
                    Text('${_clock(position)} / ${_clock(total)}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 11,
                            color: scheme.onSurfaceVariant)),
                  ],
                )),
                IconButton(
                  tooltip: 'Restart',
                  onPressed: () => unawaited(_player.seek(Duration.zero)),
                  icon: const Icon(Icons.replay_rounded, size: 22),
                ),
                DropdownButton<double>(
                  value: _speed,
                  underline: const SizedBox.shrink(),
                  items: const [0.75, 1.0, 1.25].map((value) =>
                    DropdownMenuItem<double>(
                      value: value, child: Text('$value×'),
                    )).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _speed = value);
                    unawaited(_player.setSpeed(value));
                  },
                ),
              ]),
              SizedBox(
                height: 18,
                child: Slider(
                  value: position.inMilliseconds.clamp(0, maxMs).toDouble(),
                  max: maxMs.toDouble(),
                  activeColor: const Color(0xFF237D5C),
                  onChanged: (value) => unawaited(_player.seek(
                    Duration(milliseconds: value.round()))),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _dialogueLine(PodcastDialogueLine line, int i) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Explicit high-contrast ink on real Material cards prevents blank
    // transcript blocks on some devices in dark mode.
    final ink = isDark ? const Color(0xFFF5F8F5) : const Color(0xFF17271E);
    final secondary = isDark
        ? const Color(0xFFC3D6C9) : const Color(0xFF506D59);
    final surface = isDark
        ? (i.isEven ? const Color(0xFF22302A) : const Color(0xFF1B2822))
        : (i.isEven ? const Color(0xFFF2F7F3) : Colors.white);
    final anna = line.speaker == 'Anna';
    final sourceIsArabic = _episode?.language == 'ar';
    final translation = sourceIsArabic
        ? line.translationEn ?? '' : line.translationAr;
    final canReplay = (_audioLoaded && line.startMs != null) ||
        (_episode?.canReadAloud ?? false);
    // The dialogue itself is a cached child. Cue updates repaint only the
    // slim left indicator instead of rebuilding text and avatars.
    final paragraph = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: anna
                ? const Color(0xFFF2CEDF) : const Color(0xFFCFE0F7),
            child: Icon(anna
                ? Icons.face_3_rounded
                : line.speaker == 'Marsha'
                    ? Icons.face_3_outlined : Icons.face_rounded,
              color: const Color(0xFF204D3B), size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.speaker,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: secondary,
                  fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 6),
              Text(line.text,
                key: ValueKey('podcast-line-text-$i'),
                textDirection: sourceIsArabic
                    ? TextDirection.rtl : TextDirection.ltr,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: _fontSize, height: 1.5,
                    color: ink, fontWeight: FontWeight.w500),
              ),
              PodcastSentenceTranslation(
                key: ValueKey('podcast-translate-line-$i'),
                text: line.text,
                sourceLanguage: sourceIsArabic ? 'ar' : 'en',
                arabicDraft: sourceIsArabic ? null : line.translationAr,
              ),
            ],
          )),
          if (canReplay) ...[
            const SizedBox(width: 4),
            Icon(Icons.play_circle_outline_rounded,
                color: secondary, size: 18),
          ],
        ],
      ),
    );
    return ValueListenableBuilder<int?>(
      valueListenable: _activeLine,
      child: paragraph,
      builder: (context, selected, child) {
        final current = _audioLoaded && selected == i;
        return Container(
          key: _anchors[i],
          margin: const EdgeInsets.only(bottom: 7),
          // A non-uniform Border and borderRadius together trigger a Flutter
          // paint exception, leaving the entire dialogue card empty.
          // The rounded corner belongs to Material, not to this border.
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: current
                      ? const Color(0xFF39B781) : Colors.transparent,
                  width: 4),
            ),
          ),
          child: Material(
            key: ValueKey('podcast-dialogue-line-$i'),
            color: surface,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: !canReplay ? null
                  : (_episode?.canReadAloud ?? false)
                      ? () => unawaited(_readAloudFrom(i))
                      : () => _seekLine(line),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _quiz(AcademyPodcastEpisode episode) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(ar ? 'اختبار الفهم' : 'Listening comprehension',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        for (var i = 0; i < episode.questions.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(episode.questions[i].question,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                for (var choice = 0;
                    choice < episode.questions[i].options.length;
                    choice++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _answers[i] == choice
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _answers[i] == choice
                          ? const Color(0xFF198058)
                          : scheme.outline,
                    ),
                    title: Text(episode.questions[i].options[choice],
                        textDirection: TextDirection.ltr),
                    onTap: () => setState(() => _answers[i] = choice),
                  ),
                if (_answers.containsKey(i))
                  Text(
                    _answers[i] == episode.questions[i].answer
                        ? (ar ? 'إجابة صحيحة' : 'Correct answer')
                        : (ar ? 'حاول مرة أخرى' : 'Try again'),
                    style: TextStyle(
                      color: _answers[i] == episode.questions[i].answer
                          ? const Color(0xFF198058)
                          : scheme.error,
                    ),
                  ),
              ]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final episode = _episode;
    return Scaffold(
      appBar: AppBar(
        title: Text(episode == null
            ? widget.entry.title
            : ar ? episode.titleAr : episode.title),
        centerTitle: true,
      ),
      bottomNavigationBar: episode == null
          ? null
          : _audioLoaded
              ? _fixedPlayer(episode)
              : episode.canReadAloud
                  ? _readAloudPlayer(episode)
                  : null,
      body: episode == null
          ? Center(child: _error == null
              ? const CircularProgressIndicator()
              : Text(_error!))
          : NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                // A manual swipe wins over auto-follow until re-enabled.
                if (notification.dragDetails != null && _autoFollow) {
                  setState(() => _autoFollow = false);
                }
                return false;
              },
              child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _audioPanel(episode),
                const SizedBox(height: 19),
                Row(children: [
                  const Icon(Icons.menu_book_rounded,
                      color: Color(0xFF318560), size: 21),
                  const SizedBox(width: 7),
                  Expanded(child: Text(
                    episode.isExcerpt
                        ? (ar ? 'مقتطف من المحادثة الأصلية' : 'Original conversation excerpt')
                        : (ar ? 'نص المحادثة' : 'Transcript'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900))),
                  IconButton(
                    key: const ValueKey('podcast-auto-follow-toggle'),
                    tooltip: ar
                        ? (_autoFollow ? 'إيقاف متابعة الجملة' : 'متابعة الجملة تلقائيًا')
                        : (_autoFollow ? 'Disable auto-follow' : 'Enable auto-follow'),
                    onPressed: () {
                      setState(() => _autoFollow = !_autoFollow);
                      if (_autoFollow && _activeLine.value != null) {
                        _jumpToLine(_activeLine.value!);
                      }
                    },
                    icon: Icon(_autoFollow
                        ? Icons.my_location_rounded
                        : Icons.location_disabled_rounded),
                    color: _autoFollow ? const Color(0xFF318560)
                        : scheme.onSurfaceVariant,
                  ),
                  IconButton(
                    key: const ValueKey('podcast-text-smaller'),
                    tooltip: ar ? 'تصغير الخط' : 'Decrease text size',
                    onPressed: () => setState(() =>
                        _fontSize = (_fontSize - 1).clamp(14.0, 22.0).toDouble()),
                    icon: const Icon(Icons.text_decrease_rounded)),
                  IconButton(
                    key: const ValueKey('podcast-text-larger'),
                    tooltip: ar ? 'تكبير الخط' : 'Increase text size',
                    onPressed: () => setState(() =>
                        _fontSize = (_fontSize + 1).clamp(14.0, 22.0).toDouble()),
                    icon: const Icon(Icons.text_increase_rounded)),
                ]),
                Text(
                  ar ? 'اضغط علامة الترجمة على أي جملة لترجمتها إلى لغتك الأم'
                      : 'Tap the translation icon on a sentence to read it in your native language',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    episode.isPlayable
                        ? (episode.syncStatus == 'provisional'
                            ? (ar ? 'تزامن الجمل تجريبي · اضغط على الجملة لإعادة سماعها'
                                : 'Provisional sync · Tap any line to replay')
                            : (ar ? 'يُبرز السطر عند سماعه · اضغط عليه لإعادته'
                                : 'Follow the highlighted line · Tap to replay'))
                        : (!episode.canStream
                            ? (episode.canReadAloud
                                ? (ar
                                    ? 'شغّل القراءة الآلية واستمع لكل سطر؛ لا يوجد تسجيل بشري لهذه الحلقة.'
                                    : 'Play the device voice to follow each line · No human recording.')
                                : (ar
                                    ? 'نص تعليمي للقراءة · التسجيل الصوتي غير متوفر بعد.'
                                    : 'Reading transcript · No recording published yet.'))
                            : episode.isExcerpt
                                ? (ar
                                    ? 'اقرأ المقتطف مع التسجيل البشري الكامل. افتح النص الكامل من VOA؛ توقيت السطور غير متاح.'
                                    : 'Read this excerpt with the complete human recording. Full transcript on VOA; line timing unavailable.')
                                : (ar
                                    ? 'اقرأ النص مع تشغيل التسجيل الأصلي. مزامنة السطور قيد التحقق.'
                                    : 'Read along with the authentic recording. Line timing is under review.')),
                    style: TextStyle(color: scheme.onSurfaceVariant,
                      fontSize: 11)),
                ),
                const SizedBox(height: 15),
                for (var i = 0; i < episode.dialogue.length; i++)
                  _dialogueLine(episode.dialogue[i], i),
                const SizedBox(height: 10),
                Text(ar ? 'المفردات' : 'Vocabulary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900)),
                const SizedBox(height: 9),
                Wrap(spacing: 7, runSpacing: 5, children: [
                  for (final word in episode.vocabulary)
                    Chip(label: Text('${word.word} · ${word.meaningAr}')),
                ]),
                _quiz(episode),
                if (episode.sourceUrl != null)
                  PodcastSourceInfo(
                    source: episode.sourceCredit ?? 'Original recording',
                    url: episode.sourceUrl!,
                  ),
                ],
              ),
            ),
            ),
    );
  }
}
