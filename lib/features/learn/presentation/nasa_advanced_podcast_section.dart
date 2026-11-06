import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

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

  factory NasaBilingualParagraph.fromJson(Map<String, dynamic> data) =>
      NasaBilingualParagraph(
        english: data['text'] as String,
        arabic: data['translation_ar'] as String,
      );
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
                  ar
                      ? '${selected[i].durationSeconds ~/ 60} دقيقة · صوت أصلي'
                      : '${selected[i].durationSeconds ~/ 60} min · original audio',
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
  bool _showArabic = true;

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
    setState(() {
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
                    Text(ar ? 'النص الإنجليزي والترجمة العربية'
                        : 'English transcript + Arabic translation',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(ar
                        ? 'نص NASA الأصلي مع ترجمة عربية آلية تحتاج مراجعة. لم نعتمد توقيتًا للجمل بعد.'
                        : 'Original NASA text with machine-draft Arabic translation. No sentence alignment is claimed.',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                    Row(children: [
                      Switch(
                        value: _showArabic,
                        onChanged: (n) => setState(() => _showArabic = n)),
                      Text(ar ? 'إظهار العربية' : 'Show Arabic'),
                    ]),
                    SizedBox(height: 440, child: ListView.builder(
                      key: const ValueKey('nasa-bilingual-reader'),
                      itemCount: transcript.paragraphs.length,
                      itemBuilder: (context, index) {
                        final line = transcript.paragraphs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(line.english,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(height: 1.5)),
                              if (_showArabic) ...[
                                const SizedBox(height: 3),
                                SelectableText(line.arabic,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                      height: 1.5,
                                      color: scheme.onSurfaceVariant)),
                              ],
                              const Divider(),
                            ],
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
        OutlinedButton.icon(
          key: const ValueKey('nasa-source-page'),
          onPressed: () => launchUrl(Uri.parse(episode.sourceUrl),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new),
          label: Text(ar
              ? 'صفحة NASA الأصلية والنص الإنجليزي الكامل'
              : 'Original NASA page and full English transcript'),
        ),
        Text(
          ar ? 'المصدر: NASA. التطبيق غير تابع لناسا ولا تمثله.'
              : 'Source: NASA. WorldVoice is not affiliated with NASA.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        ),
      ]),
    );
  }
}
