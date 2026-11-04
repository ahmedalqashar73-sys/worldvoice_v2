import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/story_library_repository.dart';
import '../domain/models/story_library_models.dart';
import 'story_textbook_reader_screen.dart';

/// Independent illustrated story reader. Synchronized audio and XP are
/// implemented separately in later phases.
class StoryLibraryReaderScreen extends StatefulWidget {
  const StoryLibraryReaderScreen({
    required this.entry,
    required this.repository,
    super.key,
  });

  final StoryLibraryEntry entry;
  final StoryLibraryRepository repository;

  @override
  State<StoryLibraryReaderScreen> createState() =>
      _StoryLibraryReaderScreenState();
}

class _StoryLibraryReaderScreenState extends State<StoryLibraryReaderScreen> {
  late final Future<StoryLibraryBook> _story =
      widget.repository.loadStory(widget.entry);
  final PageController _pages = PageController();
  int _currentPage = 0;
  bool _translationVisible = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    await _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry.format == 'textbook') {
      return StoryTextbookReaderScreen(
        entry: widget.entry, repository: widget.repository);
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4)
        : const Color(0xFF164E39);
    return Scaffold(
      appBar: AppBar(title: Text(
        ar ? widget.entry.titleAr : widget.entry.title,
      )),
      body: FutureBuilder<StoryLibraryBook>(
        future: _story,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(
              ar ? 'تعذّر فتح القصة.' : 'Unable to open this story.',
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snapshot.data!;
          return SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text(
                      ar
                          ? 'الصفحة ${_currentPage + 1} من ${book.pages.length}'
                          : 'Page ${_currentPage + 1} of ${book.pages.length}',
                      style: TextStyle(
                        color: accent, fontWeight: FontWeight.w800),
                    )),
                    Text('${book.level} · ${book.language.toUpperCase()}'),
                  ]),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / book.pages.length,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                    color: accent,
                  ),
                ]),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: book.pages.length,
                  onPageChanged: (page) => setState(() {
                    _currentPage = page;
                    _translationVisible = false;
                  }),
                  itemBuilder: (context, index) {
                    final page = book.pages[index];
                    return ListView(
                      key: ValueKey('story-page-${page.page}'),
                      padding: const EdgeInsets.all(20),
                      children: [
                        StoryLibraryIllustration(
                          key: ValueKey('story-illustration-${page.page}'),
                          page: page,
                          active: index == _currentPage,
                        ),
                        const SizedBox(height: 22),
                        for (final line in page.script)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Text(
                              line.text,
                              textDirection: TextDirection.ltr,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(height: 1.5),
                            ),
                          ),
                        OutlinedButton.icon(
                          key: ValueKey('story-translation-${page.page}'),
                          onPressed: () => setState(() =>
                              _translationVisible = !_translationVisible),
                          icon: const Icon(Icons.translate_rounded),
                          label: Text(ar ? 'الترجمة العربية'
                              : 'Arabic translation'),
                        ),
                        if (_translationVisible)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              page.translationAr,
                              textDirection: TextDirection.rtl,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(height: 1.6),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: _currentPage == 0
                        ? null : () => _goToPage(_currentPage - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: Text(ar ? 'السابق' : 'Previous'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const ValueKey('stories-next-page'),
                    onPressed: _currentPage == book.pages.length - 1
                        ? null : () => _goToPage(_currentPage + 1),
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: Text(ar ? 'التالي' : 'Next'),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}


/// Subtle one-shot illustration animation; respects reduced-motion settings.
class StoryLibraryIllustration extends StatefulWidget {
  const StoryLibraryIllustration({
    required this.page,
    required this.active,
    super.key,
  });

  final StoryLibraryPage page;
  final bool active;

  @override
  State<StoryLibraryIllustration> createState() =>
      _StoryLibraryIllustrationState();
}

class _StoryLibraryIllustrationState extends State<StoryLibraryIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.page.animation == StoryLibraryAnimation.fadeIn
        ? const Duration(milliseconds: 800)
        : const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant StoryLibraryIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.animation != widget.page.animation) {
      _controller.duration = widget.page.animation == StoryLibraryAnimation.fadeIn
          ? const Duration(milliseconds: 800)
          : const Duration(seconds: 6);
    }
    if (!widget.active || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!oldWidget.active || oldWidget.page != widget.page) {
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
    final scheme = Theme.of(context).colorScheme;
    final image = widget.page.image;
    final child = image == null
        ? Icon(Icons.auto_stories_rounded,
            color: scheme.primary, size: 80)
        : image.endsWith('.svg')
            ? SvgPicture.asset(
                image,
                fit: BoxFit.cover,
                semanticsLabel: 'Story illustration page ${widget.page.page}',
                placeholderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : image.startsWith('https://')
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image_outlined),
                  );
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 216,
        width: double.infinity,
        color: scheme.primaryContainer,
        child: AnimatedBuilder(
          animation: _controller,
          child: RepaintBoundary(child: child),
          builder: (context, illustration) {
            final t = Curves.easeInOut.transform(_controller.value);
            final animation = widget.page.animation;
            final scale = animation == StoryLibraryAnimation.slowZoom
                ? 1.0 + 0.075 * t : 1.04;
            final dx = switch (animation) {
              StoryLibraryAnimation.panLeft => -16.0 * t,
              StoryLibraryAnimation.panRight => 16.0 * t,
              _ => 0.0,
            };
            final opacity = animation == StoryLibraryAnimation.fadeIn
                ? t : 1.0;
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.scale(
                  scale: scale,
                  child: illustration,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
