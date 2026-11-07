import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'podcast_sentence_translation.dart';

const nasaAdvancedLevels = ['B2', 'C1', 'C2'];

/// Source-verified original audio from the official NASA podcast RSS.
/// These are WorldVoice editorial level candidates, not NASA CEFR ratings.
class NasaLongEpisode {
  const NasaLongEpisode({
    required this.id,
    required this.level,
    required this.order,
    required this.title,
    required this.audioUrl,
    required this.sourceUrl,
    required this.durationSeconds,
  });
  final String id;
  final String level;
  final int order;
  final String title;
  final String audioUrl;
  final String sourceUrl;
  final int durationSeconds;

  factory NasaLongEpisode.fromJson(Map<String, dynamic> json) =>
      NasaLongEpisode(
        id: json['id'] as String,
        level: json['level'] as String,
        order: json['order'] as int,
        title: json['title'] as String,
        audioUrl: json['audio_url'] as String,
        sourceUrl: json['source_url'] as String,
        durationSeconds: json['duration_seconds'] as int,
      );

  bool get isOfficialSource {
    final source = Uri.tryParse(sourceUrl);
    final audio = Uri.tryParse(audioUrl);
    return nasaAdvancedLevels.contains(level) &&
        id == 'en-${level.toLowerCase()}-nasa-${order.toString().padLeft(3,'0')}' &&
        order >= 1 && order <= 30 &&
        durationSeconds >= 600 &&
        source?.scheme == 'https' &&
        (source?.host == 'nasa.gov' || source?.host == 'www.nasa.gov') &&
        (source?.path.startsWith('/podcasts/houston-we-have-a-podcast/') ??
            false) &&
        audio?.scheme == 'https' &&
        audio?.host == 'traffic.megaphone.fm' &&
        (audio?.path.startsWith(
            '/NATIONALAERONAUTICSANDSPACEADMINISTRATION') ?? false) &&
        (audio?.path.endsWith('.mp3') ?? false);
  }
}

class NasaLongCatalog {
  const NasaLongCatalog();

  Future<List<NasaLongEpisode>> load() async {
    final raw = await rootBundle.loadString(
        'assets/podcasts/nasa_advanced_long_form.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['schema'] != 1 ||
        decoded['language'] != 'en' ||
        decoded['episode_count'] != 90 ||
        decoded['episodes_per_level'] != 30) {
      throw const FormatException('Unexpected NASA original catalog');
    }
    final entries = (decoded['episodes'] as List<dynamic>)
        .map((value) =>
            NasaLongEpisode.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
    if (entries.length != 90 ||
        entries.map((e) => e.audioUrl).toSet().length != 90 ||
        entries.map((e) => e.sourceUrl).toSet().length != 90 ||
        entries.any((e) => !e.isOfficialSource)) {
      throw const FormatException('Unapproved advanced NASA recordings');
    }
    for (final level in nasaAdvancedLevels) {
      final records = entries.where((e) => e.level == level).toList();
      if (records.length != 30) {
        throw FormatException('Need 30 originals at $level');
      }
      for (var i = 0; i < records.length; i++) {
        if (records[i].order != i + 1) {
          throw FormatException('Wrong $level episode order');
        }
      }
    }
    return entries;
  }
}

/// A paragraph from NASA's official transcript, translated to Arabic as
/// a machine draft. No fake sentence timestamps are created here.
class NasaBilingualParagraph {
  const NasaBilingualParagraph({
    required this.english,
    required this.arabic,
  });

  final String english;
  final String arabic;

  factory NasaBilingualParagraph.fromJson(Map<String, dynamic> data) {
    // Paragraph-level timings must come from an independently reviewed
    // alignment. Never silently treat an unverified machine estimate as a
    // timed subtitle cue.
    if (data.containsKey('start_ms') || data.containsKey('end_ms')) {
      throw const FormatException('Unverified NASA paragraph timestamps');
    }
    return NasaBilingualParagraph(
      english: data['text'] as String,
      arabic: data['translation_ar'] as String,
    );
  }
}

class NasaBilingualTranscript {
  const NasaBilingualTranscript({
    required this.id,
    required this.audioUrl,
    required this.paragraphs,
  });

  final String id;
  final String audioUrl;
  final List<NasaBilingualParagraph> paragraphs;

