import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'b1_voa_transcript_section.dart';

/// Curated real VOA broadcasts. None of these episodes has an approved
/// full-length bilingual transcript or sentence cue file yet.
class B1VoaLongEpisode {
  const B1VoaLongEpisode({
    required this.id,
    required this.order,
    required this.title,
    required this.titleAr,
    required this.publishedDate,
    required this.audioUrl,
    required this.sourceUrl,
    required this.approximateDurationMinutes,
    required this.transcriptStatus,
    required this.translationStatus,
  });

  final String id;
  final int order;
  final String title;
  final String titleAr;
  final String publishedDate;
  final String audioUrl;
  final String sourceUrl;
  final int approximateDurationMinutes;
  final String transcriptStatus;
  final String translationStatus;

  factory B1VoaLongEpisode.fromJson(Map<String, dynamic> data) {
    return B1VoaLongEpisode(
      id: data['id'] as String,
      order: data['order'] as int,
      title: data['title'] as String,
      titleAr: data['title_ar'] as String,
      publishedDate: data['published_date'] as String,
      audioUrl: data['audio_url'] as String,
      sourceUrl: data['source_url'] as String,
      approximateDurationMinutes: data['approximate_duration_minutes'] as int,
      transcriptStatus: data['transcript_status'] as String,
      translationStatus: data['translation_status'] as String,
    );
  }

  bool get isVerifiedVoaSource {
    final source = Uri.tryParse(sourceUrl);
    final audio = Uri.tryParse(audioUrl);
    final date = DateTime.tryParse(publishedDate);
    if (date == null || date.year != 2025 || date.month != 3 ||
        date.day < 2 || date.day > 31) {
      return false;
    }
    final day = date.day.toString().padLeft(2, '0');
    final expectedAudioPath =
        '/vle/2025/03/$day/202503$day-003003-vle122-program.mp3';
    return source != null &&
        source.scheme == 'https' &&
        source.host == 'learningenglish.voanews.com' &&
        RegExp(r'^/a/[0-9]+[.]html$').hasMatch(source.path) &&
        audio != null &&
        audio.scheme == 'https' &&
        audio.host == 'voa-audio.voanews.eu' &&
        audio.path == expectedAudioPath &&
        approximateDurationMinutes >= 10 &&
        transcriptStatus == 'pending_full_audio_transcription_review' &&
        translationStatus == 'pending_english_transcript';
  }
}

class B1VoaLongCatalog {
  const B1VoaLongCatalog();

  Future<List<B1VoaLongEpisode>> load() async {
    final raw = await rootBundle.loadString(
        'assets/podcasts/voa_english_b1_long_form.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['schema'] != 1 || json['language'] != 'en' ||
        json['level'] != 'B1' || json['episode_count'] != 30) {
      throw const FormatException('Invalid B1 VOA catalog');
    }
    final episodes = (json['episodes'] as List<dynamic>)
        .map((record) => B1VoaLongEpisode.fromJson(
            record as Map<String, dynamic>))
        .toList(growable: false);
    if (episodes.length != 30 ||
        episodes.map((e) => e.id).toSet().length != 30 ||
        episodes.map((e) => e.audioUrl).toSet().length != 30 ||
        episodes.map((e) => e.sourceUrl).toSet().length != 30) {
      throw const FormatException('Duplicate or missing B1 recordings');
    }
    for (var i = 0; i < episodes.length; i++) {
      final entry = episodes[i];
      if (entry.order != i + 1 ||
          entry.id != 'en-b1-voa-${(i + 1).toString().padLeft(3, '0')}' ||
          !entry.isVerifiedVoaSource) {
        throw FormatException('Invalid B1 recording ${i + 1}');
      }
    }
    return episodes;
  }
}

/// Presented only in B1. A1/A2 player and curriculum assets stay untouched.
class B1VoaLongSection extends StatefulWidget {
  const B1VoaLongSection({super.key, this.initialEpisodes});
  final List<B1VoaLongEpisode>? initialEpisodes;

  @override
  State<B1VoaLongSection> createState() => _B1VoaLongSectionState();
}

