import 'package:flutter/material.dart';

import '../data/story_library_repository.dart';
import '../domain/models/story_library_models.dart';

/// Starter text reader. Illustrations, synchronized audio, and XP are
/// intentionally separate stages, not simulated by this screen.
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
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
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
                        Container(
                          height: 170,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: page.image == null
                              ? Icon(
                                  Icons.auto_stories_rounded,
                                  size: 64,
                                  color: accent,
                                )
                              : page.image!.startsWith('https://')
                                  ? Image.network(
                                      page.image!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) =>
                                          const Icon(Icons.broken_image_outlined),
                                    )
                                  : Image.asset(
                                      page.image!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) =>
                                          const Icon(Icons.broken_image_outlined),
                                    ),
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
