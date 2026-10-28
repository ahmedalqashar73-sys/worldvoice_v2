import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_catalog.dart';
import '../data/academy_story_catalog.dart';

const _bookGreen = Color(0xFF155C46);
const _bookGold = Color(0xFFE8BE72);

/// A page-turning reader that uses original content, accessible typography,
/// optional Arabic assistance and target-language speech. Returns true only
/// after the learner answers a comprehension question correctly.
class AcademyStoryReader extends StatefulWidget {
  const AcademyStoryReader({required this.unit, super.key});
  final AcademyUnit unit;

  @override
  State<AcademyStoryReader> createState() => _AcademyStoryReaderState();
}

class _AcademyStoryReaderState extends State<AcademyStoryReader> {
  late final AcademyStoryBook _story = AcademyStoryCatalog.forUnit(widget.unit);
  late final FlutterTts _tts;
  final PageController _controller = PageController();
  int _page = 0;
  int? _answer;
  bool _checked = false;
  bool _showTranslation = false;
  bool _speaking = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  bool get _quiz => _page == _story.pages.length + 1;
  int get _total => _story.pages.length + 2;

  String get _locale => switch (widget.unit.language) {
    'en' => 'en-US',
    'es' => 'es-ES',
    'fr' => 'fr-FR',
    'zh' => 'zh-CN',
    'ko' => 'ko-KR',
    _ => widget.unit.language,
  };

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setCompletionHandler(_stopSpeaking);
    _tts.setCancelHandler(_stopSpeaking);
    _tts.setErrorHandler((_) => _stopSpeaking());
  }

  void _stopSpeaking() {
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _speak(String text, {bool slow = false}) async {
    try {
      if (_speaking) {
        await _tts.stop();
        if (mounted) setState(() => _speaking = false);
        if (!slow) return;
      }
      if (!mounted) return;
      setState(() => _speaking = true);
      final supportsLanguage = await _tts.isLanguageAvailable(_locale);
      if (supportsLanguage == false) {
        throw StateError('Target language voice is not available');
      }
      await _tts.setLanguage(_locale);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(slow ? .30 : .50);
      final result = await _tts.speak(text);
      if (result == 0) throw StateError('TTS start failed');
    } catch (_) {
      if (!mounted) return;
      _stopSpeaking();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_arabic
            ? 'صوت هذه اللغة غير متوفر. ثبّت حزمة الصوت من إعدادات الهاتف.'
            : 'Install the voice for this language in device settings.'),
      ));
    }
  }

  Future<void> _stopAudioSafely() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Page turns never wait for a speech engine.
    }
  }

  void _move(int next) {
    if (next < 0 || next >= _total) return;
    _stopAudioSafely();
    setState(() {
      _page = next;
      _speaking = false;
      _showTranslation = false;
    });
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  Widget _cover() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4839), Color(0xFF197D62)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded,
              color: _bookGold, size: 46),
          const SizedBox(height: 24),
          Text(_story.coverSymbol, style: const TextStyle(fontSize: 92)),
          const SizedBox(height: 26),
          Text(_story.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900,
                height: 1.28,
              )),
          const SizedBox(height: 12),
          Text(_story.titleArabic,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE8F5EE), fontSize: 18)),
          const SizedBox(height: 35),
          Text(
            _arabic
                ? 'قصة قصيرة • ${_story.pages.length} صفحات'
                : 'A short story • ${_story.pages.length} pages',
            style: const TextStyle(color: _bookGold,
                fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _glossary() {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 7, runSpacing: 7,
      children: [
        for (final word in widget.unit.words)
          ActionChip(
            label: Text(word.term, textDirection: TextDirection.ltr),
            avatar: const Icon(Icons.menu_book_rounded, size: 16),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (sheetContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(word.term,
                        style: TextStyle(fontSize: 26,
                            color: scheme.onSurface, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(word.pronunciation, style: const TextStyle(
                          fontSize: 18, color: _bookGreen)),
                      const SizedBox(height: 9),
                      Text(word.arabic,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: scheme.onSurface, fontSize: 18)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _speak(word.term),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Text(_arabic ? 'استمع للكلمة' : 'Hear the word'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _readingPage(int index) {
    final page = _story.pages[index];
    final scheme = Theme.of(context).colorScheme;
    final night = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(minHeight: 330),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          color: night ? scheme.surfaceContainerHigh : const Color(0xFFFFFDF6),
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.menu_book_outlined, color: _bookGold),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _arabic ? 'صفحة ${index + 1}' : 'Page ${index + 1}',
                style: TextStyle(color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700),
              )),
              IconButton(
                tooltip: _arabic ? 'إظهار أو إخفاء الترجمة' : 'Toggle translation',
                onPressed: () => setState(() => _showTranslation = !_showTranslation),
                icon: const Icon(Icons.translate_rounded),
              ),
            ]),
            const SizedBox(height: 24),
            SelectableText(
              page.text,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 23, height: 1.85,
                color: scheme.onSurface, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            if (_showTranslation)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(page.arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 17, height: 1.6,
                        color: scheme.onSurface)),
              ),
            const SizedBox(height: 18),
            Wrap(spacing: 8, children: [
              FilledButton.icon(
                onPressed: () => _speak(page.text),
                icon: Icon(_speaking ? Icons.stop_rounded
                    : Icons.volume_up_rounded),
                label: Text(_arabic ? 'استمع' : 'Listen'),
                style: FilledButton.styleFrom(
                  backgroundColor: _bookGreen, foregroundColor: Colors.white),
              ),
              OutlinedButton.icon(
                onPressed: () => _speak(page.text, slow: true),
                icon: const Icon(Icons.slow_motion_video_rounded),
                label: Text(_arabic ? 'ببطء' : 'Slow'),
              ),
            ]),
            const SizedBox(height: 20),
            Text(_arabic ? 'مفردات الدرس' : 'Lesson vocabulary',
              style: TextStyle(color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            _glossary(),
          ],
        ),
      ),
    );
  }

  Widget _quizPage() {
    final scheme = Theme.of(context).colorScheme;
    final correct = _checked && _answer == _story.correctIndex;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.emoji_events_outlined,
              size: 62, color: _bookGold),
          const SizedBox(height: 10),
          Text(_arabic ? 'هل فهمت القصة؟' : 'Did you understand?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Text(_story.question,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.4,
                  color: scheme.onSurface, fontWeight: FontWeight.w800)),
          if (_arabic) ...[
            const SizedBox(height: 5),
            Text(_story.questionArabic, textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 24),
          for (var i = 0; i < _story.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: correct ? null : () => setState(() {
                  _answer = i;
                  _checked = false;
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(17),
                  alignment: AlignmentDirectional.centerStart,
                  backgroundColor: _answer == i
                      ? scheme.primaryContainer : scheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_story.options[i], textDirection: TextDirection.ltr,
                        style: TextStyle(color: scheme.onSurface,
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    if (_arabic)
                      Text(_story.optionsArabic[i],
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          if (_checked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(correct
                  ? (_arabic ? 'ممتاز! فهمت القصة.' : 'Excellent! You understood.')
                  : (_arabic ? 'حاول مرة أخرى واقرأ الصفحة السابقة.'
                      : 'Try again and reread the story.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: correct ? _bookGreen : scheme.error,
                )),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _answer == null ? null
                : correct ? () => Navigator.of(context).pop(true)
                : () => setState(() => _checked = true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _bookGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(correct
                ? (_arabic ? 'أنهي القصة واحفظ التقدم' : 'Finish and save progress')
                : (_arabic ? 'تحقق من الإجابة' : 'Check my answer')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_arabic ? 'مكتبة WorldVoice' : 'WorldVoice Storybooks',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: _arabic ? 'إغلاق القصة' : 'Close story',
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 17),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_page + 1) / _total,
                      minHeight: 7,
                      color: _bookGreen,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_page + 1} / $_total',
                  style: TextStyle(color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 15),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _total,
                  itemBuilder: (context, index) {
                    if (index == 0) return _cover();
                    if (index == _total - 1) return _quizPage();
                    return _readingPage(index - 1);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                if (_page > 0)
                  OutlinedButton.icon(
                    onPressed: () => _move(_page - 1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(_arabic ? 'السابق' : 'Back'),
                  ),
                const Spacer(),
                if (!_quiz)
                  FilledButton.icon(
                    onPressed: () => _move(_page + 1),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_page == 0
                        ? (_arabic ? 'ابدأ القراءة' : 'Start reading')
                        : (_arabic ? 'الصفحة التالية' : 'Next page')),
                    style: FilledButton.styleFrom(
                      backgroundColor: _bookGreen, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