  factory NasaBilingualTranscript.fromJson(Map<String, dynamic> json) {
    if (json['content_source'] != 'NASA_official_podcast_transcript' ||
        json['translation_status'] != 'machine_draft_review_required' ||
        json['sync_status'] != 'unverified' ||
        json['approved_for_publication'] != false) {
      throw const FormatException('Transcript provenance not verified');
    }
    final lines = (json['dialogue'] as List<dynamic>)
        .map((line) => NasaBilingualParagraph.fromJson(
            line as Map<String, dynamic>))
        .toList(growable: false);
    if (lines.length < 10 ||
        lines.any((line) =>
            line.english.trim().isEmpty || line.arabic.trim().isEmpty)) {
      throw const FormatException('Missing English / Arabic NASA text');
    }
    return NasaBilingualTranscript(
      id: json['id'] as String,
      audioUrl: json['audio_url'] as String,
      paragraphs: lines,
    );
  }
}

class NasaTranscriptRepository {
  const NasaTranscriptRepository();

  // One large bilingual document per CEFR level. Keep a shared in-memory
  // Future so changing episodes does not decode another 30 long transcripts.
  static final Map<String, Future<Map<String, dynamic>?>> _levelCache = {};
  static final Map<String, Future<Set<String>>> _readinessCache = {};

  /// Availability is backed by the actual 30-episode bilingual asset,
  /// never a guess based on the presence of the original audio.
  Future<Set<String>> availableIds(String level) =>
      _readinessCache.putIfAbsent(level, () async {
        final doc = await _levelCache.putIfAbsent(
            level, () => _loadLevel(level));
        if (doc == null) return <String>{};
        return (doc['episodes'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .where((row) =>
                row['level'] == level &&
                row['translation_status'] ==
                    'machine_draft_review_required' &&
                row['content_source'] ==
                    'NASA_official_podcast_transcript' &&
                row['approved_for_publication'] == false &&
                (row['dialogue'] as List<dynamic>?)?.isNotEmpty == true)
            .map((row) => row['id'] as String)
            .toSet();
      });

  static Future<Map<String, dynamic>?> _loadLevel(String level) async {
    final path =
        'assets/podcasts/nasa_${level.toLowerCase()}_translations.json';
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } on FlutterError {
      // Streaming original NASA audio works without downloaded captions.
      return null;
    }
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    if (doc['schema'] != 1 || doc['level'] != level ||
        doc['language'] != 'en' || doc['episode_count'] != 30 ||
        (doc['episodes'] as List<dynamic>).length != 30) {
      throw const FormatException('Unexpected NASA translation catalog');
    }
    return doc;
  }

  Future<NasaBilingualTranscript?> loadFor(NasaLongEpisode episode) async {
    if (!episode.isOfficialSource) return null;
    final doc = await _levelCache.putIfAbsent(
      episode.level, () => _loadLevel(episode.level));
    if (doc == null) return null;
    for (final value in doc['episodes'] as List<dynamic>) {
      final json = value as Map<String, dynamic>;
      if (json['id'] == episode.id) {
        if (json['audio_url'] != episode.audioUrl ||
            json['source_url'] != episode.sourceUrl) {
          throw const FormatException('NASA audio and transcript mismatch');
        }
        return NasaBilingualTranscript.fromJson(json);
      }
    }
    return null;
  }
}

class NasaLongPodcastSection extends StatefulWidget {
  const NasaLongPodcastSection({
    super.key,
    required this.level,
    this.initialEpisodes,
  });

  final String level;
  final List<NasaLongEpisode>? initialEpisodes;

