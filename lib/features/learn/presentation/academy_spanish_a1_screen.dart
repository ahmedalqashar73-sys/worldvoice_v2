import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_spanish_a1_course.dart';
import '../data/academy_spanish_a2_course.dart';
import '../data/academy_spanish_b1_course.dart';
import '../data/academy_spanish_b2_course.dart';
import 'academy_illustrated_story_art.dart';

const _verde = Color(0xFF15583F);
const _oro = Color(0xFFECC887);

/// Account-isolated offline completion, independent from the legacy
/// six-activity Academy format and from English A1 progress.
abstract final class SpanishA1Progress {
  static String _key(String? uid, {String level = 'A1'}) =>
      'worldvoice.academy.es.${level.toLowerCase()}.integrated.v1.${uid ?? 'guest'}.done';

  static Future<Set<String>> load(String? uid, {String level = 'A1'}) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(uid, level: level)) ?? <String>[]).toSet();
  }

  static Future<void> complete(String? uid, SpanishA1Lesson lesson,
      {String level = 'A1'}) async {
    final accepted = level == 'B2'
        ? SpanishB2Course.lessons.any((x) => x.id == lesson.id)
        : level == 'B1'
        ? SpanishB1Course.lessons.any((x) => x.id == lesson.id)
        : level == 'A2'
        ? SpanishA2Course.lessons.any((x) => x.id == lesson.id)
        : level == 'A1' && SpanishA1Course.lessons.any((x) => x.id == lesson.id);
    if (!accepted) {
      throw ArgumentError.value(lesson.id, 'lesson', 'Unknown Spanish lesson');
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _key(uid, level: level);
    final completed = (prefs.getStringList(key) ?? <String>[]).toSet()
      ..add(lesson.id);
    if (!await prefs.setStringList(key, completed.toList()..sort())) {
      throw StateError('Unable to save Spanish $level progress locally');
    }
  }
}

/// Spanish A1, A2, B1 and B2: each keeps three units and ten lessons per unit.
class AcademySpanishA1Path extends StatefulWidget {
  const AcademySpanishA1Path({this.level = 'A1', super.key});
  final String level;

  @override
  State<AcademySpanishA1Path> createState() => _SpanishA1PathState();
}

class _SpanishA1PathState extends State<AcademySpanishA1Path> {
  Set<String> _completed = <String>{};

  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final completed = await SpanishA1Progress.load(_uid, level: widget.level);
    if (mounted) setState(() => _completed = completed);
  }

  Future<void> _unit(SpanishA1Unit unit) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _SpanishUnitScreen(unit: unit, level: widget.level)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_ar
          ? 'الإسبانية ${widget.level} · ${widget.level == 'A1' ? 'المبتدئ' : widget.level == 'A2' ? 'الابتدائي' : widget.level == 'B1' ? 'المتوسط' : 'فوق المتوسط'}'
          : 'Español ${widget.level} · ${widget.level == 'A1' ? 'Beginner' : widget.level == 'A2' ? 'Elementary' : widget.level == 'B1' ? 'Intermediate' : 'Upper-intermediate'}'),
      backgroundColor: _verde, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF124C37), Color(0xFF268C67)]),
          borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.auto_stories_rounded, color: _oro, size: 42),
          const SizedBox(height: 11),
          Text(_ar ? (widget.level == 'A1'
              ? 'رحلتك الأولى باللغة الإسبانية'
              : 'واصل رحلتك في الإسبانية')
              : (widget.level == 'A1'
                  ? 'Tu aventura en español'
                  : 'Tu siguiente paso en español'),
            style: const TextStyle(color: Colors.white,
                fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('${widget.level}  ·  3 UNIDADES  ·  30 LECCIONES',
            style: const TextStyle(color: _oro, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(_ar ? '${_completed.length} من 30 درسًا مكتملًا'
              : '${_completed.length} of 30 lessons completed',
            style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _completed.length / 30,
            color: _oro, backgroundColor: Colors.white24),
        ]),
      ),
      const SizedBox(height: 20),
      for (final unit in widget.level == 'B2'
          ? SpanishB2Course.units : widget.level == 'B1'
          ? SpanishB1Course.units : widget.level == 'A2'
              ? SpanishA2Course.units : SpanishA1Course.units)
        Card(clipBehavior: Clip.antiAlias,
          child: ListTile(
            key: ValueKey('spanish-${widget.level.toLowerCase()}-unit-${unit.number}'),
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(backgroundColor: _verde,
              child: Text('${unit.number}',
                style: const TextStyle(color: Colors.white))),
            title: Text(unit.title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
              _ar ? '${unit.arabic} · 10 دروس' : '10 lessons · 400 word slots'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _unit(unit),
          )),
    ]),
  );
}

