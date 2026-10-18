import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_catalog.dart';

const _dialogueGreen = Color(0xFF155C46);

class _DialogueTurn {
  const _DialogueTurn({
    required this.speaker,
    required this.prompt,
    required this.hintArabic,
    required this.options,
    required this.correctIndex,
  });
  final String speaker;
  final String prompt;
  final String hintArabic;
  final List<String> options;
  final int correctIndex;
}

/// A scripted, interactive first conversation for each currently published
/// Academy course. Never pretends to be free-form AI or voice recognition.
class AcademyFirstConversation extends StatefulWidget {
  const AcademyFirstConversation({required this.course, super.key});
  final AcademyCourse course;

  @override
  State<AcademyFirstConversation> createState() =>
      _AcademyFirstConversationState();
}

class _AcademyFirstConversationState extends State<AcademyFirstConversation> {
  late final FlutterTts _tts;
  int _step = 0;
  int? _selected;
  bool _checked = false;
  bool _speaking = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  String get _locale => switch (widget.course.code) {
    'en' => 'en-US',
    'es' => 'es-ES',
    'zh' => 'zh-CN',
    'fr' => 'fr-FR',
    'ko' => 'ko-KR',
    _ => widget.course.code,
  };

  static const _turns = <String, List<_DialogueTurn>>{
    'en': [
      _DialogueTurn(speaker: 'Emma', prompt: 'Hello! My name is Emma. What is your name?',
        hintArabic: 'إيما تسألك عن اسمك. اختر ردًا مناسبًا.',
        options: ['Goodbye!', 'My name is Alex.', 'Thank you!'], correctIndex: 1),
      _DialogueTurn(speaker: 'Emma', prompt: 'Nice to meet you, Alex!',
        hintArabic: 'رد على ترحيب إيما.',
        options: ['Nice to meet you too!', 'I am a book.', 'Good night!'], correctIndex: 0),
      _DialogueTurn(speaker: 'Emma', prompt: 'How are you today?',
        hintArabic: 'أخبر إيما أنك بخير.',
        options: ['My name is seven.', 'The bus is blue.', 'I am fine, thanks!'], correctIndex: 2),
    ],
    'es': [
      _DialogueTurn(speaker: 'Ana', prompt: '¡Hola! Me llamo Ana. ¿Cómo te llamas?',
        hintArabic: 'آنا تسألك عن اسمك.',
        options: ['Me llamo Luis.', 'Adiós.', 'Buenas noches.'], correctIndex: 0),
      _DialogueTurn(speaker: 'Ana', prompt: '¡Mucho gusto, Luis!',
        hintArabic: 'رد على التعارف بطريقة مهذبة.',
        options: ['Soy una mesa.', 'Mucho gusto.', 'Hasta mañana.'], correctIndex: 1),
      _DialogueTurn(speaker: 'Ana', prompt: '¿Cómo estás?',
        hintArabic: 'أخبر آنا أنك بخير.',
        options: ['No me llamo.', 'Es un libro.', 'Estoy bien, gracias.'], correctIndex: 2),
    ],
    'zh': [
      _DialogueTurn(speaker: '小美', prompt: '你好！我叫小美。你叫什么名字？',
        hintArabic: 'شياو مي تسألك عن اسمك.',
        options: ['再见！', '我叫小明。', '谢谢！'], correctIndex: 1),
      _DialogueTurn(speaker: '小美', prompt: '很高兴认识你！',
        hintArabic: 'قل إنك سعيد بالتعارف أيضًا.',
        options: ['我也很高兴认识你！', '我是书。', '早上七点。'], correctIndex: 0),
      _DialogueTurn(speaker: '小美', prompt: '你好吗？',
        hintArabic: 'كيف تجيب بأنك بخير؟',
        options: ['那是我的书。', '我明天工作。', '我很好，谢谢！'], correctIndex: 2),
    ],
    'fr': [
      _DialogueTurn(speaker: 'Léa', prompt: 'Bonjour ! Je m’appelle Léa. Comment tu t’appelles ?',
        hintArabic: 'ليا تسألك عن اسمك.',
        options: ['Au revoir !', 'Je m’appelle Paul.', 'Merci.'], correctIndex: 1),
      _DialogueTurn(speaker: 'Léa', prompt: 'Enchantée, Paul !',
        hintArabic: 'أخبر ليا أنك تشرفت بمعرفتها.',
        options: ['Enchanté !', 'Je suis une chaise.', 'Bonsoir !'], correctIndex: 0),
      _DialogueTurn(speaker: 'Léa', prompt: 'Comment ça va ?',
        hintArabic: 'أخبر ليا أنك بخير.',
        options: ['Le livre est bleu.', 'Je m’appelle demain.', 'Ça va bien, merci !'], correctIndex: 2),
    ],
    'ko': [
      _DialogueTurn(speaker: '민지', prompt: '안녕하세요! 저는 민지예요. 이름이 뭐예요?',
        hintArabic: 'مينجي تسألك عن اسمك.',
        options: ['안녕히 가세요.', '저는 준호예요.', '감사합니다.'], correctIndex: 1),
      _DialogueTurn(speaker: '민지', prompt: '만나서 반가워요!',
        hintArabic: 'كيف تقول إنك سعيد بلقائها أيضًا؟',
        options: ['저도 반가워요!', '책이 있어요.', '아침이에요.'], correctIndex: 0),
      _DialogueTurn(speaker: '민지', prompt: '잘 지내세요?',
        hintArabic: 'كيف ترد أنك بخير؟',
        options: ['이름이 학교예요.', '책은 파란색이에요.', '네, 잘 지내요!'], correctIndex: 2),
    ],
  };

