import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/story_library_repository.dart';
import '../domain/models/story_library_models.dart';
import '../domain/models/story_textbook_models.dart';
import '../services/story_textbook_narration.dart';

class StoryTextbookReaderScreen extends StatefulWidget {
  const StoryTextbookReaderScreen({
    required this.entry,
    required this.repository,
    super.key,
  });
  final StoryLibraryEntry entry;
  final StoryLibraryRepository repository;

  @override
  State<StoryTextbookReaderScreen> createState() => _StoryTextbookReaderState();
}

class _Step {
  const _Step(this.chapter, this.block);
  final int chapter;
  final int? block;
  bool get isTransition => chapter == 1 && block == null;
  bool get isReview => chapter == 2;
}

class _StoryTextbookReaderState extends State<StoryTextbookReaderScreen> {
  late final Future<StoryTextbookBook> _future =
      widget.repository.loadTextbook(widget.entry);
  late final StoryTextbookNarration _audio =
      StoryTextbookNarration(language: widget.entry.language);
  final PageController _pager = PageController();
  final Set<String> _translation = {};
  final Map<int, int> _answers = {};
  final Map<String, GlobalKey> _sentenceKeys = {};
  int _page = 0;
  int? _active;

  @override
  void dispose() {
    _audio.dispose();
    _pager.dispose();
    super.dispose();
  }

  List<_Step> _steps(StoryTextbookBook book) => [
    for (var chapter = 0; chapter < 2; chapter++) ...[
      if (chapter == 1) const _Step(1, null),
      for (var block = 0; block < book.chapters[chapter].blocks.length; block++)
        _Step(chapter, block),
    ],
    const _Step(2, null),
  ];

  Future<void> _go(int page) async {
    unawaited(_audio.stop());
    if (!mounted) return;
    setState(() => _active = null);
    await _pager.animateToPage(page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut);
  }