  @override
  State<NasaLongPodcastSection> createState() =>
      _NasaLongPodcastSectionState();
}

class _NasaLongPodcastSectionState extends State<NasaLongPodcastSection> {
  late final Future<List<NasaLongEpisode>> _episodes =
      widget.initialEpisodes == null
          ? const NasaLongCatalog().load()
          : SynchronousFuture<List<NasaLongEpisode>>(
              widget.initialEpisodes!);

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<NasaLongEpisode>>(
      future: _episodes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(ar
              ? 'تعذر تحميل تسجيلات NASA الأصلية.'
              : 'Could not load original NASA recordings.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final selected = snapshot.data!
            .where((e) => e.level == widget.level)
            .toList(growable: false);
        return FutureBuilder<Set<String>>(
          future: const NasaTranscriptRepository()
              .availableIds(widget.level),
          builder: (context, captions) {
            final available = captions.data ?? <String>{};
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            ar ? 'بودكاست الإنجليزية — ${widget.level} · 30 حلقة طويلة'
                : 'English ${widget.level} · 30 long originals',
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            ar
                ? 'تسجيلات NASA الأصلية بأصوات بشرية ومقابلات واقعية. مستويات WorldVoice مقترحة وتحتاج مراجعة تربوية. نعرض النصوص والترجمة عند اكتمال استيرادها؛ لا نختلق توقيت الجمل.'
                : 'Real NASA interviews. Level labels are provisional WorldVoice editorial ratings. We show bilingual text only after importing and validating the original transcripts; sentence timing is not invented.',
            style: TextStyle(
                color: scheme.onSurfaceVariant, height: 1.5, fontSize: 12)),
          const SizedBox(height: 10),
          for (var i = 0; i < selected.length; i++)
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              margin: const EdgeInsets.only(bottom: 7),
              child: ListTile(
                key: ValueKey('nasa-${widget.level}-${i + 1}'),
                leading: const Icon(Icons.headphones_rounded,
                    color: Color(0xFF20845C), size: 27),
                title: Text(selected[i].title,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: Text(
                  available.contains(selected[i].id)
                      ? (ar
                          ? '${selected[i].durationSeconds ~/ 60} دقيقة · صوت أصلي · نص وترجمة عربية آليان'
                          : '${selected[i].durationSeconds ~/ 60} min · original audio · English/Arabic machine drafts')
                      : (ar
                          ? '${selected[i].durationSeconds ~/ 60} دقيقة · صوت أصلي · النص قيد الإعداد'
                          : '${selected[i].durationSeconds ~/ 60} min · original audio · text pending'),
                  style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFF20845C)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NasaLongPodcastPlayer(
                      episodes: selected,
                      initialIndex: i,
                    ),
                  ),
                ),
              ),
            ),
        ]);
          },
        );
      },
    );
  }
}

