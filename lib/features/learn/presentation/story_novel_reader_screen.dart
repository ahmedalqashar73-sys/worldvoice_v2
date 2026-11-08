import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../domain/models/story_library_models.dart';

/// Seven-chapter, offline original reader; independent of the short-story parser.
class StoryNovelReaderScreen extends StatefulWidget {
  const StoryNovelReaderScreen({super.key, required this.entry});
  final StoryLibraryEntry entry;
  @override
  State<StoryNovelReaderScreen> createState() => _StoryNovelReaderScreenState();
}

class _StoryNovelReaderScreenState extends State<StoryNovelReaderScreen> {
  late final Future<Map<String, dynamic>> _book = _load();
  int _section = -1; // -1 introduction, -2 glossary, -3 questions
  final Map<int, int> _answers = {};
  final Map<int, int> _finalAnswers = {};

  Future<Map<String, dynamic>> _load() async {
    final raw = jsonDecode(await rootBundle.loadString(widget.entry.asset));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Novel must be an object.');
    }
    if (raw['id'] != widget.entry.id ||
        raw['title'] != widget.entry.title ||
        raw['title_ar'] != widget.entry.titleAr ||
        raw['language'] != widget.entry.language ||
        raw['level'] != widget.entry.level) {
      throw const FormatException('Novel index mismatch.');
    }
    final chapters = raw['chapters'];
    if (chapters is! List || chapters.length < 5) {
      throw const FormatException('A novel must have at least five chapters.');
    }
    for (var i = 0; i < chapters.length; i++) {
      final c = chapters[i];
      if (c is! Map<String, dynamic> ||
          c['number'] != i + 1 || c['title'] is! String ||
          c['paragraphs'] is! List ||
          (c['paragraphs'] as List).length < 5) {
        throw FormatException('Invalid novel chapter ' + (i + 1).toString());
      }
    }
    return raw;
  }

  Widget _p(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text('     ' + value, textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      style: const TextStyle(fontFamily: 'serif', fontSize: 18,
        color: Colors.black, height: 1.55)),
  );

  Widget _heading(String value, {double size = 25}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(value, textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold,
        fontSize: size, color: Colors.black)),
  );

  Widget _contents(Map<String, dynamic> novel, bool ar) {
    final chapters = (novel['chapters'] as List).cast<Map<String, dynamic>>();
    final children = <Widget>[];
    if (_section == -1) {
      children.addAll([
        if (widget.entry.coverImage != null)
          widget.entry.coverImage!.endsWith('.svg')
              ? SvgPicture.asset(widget.entry.coverImage!,
                  height: 260, fit: BoxFit.contain)
              : Image.asset(widget.entry.coverImage!,
                  height: 260, fit: BoxFit.contain),
        _heading(novel['title'] as String, size: 29),
        Center(child: Text(novel['author'] as String,
          style: const TextStyle(color: Colors.black87))),
        _heading('Story Introduction', size: 23),
        _p(novel['synopsis'] as String),
        _heading('Characters', size: 22),
        for (final c in (novel['characters'] as List))
          _p((c['name'] as String) + ' — ' + (c['description'] as String)),
        _heading('Contents', size: 22),
        for (var i = 0; i < chapters.length; i++)
          ListTile(
            title: Text((i + 1).toString() + '. ' + (chapters[i]['title'] as String),
              style: const TextStyle(color: Colors.black, fontFamily: 'serif')),
            trailing: const Icon(Icons.chevron_right, color: Colors.black54),
            onTap: () => setState(() => _section = i),
          ),
      ]);
    } else if (_section >= 0 && _section < chapters.length) {
      final ch = chapters[_section];
      children.addAll([
        _heading('Chapter ' + (_section + 1).toString(), size: 17),
        _heading(ch['title'] as String),
        const Divider(color: Colors.black38),
        for (var i = 0; i < (ch['paragraphs'] as List).length; i++) ...[
          if (i == 3 && ch['image'] is String &&
              (ch['image'] as String).isNotEmpty) ...[
            const SizedBox(height: 9),
            if ((ch['image'] as String).endsWith('.svg'))
              SvgPicture.asset(ch['image'] as String,
                height: 180, fit: BoxFit.contain)
            else
              Image.asset(ch['image'] as String,
                height: 180, fit: BoxFit.contain),
            const SizedBox(height: 19),
          ],
          _p(ch['paragraphs'][i] as String),
          if (i == 9 && ch['extra_image'] is String) ...[
            const SizedBox(height: 9),
            Image.asset(ch['extra_image'] as String,
              height: 180, fit: BoxFit.contain),
            const SizedBox(height: 19),
          ],
        ],
        const SizedBox(height: 20),
        Center(child: FilledButton.icon(
          onPressed: () => setState(() => _section = _section + 1 < chapters.length
              ? _section + 1 : -2),
          icon: const Icon(Icons.arrow_forward),
          label: Text(_section + 1 < chapters.length
              ? (ar ? 'الفصل التالي' : 'Next Chapter')
              : (ar ? 'المفردات' : 'Glossary')),
        )),
      ]);
    } else if (_section == -2) {
      children.add(_heading('Glossary'));
      for (final word in (novel['vocabulary'] as List)) {
        children.add(ListTile(
          title: Text(word['word'] as String,
            style: const TextStyle(color: Colors.black,
              fontFamily: 'serif', fontWeight: FontWeight.bold)),
          subtitle: Text(word['meaning'] as String,
            style: const TextStyle(color: Colors.black87)),
        ));
      }
    } else {
      final finalTest = _section == -4 && novel['final_test'] is List;
      final qs = ((finalTest ? novel['final_test'] : novel['questions']) as List)
          .cast<Map<String, dynamic>>();
      final answers = finalTest ? _finalAnswers : _answers;
      children.add(_heading(finalTest ? 'Final Test' : 'Reading Comprehension'));
      for (var j = 0; j < qs.length; j++) {
        final q = qs[j];
        children.add(Padding(
          padding: const EdgeInsets.only(top: 21, bottom: 7),
          child: Text((j + 1).toString() + '. ' + (q['q'] as String),
            style: const TextStyle(color: Colors.black, fontSize: 17,
              fontWeight: FontWeight.bold))));
        for (var k = 0; k < (q['options'] as List).length; k++) {
          children.add(RadioListTile<int>(
            title: Text(q['options'][k] as String,
              style: const TextStyle(color: Colors.black)),
            value: k, groupValue: answers[j],
            onChanged: (v) => setState(() { if (v != null) answers[j] = v; }),
          ));
        }
      }
      if (answers.length == qs.length) {
        final score = List<int>.generate(qs.length, (i) => i)
            .where((i) => qs[i]['answer'] == answers[i]).length;
        children.add(_heading('Score: ' + score.toString() + '/' +
            qs.length.toString(), size: 21));
      }
    }
    return ListView(
      key: ValueKey('novel-section-' + _section.toString()),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _book,
        builder: (context, data) {
          if (data.hasError) {
            return Center(child: Text(ar ? 'تعذر فتح الرواية.' : 'Cannot open novel.'));
          }
          if (!data.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = data.data!;
          final length = (book['chapters'] as List).length;
          return ColoredBox(color: Colors.white,
            child: SafeArea(child: Column(children: [
              SizedBox(height: 55, child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(label: Text(ar ? 'المقدمة' : 'Introduction'),
                    selected: _section == -1,
                    onSelected: (_) => setState(() => _section = -1)),
                  const SizedBox(width: 6),
                  for (var i = 0; i < length; i++) ...[
                    ChoiceChip(label: Text(ar ? 'الفصل ' + (i + 1).toString()
                      : 'Chapter ' + (i + 1).toString()),
                      selected: _section == i,
                      onSelected: (_) => setState(() => _section = i)),
                    const SizedBox(width: 6),
                  ],
                  ChoiceChip(label: Text(ar ? 'المفردات' : 'Glossary'),
                    selected: _section == -2,
                    onSelected: (_) => setState(() => _section = -2)),
                  const SizedBox(width: 6),
                  ChoiceChip(label: Text(ar ? 'أسئلة الفهم' : 'Reading Check'),
                    selected: _section == -3,
                    onSelected: (_) => setState(() => _section = -3)),
                  if (book['final_test'] is List) ...[
                    const SizedBox(width: 6),
                    ChoiceChip(label: Text(ar ? 'الاختبار النهائي' : 'Final Test'),
                      selected: _section == -4,
                      onSelected: (_) => setState(() => _section = -4)),
                  ],
                ],
              )),
              const Divider(height: 1, color: Colors.black26),
              Expanded(child: _contents(book, ar)),
            ])),
          );
        },
      ),
    );
  }
}
