import 'package:flutter/material.dart';

import '../data/academy_catalog.dart';

/// An eight-item preliminary study recommendation, NOT a CEFR certificate.
/// High-level writing and speaking require a separate human-validated test.
class AcademyPlacementQuestion {
  const AcademyPlacementQuestion(
      this.prompt, this.options, this.correctIndex);
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

abstract final class AcademyPlacementCatalog {
  static List<AcademyPlacementQuestion> forLanguage(String code) =>
      _questions[code] ?? _questions['en']!;

  static const _questions = <String, List<AcademyPlacementQuestion>>{
    'en': [
      AcademyPlacementQuestion('Choose the greeting.', ['Hello', 'Table', 'Yesterday'], 0),
      AcademyPlacementQuestion('I ___ a student.', ['is', 'am', 'are'], 1),
      AcademyPlacementQuestion('She ___ English every day.', ['study', 'studies', 'studying'], 1),
      AcademyPlacementQuestion('We ___ to the market yesterday.', ['went', 'go', 'going'], 0),
      AcademyPlacementQuestion('If I have time, I ___ you.', ['call', 'called', 'will call'], 2),
      AcademyPlacementQuestion('The book ___ by millions.', ['has been read', 'have reading', 'has read'], 0),
      AcademyPlacementQuestion('Despite ___ tired, she continued.', ['be', 'being', 'was'], 1),
      AcademyPlacementQuestion('Choose the natural inversion.', ['Hardly had I arrived when it rained.', 'Hardly I had arrived when it rained.', 'Hardly arrived I when it rained.'], 0),
    ],
    'es': [
      AcademyPlacementQuestion('¿Cómo se dice «مرحبًا»?', ['Adiós', 'Hola', 'Amigo'], 1),
      AcademyPlacementQuestion('Yo ___ Ana.', ['soy', 'es', 'son'], 0),
      AcademyPlacementQuestion('Ella ___ español cada día.', ['estudio', 'estudia', 'estudiar'], 1),
      AcademyPlacementQuestion('Ayer ___ al mercado.', ['voy', 'fui', 'iré'], 1),
      AcademyPlacementQuestion('Si tengo tiempo, te ___.', ['llamé', 'llamando', 'llamaré'], 2),
      AcademyPlacementQuestion('Espero que tú ___ bien.', ['estás', 'estés', 'estar'], 1),
      AcademyPlacementQuestion('Aunque ___ cansada, siguió trabajando.', ['estaba', 'está', 'estar'], 0),
      AcademyPlacementQuestion('Si lo hubiera sabido, te ___.', ['habría llamado', 'llamaré', 'llamo'], 0),
    ],
    'zh': [
      AcademyPlacementQuestion('哪个词是“你好”？', ['再见', '谢谢', '你好'], 2),
      AcademyPlacementQuestion('“我___学生。”', ['是', '有', '在'], 0),
      AcademyPlacementQuestion('“我每天___中文。”', ['学习', '学生', '学会了'], 0),
      AcademyPlacementQuestion('“昨天我___学校。”', ['去', '去了', '去过了明天'], 1),
      AcademyPlacementQuestion('如果明天下雨，我们___在家。', ['就', '了', '过'], 0),
      AcademyPlacementQuestion('这个问题已经被老师___了。', ['解决', '解决着', '解决过的'], 0),
      AcademyPlacementQuestion('尽管天气不好，他___坚持跑步。', ['还是', '却是的', '不但了'], 0),
      AcademyPlacementQuestion('选择自然的句子。', ['他不但会写，还会说。', '他会不但写，说还会。', '不但他写还会说会。'], 0),
    ],
    'fr': [
      AcademyPlacementQuestion('Choisissez une salutation.', ['Bonjour', 'Merci', 'Livre'], 0),
      AcademyPlacementQuestion('Je ___ étudiant.', ['suis', 'es', 'sommes'], 0),
      AcademyPlacementQuestion('Elle ___ français tous les jours.', ['étudie', 'étudies', 'étudier'], 0),
      AcademyPlacementQuestion('Hier, je ___ au marché.', ['vais', 'suis allé', 'irai'], 1),
      AcademyPlacementQuestion('Si j’ai le temps, je t’___.', ['appellerai', 'appelle hier', 'appelais demain'], 0),
      AcademyPlacementQuestion('Il faut que tu ___ là.', ['es', 'sois', 'être'], 1),
      AcademyPlacementQuestion('Bien qu’il ___ fatigué, il continue.', ['soit', 'est', 'être'], 0),
      AcademyPlacementQuestion('Si je l’avais su, je t’___ prévenu.', ['aurais', 'ai', 'avais'], 0),
    ],
    'ko': [
      AcademyPlacementQuestion('어떤 말이 인사인가요?', ['안녕하세요', '감사합니다', '책'], 0),
      AcademyPlacementQuestion('저는 학생___ .', ['이에요', '해요', '가요'], 0),
      AcademyPlacementQuestion('저는 매일 한국어를 ___.', ['공부해요', '학교예요', '있어요'], 0),
      AcademyPlacementQuestion('어제 학교에 ___.', ['가요', '갔어요', '갈 거예요'], 1),
      AcademyPlacementQuestion('시간이 있으면 같이 ___.', ['가요', '갔었어요', '가는 중이었어요'], 0),
      AcademyPlacementQuestion('오늘은 비가 올 ___ 같아요.', ['것', '수', '적'], 0),
      AcademyPlacementQuestion('피곤한데도 끝까지 ___.', ['했어요', '하는 중에만', '하도록만'], 0),
      AcademyPlacementQuestion('그 사실을 알았더라면 미리 ___.', ['말했을 거예요', '말해요', '말했어요 지금'], 0),
    ],
  };