String nasaPlaybackTime(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class NasaLongPodcastPlayer extends StatefulWidget {
  const NasaLongPodcastPlayer({
    super.key,
    required this.episodes,
    this.initialIndex = 0,
  });

  final List<NasaLongEpisode> episodes;
  final int initialIndex;

  @override
  State<NasaLongPodcastPlayer> createState() => _NasaLongPodcastPlayerState();
}

class _NasaLongPodcastPlayerState extends State<NasaLongPodcastPlayer> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positions;
  StreamSubscription<PlayerState>? _states;
  int _index = 0;
  int _generation = 0;
  bool _switching = false;
  bool _loading = false;
  bool _playing = false;
  bool _autoNext = true;
  bool _completed = false;
  String? _error;
  double _speed = 1;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late Future<NasaBilingualTranscript?> _transcript;
  int _readingParagraph = 0;
  double _readerFontSize = 15;
  final ScrollController _readerScroll = ScrollController();
  final Map<int, GlobalKey> _paragraphKeys = {};

  // NASA source transcripts have no verified timestamps. Navigation below
  // follows the reader's explicit selection, never a guessed audio offset.
  void _selectParagraph(int index, int count) {
    if (index < 0 || index >= count) return;
    setState(() => _readingParagraph = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_readerScroll.hasClients) return;
      void reveal() {
        final context = _paragraphKeys[index]?.currentContext;
        if (mounted && context != null) {
          Scrollable.ensureVisible(context,
              alignment: 0.15,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut);
        }
      }
      if (_paragraphKeys[index]?.currentContext != null) {
        reveal();
      } else {
        final maxScroll = _readerScroll.position.maxScrollExtent;
        final fraction = count > 1 ? index / (count - 1) : 0.0;
        _readerScroll.jumpTo((maxScroll * fraction).clamp(0.0, maxScroll));
        WidgetsBinding.instance.addPostFrameCallback((_) => reveal());
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _transcript =
        const NasaTranscriptRepository().loadFor(widget.episodes[_index]);
    _positions = _player.positionStream.listen((duration) {
      if (mounted && !_loading) setState(() => _position = duration);
    });
    _states = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final current = state.playing &&
          state.processingState != ProcessingState.completed;
      if (current != _playing) setState(() => _playing = current);
      if (state.processingState == ProcessingState.completed &&
          !_switching && !_loading && !_completed) {
        if (_autoNext && _index + 1 < widget.episodes.length) {
          unawaited(_open(_index + 1));
        } else {
          setState(() => _completed = true);
        }
      }
    });
    unawaited(_open(_index));
  }

  Future<void> _open(int index) async {
    if (!mounted || _switching || index < 0 ||
        index >= widget.episodes.length) {
      return;
    }
    _switching = true;
    final generation = ++_generation;
    final episode = widget.episodes[index];
    _transcript = const NasaTranscriptRepository().loadFor(episode);
    _paragraphKeys.clear();
    if (_readerScroll.hasClients) _readerScroll.jumpTo(0);
    setState(() {
      _readingParagraph = 0;
      _index = index;
      _position = Duration.zero;
      _duration = Duration(seconds: episode.durationSeconds);
      _loading = true;
      _error = null;
      _playing = false;
      _completed = false;
    });
    try {
      if (!episode.isOfficialSource) {
        throw const FormatException('Untrusted NASA podcast source');
      }
      await _player.stop();
      final measured = await _player.setUrl(episode.audioUrl)
          .timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) return;
      await _player.setSpeed(_speed);
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        if (measured != null && measured > Duration.zero) {
          _duration = measured;
        }
      });
      unawaited(_player.play());
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = 'Unable to stream original NASA audio';
        });
      }
    } finally {
      _switching = false;
    }
  }

  void _playPause() {
    if (_loading || _error != null) return;
    if (_completed) {
      unawaited(_open(_index));
    } else if (_player.playing) {
      unawaited(_player.pause());
    } else {
      unawaited(_player.play());
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_positions?.cancel() ?? Future<void>.value());
    unawaited(_states?.cancel() ?? Future<void>.value());
    unawaited(_player.dispose());
    _readerScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final episode = widget.episodes[_index];
    final max = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble() : 1.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('${episode.level} · ${_index + 1}/${widget.episodes.length}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF133B2E), Color(0xFF207C58)]),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NASA · HOUSTON WE HAVE A PODCAST',
              style: TextStyle(color: Color(0xFFF1DB9E),
                  fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 10),
            Text(episode.title,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(ar ? 'تسجيل صوت بشري أصلي'
                : 'Original human voice recording',
              style: const TextStyle(color: Colors.white70)),
            if (_loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(ar ? 'تعذر تحميل الصوت الأصلي، تحقق من الإنترنت.'
                  : 'Original audio failed. Check your connection.',
                style: const TextStyle(color: Color(0xFFFFD69B))),
              TextButton.icon(
                onPressed: () => unawaited(_open(_index)),
                icon: const Icon(Icons.refresh),
                label: Text(ar ? 'إعادة المحاولة' : 'Retry')),
            ],
            Row(children: [
              IconButton(
                onPressed: _loading || _index == 0
                    ? null : () => unawaited(_open(_index - 1)),
                icon: const Icon(Icons.skip_previous),
                color: Colors.white),
              IconButton(
                key: const ValueKey('nasa-long-play'),
                onPressed: _loading || _error != null ? null : _playPause,
                icon: Icon(_playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill, size: 39),
                color: const Color(0xFFF1DB9E)),
              IconButton(
                onPressed: _loading || _index + 1 == widget.episodes.length
                    ? null : () => unawaited(_open(_index + 1)),
                icon: const Icon(Icons.skip_next),
                color: Colors.white),
              const Spacer(),
              Text(
                '${nasaPlaybackTime(_position)} / ${nasaPlaybackTime(_duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            ]),
            Slider(
              value: _position.inMilliseconds.toDouble().clamp(0, max),
              max: max,
              onChanged: _loading || _error != null ? null : (n) {
                unawaited(_player.seek(Duration(milliseconds: n.toInt())));
              },
            ),
            Row(children: [
              Expanded(child: Text(
                  ar ? 'تشغيل الحلقة التالية تلقائيًا' : 'Auto-play next',
                  style: const TextStyle(color: Colors.white))),
              Switch(
                value: _autoNext,
                onChanged: (value) => setState(() => _autoNext = value)),
            ]),
            Wrap(spacing: 6, children: [
              for (final speed in [0.85, 1.0, 1.15])
                ChoiceChip(
                  label: Text('×$speed'),
                  selected: _speed == speed,
                  onSelected: (_) {
                    setState(() => _speed = speed);
                    unawaited(_player.setSpeed(speed));
                  }),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Card(
          color: scheme.surfaceContainerLow,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: FutureBuilder<NasaBilingualTranscript?>(
              key: ValueKey('nasa-text-${episode.id}'),
              future: _transcript,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(ar
                      ? 'حدث خطأ في مطابقة النص والصوت. لن نعرض نصًا غير مطابق.'
                      : 'Original source/caption mismatch; no unverified text will be displayed.');
                }
                final transcript = snapshot.data;
                if (transcript == null) {
                  return Text(ar
                      ? 'النص الإنجليزي والترجمة العربية قيد الاستيراد من مصدر NASA الأصلي. افتح صفحة المصدر لقراءة النص الآن.'
                      : 'English and Arabic captions are being imported from the original NASA source. Open the official episode for its full English transcript.',
                    style: TextStyle(
                        height: 1.5, color: scheme.onSurfaceVariant));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ar ? 'النص الإنجليزي · ترجمة كل جملة عند الضغط'
                        : 'English transcript · tap to translate a sentence',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(ar
                        ? 'الترجمة اختيارية لكل جملة إلى لغتك الأم. توقيت الفقرات غير معتمد والتنقل يدوي.'
                        : 'Translate individual sentences into your native language on demand. Paragraph timing is not verified.',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                    Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: ar ? 'تصغير الخط' : 'Smaller text',
                          onPressed: _readerFontSize <= 13 ? null : () =>
                              setState(() => _readerFontSize -= 1),
                          icon: const Icon(Icons.text_decrease_rounded)),
                        IconButton(
                          tooltip: ar ? 'تكبير الخط' : 'Larger text',
                          onPressed: _readerFontSize >= 21 ? null : () =>
                              setState(() => _readerFontSize += 1),
                          icon: const Icon(Icons.text_increase_rounded)),
                      ]),
                    Row(children: [
                      IconButton(
                        key: const ValueKey('nasa-paragraph-previous'),
                        tooltip: ar ? 'الفقرة السابقة' : 'Previous paragraph',
                        onPressed: _readingParagraph == 0 ? null : () =>
                            _selectParagraph(_readingParagraph - 1,
                                transcript.paragraphs.length),
                        icon: const Icon(Icons.chevron_left_rounded)),
                      Expanded(child: Text(
                        ar ? 'موضع القراءة اليدوي: ${_readingParagraph + 1} / ${transcript.paragraphs.length}'
                            : 'Manual reading position: ${_readingParagraph + 1} / ${transcript.paragraphs.length}',
                        key: const ValueKey('nasa-manual-reading-position'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12))),
                      IconButton(
                        key: const ValueKey('nasa-paragraph-next'),
                        tooltip: ar ? 'الفقرة التالية' : 'Next paragraph',
                        onPressed: _readingParagraph + 1 >= transcript.paragraphs.length
                            ? null : () => _selectParagraph(_readingParagraph + 1,
                                transcript.paragraphs.length),
                        icon: const Icon(Icons.chevron_right_rounded)),
                    ]),
                    SizedBox(height: 440, child: ListView.builder(
                      key: const ValueKey('nasa-bilingual-reader'),
                      controller: _readerScroll,
                      itemCount: transcript.paragraphs.length,
                      itemBuilder: (context, index) {
                        final line = transcript.paragraphs[index];
                        final selected = _readingParagraph == index;
                        return Padding(
                          key: _paragraphKeys.putIfAbsent(index, () => GlobalKey()),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            key: ValueKey('nasa-paragraph-$index'),
                            onTap: () => _selectParagraph(index,
                                transcript.paragraphs.length),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final sentence in line.english
                                    .split(RegExp(r'(?<=[.!?])\s+'))
                                    .where((value) => value.trim().isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SelectableText(sentence.trim(),
                                          textDirection: TextDirection.ltr,
                                          style: TextStyle(
                                            fontSize: _readerFontSize,
                                            height: 1.55)),
                                        PodcastSentenceTranslation(
                                          key: ValueKey('nasa-translate-$index-${sentence.hashCode}'),
                                          text: sentence.trim(),
                                        ),
                                      ],
                                    ),
                                  ),
                                Divider(thickness: selected ? 2 : 1,
                                    color: selected ? scheme.primary
                                        : scheme.outlineVariant),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        PodcastSourceInfo(source: 'NASA', url: episode.sourceUrl),
      ]),
    );
  }
}
