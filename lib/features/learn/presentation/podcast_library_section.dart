import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/academy_podcast_repository.dart';

/// Academy podcast episodes remain unplayable until a real recording and
/// verified dialogue cue timings have been attached to the manifest.
class PodcastLibrarySection extends StatefulWidget {
  const PodcastLibrarySection({super.key});

  @override
  State<PodcastLibrarySection> createState() =>
      _PodcastLibrarySectionState();
}

class _PodcastLibrarySectionState extends State<PodcastLibrarySection> {
  final _repository = const AcademyPodcastRepository();
  late final Future<List<AcademyPodcastEntry>> _future =
      _repository.allEpisodes();
  String _selectedLevel = 'A1';

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ar ? 'بودكاست آنا ودانيال' : 'Anna & Daniel Podcast',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(
          ar
              ? 'محادثات مستقلة مدتها نحو 5 دقائق. استمع واقرأ النص في نفس الوقت.'
              : 'Independent five-minute conversations. Listen and read together.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          runSpacing: 5,
          children: [
            for (final level in AcademyPodcastRepository.levels)
              ChoiceChip(
                key: ValueKey('podcast-level-' + level),
                label: Text(level),
                selected: _selectedLevel == level,
                onSelected: (_) => setState(() => _selectedLevel = level),
                selectedColor: const Color(0xFFCCE8D8),
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _selectedLevel == level
                        ? const Color(0xFF125F41)
                        : scheme.onSurface),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AcademyPodcastEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(ar ? 'تعذر تحميل قائمة الحلقات.'
                  : 'Could not load episodes.');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final episodes = snapshot.data!
                .where((entry) => entry.level == _selectedLevel)
                .toList(growable: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(
                    ar ? '15 حلقة مخططة للمستوى ' + _selectedLevel
                        : '15 planned episodes in ' + _selectedLevel,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                for (var i = 0; i < episodes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: ValueKey('podcast-episode-' + episodes[i].id),
                        onTap: episodes[i].hasTranscript
                            ? () => Navigator.of(context).push<void>(
                                MaterialPageRoute(builder: (_) =>
                                  PodcastReaderScreen(
                                    entry: episodes[i],
                                    repository: _repository)))
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE1EEE5),
                          child: Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: const TextStyle(
                                color: Color(0xFF176245),
                                fontWeight: FontWeight.w900)),
                        ),
                        title: Text(
                          ar && episodes[i].titleAr != null
                              ? episodes[i].titleAr!
                              : episodes[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          episodes[i].hasTranscript
                              ? (ar ? 'النص جاهز · الصوت قيد التسجيل'
                                  : 'Transcript ready · Audio in production')
                              : (ar ? 'مخططة · لم تُسجل بعد'
                                  : 'Planned · Not yet recorded'),
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                        trailing: Icon(
                          episodes[i].hasTranscript
                              ? Icons.menu_book_rounded
                              : Icons.lock_clock_rounded,
                          color: episodes[i].hasTranscript
                              ? const Color(0xFF176245)
                              : scheme.outline,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
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
        if (mounted) setState(() {});
      });
      await _player.setUrl(loaded.audioUrl!);
      if (mounted) setState(() => _audioLoaded = true);
    } catch (_) {
      if (mounted) setState(() {
        _error = 'تعذر تحميل الحلقة أو ملف الصوت.';
      });
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
    if (!_player.playing) unawaited(_player.play());
  }

  String _clock(Duration time) {
    final sec = time.inSeconds;
    return (sec ~/ 60).toString() + ':' +
        (sec % 60).toString().padLeft(2, '0');
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
    final scheme = Theme.of(context).colorScheme;
    const gold = Color(0xFFF2D68A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF114C36), Color(0xFF267D58)]),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(ar ? 'آنا  ×  دانيال' : 'Anna  ×  Daniel',
            style: const TextStyle(color: gold,
                fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          ar ? 'نص المحادثة مع الصوت' : 'Read along with the voices',
          style: const TextStyle(color: Colors.white),
        ),
        if (!_audioLoaded) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.mic_off_outlined, color: gold),
            const SizedBox(width: 8),
            Expanded(child: Text(
              ar
                  ? 'النص جاهز للقراءة. التسجيل البشري والتوقيت المتزامن لم يُنشرا بعد؛ لن نشغّل صوتًا وهميًا.'
                  : 'Read the script now. The human recording and verified sync cues are not yet published.',
              style: const TextStyle(color: Colors.white, height: 1.4),
            )),
          ]),
        ] else ...[
          const SizedBox(height: 9),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final total = _player.duration ??
                  Duration(milliseconds: episode.durationMs!);
              final ms = total.inMilliseconds > 0
                  ? total.inMilliseconds : 1;
              final position = snapshot.data ?? Duration.zero;
              return Column(children: [
                Slider(
                  value: position.inMilliseconds.clamp(0, ms).toDouble(),
                  max: ms.toDouble(),
                  activeColor: gold,
                  inactiveColor: const Color(0xFFAFD7C0),
                  onChanged: (value) => unawaited(_player.seek(
                    Duration(milliseconds: value.round()))),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_clock(position),
                      style: const TextStyle(color: Colors.white)),
                  Text(_clock(total),
                      style: const TextStyle(color: Colors.white)),
                ]),
              ]);
            },
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              onPressed: () => unawaited(_player.seek(Duration.zero)),
              tooltip: ar ? 'من البداية' : 'Restart',
              icon: const Icon(Icons.replay, color: Colors.white),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              key: const ValueKey('podcast-play-pause'),
              onPressed: _playPause,
              style: IconButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: const Color(0xFF114C36)),
              icon: Icon(_player.playing
                  ? Icons.pause_rounded : Icons.play_arrow_rounded),
              iconSize: 32,
            ),
            const SizedBox(width: 9),
            DropdownButton<double>(
              value: _speed,
              dropdownColor: const Color(0xFF176245),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox.shrink(),
              items: const [0.75, 1.0, 1.25].map((value) =>
                DropdownMenuItem<double>(
                  value: value, child: Text('' + value.toString() + '×'),
                )).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _speed = value);
                unawaited(_player.setSpeed(value));
              },
            ),
          ]),
        ],
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 7),
            child: Text(_error!, style: const TextStyle(
              color: Colors.white70))),
      ]),
    );
  }

  Widget _dialogueLine(PodcastDialogueLine line, int i) {
    final scheme = Theme.of(context).colorScheme;
    final current = _activeIndex == i && _audioLoaded;
    final anna = line.speaker == 'Anna';
    return AnimatedContainer(
      key: _anchors[i],
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: current
            ? const Color(0xFFF2D68A).withValues(alpha: .32)
            : anna
                ? scheme.surfaceContainerHighest
                : scheme.primaryContainer.withValues(alpha: .4),
        border: Border.all(
          color: current
              ? const Color(0xFFC7A14C) : Colors.transparent,
          width: current ? 2 : 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: _audioLoaded ? () => _seekLine(line) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: anna
                    ? const Color(0xFFE3AFC5)
                    : const Color(0xFFB0C7EA),
                child: Icon(anna ? Icons.face_3 : Icons.face,
                    color: const Color(0xFF254937), size: 17),
              ),
              const SizedBox(width: 7),
              Text(line.speaker, style: const TextStyle(
                  color: Color(0xFF198058), fontWeight: FontWeight.w900)),
              const Spacer(),
              if (current) const Icon(Icons.graphic_eq,
                  color: Color(0xFFA98330)),
              if (_audioLoaded && !current) const Icon(
                  Icons.play_arrow_rounded, size: 20),
            ]),
            const SizedBox(height: 8),
            Text(line.text,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: TextStyle(
                height: 1.55,
                fontSize: 17,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                color: scheme.onSurface,
              )),
            if (_showArabic) ...[
              const SizedBox(height: 9),
              Text(line.translationAr,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  height: 1.55,
                  fontSize: 14,
                  color: scheme.onSurfaceVariant)),
            ],
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
                  RadioListTile<int>(
                    dense: true,
                    title: Text(episode.questions[i].options[choice],
                        textDirection: TextDirection.ltr),
                    value: choice,
                    groupValue: _answers[i],
                    onChanged: (value) =>
                        setState(() => _answers[i] = value!),
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
      appBar: AppBar(title: Text(episode == null
          ? widget.entry.title
          : ar ? episode.titleAr : episode.title)),
      body: episode == null
          ? Center(child: _error == null
              ? const CircularProgressIndicator()
              : Text(_error!))
          : ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                _audioPanel(episode),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Text(
                    ar ? 'كتاب المحادثة' : 'Conversation book',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900))),
                  Text(ar ? 'ترجمة عربية' : 'Arabic',
                      style: TextStyle(color: scheme.onSurfaceVariant,
                          fontSize: 12)),
                  Switch(
                    key: const ValueKey('podcast-translation-toggle'),
                    value: _showArabic,
                    onChanged: (value) => setState(() => _showArabic = value),
                  ),
                ]),
                Text(
                  ar
                      ? 'تضيء الجملة عند سماعها، ويمكن الضغط عليها لإعادتها.'
                      : 'The spoken line highlights automatically; tap it to replay.',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12),
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
                    Chip(label: Text(word.word + ' · ' + word.meaningAr)),
                ]),
                _quiz(episode),
              ],
            ),
    );
  }
}
