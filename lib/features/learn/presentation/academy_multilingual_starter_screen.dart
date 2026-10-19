import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_multilingual_starters.dart';
import 'academy_illustrated_story_art.dart';

const _academyGreen = Color(0xFF145A45);

/// A small but complete, language-specific first lesson. The original target
/// language is always spoken in the target locale; no Arabic TTS substitution.
/// This pilot does not alter legacy Firestore progress IDs or room settings.
class AcademyGuidedStartScreen extends StatefulWidget {
  const AcademyGuidedStartScreen({required this.lesson, super.key});
  final AcademyGuidedStart lesson;

  @override
  State<AcademyGuidedStartScreen> createState() => _AcademyGuidedStartScreenState();
}

class _AcademyGuidedStartScreenState extends State<AcademyGuidedStartScreen> {
  final FlutterTts _tts = FlutterTts();
  int _questionIndex = 0;
  int? _answer;
  bool _checked = false;
  bool _saved = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String get _ttsLocale => switch (widget.lesson.code) {
    'es' => 'es-ES',
    'fr' => 'fr-FR',
    'zh' => 'zh-CN',
    'ko' => 'ko-KR',
    _ => 'en-US',
  };
  String get _progressKey =>
      'worldvoice.academy.starter.v1.${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}.${widget.lesson.code}';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _saved = prefs.getBool(_progressKey) ?? false);
  }

  Future<void> _speak(String content, {bool slow = false}) async {
    try {
      await _tts.stop();
      final installed = await _tts.isLanguageAvailable(_ttsLocale);
      if (installed == false) throw StateError('Target voice unavailable');
      await _tts.setLanguage(_ttsLocale);
      await _tts.setVolume(1);
      await _tts.setSpeechRate(slow ? .30 : .50);
      final started = await _tts.speak(content);
      if (started == 0) throw StateError('Speech did not start');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'ثبّت صوت هذه اللغة في إعدادات تحويل النص إلى كلام على جهازك.'
            : 'Install this language voice in your device text-to-speech settings.'),
      ));
    }
  }

  Future<void> _checkQuestion() async {
    if (_answer == null) return;
    final current = widget.lesson.checks[_questionIndex];
    if (_answer != current.answer) {
      setState(() => _checked = true);
      return;
    }
    if (_questionIndex < widget.lesson.checks.length - 1) {
      setState(() {
        _questionIndex++;
        _answer = null;
        _checked = false;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(_progressKey, true);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _checked = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved
          ? (_ar ? 'أحسنت! حُفظ هذا الدرس على الجهاز.' :
              'Well done! Your lesson is saved on this device.')
          : (_ar ? 'اكتمل الاختبار ولكن الحفظ على الجهاز فشل.' :
              'Quiz passed, but device progress could not be saved.')),
    ));
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Widget _section({
    required String title, required IconData icon,
    required Widget content, bool expanded = false, Key? key,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface, elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ExpansionTile(
        key: key,
        initiallyExpanded: expanded,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: _academyGreen)),
        title: Text(title, style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 17)),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
        children: [content],
      ),
    );
  }

  Widget _audio(String text) => Wrap(spacing: 8, children: [
    FilledButton.tonalIcon(
      onPressed: () => _speak(text),
      icon: const Icon(Icons.volume_up_rounded),
      label: Text(_ar ? 'استمع' : 'Listen'),
    ),
    OutlinedButton.icon(
      onPressed: () => _speak(text, slow: true),
      icon: const Icon(Icons.slow_motion_video_rounded),
      label: Text(_ar ? 'ببطء' : 'Slow'),
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final scheme = Theme.of(context).colorScheme;
    final current = lesson.checks[_questionIndex];
    final textColor = scheme.onSurface;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DE9C5) : _academyGreen;
    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson.name} · A1'),
        backgroundColor: _academyGreen, foregroundColor: Colors.white,
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 15, 17, 25),
        children: [
          Text(_ar ? lesson.titleArabic : lesson.title,
            style: TextStyle(color: accent,
              fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_ar
              ? 'درس أول متكامل · قواعد · 20 كلمة · محادثة · قصة · استماع · اختبار'
              : 'First guided lesson · grammar · 20 words · dialogue · story · listening · quiz',
            style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          _section(
            key: const ValueKey('academy-guided-grammar'),
            title: _ar ? '1. شرح القواعد' : '1. Grammar explanation',
            icon: Icons.school_rounded, expanded: true,
            content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(lesson.grammar, textDirection: TextDirection.ltr,
                style: TextStyle(color: textColor,
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1.5)),
              const SizedBox(height: 12),
              Text(_ar ? lesson.grammarArabic : lesson.grammarEnglish,
                style: TextStyle(color: textColor, fontSize: 16, height: 1.6)),
              const SizedBox(height: 12),
              _audio(lesson.grammar),
            ]),
          ),
          _section(
            key: const ValueKey('academy-guided-words'),
            title: _ar ? '2. تعلم 20 مفردة' : '2. Learn 20 words',
            icon: Icons.menu_book_rounded,
            content: Column(children: [
              for (var i = 0; i < lesson.words.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(lesson.words[i].term,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: textColor,
                              fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(lesson.words[i].phonetic,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: accent, fontSize: 14)),
                        Text(lesson.words[i].arabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    )),
                    IconButton(
                      tooltip: _ar ? 'استمع للكلمة' : 'Hear word',
                      onPressed: () => _speak(lesson.words[i].term),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ]),
                ),
            ]),
          ),
          _section(
            key: const ValueKey('academy-guided-conversation'),
            title: _ar ? '3. محادثة مع المعلم' : '3. Guided conversation',
            icon: Icons.forum_rounded,
            content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SelectableText(lesson.dialogue,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: textColor, fontSize: 18, height: 1.7)),
              const SizedBox(height: 13),
              _audio(lesson.dialogue),
            ]),
          ),
          _section(
            key: const ValueKey('academy-guided-story'),
            title: _ar ? '4. قصة قصيرة مصورة' : '4. Illustrated short story',
            icon: Icons.auto_stories_rounded,
            content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AcademyIllustratedStoryArt(
                scene: switch (lesson.code) {
                  'es' => 0, 'fr' => 1, 'zh' => 4, _ => 5,
                },
                page: 1, animate: false,
              ),
              const SizedBox(height: 15),
              for (var i = 0; i < lesson.story.length; i++) ...[
                SelectableText(lesson.story[i],
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: textColor, fontSize: 18, height: 1.65)),
                const SizedBox(height: 8),
                Text(_ar ? lesson.storyArabic[i] : '',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: scheme.onSurfaceVariant,
                      fontSize: 14, height: 1.5)),
                const SizedBox(height: 14),
              ],
              _audio(lesson.story.join(' ')),
            ]),
          ),
          _section(
            key: const ValueKey('academy-guided-quiz'),
            title: _ar ? '5. اختبار فهم الدرس' : '5. Lesson knowledge check',
            icon: Icons.fact_check_rounded,
            content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${_ar ? 'السؤال' : 'Question'} ${_questionIndex + 1} / ${lesson.checks.length}',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(current.question, textDirection: TextDirection.ltr,
                style: TextStyle(color: textColor,
                    fontSize: 19, height: 1.6)),
              const SizedBox(height: 12),
              for (var i = 0; i < current.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: OutlinedButton(
                    onPressed: _saved ? null : () => setState(() {
                      _answer = i; _checked = false;
                    }),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _answer == i
                          ? scheme.primaryContainer : scheme.surface,
                      minimumSize: const Size.fromHeight(55),
                    ),
                    child: Align(alignment: AlignmentDirectional.centerStart,
                      child: Text(current.options[i], textDirection: TextDirection.ltr,
                          style: TextStyle(color: textColor))),
                  ),
                ),
              if (_checked)
                Text(_ar ? 'حاول مجددًا، ثم أكمل الأسئلة.'
                    : 'Try again before continuing.',
                  style: TextStyle(color: scheme.error)),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('academy-guided-submit'),
                onPressed: _saved || _answer == null ? null : _checkQuestion,
                style: FilledButton.styleFrom(
                  backgroundColor: _academyGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52)),
                icon: Icon(_saved
                    ? Icons.check_circle_rounded : Icons.task_alt_rounded),
                label: Text(_saved
                    ? (_ar ? 'اكتمل هذا الدرس' : 'Lesson completed')
                    : (_ar ? 'تحقق وتابع' : 'Check and continue')),
              ),
            ]),
          ),
          Text(_ar
              ? 'الإنجاز محفوظ على هذا الجهاز فقط، ولم تتم مزامنته مع Firebase.'
              : 'Completion is stored only on this device, not synchronized to Firebase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      )),
    );
  }
}