  void _mark(int segment) {
    if (!mounted) return;
    setState(() => _active = segment);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _sentenceKeys['$_page:$segment']?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 270),
          alignment: 0.34);
      }
    });
  }

  void _meaning(String word, Map<String, String> meanings) {
    final value = meanings[word.toLowerCase()];
    if (value == null) return;
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(word),
      content: Text(value, textDirection: TextDirection.rtl),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ));
  }

  List<InlineSpan> _spans(String source, TextStyle style,
      Map<String, String> meanings) {
    final result = <InlineSpan>[];
    var start = 0;
    for (final match in RegExp(r'\*\*([^*]+)\*\*').allMatches(source)) {
      if (match.start > start) {
        result.add(TextSpan(text: source.substring(start, match.start)));
      }
      final word = match.group(1)!;
      result.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => _meaning(word, meanings),
          child: Text(word,
            textDirection: TextDirection.ltr,
            style: style.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFFBD9143),
              decoration: TextDecoration.underline)),
        ),
      ));
      start = match.end;
    }
    if (start < source.length) {
      result.add(TextSpan(text: source.substring(start)));
    }
    return result;
  }

  Widget _chapterBlock(StoryTextbookBook book, _Step step, int pageIndex) {
    final block = book.chapters[step.chapter].blocks[step.block!];
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final style = TextStyle(
      color: onSurface, fontSize: 18, height: 1.65);
    final segmentWidgets = <Widget>[];
    final spoken = <StoryTextbookSegment>[];
    for (var p = 0; p < block.paragraphs.length; p++) {
      final paragraph = block.paragraphs[p];
      final translatedKey = '$pageIndex:$p';
      for (var s = 0; s < paragraph.segments.length; s++) {
        final segment = paragraph.segments[s];
        final number = spoken.length;
        spoken.add(segment);
        final anchor = _sentenceKeys.putIfAbsent(
            '$pageIndex:$number', GlobalKey.new);
        segmentWidgets.add(Container(
          key: anchor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _page == pageIndex && _active == number
                ? const Color(0xFFD0A955).withValues(alpha: 0.22)
                : Colors.transparent,
          ),
          child: Text.rich(TextSpan(
            style: style,
            children: [
              if (s == 0) const TextSpan(text: '    '),
              ..._spans(segment.text, style, book.meanings),
            ],
          ), textDirection: TextDirection.ltr),
        ));
      }
      segmentWidgets.add(const SizedBox(height: 8));
      segmentWidgets.add(Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          key: ValueKey('textbook-translation-$translatedKey'),
          onPressed: () => setState(() {
            if (!_translation.add(translatedKey)) {
              _translation.remove(translatedKey);
            }
          }),
          icon: const Icon(Icons.translate, size: 18),
          label: Text(ar ? 'الترجمة العربية' : 'Arabic translation'),
        ),
      ));
      if (_translation.contains(translatedKey)) {
        segmentWidgets.add(Text(paragraph.translationAr,
          textDirection: TextDirection.rtl,
          style: style.copyWith(fontSize: 16)));
      }
      segmentWidgets.add(const SizedBox(height: 22));
    }

    return Column(children: [
      Expanded(child: ListView(
        key: PageStorageKey('textbook-page-$pageIndex'),
        padding: const EdgeInsets.all(18),
        children: [
          StoryTextbookIllustration(
            key: ValueKey('textbook-image-$pageIndex'),
            image: block.image,
            motion: block.animation,
            active: pageIndex == _page),
          const SizedBox(height: 22),
          ...segmentWidgets,
        ],
      )),
      AnimatedBuilder(
        animation: _audio,
        builder: (context, child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            IconButton.filledTonal(
              key: const ValueKey('textbook-play'),
              onPressed: () {
                if (_audio.playing) {
                  _audio.pause();
                } else if (_audio.paused) {
                  _audio.resume();
                } else {
                  _audio.play(spoken, onSegment: _mark);
                }
              },
              icon: Icon(_audio.playing
                  ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            IconButton(
              onPressed: () {
                _audio.stop();
                setState(() => _active = null);
              },
              icon: const Icon(Icons.stop_rounded),
            ),
            const Spacer(),
            Text(ar ? 'السرعة' : 'Speed'),
            const SizedBox(width: 6),
            DropdownButton<double>(
              key: const ValueKey('textbook-speed'),
              value: _audio.speed,
              items: const [
                DropdownMenuItem(value: 0.35, child: Text('0.75×')),
                DropdownMenuItem(value: 0.46, child: Text('1×')),
                DropdownMenuItem(value: 0.65, child: Text('1.25×')),
              ],
              onChanged: (value) {
                if (value != null) _audio.changeSpeed(value);
              },
            ),
          ]),
        ),
      ),
      if (_audio.error != null) Text(
        ar ? 'تعذر تشغيل الصوت على هذا الجهاز.' : _audio.error!,
        style: const TextStyle(color: Colors.redAccent)),
    ]);
  }

  Widget _transition(StoryTextbookBook book, int pageIndex) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_stories_rounded,
          size: 68, color: Color(0xFF318E62)),
        const SizedBox(height: 18),
        Text(ar ? 'الفصل الثاني' : 'Chapter 2',
          style: Theme.of(context).textTheme.headlineMedium),
        Text(ar ? book.chapters[1].titleAr : book.chapters[1].title,
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('textbook-next-chapter'),
          onPressed: () => _go(pageIndex + 1),
          child: Text(ar ? 'ابدأ الفصل الثاني' : 'Start chapter two'),
        ),
      ],
    ));
  }

  Widget _review(StoryTextbookBook book) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final score = book.questions.asMap().entries
        .where((e) => _answers[e.key] == e.value.answer).length;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text(ar ? 'المفردات' : 'Vocabulary',
        style: Theme.of(context).textTheme.headlineSmall),
      for (final word in book.vocabulary)
        ListTile(
          dense: true,
          title: Text(word.word),
          subtitle: Text(word.meaningAr, textDirection: TextDirection.rtl)),
      const Divider(),
      Text(ar ? 'أسئلة الفهم' : 'Comprehension',
        style: Theme.of(context).textTheme.headlineSmall),
      for (var q = 0; q < book.questions.length; q++) ...[
        const SizedBox(height: 16),
        Text(book.questions[q].question,
          style: const TextStyle(fontWeight: FontWeight.w800)),
        RadioGroup<int>(
          groupValue: _answers[q],
          onChanged: (value) {
            if (value != null) setState(() => _answers[q] = value);
          },
          child: Column(children: [
            for (var option = 0; option < 4; option++)
              RadioListTile<int>(
                value: option,
                title: Text(book.questions[q].options[option]),
              ),
          ]),
        ),
      ],
      if (_answers.length == book.questions.length)
        Text(ar ? 'النتيجة: $score / 8' : 'Score: $score / 8',
          style: Theme.of(context).textTheme.titleLarge),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : const Color(0xFF164E39);
    return FutureBuilder<StoryTextbookBook>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(ar
                ? 'تعذر تحميل القصة.' : 'Unable to load story.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
        }
        final book = snapshot.data!;
        final steps = _steps(book);
        final step = steps[_page];
        final chapter = book.chapters[step.isReview ? 1 : step.chapter];
        return Scaffold(
          appBar: AppBar(title: Text(ar ? 'القصص' : 'Stories')),
          body: SafeArea(child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ar ? book.titleAr : book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: accent)),
                  const SizedBox(height: 5),
                  Text(ar
                      ? 'الفصل ${chapter.number}: ${chapter.titleAr}'
                      : 'Chapter ${chapter.number}: ${chapter.title}',
                    style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(children: [
                    for (var i = 0; i < book.chapters.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: LinearProgressIndicator(
                        value: step.isReview ? 1 :
                          steps.take(_page + 1).where((step) =>
                            step.chapter == i && step.block != null).length /
                            book.chapters[i].blocks.length,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                        color: accent,
                      )),
                    ],
                  ]),
                ],
              ),
            ),
            Expanded(child: PageView.builder(
              controller: _pager,
              itemCount: steps.length,
              onPageChanged: (index) {
                _audio.stop();
                setState(() {
                  _page = index;
                  _active = null;
                });
              },
              itemBuilder: (context, index) {
                final current = steps[index];
                if (current.isReview) return _review(book);
                if (current.isTransition) return _transition(book, index);
                return _chapterBlock(book, current, index);
              },
            )),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                OutlinedButton(
                  key: const ValueKey('textbook-back'),
                  onPressed: _page == 0 ? null : () => _go(_page - 1),
                  child: Text(ar ? 'السابق' : 'Previous')),
                const Spacer(),
                Text('${_page + 1} / ${steps.length}'),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('textbook-next'),
                  onPressed: _page == steps.length - 1
                      ? null : () => _go(_page + 1),
                  child: Text(ar ? 'التالي' : 'Next')),
              ]),
            ),
          ])),
        );
      },
    );
  }
}

