import 'dart:async';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/academy_podcast_repository.dart';
import 'voa_originals_section.dart';

/// Five original VOA A2 episodes played in sequence, with no duplicated audio.
class A2LongListeningSession {
  const A2LongListeningSession(this.number, this.lessons);
  final int number;
  final List<VoaOriginalLesson> lessons;
  int get durationSec =>
      lessons.fold<int>(0, (total, e) => total + e.durationSec);
}

String a2LongTime(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

List<A2LongListeningSession> buildA2LongSessions(
    List<VoaOriginalLesson> input) {
  if (input.length != 30) {
    throw const FormatException('Exactly 30 A2 originals required');
  }
  final ordered = [...input]..sort((a, b) => a.number.compareTo(b.number));
  for (var i = 0; i < ordered.length; i++) {
    final item = ordered[i];
    if (item.level != 'A2' || item.number != i + 1 ||
        item.id != 'en-a2-voa-${(i + 1).toString().padLeft(3, '0')}' ||
        item.existingEpisodeId != item.id ||
        !item.isOfficialSource || item.durationSec < 210) {
      throw FormatException('Invalid A2 original number ${i + 1}');
    }
  }
  return List.unmodifiable([
    for (var start = 0; start < 30; start += 5)
      A2LongListeningSession(start ~/ 5 + 1,
          List.unmodifiable(ordered.skip(start).take(5))),
  ]);
}

/// Visible only in English A2; A1 and individual podcasts are unchanged.
class A2LongListeningSection extends StatefulWidget {
  const A2LongListeningSection({super.key, this.initialLessons});
  final List<VoaOriginalLesson>? initialLessons;

  @override
  State<A2LongListeningSection> createState() => _A2LongListeningSectionState();
}

class _A2LongListeningSectionState extends State<A2LongListeningSection> {
  late final Future<List<VoaOriginalLesson>> _catalog =
      widget.initialLessons == null
          ? const VoaOriginalCatalog(level: 'A2').load()
          : SynchronousFuture<List<VoaOriginalLesson>>(widget.initialLessons!);

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<VoaOriginalLesson>>(
      future: _catalog,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(ar ? 'تعذر تحميل جلسات A2 المطولة.' : 'Cannot load A2 sessions.');
        }
        if (!snap.hasData) return const LinearProgressIndicator();
        late final List<A2LongListeningSession> sessions;
        try {
          sessions = buildA2LongSessions(snap.data!);
        } catch (_) {
          return Text(ar ? 'بيانات جلسات A2 غير مكتملة.' : 'Invalid A2 session data.');
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ar ? 'جلسات الاستماع المطولة — A2'
                  : 'Long listening sessions — A2',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(ar
                  ? '6 جلسات متتابعة، كل واحدة تضم 5 تسجيلات VOA أصلية لمدة 20–25 دقيقة تقريبًا، مع عرض النص والترجمة لكل حلقة. بدون تكرار أو تمديد صناعي.'
                  : 'Six continuous 20–25-minute sessions, five original VOA recordings each, with the matching transcript and Arabic translation. No looping or synthetic extension.',
              style: TextStyle(fontSize: 12, height: 1.5,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 9),
          for (final session in sessions)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: scheme.surfaceContainerLow,
              child: ListTile(
                key: ValueKey('a2-long-session-${session.number}'),
                leading: const Icon(Icons.headphones_rounded,
                    color: Color(0xFF21805B)),
                title: Text(ar
                    ? 'الجلسة ${session.number} · الدروس ${session.lessons.first.number}–${session.lessons.last.number}'
                    : 'Session ${session.number} · Lessons ${session.lessons.first.number}–${session.lessons.last.number}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(ar
                    ? '${a2LongTime(session.durationSec)} دقيقة · خمسة تسجيلات أصلية'
                    : '${a2LongTime(session.durationSec)} · five original recordings'),
                trailing: const Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFF21805B)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => A2LongListeningPlayer(session: session),
                  ),
                ),
              ),
            ),
          TextButton.icon(
            key: const ValueKey('a2-long-official-voa'),
            onPressed: () async {
              await launchUrl(
                Uri.parse('https://learningenglish.voanews.com/podcasts'),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(ar
                ? 'المزيد من بودكاست VOA الطويل (حتى 30 دقيقة) على الموقع'
                : 'More long VOA podcasts (up to 30 minutes) on the official site'),
          ),
          const SizedBox(height: 16),
        ]);
      },
    );
  }
}