class _SpanishUnitScreen extends StatefulWidget {
  const _SpanishUnitScreen({required this.unit, required this.level});
  final SpanishA1Unit unit;
  final String level;

  @override
  State<_SpanishUnitScreen> createState() => _SpanishUnitScreenState();
}

class _SpanishUnitScreenState extends State<_SpanishUnitScreen> {
  Set<String> _completed = <String>{};
  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final data = await SpanishA1Progress.load(_uid, level: widget.level);
    if (mounted) setState(() => _completed = data);
  }

  Future<void> _open(SpanishA1Lesson lesson) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => AcademySpanishA1LessonScreen(
        lesson: lesson, level: widget.level)));
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.unit.title),
        backgroundColor: _verde, foregroundColor: Colors.white),
    body: ListView(
      padding: const EdgeInsets.all(15),
      children: [
        Text(_ar ? widget.unit.arabic : widget.unit.title,
          style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        for (final lesson in widget.unit.lessons)
          Card(child: ListTile(
            key: ValueKey('spanish-${widget.level.toLowerCase()}-lesson-${lesson.unit}-${lesson.number}'),
            leading: CircleAvatar(backgroundColor: _verde.withValues(alpha: .1),
              child: Text('${lesson.number}',
                style: const TextStyle(color: _verde))),
            title: Text(lesson.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(_ar ? lesson.titleAr : '40 words · Grammar · Story'),
            trailing: Icon(_completed.contains(lesson.id)
                ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: _verde),
            onTap: () => _open(lesson),
          )),
      ]),
  );
}

/// Eight sequential classroom sections, identical in intent to English A1:
/// grammar, vocabulary, illustrated story, word checks, dialogue, pronunciation,
/// podcast listening and confirmed completion.
class AcademySpanishA1LessonScreen extends StatefulWidget {
  const AcademySpanishA1LessonScreen({
    required this.lesson, this.level = 'A1', super.key});
  final SpanishA1Lesson lesson;
  final String level;

  @override
  State<AcademySpanishA1LessonScreen> createState() =>
      _AcademySpanishA1LessonScreenState();
}

