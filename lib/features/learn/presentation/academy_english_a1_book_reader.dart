import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_english_a1_catalog.dart';
import 'academy_illustrated_story_art.dart';

const _ink = Color(0xFF185441);
const _paper = Color(0xFFF8F2E8);
const _gold = Color(0xFFD9AD62);

/// Book-style A1 reader: original art, 4 substantive paragraphs per book,
/// target-language narration, optional translation and comprehension.
class AcademyEnglishA1BookReader extends StatefulWidget {
  const AcademyEnglishA1BookReader({required this.story, super.key});
  final EnglishA1Story story;

  @override
  State<AcademyEnglishA1BookReader> createState() =>
      _AcademyEnglishA1BookReaderState();
}

class _AcademyEnglishA1BookReaderState
    extends State<AcademyEnglishA1BookReader> {
  final FlutterTts _tts = FlutterTts();
  int _page = -1;
  bool _translate = false;
  int? _answer;
  bool _checked = false;
  bool _speaking = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool get _quiz => _page == widget.story.pages.length;
  bool get _passed => _quiz && _checked &&
      _answer == widget.story.answer;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _say(String words, {bool slow = false}) async {
    try {
      await _tts.stop();
      if (!mounted) return;
      final installed = await _tts.isLanguageAvailable('en-US');
      if (installed == false) throw StateError('English voice unavailable');
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(slow ? .34 : .50);
      await _tts.setVolume(1.0);
      if (!mounted) return;
      setState(() => _speaking = true);
      final status = await _tts.speak(words);
      if (status == 0) throw StateError('Speech engine refused playback');
    } catch (_) {
      if (!mounted) return;
      setState(() => _speaking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          _ar ? 'الصوت غير متوفر. ثبّت صوت الإنجليزية من إعدادات الهاتف.'
              : 'English voice unavailable. Install it in device settings.')));
    }
  }

  void _move(int delta) {
    final next = _page + delta;
    if (next < -1 || next > widget.story.pages.length) return;
    _tts.stop();
    setState(() {
      _page = next;
      _translate = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Widget _cover(ColorScheme colors) => Container(
    key: const ValueKey('storybook-cover'),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF103F37), Color(0xFF277A68)],
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(children: [
        const SizedBox(height: 10),
        const Icon(Icons.auto_stories_rounded, size: 42, color: _gold),
        const SizedBox(height: 15),
        Text(_ar ? 'حكايات WorldVoice' : 'WorldVoice Storybook',
          style: const TextStyle(color: Color(0xFFFFE6B9),
              letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        AcademyIllustratedStoryArt(
          scene: widget.story.scene, page: 0),
        const SizedBox(height: 25),
        Text(widget.story.title, textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 27,
              height: 1.3, fontWeight: FontWeight.w900)),
        const SizedBox(height: 9),
        Text(widget.story.titleAr, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE0F3EB), fontSize: 20)),
        const SizedBox(height: 22),
        Text(_ar ? 'قصة مصوّرة • 4 فقرات • قراءة واستماع'
            : 'Illustrated • 4 chapters • read and listen',
            style: const TextStyle(color: _gold)),
      ]),
    ),
  );

  Widget _chapter(ColorScheme scheme) {
    final current = widget.story.pages[_page];
    return Container(
      key: ValueKey('storybook-chapter-$_page'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        color: Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHigh : _paper,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListView(padding: const EdgeInsets.all(17), children: [
        Row(children: [
          const Icon(Icons.menu_book_rounded, color: _ink),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _ar ? 'الفصل ${_page + 1} من ${widget.story.pages.length}'
                : 'Chapter ${_page + 1} of ${widget.story.pages.length}',
            style: TextStyle(fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant))),
          IconButton(
            tooltip: _ar ? 'إظهار الترجمة' : 'Show translation',
            onPressed: () => setState(() => _translate = !_translate),
            icon: const Icon(Icons.translate_rounded),
          ),
        ]),
        const SizedBox(height: 12),
        AcademyIllustratedStoryArt(
          scene: widget.story.scene, page: _page),
        const SizedBox(height: 22),
        Text(current.text, textDirection: TextDirection.ltr,
          style: TextStyle(color: scheme.onSurface, fontSize: 21,
              height: 1.7, fontWeight: FontWeight.w500)),
        const SizedBox(height: 19),
        if (_translate)
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: scheme.primaryContainer.withValues(alpha: .55)),
            child: Text(current.arabic, textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface,
                  fontSize: 17, height: 1.65)),
          ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 7, children: [
          FilledButton.icon(
            onPressed: () => _say(current.text),
            icon: Icon(_speaking
                ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
            label: Text(_ar ? 'اقرأ لي' : 'Narrate'),
            style: FilledButton.styleFrom(
              backgroundColor: _ink, foregroundColor: Colors.white),
          ),
          OutlinedButton.icon(
            onPressed: () => _say(current.text, slow: true),
            icon: const Icon(Icons.slow_motion_video_rounded),
            label: Text(_ar ? 'ببطء' : 'Slow'),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _question(ColorScheme scheme) {
    return Container(
      key: const ValueKey('storybook-quiz'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        color: scheme.surfaceContainerLow,
      ),
      child: ListView(padding: const EdgeInsets.all(19), children: [
        const Icon(Icons.emoji_events_rounded, color: _gold, size: 52),
        const SizedBox(height: 14),
        Text(_ar ? 'ماذا فهمت من الحكاية؟' : 'What did you understand?',
          textAlign: TextAlign.center, style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 22)),
        const SizedBox(height: 18),
        Text(widget.story.question, textDirection: TextDirection.ltr,
          style: const TextStyle(fontWeight: FontWeight.w800,
              fontSize: 21, height: 1.5)),
        const SizedBox(height: 17),
        for (var i = 0; i < widget.story.options.length; i++)
          Padding(padding: const EdgeInsets.only(bottom: 11),
            child: OutlinedButton(
              onPressed: _passed ? null : () => setState(() {
                _answer = i;
                _checked = false;
              }),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: _answer == i
                    ? scheme.primaryContainer : scheme.surface),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(widget.story.options[i],
                  style: TextStyle(color: scheme.onSurface, fontSize: 17))),
            )),
        if (_checked)
          Padding(padding: const EdgeInsets.all(13),
            child: Text(_passed
                ? (_ar ? 'أحسنت! فهمت القصة.' : 'Great reading!')
                : (_ar ? 'إجابة غير صحيحة. حاول مجددًا.'
                    : 'Try another answer.'),
              style: TextStyle(fontWeight: FontWeight.w800,
                  color: _passed ? _ink : scheme.error))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _ink, foregroundColor: Colors.white,
        title: Text(_ar ? 'القراءة الممتعة' : 'Storytime'),
      ),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
        child: Column(children: [
          LinearProgressIndicator(
            value: (_page + 2) / (widget.story.pages.length + 2),
            minHeight: 7, borderRadius: BorderRadius.circular(7),
            color: _ink, backgroundColor: scheme.surfaceContainerHighest),
          const SizedBox(height: 13),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation, child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(.08, 0), end: Offset.zero)
                    .animate(animation), child: child,
              ),
            ),
            child: _page < 0 ? _cover(scheme)
              : _quiz ? _question(scheme) : _chapter(scheme),
          )),
          const SizedBox(height: 13),
          Row(children: [
            if (_page > -1)
              OutlinedButton.icon(
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(_ar ? 'السابق' : 'Previous'),
              ),
            const Spacer(),
            FilledButton.icon(
              key: const ValueKey('english-story-next'),
              onPressed: _quiz
                  ? _answer == null ? null
                    : _passed ? () => Navigator.pop(context, true)
                    : () => setState(() => _checked = true)
                  : () => _move(1),
              icon: Icon(_passed ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded),
              style: FilledButton.styleFrom(
                  backgroundColor: _ink, foregroundColor: Colors.white),
              label: Text(_quiz
                  ? (_passed
                      ? (_ar ? 'تم فهم القصة' : 'Finish story')
                      : (_ar ? 'تحقق' : 'Check answer'))
                  : (_ar ? 'التالي' : 'Next')),
            ),
          ]),
        ]),
      )),
    );
  }
}
