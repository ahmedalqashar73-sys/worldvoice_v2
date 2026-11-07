import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/graded_story_repository.dart';
import 'podcast_sentence_translation.dart';

/// Original public-domain text with attributed human narration; never
/// manufactures timestamps or uses Oxford Bookworms proprietary content.
class GradedStoryReaderScreen extends StatefulWidget {
  const GradedStoryReaderScreen({
    super.key, required this.entry, required this.repository,
  });
  final GradedStoryEntry entry;
  final GradedStoryRepository repository;

  @override
  State<GradedStoryReaderScreen> createState() =>
      _GradedStoryReaderScreenState();
}

class _GradedStoryReaderScreenState extends State<GradedStoryReaderScreen> {
  late final Future<GradedStoryBook> _book =
      widget.repository.loadBook(widget.entry);
  final AudioPlayer _player = AudioPlayer();
  int _chapterIndex = 0;
  int? _loadedChapter;
  bool _loading = false;
  String? _error;
  double _size = 16;

  Future<void> _selectChapter(int next) async {
    if (next == _chapterIndex) return;
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _chapterIndex = next;
      _loadedChapter = null;
      _error = null;
    });
  }

  Future<void> _toggleAudio(GradedStoryChapter chapter) async {
    if (_loading) return;
    if (_loadedChapter == chapter.number) {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        unawaited(_player.play());
      }
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _player.setUrl(chapter.audioUrl);
      if (!mounted) return;
      setState(() {
        _loadedChapter = chapter.number;
        _loading = false;
      });
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Original audio unavailable. Please check the connection.';
      });
    }
  }

  String _clock(Duration value) {
    final s = value.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? widget.entry.titleAr : widget.entry.title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<GradedStoryBook>(
        future: _book,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(ar
                ? 'تعذّر تحميل نص القصة.' : 'Could not load the story.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snapshot.data!;
          final chapter = book.chapters[_chapterIndex];
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORLDVOICE · GRADED CLASSICS',
                    style: TextStyle(color: scheme.primary,
                      fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(ar
                      ? '${book.level} · ${book.author} · ${book.chapters.length} فصول'
                      : '${book.level} · ${book.author} · ${book.chapters.length} chapters',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(ar
                    ? 'نسخة تجريبية: النص والتسجيل ضمن الملك العام في الولايات المتحدة. التحقق من حقوق التسجيل عالميًا لم يكتمل. النص غير مبسط ولا توجد مزامنة معتمدة.'
                    : 'Preview: US public-domain text and audio; global audio rights require review. Original text is not simplified and sentence alignment is not verified.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11, height: 1.4)),
                  const SizedBox(height: 10),
                  SizedBox(height: 43, child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: book.chapters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => ChoiceChip(
                      key: ValueKey('graded-chapter-${i + 1}'),
                      label: Text(ar ? 'الفصل ${i + 1}' : 'Chapter ${i + 1}'),
                      selected: _chapterIndex == i,
                      onSelected: (_) => unawaited(_selectChapter(i)),
                    ),
                  )),
                  const SizedBox(height: 9),
                  Text(chapter.title,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 17)),
                  const SizedBox(height: 8),
                  Row(children: [
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (context, state) => IconButton.filled(
                        key: const ValueKey('graded-original-audio-toggle'),
                        tooltip: ar ? 'تشغيل أو إيقاف الصوت البشري'
                            : 'Play or pause human narration',
                        onPressed: _loading
                            ? null : () => unawaited(_toggleAudio(chapter)),
                        icon: Icon(_loading
                            ? Icons.hourglass_empty_rounded
                            : (_loadedChapter == chapter.number &&
                                    _player.playing)
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, positionSnap) {
                        final current = _loadedChapter == chapter.number
                            ? positionSnap.data ?? Duration.zero
                            : Duration.zero;
                        final total = _loadedChapter == chapter.number
                            ? _player.duration ??
                                Duration(seconds: chapter.durationSeconds)
                            : Duration(seconds: chapter.durationSeconds);
                        final max = total.inMilliseconds > 0
                            ? total.inMilliseconds.toDouble() : 1.0;
                        return Column(children: [
                          Text('${_clock(current)} / ${_clock(total)}',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 12)),
                          Slider(
                            key: const ValueKey('graded-original-audio-seek'),
                            value: current.inMilliseconds
                                .clamp(0, max.toInt()).toDouble(),
                            max: max,
                            onChanged: _loadedChapter == chapter.number
                                ? (ms) => unawaited(_player.seek(
                                    Duration(milliseconds: ms.round())))
                                : null),
                        ]);
                      },
                    )),
                  ]),
                  if (_error != null) Text(ar
                      ? 'تعذر تشغيل التسجيل الأصلي. تأكد من اتصال الإنترنت.'
                      : _error!, style: TextStyle(
                          color: scheme.error, fontSize: 12)),
                  Row(children: [
                    Expanded(child: Text(ar ? 'اضغط على الترجمة بجانب الجملة'
                        : 'Tap a sentence icon to translate into your native language',
                      style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant))),
                    IconButton(
                      tooltip: ar ? 'تصغير الخط' : 'Smaller text',
                      onPressed: () => setState(() =>
                        _size = (_size - 1).clamp(14.0, 22.0)),
                      icon: const Icon(Icons.text_decrease_rounded)),
                    IconButton(
                      tooltip: ar ? 'تكبير الخط' : 'Larger text',
                      onPressed: () => setState(() =>
                        _size = (_size + 1).clamp(14.0, 22.0)),
                      icon: const Icon(Icons.text_increase_rounded)),
                  ]),
                ],
              ),
            ),
            Expanded(child: ListView.builder(
              key: ValueKey('graded-chapter-text-${chapter.number}'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: chapter.paragraphs.length,
              itemBuilder: (context, paragraphIndex) {
                final sentences = podcastReadingSentences(
                  chapter.paragraphs[paragraphIndex]);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < sentences.length; i++)
                        PodcastSentenceTranslation(
                          key: ValueKey('graded-translate-${chapter.number}-$paragraphIndex-$i'),
                          text: sentences[i],
                          original: Text(sentences[i],
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontSize: _size,
                              height: 1.55)),
                        ),
                    ],
                  ),
                );
              },
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: PodcastSourceInfo(
                source: 'LibriVox · ${book.reader} · original work by ${book.author}',
                url: book.sourceAudioUrl),
            ),
          ]);
        },
      ),
    );
  }
}