class _AcademySpanishA1LessonScreenState
    extends State<AcademySpanishA1LessonScreen> {
  final FlutterTts _tts = FlutterTts();
  int _stage = 0;
  int _highestUnlocked = 0;
  final Set<int> _passed = <int>{};
  int? _choice;
  bool _checked = false;
  int _wordIndex = 0;
  bool _saving = false;
  bool _complete = false;
  bool _transcript = false;

  static const _arNames = <String>[
    'شرح القواعد', '40 مفردة', 'القصة المصورة', 'اختبار الكلمات',
    'المحادثة', 'النطق', 'الاستماع والبودكاست', 'اكتمال الدرس',
  ];
  static const _esNames = <String>[
    'Gramática', 'Vocabulario', 'Historia ilustrada', 'Repaso',
    'Conversación', 'Pronunciación', 'Pódcast y escucha', 'Completado',
  ];

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await SpanishA1Progress.load(_uid, level: widget.level);
    if (mounted) setState(() => _complete = saved.contains(widget.lesson.id));
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String value, {bool slow = false}) async {
    try {
      await _tts.stop();
      if (await _tts.isLanguageAvailable('es-ES') == false) {
        throw StateError('Spanish speech package unavailable');
      }
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(slow ? .32 : .48);
      await _tts.setVolume(1);
      if (await _tts.speak(value) == 0) {
        throw StateError('Speech not started');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ar
          ? 'ثبّت صوت الإسبانية من إعدادات تحويل النص إلى كلام ثم جرّب مرة أخرى.'
          : 'Install an es-ES text-to-speech voice and try again.')));
    }
  }

  void _choose(int next) => setState(() {
    if (next <= _highestUnlocked) {
      _stage = next;
      _choice = null;
      _checked = false;
    }
  });

  void _pass() {
    setState(() {
      _passed.add(_stage);
      _highestUnlocked = (_stage + 1).clamp(0, 7);
      _stage = _highestUnlocked;
      _choice = null;
      _checked = false;
      _wordIndex = 0;
    });
  }

  Future<void> _finish() async {
    if (_saving || _passed.length < 7) return;
    setState(() => _saving = true);
    try {
      await SpanishA1Progress.complete(
          _uid, widget.lesson, level: widget.level);
      if (mounted) {
        setState(() => _complete = true);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          _ar ? 'تعذر حفظ التقدم على الجهاز.' :
          'Lesson completion could not be saved on this device.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _panel(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Padding(padding: const EdgeInsets.all(16), child: child));

  Widget _primary(String label, VoidCallback? onTap,
      {Key? key, IconData icon = Icons.arrow_forward_rounded}) =>
    Padding(
      padding: const EdgeInsets.only(top: 14),
      child: FilledButton.icon(
        key: key, onPressed: onTap,
        icon: Icon(icon), label: Text(label),
        style: FilledButton.styleFrom(
            backgroundColor: _verde, foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52))),
    );

  /// Modern accessible multiple-choice control. Avoid deprecated RadioListTile
  /// groupValue/onChanged API, keep the question state in this lesson alone.
  Widget _option(String label, int index, String keyPrefix) =>
      Card(child: ListTile(
        key: ValueKey('$keyPrefix-$index'),
        title: Text(label, textDirection: TextDirection.ltr),
        leading: Icon(_choice == index
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
            color: _choice == index ? _verde : null),
        selected: _choice == index,
        onTap: () => setState(() {
          _choice = index;
          _checked = false;
        }),
      ));

  Widget _audio(String text, {bool slow = false}) =>
      IconButton(tooltip: _ar ? 'استمع للإسبانية' : 'Hear Spanish',
        onPressed: () => _speak(text, slow: slow),
        icon: const Icon(Icons.volume_up_rounded));

  Widget _grammar() {
    final item = widget.lesson;
    final examples = item.grammarExamples;
    final choices = widget.level == 'B2'
        ? SpanishB2Course.grammarOptions(widget.lesson as SpanishB2Lesson)
        : widget.level == 'B1'
        ? SpanishB1Course.grammarOptions(widget.lesson as SpanishB1Lesson)
        : widget.level == 'A2'
        ? SpanishA2Course.grammarOptions(widget.lesson as SpanishA2Lesson)
        : <String>['Yo es una estudiantes.', examples[0], 'Tú soy la libros.'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_rounded, color: Color(0xFFB48A46)),
        Text(_ar ? 'قاعدة واحدة · خطوة بخطوة' :
            'Una regla · paso a paso',
          style: const TextStyle(color: _verde, fontWeight: FontWeight.w900,
            fontSize: 21)),
        const SizedBox(height: 12),
        Text(item.grammar, style: const TextStyle(
          fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 8),
        Text(item.grammarAr, style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        Text(item.grammarHelpAr, style: const TextStyle(height: 1.8)),
        const SizedBox(height: 8),
        const Text('1 · Comprende     2 · Observa     3 · Practica',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ])),
      Text(_ar ? 'أمثلة مشروحة بالصوت' : 'Ejemplos con audio',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      for (final e in examples)
        _panel(Row(children: [
          Expanded(child: Text(e, textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 17))),
          _audio(e),
        ])),
      Text(_ar ? 'اختر الجملة الصحيحة' : 'Elige la frase correcta',
        style: const TextStyle(fontWeight: FontWeight.w900)),
      for (var i = 0; i < choices.length; i++)
        _option(choices[i], i, 'spanish-grammar-option'),
      if (_checked)
        Text(_choice == 1 ? (_ar ? 'صحيح!' : '¡Correcto!') :
          (_ar ? 'راجع القاعدة وحاول مرة أخرى.' : 'Inténtalo otra vez.'),
          style: TextStyle(color: _choice == 1 ? _verde :
              Theme.of(context).colorScheme.error)),
      _primary(_ar ? 'تحقق ثم تابع' : 'Comprueba y continúa',
        _choice == null ? null : () {
          if (_choice == 1) {
            _pass();
          } else {
            setState(() => _checked = true);
          }
        }, key: const ValueKey('spanish-grammar-check')),
    ]);
  }

  Widget _vocabulary() {
    final words = widget.lesson.words;
    const labels = <SpanishWordKind, (String, String)>{
      SpanishWordKind.noun: ('Sustantivos', 'الأسماء'),
      SpanishWordKind.verb: ('Verbos', 'الأفعال'),
      SpanishWordKind.adjective: ('Adjetivos', 'الصفات'),
      SpanishWordKind.adverb: ('Adverbios', 'الظروف'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? '40 كلمة في أربع مجموعات' :
          '40 palabras · cuatro categorías',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
            color: _verde)),
      const SizedBox(height: 10),
      for (final kind in SpanishWordKind.values) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 12, bottom: 7),
          decoration: BoxDecoration(color: _verde,
            borderRadius: BorderRadius.circular(13)),
          child: Text(_ar ? '${labels[kind]!.$2} · 10' :
            '${labels[kind]!.$1} · 10',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900))),
        for (final word in words.where((w) => w.kind == kind))
          ListTile(
            key: ValueKey('spanish-word-${word.es}'),
            title: Text(word.es, textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(word.ar),
            trailing: _audio(word.es)),
      ],
      _primary(_ar ? 'راجعت المفردات الأربعين' : 'He repasado 40 palabras',
        _pass, key: const ValueKey('spanish-vocabulary-next')),
    ]);
  }

  Widget _story() {
    final lesson = widget.lesson;
    final paragraphs = widget.level == 'B2'
        ? SpanishB2Course.reading(lesson as SpanishB2Lesson)
        : widget.level == 'B1'
        ? SpanishB1Course.reading(lesson as SpanishB1Lesson)
        : widget.level == 'A2'
        ? SpanishA2Course.reading(lesson as SpanishA2Lesson)
        : SpanishA1Course.reading(lesson);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        key: const ValueKey('spanish-story-cover'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF113F33), Color(0xFF2D8868)]),
          borderRadius: BorderRadius.circular(22)),
        child: Column(children: [
          const Icon(Icons.auto_stories, color: _oro, size: 40),
          const SizedBox(height: 8),
          Text('WORLDVOICE · ESPAÑOL ${widget.level}',
            style: const TextStyle(color: _oro, letterSpacing: 1.4)),
          const SizedBox(height: 12),
          Text(lesson.title, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white,
              fontFamily: 'serif', fontWeight: FontWeight.w900,
              fontSize: 26)),
          const SizedBox(height: 8),
          Text(lesson.titleAr, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
        ])),
      const SizedBox(height: 13),
      for (var i = 0; i < paragraphs.length; i++) ...[
        if (i == 0 || i == 2)
          AcademyIllustratedStoryArt(
            scene: ((lesson.unit - 1) * 10 + lesson.number - 1) % 9,
            page: i + 1, animate: false),
        _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(_ar ? 'الصفحة ${i+1}' : 'PÁGINA ${i+1}',
              style: const TextStyle(color: _verde,
                  fontWeight: FontWeight.w900)),
            const Spacer(), _audio(paragraphs[i]),
          ]),
          SelectableText(paragraphs[i],
            key: ValueKey('spanish-story-paragraph-$i'),
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontFamily: 'serif',
                fontSize: 19, height: 1.75)),
        ])),
      ],
      Wrap(spacing: 8, children: [
        FilledButton.tonalIcon(
          onPressed: () => _speak(paragraphs.join(' ')),
          icon: const Icon(Icons.headphones_rounded),
          label: Text(_ar ? 'استمع للقصة كاملة' : 'Escuchar la historia')),
        OutlinedButton.icon(
          onPressed: () => _speak(paragraphs.join(' '), slow: true),
          icon: const Icon(Icons.slow_motion_video_rounded),
          label: Text(_ar ? 'استماع بطيء' : 'Más despacio')),
      ]),
      const SizedBox(height: 10),
      Text(_ar ? 'اقرأ القصة وانتبه للكلمات التي تعلمتها.'
          : 'Lee y busca las palabras nuevas.'),
      _primary(_ar ? 'قرأت القصة' : 'He leído la historia', _pass,
        key: const ValueKey('spanish-story-next')),
    ]);
  }

  Widget _quiz() {
    final kinds = SpanishWordKind.values;
    final kind = kinds[_wordIndex % kinds.length];
    final selected = SpanishA1Course.wordsOf(widget.lesson, kind);
    final word = selected[_wordIndex ~/ 4];
    final answers = <String>[
      word.ar,
      selected[(2 + _wordIndex) % selected.length].ar,
      selected[(5 + _wordIndex) % selected.length].ar,
    ];
    final correct = _wordIndex % 3;
    final options = <String>[answers[1], answers[2]]
      ..insert(correct, answers[0]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'اختبار الكلمات · ${_wordIndex + 1}/8' :
          'Repaso · ${_wordIndex + 1}/8',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      _panel(Row(children: [
        Expanded(child: Text(word.es,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
        _audio(word.es),
      ])),
      Text(_ar ? 'ما المعنى الصحيح؟' : '¿Qué significa?'),
      for (var i = 0; i < options.length; i++)
        _option(options[i], i, 'spanish-quiz-option'),
      if (_checked)
        Text(_ar ? 'الإجابة غير صحيحة، حاول مجددًا.' :
          'No es correcto. Inténtalo otra vez.'),
      _primary(_ar ? 'تحقق من الإجابة' : 'Comprobar respuesta',
        _choice == null ? null : () {
          if (_choice != correct) {
            setState(() => _checked = true);
          } else if (_wordIndex == 7) {
            _pass();
          } else {
            setState(() { _wordIndex++; _choice = null; _checked = false; });
          }
        }, key: const ValueKey('spanish-quiz-check')),
    ]);
  }

  Widget _conversation() {
    final dialogue = widget.level == 'B2'
        ? SpanishB2Course.conversation(widget.lesson as SpanishB2Lesson)
        : widget.level == 'B1'
        ? SpanishB1Course.conversation(widget.lesson as SpanishB1Lesson)
        : widget.level == 'A2'
        ? SpanishA2Course.conversation(widget.lesson as SpanishA2Lesson)
        : SpanishA1Course.dialogue(widget.lesson);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'محادثة تستخدم كلمات الدرس' :
          'Conversación con las palabras de hoy',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
      for (var i=0; i<dialogue.length; i++)
        Card(
          color: i.isEven ? const Color(0xFFE0F1E7) :
              Theme.of(context).colorScheme.surfaceContainerHigh,
          child: ListTile(
            title: Text(dialogue[i], textDirection: TextDirection.ltr,
                style: TextStyle(color: i.isEven ? _verde : null)),
            trailing: _audio(dialogue[i].split(': ').last),
          )),
      _primary(_ar ? 'تدربت على دوري في المحادثة' :
          'He practicado la conversación', _pass,
          key: const ValueKey('spanish-conversation-next')),
    ]);
  }

  Widget _pronunciation() {
    final words = widget.lesson.words.take(12).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'استمع ثم كرر بالإسبانية' : 'Escucha y repite',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      Text(_ar ? 'النطق هنا تدريب سماع وتكرار، ولا يوجد تقييم آلي للميكروفون.'
          : 'Listening and repetition only; microphone scoring is not enabled.'),
      for (final word in words)
        ListTile(
          title: Text(word.es, textDirection: TextDirection.ltr),
          subtitle: Text(word.ar), trailing: _audio(word.es, slow: true)),
      _primary(_ar ? 'تدربت على النطق' : 'He practicado la pronunciación',
        _pass, key: const ValueKey('spanish-pronunciation-next')),
    ]);
  }

  Widget _listening() {
    final episode = widget.level == 'B2'
        ? SpanishB2Course.podcast(widget.lesson as SpanishB2Lesson)
        : widget.level == 'B1'
        ? SpanishB1Course.podcast(widget.lesson as SpanishB1Lesson)
        : widget.level == 'A2'
        ? SpanishA2Course.podcast(widget.lesson as SpanishA2Lesson)
        : SpanishA1Course.podcast(widget.lesson);
    final nouns = SpanishA1Course.wordsOf(widget.lesson, SpanishWordKind.noun);
    final answers = <String>[nouns[0].ar, nouns[3].ar, nouns[6].ar];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.headphones_rounded, color: _verde, size: 40),
      Text(_ar ? 'بودكاست المفردات الأربعين' :
          'Pódcast de 40 palabras',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
      Text(_ar ? 'اسمع القصة والكلمات، ثم أجب عن السؤال.'
          : 'Escucha la historia y las palabras. Después responde.'),
      Wrap(spacing: 8, children: [
        FilledButton.tonalIcon(
          onPressed: () => _speak(episode),
          icon: const Icon(Icons.play_arrow),
          label: Text(_ar ? 'تشغيل البودكاست' : 'Reproducir pódcast')),
        OutlinedButton.icon(
          onPressed: () => _speak(episode, slow: true),
          icon: const Icon(Icons.slow_motion_video),
          label: Text(_ar ? 'ببطء' : 'Lento')),
        TextButton(onPressed: () => setState(() => _transcript = !_transcript),
          child: Text(_ar ? 'إظهار أو إخفاء النص' :
            'Mostrar u ocultar texto')),
      ]),
      if (_transcript) _panel(SelectableText(episode,
          textDirection: TextDirection.ltr)),
      const SizedBox(height: 15),
      Text(_ar ? 'ما معنى «${nouns[0].es}»؟' :
          '¿Qué significa «${nouns[0].es}»?'),
      for (var i=0;i<answers.length;i++)
        _option(answers[i], i, 'spanish-listening-option'),
      if (_checked)
        Text(_ar ? 'حاول مرة أخرى.' : 'Inténtalo otra vez.'),
      _primary(_ar ? 'تحقق ثم أكمل' : 'Comprobar y continuar',
        _choice == null ? null : () {
          if (_choice == 0) {
            _pass();
          } else {
            setState(() => _checked = true);
          }
        }, key: const ValueKey('spanish-listening-check')),
    ]);
  }

  Widget _completion() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.workspace_premium_rounded,
          color: Color(0xFFB8924D), size: 70),
      const SizedBox(height: 10),
      Text(_ar ? 'أحسنت! أكملت أقسام الدرس الثمانية.' :
          '¡Enhorabuena! Has completado la lección.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
      Text(_ar ? 'احفظ إنجازك للعودة إليه حتى بعد إغلاق التطبيق.'
          : 'Guarda tu progreso en este dispositivo.',
        textAlign: TextAlign.center),
      _primary(_complete
          ? (_ar ? 'الدرس محفوظ' : 'Lección guardada')
          : (_ar ? 'إنهاء الدرس وحفظ التقدم' : 'Terminar y guardar'),
          _saving || _complete || _passed.length != 7 ? null : _finish,
          key: ValueKey('spanish-${widget.level.toLowerCase()}-finish'),
          icon: Icons.check_circle_rounded),
    ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: _verde, foregroundColor: Colors.white,
      title: Text('Español ${widget.level} · ${widget.lesson.unit}.${widget.lesson.number}'),
      actions: [
        IconButton(
          tooltip: _ar ? 'عرض الأقسام' : 'Secciones',
          onPressed: () => showModalBottomSheet<void>(
            context: context, builder: (sheetContext) => SafeArea(
              child: ListView(shrinkWrap: true, children: [
                for (var i = 0; i < 8; i++)
                  ListTile(
                    title: Text(_ar ? _arNames[i] : _esNames[i]),
                    leading: Icon(i < _highestUnlocked
                        ? Icons.check_circle : Icons.lock_outline),
                    enabled: i <= _highestUnlocked,
                    onTap: i <= _highestUnlocked ? () {
                      Navigator.pop(sheetContext); _choose(i);
                    } : null),
              ]))),
          icon: const Icon(Icons.view_list_rounded)),
      ]),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 28),
      children: [
        Text(widget.lesson.title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900,
              color: _verde)),
        const SizedBox(height: 5),
        Text(_arNames[_stage], textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 9),
        LinearProgressIndicator(value: _stage / 7,
          color: _verde, borderRadius: BorderRadius.circular(6)),
        const SizedBox(height: 16),
        switch(_stage) {
          0 => _grammar(),
          1 => _vocabulary(),
          2 => _story(),
          3 => _quiz(),
          4 => _conversation(),
          5 => _pronunciation(),
          6 => _listening(),
          _ => _completion(),
        },
      ],
    )),
  );
}