/// Large, gently animated illustration; honors reduced motion.
class StoryTextbookIllustration extends StatefulWidget {
  const StoryTextbookIllustration({
    required this.image,
    required this.motion,
    required this.active,
    super.key,
  });
  final String? image;
  final StoryTextbookMotion motion;
  final bool active;

  @override
  State<StoryTextbookIllustration> createState() =>
      _StoryTextbookIllustrationState();
}

class _StoryTextbookIllustrationState
    extends State<StoryTextbookIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.motion == StoryTextbookMotion.fadeIn
        ? const Duration(milliseconds: 850)
        : const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant StoryTextbookIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!oldWidget.active || oldWidget.image != widget.image) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.image;
    final image = source == null
        ? const Icon(Icons.auto_stories_rounded, size: 80)
        : source.endsWith('.svg')
            ? SvgPicture.asset(source, fit: BoxFit.cover)
            : source.startsWith('https://')
                ? Image.network(source, fit: BoxFit.cover)
                : Image.asset(source, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: AnimatedBuilder(
            animation: _controller,
            child: RepaintBoundary(child: image),
            builder: (context, illustration) {
              final t = Curves.easeInOut.transform(_controller.value);
              final dx = switch (widget.motion) {
                StoryTextbookMotion.panLeft => -16.0 * t,
                StoryTextbookMotion.panRight => 16.0 * t,
                StoryTextbookMotion.parallax => 10.0 * t,
                _ => 0.0,
              };
              return Opacity(
                opacity: widget.motion == StoryTextbookMotion.fadeIn
                    ? t : 1,
                child: Transform.translate(
                  offset: Offset(dx, widget.motion ==
                      StoryTextbookMotion.parallax ? -8.0 * t : 0),
                  child: Transform.scale(
                    scale: widget.motion == StoryTextbookMotion.zoomInSlow
                        ? 1 + t * 0.085 : 1.04,
                    child: illustration,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
