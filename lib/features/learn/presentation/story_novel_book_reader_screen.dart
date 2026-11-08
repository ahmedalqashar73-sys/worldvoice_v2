import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/novel_book_pagination.dart';
import '../domain/models/story_library_models.dart';
import 'story_novel_reader_screen.dart';

/// Book-first view for WorldVoice original graded novels.
/// The existing activities reader remains available from the book toolbar.
class StoryNovelBookReaderScreen extends StatefulWidget {
  const StoryNovelBookReaderScreen({super.key, required this.entry});

  final StoryLibraryEntry entry;

  @override
  State<StoryNovelBookReaderScreen> createState() =>
      _StoryNovelBookReaderScreenState();
}

class _BookData {
  const _BookData(this.novel, this.pages);
  final Map<String, dynamic> novel;
  final List<NovelBookPage> pages;
}

class _StoryNovelBookReaderScreenState
    extends State<StoryNovelBookReaderScreen> {
  final PageController _controller = PageController();
  late final Future<_BookData> _future = _load();
  int _pageIndex = 0;

  Future<_BookData> _load() async {
    final raw = jsonDecode(await rootBundle.loadString(widget.entry.asset));
    if (raw is! Map<String, dynamic> ||
        raw['id'] != widget.entry.id ||
        raw['title'] != widget.entry.title ||
        raw['language'] != widget.entry.language ||
        raw['level'] != widget.entry.level) {
      throw const FormatException('Original novel does not match its index.');
    }
    return _BookData(raw, buildNovelBookPages(raw));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic);
  }

  void _openActivities() {
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => StoryNovelReaderScreen(entry: widget.entry),
    ));
  }

  void _openContents(List<NovelBookPage> pages, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(ar ? 'فهرس الكتاب' : 'Table of contents',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              for (var i = 0; i < pages.length; i++)
                if (pages[i].kind == 'introduction' ||
                    (pages[i].kind == 'chapter' && !pages[i].continued) ||
                    pages[i].kind == 'characters' && !pages[i].continued)
                  ListTile(
                    title: Text(pages[i].chapterNumber == null
                        ? pages[i].heading
                        : 'Chapter ' +
                            pages[i].chapterNumber.toString() +
                            ': ' + pages[i].heading,
                      textDirection: TextDirection.ltr),
                    trailing: Text((i + 1).toString()),
                    onTap: () {
                      Navigator.of(context).pop();
                      _goTo(i);
                    },
                  ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(ar ? 'المفردات والاختبارات' :
                    'Vocabulary and exercises'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openActivities();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookImage(String asset, {double height = 196}) {
    final image = asset.endsWith('.svg')
        ? SvgPicture.asset(asset, fit: BoxFit.contain, height: height)
        : Image.asset(asset, fit: BoxFit.contain, height: height);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: image),
    );
  }

  Widget _paragraph(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        color: Color(0xFF1C1C1C),
        fontFamily: 'serif',
        fontSize: 17.5,
        height: 1.55,
      ),
    ),
  );

  Widget _pageContents(
    Map<String, dynamic> novel,
    List<NovelBookPage> pages,
    NovelBookPage page,
  ) {
    const ink = Color(0xFF171717);
    const muted = Color(0xFF606060);
    if (page.kind == 'cover') {
      return Column(children: [
        const SizedBox(height: 8),
        Text('WorldVoice Library',
          style: const TextStyle(fontFamily: 'serif',
            fontSize: 19, color: ink, fontWeight: FontWeight.bold)),
        if (widget.entry.coverImage != null)
          _bookImage(widget.entry.coverImage!, height: 355),
        Text(novel['title'] as String,
          textDirection: TextDirection.ltr, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'serif', fontSize: 26,
            fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 12),
        Text(novel['author'] as String,
          style: const TextStyle(fontFamily: 'serif',
            fontSize: 17, color: ink)),
        const SizedBox(height: 16),
        Text('English Level A1',
          style: const TextStyle(color: muted, fontSize: 14)),
      ]);
    }

    if (page.kind == 'title') {
      return Column(children: [
        const SizedBox(height: 65),
        const Icon(Icons.auto_stories_outlined, size: 44, color: ink),
        const SizedBox(height: 18),
        const Text('WorldVoice Library',
          style: TextStyle(fontFamily: 'serif', fontSize: 19,
            fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 40),
        Text(novel['title'] as String,
          textAlign: TextAlign.center, textDirection: TextDirection.ltr,
          style: const TextStyle(fontFamily: 'serif', fontSize: 28,
            fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 12),
        Text((novel['subtitle'] as String?) ?? 'A Graded Reader',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'serif', fontSize: 17,
            fontStyle: FontStyle.italic, color: muted)),
        const SizedBox(height: 42),
        Text(novel['author'] as String,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'serif',
            fontSize: 17, color: ink)),
        const SizedBox(height: 50),
        const Text('English Level A1',
          style: TextStyle(color: muted, fontSize: 13)),
      ]);
    }
    final widgets = <Widget>[];
    if (page.kind == 'chapter') {
      widgets.add(Center(child: Text(
        'Chapter ' + page.chapterNumber.toString(),
        style: const TextStyle(fontFamily: 'serif', fontSize: 16,
          fontStyle: FontStyle.italic, color: muted),
      )));
      widgets.add(const SizedBox(height: 9));
    }
    if (!page.continued || page.kind == 'chapter') {
      widgets.add(Center(child: Text(
        page.heading,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ink, fontFamily: 'serif',
          fontSize: page.kind == 'chapter' ? 23 : 26,
          fontWeight: FontWeight.bold),
      )));
      widgets.add(const SizedBox(height: 9));
      widgets.add(const Divider(color: Color(0xFFB9B9B9)));
      widgets.add(const SizedBox(height: 16));
    }
    if (page.kind == 'contents') {
      final chapters = novel['chapters'] as List;
      for (var i = 0; i < chapters.length; i++) {
        final first = pages.indexWhere((item) =>
            item.kind == 'chapter' &&
            item.chapterNumber == i + 1);
        widgets.add(ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Chapter ' + (i + 1).toString() + ': ' +
                (chapters[i]['title'] as String),
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontFamily: 'serif',
              fontSize: 16, color: ink)),
          trailing: Text((first + 1).toString(),
            style: const TextStyle(color: muted)),
          onTap: () => _goTo(first),
        ));
      }
    } else if (page.kind == 'ending') {
      widgets.add(const SizedBox(height: 120));
      widgets.add(const Center(child: Text('The End',
        style: TextStyle(fontFamily: 'serif',
          fontSize: 30, fontStyle: FontStyle.italic, color: ink))));
      widgets.add(const SizedBox(height: 28));
      widgets.add(Center(child: OutlinedButton.icon(
        onPressed: _openActivities,
        icon: const Icon(Icons.school_outlined),
        label: const Text('Vocabulary & exercises'),
      )));
    } else {
      for (final part in page.parts) {
        if (part.imageAsset != null) {
          widgets.add(_bookImage(part.imageAsset!));
        } else if (part.text != null) {
          widgets.add(_paragraph(part.text!));
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _bookPage(
    Map<String, dynamic> novel,
    List<NovelBookPage> pages,
    int index,
  ) {
    final page = pages[index];
    return Container(
      key: ValueKey('worldvoice-novel-page-' + index.toString()),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCAC7C1)),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(
          color: Color(0x33000000),
          blurRadius: 7,
          offset: Offset(2, 3),
        )],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 7),
          child: Text('WORLDVOICE LIBRARY  ·  A1',
            style: const TextStyle(fontSize: 9.5,
              letterSpacing: 1.1, color: Color(0xFF777777))),
        ),
        const Divider(height: 1, indent: 25, endIndent: 25,
          color: Color(0xFFDDDDDD)),
        Expanded(
          child: ListView(
            key: PageStorageKey<String>(
              'novel-content-' + index.toString()),
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 16),
            children: [_pageContents(novel, pages, page)],
          ),
        ),
        const Divider(height: 1, indent: 25, endIndent: 25,
          color: Color(0xFFDDDDDD)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text((index + 1).toString(),
            style: const TextStyle(fontFamily: 'serif', fontSize: 12,
              color: Color(0xFF555555))),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFE8E5DF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2926),
        foregroundColor: Colors.white,
        title: Text(widget.entry.title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: ar ? 'المفردات والاختبارات' : 'Exercises',
            icon: const Icon(Icons.school_outlined),
            onPressed: _openActivities),
        ],
      ),
      body: FutureBuilder<_BookData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(
              ar ? 'تعذر فتح الكتاب.' : 'Could not open this book.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final pages = data.pages;
          return SafeArea(child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                Text('A1 · English',
                  style: const TextStyle(fontSize: 12,
                    color: Color(0xFF444444))),
                const Spacer(),
                Text(
                  (ar ? 'صفحة ' : 'Page ') +
                  (_pageIndex + 1).toString() +
                  ' / ' + pages.length.toString(),
                  style: const TextStyle(fontSize: 12,
                    color: Color(0xFF444444))),
                IconButton(
                  tooltip: ar ? 'الفهرس' : 'Contents',
                  onPressed: () => _openContents(pages, ar),
                  icon: const Icon(Icons.menu_book_outlined)),
              ]),
            ),
            Expanded(child: Directionality(
              textDirection: TextDirection.ltr,
              child: PageView.builder(
              key: const ValueKey('worldvoice-novel-book'),
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) =>
                  _bookPage(data.novel, pages, index),
            ))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 12),
              child: Row(children: [
                IconButton.filledTonal(
                  key: const ValueKey('novel-previous-page'),
                  tooltip: ar ? 'الصفحة السابقة' : 'Previous page',
                  onPressed: _pageIndex == 0
                      ? null : () => _goTo(_pageIndex - 1),
                  icon: const Icon(Icons.chevron_left)),
                const Spacer(),
                const Text('WorldVoice Library',
                  style: TextStyle(fontFamily: 'serif', fontSize: 12,
                    color: Color(0xFF595959))),
                const Spacer(),
                IconButton.filledTonal(
                  key: const ValueKey('novel-next-page'),
                  tooltip: ar ? 'الصفحة التالية' : 'Next page',
                  onPressed: _pageIndex >= pages.length - 1
                      ? null : () => _goTo(_pageIndex + 1),
                  icon: const Icon(Icons.chevron_right)),
              ]),
            ),
          ]));
        },
      ),
    );
  }
}