class A2LongListeningPlayer extends StatefulWidget {
  const A2LongListeningPlayer({super.key, required this.session});
  final A2LongListeningSession session;

  @override
  State<A2LongListeningPlayer> createState() => _A2LongListeningPlayerState();
}

class _A2LongListeningPlayerState extends State<A2LongListeningPlayer> {
  final AudioPlayer _player = AudioPlayer();
  final AcademyPodcastRepository _repo = const AcademyPodcastRepository();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  AcademyPodcastEpisode? _episode;
  int _index = 0;
  int _generation = 0;
  bool _loading = true;
  bool _playing = false;
  bool _transitioning = false;
  bool _completedHandled = false;
  bool _showArabic = true;
  bool _finished = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final newPlaying = state.playing &&
          state.processingState != ProcessingState.completed;
      if (_playing != newPlaying) setState(() => _playing = newPlaying);
      if (state.processingState == ProcessingState.completed &&
          !_loading && !_transitioning && !_completedHandled) {
        _completedHandled = true;
        if (_index + 1 < widget.session.lessons.length) {
          unawaited(_open(_index + 1));
        } else {
          setState(() => _finished = true);
        }
      }
    });
    _positionSub = _player.positionStream.listen((value) {
      if (mounted && !_loading) setState(() => _position = value);
    });
    unawaited(_open(0));
  }

  Future<void> _open(int next) async {
    if (!mounted || _transitioning ||
        next < 0 || next >= widget.session.lessons.length) return;
    _transitioning = true;
    final gen = ++_generation;
    final lesson = widget.session.lessons[next];
    setState(() {
      _index = next;
      _episode = null;
      _loading = true;
      _finished = false;
      _playing = false;
      _error = null;
      _completedHandled = false;
      _position = Duration.zero;
      _duration = Duration(seconds: lesson.durationSec);
    });
    try {
      await _player.stop();
      final episode = await _repo.load(AcademyPodcastEntry(
        id: lesson.id,
        level: 'A2',
        language: 'en',
        title: lesson.title,
        titleAr: lesson.titleAr,
        status: 'published_audio',
        asset: 'assets/podcasts/en/A2/${lesson.id}.json',
      ));
      if (!mounted || gen != _generation) return;
      if (!episode.canStream || episode.audioUrl != lesson.audioUrl ||
          episode.durationMs == null || episode.durationMs! < 210000) {
        throw const FormatException('VOA source/transcript mismatch');
      }
      // Keep the exact transcript for this episode; no invented cue timings.
      setState(() => _episode = episode);
      final actual = await _player.setUrl(episode.audioUrl!)
          .timeout(const Duration(seconds: 30));
      if (!mounted || gen != _generation) return;
      setState(() {
        _duration = actual != null && actual > Duration.zero
            ? actual : Duration(milliseconds: episode.durationMs!);
        _loading = false;
      });
      unawaited(_player.play());
    } catch (_) {
      if (mounted && gen == _generation) {
        setState(() { _loading = false; _error = 'load'; });
      }
    } finally {
      _transitioning = false;
    }
  }

  void _select(int index) {
    if (!_loading && !_transitioning) unawaited(_open(index));
  }

  void _toggle() {
    if (_loading || _error != null) return;
    if (_finished) {
      unawaited(_open(0));
    } else if (_player.playing) {
      unawaited(_player.pause());
    } else {
      unawaited(_player.play());
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_stateSub?.cancel() ?? Future<void>.value());
    unawaited(_positionSub?.cancel() ?? Future<void>.value());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final lesson = widget.session.lessons[_index];
    final episode = _episode;
    final maxMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble() : 1.0;
    return Scaffold(
      appBar: AppBar(title: Text(ar
          ? 'استماع مطول — جلسة ${widget.session.number}'
          : 'Extended listening — Session ${widget.session.number}')),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 5),
          padding: const EdgeInsets.all(15),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF174A38),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(ar ? 'VOA · الحلقة ${_index + 1} من 5'
                    : 'VOA · Episode ${_index + 1} of 5',
                style: const TextStyle(color: Color(0xFFF1D98F))),
            const SizedBox(height: 7),
            Text(ar ? lesson.titleAr : lesson.title,
                style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900)),
            Text(ar
                ? 'إجمالي الجلسة ${a2LongTime(widget.session.durationSec)}'
                : 'Session total ${a2LongTime(widget.session.durationSec)}',
                style: const TextStyle(color: Color(0xFFD7E9DB))),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(ar
                  ? 'تعذر تحميل صوت VOA الأصلي. أعد المحاولة؛ لن يُستخدم صوت بديل.'
                  : 'Cannot load original VOA recording. Retry; no substitute audio.',
                  style: const TextStyle(color: Color(0xFFF1D98F))),
              TextButton.icon(
                key: const ValueKey('a2-long-retry'),
                onPressed: () => unawaited(_open(_index)),
                icon: const Icon(Icons.refresh),
                label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
            Row(children: [
              IconButton(
                key: const ValueKey('a2-long-prev'),
                color: Colors.white,
                onPressed: _loading || _index == 0
                    ? null : () => _select(_index - 1),
                icon: const Icon(Icons.skip_previous_rounded)),
              IconButton(
                key: const ValueKey('a2-long-play'),
                color: const Color(0xFFF1D98F),
                onPressed: _loading || _error != null ? null : _toggle,
                icon: Icon(_playing ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded, size: 34)),
              IconButton(
                key: const ValueKey('a2-long-next'),
                color: Colors.white,
                onPressed: _loading || _index == 4
                    ? null : () => _select(_index + 1),
                icon: const Icon(Icons.skip_next_rounded)),
              const Spacer(),
              Text('${a2LongTime(_position.inSeconds)} / ${a2LongTime(_duration.inSeconds)}',
                style: const TextStyle(color: Colors.white)),
            ]),
            Slider(
              key: const ValueKey('a2-long-seek'),
              max: maxMs,
              value: _position.inMilliseconds.toDouble().clamp(0.0, maxMs),
              onChanged: _loading || _error != null ? null :
                  (value) => unawaited(_player.seek(
                      Duration(milliseconds: value.round()))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(child: Text(ar
                ? 'النص الإنجليزي والترجمة العربية'
                : 'English transcript and Arabic translation',
                style: const TextStyle(fontWeight: FontWeight.w800))),
            Switch(
              key: const ValueKey('a2-long-translation'),
              value: _showArabic,
              onChanged: (value) => setState(() => _showArabic = value)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          child: Text(ar
              ? 'كل تسجيل له نصه الخاص؛ توقيت تمييز الجمل غير معتمد، وبعض الترجمات العربية مسودات تحتاج مراجعة.'
              : 'Each recording has its own transcript. Sentence timings are not verified; some Arabic translations are machine drafts.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
        ),
        if (_finished) Text(ar ? 'اكتملت جلسة الاستماع!'
            : 'Session complete!',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        Expanded(
          child: episode == null
              ? Center(child: _loading
                  ? const CircularProgressIndicator()
                  : Text(ar ? 'النص غير متاح' : 'No transcript'))
              : ListView.builder(
                key: ValueKey('a2-long-transcript-${episode.id}'),
                padding: const EdgeInsets.all(12),
                itemCount: episode.dialogue.length,
                itemBuilder: (context, index) {
                  final row = episode.dialogue[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: scheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.speaker,
                            style: const TextStyle(
                                color: Color(0xFF25805E),
                                fontWeight: FontWeight.w800)),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(row.text,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontSize: 16, height: 1.45))),
                          if (_showArabic) ...[
                            const SizedBox(height: 7),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(row.translationAr,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                    fontSize: 14, height: 1.5))),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ]),
    );
  }
}
