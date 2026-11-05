import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/academy_podcast_repository.dart';

/// Separate CEFR/language paths; never represent unrecorded plans as audio.
class PodcastLibrarySection extends StatefulWidget {
  const PodcastLibrarySection({super.key});

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

  Widget _hero(bool ar) => Container(
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
          Text(ar ? 'حكايتان، صوتان، لغة جديدة'
                  : 'Two voices. One new language.',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 21)),
          const SizedBox(height: 6),
          Text(
            ar ? 'بودكاست حواري بين آنا ودانيال. تعلّم بالاستماع والقراءة معًا.'
               : 'Anna and Daniel talk. You listen, read and learn.',
            style: const TextStyle(
                color: Color(0xFFE0EEE5), height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 17),
          Row(children: [
            _hostPill('ANNA', Icons.face_3_rounded,
                const Color(0xFFF2BDD6)),
            const SizedBox(width: 9),
            _hostPill('DANIEL', Icons.face_rounded,
                const Color(0xFFC1DBFF)),
            const Spacer(),
            const Icon(Icons.schedule_rounded,
                color: Color(0xFFF1D98F), size: 16),
            const SizedBox(width: 4),
            const Text('≈ 05:00',
                style: TextStyle(color: Color(0xFFF1D98F),
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ]),
      );

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

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      );

  Widget _episodeCard(AcademyPodcastEntry entry, int number, bool ar) {
    final theme = Theme.of(context);
    final enabled = entry.hasTranscript;
    final isPublished = entry.status == 'published';
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
                ? (ar ? 'استماع + قراءة متزامنة' : 'Audio + synced reading')
                : enabled
                    ? (ar ? 'اقرأ المحادثة · التسجيل لم يُضف بعد'
                        : 'Read transcript · No recording yet')
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
          if (_selectedLanguage != 'en') {
            final language = PodcastLanguage(
                code: _selectedLanguage, nativeName: _selectedLanguage,
                arabicName: _selectedLanguage, flag: '🎧');
            return FutureBuilder<List<PodcastLanguage>>(
              future: _languages,
              builder: (context, state) {
                final entry = state.data?.where((x) =>
                    x.code == _selectedLanguage).firstOrNull ?? language;
                return _emptyLanguage(entry, ar);
              },
            );
          }
          final available = current.where((e) => e.hasTranscript).toList();
          final planned = current.where((e) => !e.hasTranscript).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(
                  ar ? 'حلقات $_selectedLevel' : 'Level $_selectedLevel',
                  style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w900))),
                Text(ar ? '15 حلقة لكل مستوى' : '15 per level',
                  style: TextStyle(color: scheme.onSurfaceVariant,
                    fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              for (final entry in available)
                _episodeCard(entry, current.indexOf(entry) + 1, ar),
              if (available.isEmpty)
                _emptyLanguage(
                  const PodcastLanguage(code: 'en',
                    nativeName: 'English', arabicName: 'الإنجليزية',
                    flag: '🇬🇧'), ar),
              if (planned.isNotEmpty) ...[
                const SizedBox(height: 7),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                    side: BorderSide(color: scheme.outlineVariant)),
                  child: ExpansionTile(
                    key: ValueKey('podcast-planned-$_selectedLevel'),
                    leading: const Icon(Icons.library_books_outlined,
                        color: Color(0xFF438A69)),
                    title: Text(ar
                        ? '${planned.length} حلقة مخططة'
                        : '${planned.length} upcoming episodes',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: Text(ar ? 'اضغط لعرض العناوين'
                        : 'Tap to see the planned titles',
                        style: TextStyle(fontSize: 11,
                            color: scheme.onSurfaceVariant)),
                    children: [
                      for (final entry in planned)
                        ListTile(
                          dense: true,
                          title: Text(ar
                            ? entry.titleAr ?? entry.title : entry.title,
                              style: const TextStyle(fontSize: 13)),
                          trailing: const Icon(Icons.schedule,
                              color: Colors.grey, size: 16),
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
  final ScrollController _scroll = ScrollController();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  AcademyPodcastEpisode? _episode;
  List<GlobalKey> _anchors = <GlobalKey>[];
  bool _audioLoaded = false;
  bool _showArabic = false;
  String? _error;
  int? _activeIndex;
  double _speed = 1.0;
  double _fontSize = 17.0;
  final Map<int, int> _answers = <int, int>{};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final loaded = await widget.repository.load(widget.entry);
      if (!mounted) return;
      setState(() {
        _episode = loaded;
        _anchors = List<GlobalKey>.generate(
            loaded.dialogue.length, (_) => GlobalKey());
      });
      if (!loaded.isPlayable) return;
      _positionSubscription = _player.positionStream.listen(_onPosition);
      _stateSubscription = _player.playerStateStream.listen((state) {
        if (mounted) {
        setState(() {});
      }
      });
      await _player.setUrl(loaded.audioUrl!);
      if (mounted) {
        setState(() => _audioLoaded = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل الحلقة أو ملف الصوت.';
        });
      }
    }
  }

  void _onPosition(Duration position) {
    final active = _episode?.lineAt(position);
    if (_activeIndex == active || !mounted) return;
    setState(() => _activeIndex = active);
    if (active == null || active < 0 || active >= _anchors.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _anchors[active].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(context,
          alignment: 0.26,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    });
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
    _player.dispose();
    _scroll.dispose();
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
            const Text('Anna', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            const Icon(Icons.face_rounded,
                color: Color(0xFFC5DDFF), size: 20),
            const SizedBox(width: 4),
            const Text('Daniel', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.schedule, color: Color(0xFFF4D790), size: 16),
            const SizedBox(width: 5),
            Text(ready
                ? _clock(Duration(milliseconds: episode.durationMs!))
                : '≈ 05:00',
                style: const TextStyle(color: Color(0xFFF4D790),
                    fontWeight: FontWeight.w800)),
          ]),
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
                      ? 'نص قابل للقراءة الآن. تسجيل الصوت البشري لم يتوفر بعد.'
                      : 'The transcript is ready. Human audio has not been published.',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.5),
                )),
              ]),
            ),
          ],
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                style: const TextStyle(color: Colors.white70))),
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
                IconButton.filled(
                  key: const ValueKey('podcast-play-pause'),
                  onPressed: _playPause,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1F7958),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_player.playing
                      ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(episode.title, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 12)),
                    Text('${_clock(position)} / ${_clock(total)}',
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
    final scheme = Theme.of(context).colorScheme;
    final current = _activeIndex == i && _audioLoaded;
    final anna = line.speaker == 'Anna';
    final sourceIsArabic = _episode?.language == 'ar';
    final translation = sourceIsArabic
        ? line.translationEn ?? ''
        : line.translationAr;
    return AnimatedContainer(
      key: _anchors[i],
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
      decoration: BoxDecoration(
        color: current
            ? const Color(0xFFD9ECDD).withValues(alpha: .65)
            : i.isEven
                ? scheme.surfaceContainerLow
                : scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant
              .withValues(alpha: .35)),
          right: current ? const BorderSide(
              color: Color(0xFF237D5C), width: 3)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: InkWell(
        onTap: _audioLoaded ? () => _seekLine(line) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: anna
                  ? const Color(0xFFF2CEDF)
                  : const Color(0xFFCFE0F7),
              child: Icon(anna ? Icons.face_3_rounded : Icons.face_rounded,
                color: const Color(0xFF204D3B), size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(line.speaker,
                    style: TextStyle(
                      color: current
                          ? const Color(0xFF176245)
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800, fontSize: 12)),
                  if (current) ...[
                    const SizedBox(width: 7),
                    const Icon(Icons.graphic_eq_rounded,
                      color: Color(0xFF176245), size: 17),
                  ],
                ]),
                const SizedBox(height: 5),
                Text(
                  line.text,
                  textDirection: sourceIsArabic
                      ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: _fontSize,
                    height: 1.6,
                    color: current
                      ? const Color(0xFF102B20) : scheme.onSurface,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w500),
                ),
                if (_showArabic && translation.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    translation,
                    textDirection: sourceIsArabic
                        ? TextDirection.ltr : TextDirection.rtl,
                    style: TextStyle(
                      fontSize: _fontSize - 2.5, height: 1.6,
                      color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            )),
            if (_audioLoaded && !current)
              Icon(Icons.play_arrow_rounded,
                color: scheme.outline, size: 17),
          ],
        ),
      ),
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
      bottomNavigationBar: episode != null && _audioLoaded
          ? _fixedPlayer(episode)
          : null,
      body: episode == null
          ? Center(child: _error == null
              ? const CircularProgressIndicator()
              : Text(_error!))
          : SingleChildScrollView(
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
                    ar ? 'نص المحادثة' : 'Transcript',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900))),
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
                Row(children: [
                  Expanded(child: Text(
                    episode.language == 'ar'
                        ? (ar ? 'إظهار الترجمة الإنجليزية'
                            : 'Show English translation')
                        : (ar ? 'إظهار الترجمة العربية'
                            : 'Show Arabic translation'),
                    style: TextStyle(color: scheme.onSurfaceVariant,
                        fontSize: 12))),
                  Switch(
                    key: const ValueKey('podcast-translation-toggle'),
                    value: _showArabic,
                    onChanged: (value) => setState(() => _showArabic = value),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    ar ? 'تمييز الجملة أثناء الاستماع · اضغط عليها لإعادتها'
                        : 'Follow the highlighted sentence · Tap to replay',
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
                ],
              ),
            ),
    );
  }
}
