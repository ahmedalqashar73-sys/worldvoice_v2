import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/story_library_repository.dart';
import '../domain/models/story_library_models.dart';
import '../domain/models/story_textbook_models.dart';
import '../services/story_textbook_narration.dart';

/// All chapters, illustrations, paragraphs and review are in a single
/// vertically scrollable school-book. No page swipes or page breaks.
class StoryTextbookReaderScreen extends StatefulWidget {
  const StoryTextbookReaderScreen({
    required this.entry,
    required this.repository,
    super.key,
  });

  final StoryLibraryEntry entry;
  final StoryLibraryRepository repository;

  @override
  State<StoryTextbookReaderScreen> createState() =>
      _StoryTextbookReaderState();
}

class _StoryTextbookReaderState extends State<StoryTextbookReaderScreen> {
  late final Future<StoryTextbookBook> _future =
      widget.repository.loadTextbook(widget.entry);
  late final StoryTextbookNarration _audio =
      StoryTextbookNarration(language: widget.entry.language);
  final ScrollController _scroll = ScrollController();
  final Set<String> _translations = {};
  final Map<int, int> _answers = {};
  final Map<String, GlobalKey> _anchors = {};
  final Map<int, String> _spokenParagraphs = {};
  int? _active;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_readProgress);
  }

  void _readProgress() {
    if (!_scroll.hasClients) return;
    final maximum = _scroll.position.maxScrollExtent;
    final next = maximum <= 0
        ? 1.0
        : (_scroll.offset / maximum).clamp(0.0, 1.0);
    if ((next - _progress).abs() >= 0.02 || next == 1 && _progress != 1) {
      setState(() => _progress = next);
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<StoryTextbookSegment> _storyVoice(StoryTextbookBook book) {
    final result = <StoryTextbookSegment>[
      StoryTextbookSegment(
        speaker: StoryTextbookSpeaker.narrator,
        text: 'Welcome to WorldVoice Academy. '
            'This story was written by WorldVoice Academy. '
            'Today we are reading ${book.title}. Let us begin.',
      ),
    ];
    _spokenParagraphs.clear();
    for (var c = 0; c < book.chapters.length; c++) {
      final chapter = book.chapters[c];
      result.add(StoryTextbookSegment(
        speaker: StoryTextbookSpeaker.narrator,
        text: 'Chapter ${chapter.number}. ${chapter.title}.',
      ));
      for (var b = 0; b < chapter.blocks.length; b++) {
        for (var p = 0; p < chapter.blocks[b].paragraphs.length; p++) {
          final paragraph = chapter.blocks[b].paragraphs[p];
          for (final segment in paragraph.segments) {
            _spokenParagraphs[result.length] = '$c:$b:$p';
            result.add(segment);
          }
        }
      }
    }
    return result;
  }

  void _mark(int index) {
    if (!mounted) return;
    setState(() => _active = index);
    final key = _spokenParagraphs[index];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _anchors[key]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.30,
        );
      }
    });
  }

  void _meaning(String word, Map<String, String> meanings) {
    final value = meanings[word.toLowerCase()];
    if (value == null) return;
    showDialog<void>(context: context, builder: (dialog) => AlertDialog(
      title: Text(word),
      content: Text(value, textDirection: TextDirection.rtl),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: const Text('OK'),
        ),
      ],
    ));
  }

  List<InlineSpan> _highlightedText(
      String source, TextStyle style, Map<String, String> meanings) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in RegExp(r'\*\*([^*]+)\*\*').allMatches(source)) {
      if (match.start > start) {
        spans.add(TextSpan(text: source.substring(start, match.start)));
      }
      final word = match.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => _meaning(word, meanings),
          child: Text(word,
            textDirection: TextDirection.ltr,
            style: style.copyWith(
              color: const Color(0xFFD2A74F),
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFD2A74F),
            ),
          ),
        ),
      ));
      start = match.end;
    }
    if (start < source.length) {
      spans.add(TextSpan(text: source.substring(start)));
    }
    return spans;
  }

  Widget _paragraph(StoryTextbookBook book, StoryTextbookParagraph paragraph,
      String key, int firstSpeechIndex) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 18,
      height: 1.8,
      letterSpacing: 0.1,
    );
    final playing = _active != null &&
        _active! >= firstSpeechIndex &&
        _active! < firstSpeechIndex + paragraph.segments.length;
    final anchor = _anchors.putIfAbsent(key, GlobalKey.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 23),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AnimatedContainer(
          key: anchor,
          duration: const Duration(milliseconds: 230),
          padding: const EdgeInsets.fromLTRB(7, 9, 7, 9),
          decoration: BoxDecoration(
            color: playing
                ? const Color(0xFFE0AF4F).withValues(alpha: 0.19)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text.rich(
            TextSpan(style: style, children: [
              const TextSpan(text: '　'),
              for (var i = 0; i < paragraph.segments.length; i++) ...[
                if (i > 0) const TextSpan(text: ' '),
                ..._highlightedText(
                    paragraph.segments[i].text, style, book.meanings),
              ],
            ]),
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: ValueKey('textbook-translation-$key'),
            onPressed: () => setState(() {
              if (!_translations.add(key)) _translations.remove(key);
            }),
            icon: const Icon(Icons.translate_rounded, size: 18),
            label: Text(ar ? 'الترجمة العربية' : 'Arabic translation'),
          ),
        ),
        if (_translations.contains(key))
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 4, 7, 12),
            child: Text(
              paragraph.translationAr,
              textDirection: TextDirection.rtl,
              style: style.copyWith(fontSize: 16, height: 1.65),
            ),
          ),
      ]),
    );
  }

  Widget _reader(StoryTextbookBook book) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : const Color(0xFF164E39);
    final widgets = <Widget>[
      Text(
        ar ? book.titleAr : book.title,
        key: const ValueKey('textbook-story-title'),
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900, color: accent),
      ),
      const SizedBox(height: 5),
      Text(
        ar ? book.title : book.titleAr,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 12),
      Text(
        ar ? 'اسحب للأعلى والأسفل لقراءة القصة كاملة.'
            : 'Scroll up and down to read the entire story.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 18),
    ];
    var speechIndex = 1;
    var pictureNumber = 0;
    for (var c = 0; c < book.chapters.length; c++) {
      final chapter = book.chapters[c];
      speechIndex++; // Voice title for this chapter.
      widgets.add(Container(
        key: ValueKey('textbook-chapter-${chapter.number}'),
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar ? 'الفصل ${chapter.number}'
                  : 'Chapter ${chapter.number}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFCF9F49),
                fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              ar ? chapter.titleAr : chapter.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800),
            ),
            const Divider(height: 30),
          ],
        ),
      ));
      for (var b = 0; b < chapter.blocks.length; b++) {
        final block = chapter.blocks[b];
        widgets.add(StoryTextbookIllustration(
          key: ValueKey('textbook-image-$pictureNumber'),
          image: block.image,
          motion: block.animation,
          active: true,
        ));
        pictureNumber++;
        widgets.add(const SizedBox(height: 17));
        for (var p = 0; p < block.paragraphs.length; p++) {
          final paragraph = block.paragraphs[p];
          widgets.add(_paragraph(
            book, paragraph, '$c:$b:$p', speechIndex,
          ));
          speechIndex += paragraph.segments.length;
        }
        widgets.add(const SizedBox(height: 6));
      }
    }
    widgets.addAll([
      const Divider(height: 36),
      Text(
        ar ? 'العبرة من القصة' : 'The story lesson',
        style: theme.textTheme.titleLarge?.copyWith(
          color: accent, fontWeight: FontWeight.w800),
      ),
      Text(book.moralAr, textDirection: TextDirection.rtl,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.7)),
      const SizedBox(height: 20),
      Text(ar ? 'المفردات' : 'Vocabulary',
        style: theme.textTheme.headlineSmall),
      for (final word in book.vocabulary)
        ListTile(
          dense: true,
          title: Text(word.word),
          subtitle: Text(word.meaningAr, textDirection: TextDirection.rtl),
        ),
      const Divider(height: 36),
      Text(ar ? 'أسئلة الفهم' : 'Comprehension questions',
        style: theme.textTheme.headlineSmall),
    ]);
    for (var q = 0; q < book.questions.length; q++) {
      final question = book.questions[q];
      widgets.addAll([
        const SizedBox(height: 12),
        Text('${q + 1}. ${question.question}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800)),
        RadioGroup<int>(
          groupValue: _answers[q],
          onChanged: (value) {
            if (value != null) setState(() => _answers[q] = value);
          },
          child: Column(children: [
            for (var i = 0; i < question.options.length; i++)
              RadioListTile<int>(
                dense: true,
                value: i,
                title: Text(question.options[i]),
              ),
          ]),
        ),
      ]);
    }
    if (_answers.length == book.questions.length) {
      final score = book.questions.asMap().entries
          .where((e) => _answers[e.key] == e.value.answer).length;
      widgets.add(Text(
        ar ? 'النتيجة: $score / ${book.questions.length}'
            : 'Score: $score / ${book.questions.length}',
        style: theme.textTheme.titleLarge?.copyWith(color: accent),
      ));
    }
    widgets.add(const SizedBox(height: 32));
    return ListView(
      key: const ValueKey('textbook-story-scroll'),
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: widgets,
    );
  }

  Widget _audioControls(StoryTextbookBook book) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return AnimatedBuilder(
      animation: _audio,
      builder: (context, _) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_audio.error != null)
              Text(
                ar ? 'تعذّر تشغيل الصوت على هذا الجهاز.' : _audio.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            Row(children: [
              IconButton.filledTonal(
                key: const ValueKey('textbook-play'),
                tooltip: ar ? 'قراءة القصة كاملة' : 'Play full story',
                onPressed: () {
                  if (_audio.playing) {
                    unawaited(_audio.pause());
                  } else if (_audio.paused) {
                    unawaited(_audio.resume());
                  } else {
                    unawaited(_audio.play(
                      _storyVoice(book), onSegment: _mark));
                  }
                },
                icon: Icon(_audio.playing
                    ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
              IconButton(
                key: const ValueKey('textbook-stop'),
                onPressed: () {
                  unawaited(_audio.stop());
                  setState(() => _active = null);
                },
                icon: const Icon(Icons.stop_circle_outlined),
              ),
              const Spacer(),
              Text(ar ? 'السرعة' : 'Speed'),
              const SizedBox(width: 5),
              DropdownButton<double>(
                key: const ValueKey('textbook-speed'),
                value: _audio.speed,
                items: const [
                  DropdownMenuItem(value: 0.3, child: Text('0.75×')),
                  DropdownMenuItem(value: 0.36, child: Text('1×')),
                  DropdownMenuItem(value: 0.45, child: Text('1.25×')),
                ],
                onChanged: (value) {
                  if (value != null) unawaited(_audio.changeSpeed(value));
                },
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return FutureBuilder<StoryTextbookBook>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(ar ? 'القصص' : 'Stories')),
            body: Center(child: Text(
              ar ? 'تعذّر تحميل القصة.' : 'Unable to load this story.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final book = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(ar ? 'القصص · قراءة' : 'Stories · Reading'),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: Center(child: Text(book.level)),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(5),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 5,
                color: const Color(0xFF26855B),
              ),
            ),
          ),
          body: Column(children: [
            Expanded(child: _reader(book)),
            _audioControls(book),
          ]),
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