  static String recommendedLevel(int score) {
    if (score >= 7) return 'B2';
    if (score >= 5) return 'B1';
    if (score >= 3) return 'A2';
    return 'A1';
  }
}

class AcademyPlacementScreen extends StatefulWidget {
  const AcademyPlacementScreen({required this.course, super.key});
  final AcademyCourse course;

  @override
  State<AcademyPlacementScreen> createState() => _AcademyPlacementScreenState();
}

class _AcademyPlacementScreenState extends State<AcademyPlacementScreen> {
  int _index = 0;
  int? _selected;
  int _correct = 0;
  String? _recommendation;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  List<AcademyPlacementQuestion> get _questions =>
      AcademyPlacementCatalog.forLanguage(widget.course.code);

  void _next() {
    final question = _questions[_index];
    if (_selected == question.correctIndex) _correct++;
    if (_index == _questions.length - 1) {
      setState(() => _recommendation =
          AcademyPlacementCatalog.recommendedLevel(_correct));
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF145C44);
    return Scaffold(
      appBar: AppBar(title: Text(_arabic
          ? 'اختبار تحديد المستوى' : 'Placement assessment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Icon(Icons.school_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${widget.course.flag} ${widget.course.nativeName}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              )),
            ]),
            const SizedBox(height: 18),
            if (_recommendation != null) ...[
              const Icon(Icons.workspace_premium_rounded,
                  size: 68, color: green),
              const SizedBox(height: 18),
              Text(_arabic ? 'مستواك المبدئي المقترح' : 'Suggested starting point',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(_recommendation!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 62, fontWeight: FontWeight.w900,
                      color: green)),
              const SizedBox(height: 10),
              Text(
                _arabic
                    ? 'هذه نتيجة تمهيدية من 8 أسئلة، وليست شهادة CEFR. تقييم التحدث والكتابة ضروري لتحديد المستوى بدقة. الدروس المتاحة حاليًا من A1.'
                    : 'This 8-question suggestion is not a CEFR certification. Speaking and writing need separate assessment. Currently published lessons are in A1.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 25),
              FilledButton(
                key: const ValueKey('academy-placement-done'),
                onPressed: () => Navigator.of(context).pop(_recommendation),
                style: FilledButton.styleFrom(backgroundColor: green,
                    minimumSize: const Size.fromHeight(55)),
                child: Text(_arabic ? 'ادخل خطة التعلم' : 'Open learning plan'),
              ),
            ] else ...[
              Text(_arabic
                  ? 'أجب عن 8 أسئلة قصيرة لنقترح عليك نقطة البداية المناسبة. يمكنك التخطي.'
                  : 'Answer 8 short questions to estimate a starting point. You may skip.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6)),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: (_index + 1) / _questions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 9),
              Text(_arabic
                  ? 'السؤال ${_index + 1} من ${_questions.length}'
                  : 'Question ${_index + 1} of ${_questions.length}'),
              const SizedBox(height: 25),
              Text(_questions[_index].prompt,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 23, height: 1.6,
                    fontWeight: FontWeight.w800, color: scheme.onSurface)),
              const SizedBox(height: 22),
              ...List.generate(_questions[_index].options.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selected = i),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selected == i
                          ? scheme.primaryContainer : scheme.surface,
                      minimumSize: const Size.fromHeight(62),
                      side: BorderSide(color: _selected == i
                          ? green : scheme.outlineVariant),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(_questions[_index].options[i],
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: scheme.onSurface, fontSize: 17)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),
              FilledButton(
                key: const ValueKey('academy-placement-next'),
                onPressed: _selected == null ? null : _next,
                style: FilledButton.styleFrom(backgroundColor: green,
                    minimumSize: const Size.fromHeight(54)),
                child: Text(_index == _questions.length - 1
                    ? (_arabic ? 'اعرض نتيجتي' : 'Show my result')
                    : (_arabic ? 'السؤال التالي' : 'Next question')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('A1'),
                child: Text(_arabic ? 'تخطي والبدء من A1' : 'Skip and start from A1'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