class _B1VoaLongSectionState extends State<B1VoaLongSection> {
  late final Future<List<B1VoaLongEpisode>> _episodes =
      widget.initialEpisodes == null
          ? const B1VoaLongCatalog().load()
          : SynchronousFuture<List<B1VoaLongEpisode>>(
              widget.initialEpisodes!);

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<B1VoaLongEpisode>>(
      future: _episodes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(ar
              ? 'تعذر تحميل الحلقات الطويلة لـB1.'
              : 'Could not load original B1 podcasts.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final episodes = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar ? 'بودكاست الإنجليزية — B1 · 30 حلقة طويلة'
                  : 'English B1 · 30 long podcasts',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              ar
                  ? 'تسجيلات VOA الأصلية بمدة تقارب 30 دقيقة لكل حلقة، حوالي 15 ساعة استماع. النص الإنجليزي الكامل والترجمة العربية وتوقيت الجمل قيد المراجعة ولم نعتمدها بعد.'
                  : 'Real VOA recordings, roughly 30 minutes each, about 15 hours total. Full English transcripts, Arabic translation and synchronized line cues are pending review.',
              style: TextStyle(fontSize: 12, height: 1.5,
                  color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            for (final episode in episodes)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                color: scheme.surfaceContainerLow,
                child: ListTile(
                  key: ValueKey('b1-voa-long-${episode.order}'),
                  leading: const Icon(Icons.headphones_rounded,
                      color: Color(0xFF20845C), size: 28),
                  title: Text(
                    ar ? 'الحلقة ${episode.order} · ${episode.publishedDate}'
                        : 'Episode ${episode.order} · ${episode.publishedDate}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    ar ? '≈30 دقيقة · صوت أصلي · الترجمة قيد الإعداد'
                        : '~30 min · original audio · translation pending',
                    style: TextStyle(color: scheme.onSurfaceVariant,
                        fontSize: 12),
                  ),
                  trailing: const Icon(Icons.play_circle_fill_rounded,
                      color: Color(0xFF20845C)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => B1VoaLongPlayer(
                        episodes: episodes,
                        startIndex: episode.order - 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String b1VoaTime(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class B1VoaLongPlayer extends StatefulWidget {
  const B1VoaLongPlayer({
    super.key,
    required this.episodes,
    this.startIndex = 0,
  });

  final List<B1VoaLongEpisode> episodes;
  final int startIndex;

  @override
  State<B1VoaLongPlayer> createState() => _B1VoaLongPlayerState();
}

class _B1VoaLongPlayerState extends State<B1VoaLongPlayer> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  int _index = 0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 30);
  bool _loading = true;
  bool _changing = false;
  bool _autoplayNext = true;
  bool _playing = false;
  bool _finished = false;
  String? _error;
  double _speed = 1;
  int _token = 0;
  late Future<B1VoaTranscript?> _captions;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _captions = const B1VoaTranscriptRepository().loadFor(
      episodeId: widget.episodes[_index].id,
      audioUrl: widget.episodes[_index].audioUrl,
    );
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final nowPlaying = state.playing &&
          state.processingState != ProcessingState.completed;
      if (nowPlaying != _playing) {
        setState(() => _playing = nowPlaying);
      }
      if (state.processingState == ProcessingState.completed &&
          !_changing && !_loading && !_finished) {
        if (_autoplayNext && _index + 1 < widget.episodes.length) {
          unawaited(_load(_index + 1));
        } else {
          setState(() => _finished = true);
        }
      }
    });
    _positionSubscription = _player.positionStream.listen((value) {
      if (mounted && !_loading) {
        setState(() => _position = value);
      }
    });
    unawaited(_load(_index));
  }

  Future<void> _load(int next) async {
    if (!mounted || _changing ||
        next < 0 || next >= widget.episodes.length) {
      return;
    }
    _changing = true;
    final token = ++_token;
    final episode = widget.episodes[next];
    _captions = const B1VoaTranscriptRepository().loadFor(
      episodeId: episode.id,
      audioUrl: episode.audioUrl,
    );
    setState(() {
      _index = next;
      _loading = true;
      _finished = false;
      _error = null;
      _playing = false;
      _position = Duration.zero;
      _duration = Duration(minutes: episode.approximateDurationMinutes);
    });
    try {
      if (!episode.isVerifiedVoaSource) {
        throw const FormatException('Unapproved VOA audio URL');
      }
      await _player.stop();
      final measuredDuration = await _player.setUrl(episode.audioUrl)
          .timeout(const Duration(seconds: 30));
      if (!mounted || token != _token) return;
      await _player.setSpeed(_speed);
      if (!mounted || token != _token) return;
      setState(() {
        _loading = false;
        if (measuredDuration != null && measuredDuration > Duration.zero) {
          _duration = measuredDuration;
        }
      });
      unawaited(_player.play());
    } catch (_) {
      if (mounted && token == _token) {
        setState(() {
          _loading = false;
          _error = 'Unable to load the original VOA MP3';
        });
      }
    } finally {
      _changing = false;
    }
  }

  void _toggle() {
    if (_loading || _error != null) return;
    if (_finished) {
      unawaited(_load(_index));
    } else if (_player.playing) {
      unawaited(_player.pause());
    } else {
      unawaited(_player.play());
    }
  }

  @override
  void dispose() {
    _token++;
    unawaited(_stateSubscription?.cancel() ?? Future<void>.value());
    unawaited(_positionSubscription?.cancel() ?? Future<void>.value());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final episode = widget.episodes[_index];
    final maximum = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble() : 1.0;
    final current = _position.inMilliseconds.toDouble().clamp(0.0, maximum);

    return Scaffold(
      appBar: AppBar(title: Text(ar
          ? 'بودكاست B1 · الحلقة ${episode.order}'
          : 'B1 Podcast · Episode ${episode.order}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF143D30), Color(0xFF207757),
              ]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Row(children: [
                Icon(Icons.headphones_rounded, color: Color(0xFFF3D78F)),
                SizedBox(width: 8),
                Expanded(child: Text('VOA LEARNING ENGLISH · B1',
                  style: TextStyle(color: Color(0xFFF3D78F),
                      fontWeight: FontWeight.w900))),
              ]),
              const SizedBox(height: 14),
              Text(episode.title, textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(ar ? 'الصوت البشري الأصلي · حوالي 30 دقيقة'
                  : 'Original human recording · about 30 minutes',
                style: const TextStyle(color: Color(0xFFD5EEE0))),
              if (_loading) ...[
                const SizedBox(height: 15),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(ar
                    ? 'تعذر تحميل تسجيل VOA. تحقق من اتصال الإنترنت وأعد المحاولة، ولن نستبدل الصوت بآخر.'
                    : 'Could not load this VOA original. Check your connection and retry; no substitute audio will be used.',
                    style: const TextStyle(color: Color(0xFFFFD6A2))),
                TextButton.icon(
                  key: const ValueKey('b1-voa-long-retry'),
                  onPressed: () => unawaited(_load(_index)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                IconButton(
                  key: const ValueKey('b1-voa-long-previous'),
                  onPressed: _loading || _index == 0
                      ? null : () => unawaited(_load(_index - 1)),
                  color: Colors.white,
                  icon: const Icon(Icons.skip_previous_rounded)),
                IconButton(
                  key: const ValueKey('b1-voa-long-play'),
                  onPressed: _loading || _error != null ? null : _toggle,
                  color: const Color(0xFFF3D78F),
                  icon: Icon(_playing ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded, size: 38)),
                IconButton(
                  key: const ValueKey('b1-voa-long-next'),
                  onPressed: _loading || _index == widget.episodes.length - 1
                      ? null : () => unawaited(_load(_index + 1)),
                  color: Colors.white,
                  icon: const Icon(Icons.skip_next_rounded)),
                const Spacer(),
                Text('${b1VoaTime(_position)} / ${b1VoaTime(_duration)}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              Slider(
                key: const ValueKey('b1-voa-long-seek'),
                value: current,
                max: maximum,
                onChanged: _loading || _error != null ? null : (value) {
                  unawaited(_player.seek(Duration(
                      milliseconds: value.round())));
                },
              ),
              Row(children: [
                Expanded(child: Text(ar
                    ? 'انتقال تلقائي للحلقة التالية'
                    : 'Auto-play next recording',
                  style: const TextStyle(color: Colors.white))),
                Switch(
                  key: const ValueKey('b1-voa-long-autoplay'),
                  value: _autoplayNext,
                  onChanged: (value) {
                    setState(() => _autoplayNext = value);
                  },
                ),
              ]),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(ar ? 'سرعة الاستماع' : 'Playback speed',
                    style: const TextStyle(color: Colors.white)),
                  for (final speed in [0.85, 1.0, 1.15])
                    ChoiceChip(
                      key: ValueKey('b1-voa-long-speed-$speed'),
                      label: Text('×$speed'),
                      selected: _speed == speed,
                      onSelected: (_) {
                        setState(() => _speed = speed);
                        unawaited(_player.setSpeed(speed));
                      },
                    ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 17),
          if (_finished)
            Text(ar ? 'انتهى التسجيل.' : 'Recording finished.',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Card(
            color: scheme.surfaceContainerLow,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FutureBuilder<B1VoaTranscript?>(
                  future: _captions,
                  builder: (context, snapshot) {
                    final captions = snapshot.data;
                    if (captions != null &&
                        captions.id == episode.id &&
                        captions.audioUrl == episode.audioUrl) {
                      return B1VoaCaptionPanel(
                        key: ValueKey('b1-captions-${episode.id}'),
                        transcript: captions,
                        position: _position,
                        onSeek: (position) =>
                            unawaited(_player.seek(position)),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ar ? 'النص الإنجليزي والترجمة العربية'
                            : 'English transcript and Arabic translation',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(ar
                            ? 'النص الكامل والترجمة غير متاحين لهذه الحلقة بعد. نستمع فقط للصوت الأصلي حتى تكتمل المراجعة، دون عرض كلمات غير مطابقة.'
                            : 'Full English and Arabic captions are not yet available for this episode. Original audio continues; no fabricated transcript is shown.',
                          style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.5)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('b1-voa-long-source'),
                  onPressed: () async {
                    await launchUrl(Uri.parse(episode.sourceUrl),
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(ar
                      ? 'فتح تسجيل VOA والمصدر الأصلي'
                      : 'Open original VOA episode'),
                ),
                const SizedBox(height: 7),
                Text('VOA Learning English · learningenglish.voanews.com',
                  style: TextStyle(fontSize: 11,
                      color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