  List<_DialogueTurn> get _script => _turns[widget.course.code] ?? _turns['en']!;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setCompletionHandler(_stop);
    _tts.setCancelHandler(_stop);
    _tts.setErrorHandler((_) => _stop());
  }

  void _stop() {
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _hear(String message) async {
    try {
      await _tts.stop();
      if (!mounted) return;
      setState(() => _speaking = true);
      final supportsLanguage = await _tts.isLanguageAvailable(_locale);
      if (supportsLanguage == false) {
        throw StateError('Target language voice is not available');
      }
      await _tts.setLanguage(_locale);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(.44);
      final started = await _tts.speak(message);
      if (started == 0) throw StateError('TTS failed');
    } catch (_) {
      _stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_arabic ? 'ثبّت صوت هذه اللغة في إعدادات جهازك.'
            : 'Install this language voice in your device settings.'),
      ));
    }
  }

  Future<void> _stopAudioSafely() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Answer selection must not depend on speech-engine availability.
    }
  }

  void _next() {
    if (_step == _script.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    _stopAudioSafely();
    setState(() {
      _step++;
      _selected = null;
      _checked = false;
      _speaking = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final turn = _script[_step];
    final success = _checked && _selected == turn.correctIndex;
    final night = Theme.of(context).brightness == Brightness.dark;
    final accent = night ? const Color(0xFF9DECC4) : _dialogueGreen;
    return Scaffold(
      appBar: AppBar(
        title: Text(_arabic ? 'أول محادثة' : 'Your first conversation',
          style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          children: [
            Row(children: [
              Expanded(child: LinearProgressIndicator(
                value: (_step + 1) / _script.length,
                minHeight: 8, borderRadius: BorderRadius.circular(9),
                color: _dialogueGreen,
                backgroundColor: scheme.surfaceContainerHighest,
              )),
              const SizedBox(width: 10),
              Text('${_step + 1} / ${_script.length}',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 23),
            Text(
              _arabic ? 'تحدث مع ${turn.speaker}' : 'Talk with ${turn.speaker}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900, color: accent,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _arabic ? turn.hintArabic
                  : 'Listen and choose the best response.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 23),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: const Icon(Icons.face_rounded,
                  color: _dialogueGreen, size: 31)),
              const SizedBox(width: 10),
              Expanded(child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(turn.speaker,
                        style: TextStyle(color: accent,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Text(turn.prompt, textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: scheme.onSurface, fontSize: 20,
                          height: 1.5, fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 9),
                    IconButton.filledTonal(
                      tooltip: _arabic ? 'استمع للمحادثة' : 'Listen',
                      onPressed: () => _hear(turn.prompt),
                      icon: Icon(_speaking ? Icons.stop_rounded
                          : Icons.volume_up_rounded),
                    ),
                  ],
                ),
              )),
            ]),
            const SizedBox(height: 24),
            Text(_arabic ? 'ماذا سترد؟' : 'What will you say?',
                style: TextStyle(color: scheme.onSurface,
                    fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            for (var i = 0; i < turn.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: OutlinedButton(
                  onPressed: success ? null : () => setState(() {
                    _selected = i;
                    _checked = false;
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(66),
                    padding: const EdgeInsets.all(15),
                    side: BorderSide(color: _selected == i
                        ? accent : scheme.outlineVariant, width: 1.5),
                    backgroundColor: _selected == i
                        ? scheme.primaryContainer : scheme.surface,
                  ),
                  child: Align(alignment: AlignmentDirectional.centerStart,
                    child: Text(turn.options[i], textDirection: TextDirection.ltr,
                      style: TextStyle(color: scheme.onSurface,
                          fontSize: 17, fontWeight: FontWeight.w700))),
                ),
              ),
            if (_checked)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(success
                    ? (_arabic ? 'إجابة صحيحة! ممتاز 👏' : 'Correct! Great job 👏')
                    : (_arabic ? 'قريب! جرّب مرة ثانية.'
                        : 'Almost! Give it another try.'),
                  style: TextStyle(color: success ? accent : scheme.error,
                      fontWeight: FontWeight.w800, fontSize: 16))),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _selected == null ? null
                  : success ? _next : () => setState(() => _checked = true),
              style: FilledButton.styleFrom(
                backgroundColor: _dialogueGreen, foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54)),
              child: Text(success
                  ? (_step == _script.length - 1
                      ? (_arabic ? 'انتقل إلى المفردات' : 'Go to vocabulary')
                      : (_arabic ? 'المحادثة التالية' : 'Continue'))
                  : (_arabic ? 'تحقق من الرد' : 'Check my reply'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 14),
            Text(
              _arabic
                  ? 'هذا تدريب تفاعلي بإجابات محددة، وليس محادثة صوتية حرة.'
                  : 'This is guided response practice, not a live voice conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
