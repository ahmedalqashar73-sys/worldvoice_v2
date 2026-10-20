import 'academy_spanish_a1_course.dart';

/// Spanish C2: a separate thirty-lesson syllabus with advanced reading,
/// oral argument and CEFR-scoped completion IDs. Shared B2-stage UI retained.
class SpanishC2Lesson extends SpanishA1Lesson {
  const SpanishC2Lesson({
    required this.level,
    required super.unit,
    required super.number,
    required super.title,
    required super.titleAr,
    required super.grammar,
    required super.grammarAr,
    required super.grammarHelpAr,
    required super.grammarExamples,
    required super.story,
    required this.grammarMistakes,
  });
  final String level;
  final List<String> grammarMistakes;
  @override
  String get id => 'worldvoice.es.${level.toLowerCase()}.u$unit.l${number.toString().padLeft(2, '0')}';
  @override
  List<SpanishA1Word> get words => SpanishC2Course.wordsFor(unit,number);
}

class SpanishC2Unit extends SpanishA1Unit {
  const SpanishC2Unit(super.number,super.title,super.arabic);
  @override
  List<SpanishC2Lesson> get lessons => SpanishC2Course.lessons
      .where((e)=>e.unit==number).toList(growable:false);
}

abstract final class SpanishC2Course {
  static const units=<SpanishC2Unit>[
    SpanishC2Unit(1,'Lenguaje, texto e historia','اللغة والنص والتاريخ'),
    SpanishC2Unit(2,'Filosofía y razonamiento ético','الفلسفة والمنطق الأخلاقي'),
    SpanishC2Unit(3,'Investigación y análisis crítico','البحث والتحليل النقدي'),
  ];
  static const _core=<SpanishWordKind,String>{
    SpanishWordKind.noun: "epistemología|نظرية المعرفة;hermenéutica|علم التأويل;indeterminación|عدم التعيين;presuposición|افتراض مسبق;anacronismo|مفارقة زمنية;paradoja|مفارقة;contrafactual|افتراض مضاد للواقع;ontología|علم الوجود;discurso|خطاب;metarrelato|سردية كبرى;intertextualidad|التناص;disonancia|تنافر;hegemonía|هيمنة;contingencia|احتمال غير حتمي;dialéctica|جدلية;paradigma|نموذج فكري;axioma|مسلّمة;falibilidad|قابلية الخطأ;subjetividad|ذاتية;exégesis|تفسير نقدي للنص",
    SpanishWordKind.verb: "problematizar|يجعل موضع إشكال;deconstruir|يفكك نقديًا;sintetizar|يركب الأفكار;interrogar|يفحص نقديًا;destacar|يبرز;matizar|يقيد الحكم;delimitar|يحدد النطاق;desestabilizar|يزعزع;yuxtaponer|يضع جنبًا إلى جنب;extrapolar|يستقرئ;conciliar|يوفق;fundamentar|يسند بالأدلة;explicitar|يوضح بالتفصيل;dilucidar|يجلي;impugnar|يطعن في;desentrañar|يفك التعقيد;conceptualizar|يصوغ مفهومًا;reformular|يعيد الصياغة;escudriñar|يمحص;contextualizar|يضع في السياق",
    SpanishWordKind.adjective: "epistémico|معرفي;hermenéutico|تأويلي;axiomático|مسلمي;dialéctico|جدلي;ontológico|وجودي;equívoco|ملتبس;inconmensurable|غير قابل للقياس بمعيار مشترك;discursivo|خطابي;contingente|غير حتمي;paradójico|مفارقي;apodíctico|قطعي البرهان;intersubjetivo|بين ذاتي;interpretativo|تفسيري;teleológico|غائي;normativo|معياري;reduccionista|اختزالي;polisémico|متعدد الدلالات;autorreferencial|ذاتي الإحالة;anacrónico|خارج السياق الزمني;irreductible|متعذر الاختزال",
    SpanishWordKind.adverb: "epistémicamente|معرفيًا;hermenéuticamente|تأويليًا;dialécticamente|جدليًا;ostensiblemente|ظاهريًا;tácitamente|ضمنيًا;inequívocamente|بلا لبس;categóricamente|بصورة قاطعة;provisionalmente|مبدئيًا;coherentemente|بتماسك;incisivamente|بنفاذ نقدي;oblicuamente|بصورة غير مباشرة;normativamente|معياريًا;discursivamente|خطابيًا;intrínsecamente|جوهريًا;contingentemente|بصورة غير حتمية;reflexivamente|بمراجعة ذاتية;comparativamente|بالمقارنة;meticulosamente|بدقة فائقة;tentativamente|مؤقتًا;paradójicamente|بصورة مفارقة",
  };
  static const _focused=<int,Map<SpanishWordKind,String>>{
    1:<SpanishWordKind,String>{
    SpanishWordKind.noun: "crítica textual|نقد نصي;variante textual|تنويع نصي;anotación marginal|تعليق هامشي;paleografía|علم الخطوط القديمة;palimpsesto|مخطوطة معاد استخدامها;atribución|إسناد;cronología|تسلسل زمني;testimonio presencial|شهادة شاهد عيان;procedencia|منشأ;historiografía|كتابة التاريخ",
    SpanishWordKind.verb: "cotejar|يقارن النسخ;autentificar|يثبت الأصالة;anotar|يشرح هامشيًا;transcribir|ينسخ نصيًا;enmendar|يصحح النص;descifrar|يفك الرموز;reconstruir|يعيد البناء;historizar|يضع في سياقه التاريخي;traducir|يترجم;datar|يحدد زمنًا",
    SpanishWordKind.adjective: "archivístico|أرشيفي;fragmentario|مجتزأ;controvertido|متنازع عليه;apócrifo|منحول;auténtico|أصيل;inconcluyente|غير حاسم;arcaico|قديم الأسلوب;diacrónico|متعاقب تاريخيًا;filológico|فقه لغوي;polifónico|متعدد الأصوات",
    SpanishWordKind.adverb: "históricamente|تاريخيًا;anacrónicamente|خارج السياق الزمني;cronológicamente|بالتسلسل الزمني;filológicamente|وفق فقه اللغة;retrospectivamente|بأثر رجعي;secuencialmente|بالتتابع;intertextualmente|تناصيًا;textualmente|نصيًا;archivísticamente|أرشيفيًا;fielmente|بأمانة",
    },
    2:<SpanishWordKind,String>{
    SpanishWordKind.noun: "agencia ética|فاعلية أخلاقية;culpabilidad moral|مسؤولية أخلاقية;justicia distributiva|عدالة توزيعية;razón pública|تعليل عمومي;eufemismo|تلطيف لفظي;entimema|قياس مضمر;encuadre retórico|تأطير بلاغي;legitimación|إضفاء الشرعية;azar moral|الحظ الأخلاقي;reciprocidad|المعاملة بالمثل",
    SpanishWordKind.verb: "atribuir|ينسب;legitimar|يضفي شرعية;racionalizar|يبرر عقلانيًا;atenuar|يلطف التعبير;implicar|يقتضي;reivindicar|يثبت الحق;presuponer|يفترض سلفًا;universalizar|يعمم;arbitrar|يفصل في نزاع;instrumentalizar|يستخدم كوسيلة",
    SpanishWordKind.adjective: "ético|أخلاقي;justificativo|تبريري;retórico|بلاغي;coercitivo|قسري;deliberativo|تداولي;distributivo|توزيعي;consecuencialista|نتائجي أخلاقيًا;deontológico|واجباتي أخلاقيًا;paternalista|أبوي متسلط;dialógico|حواري",
    SpanishWordKind.adverb: "éticamente|أخلاقيًا;retóricamente|بلاغيًا;deliberativamente|بالمداولة;pragmáticamente|عمليًا;coercitivamente|بالإكراه;equitativamente|بإنصاف;moralmente|من الناحية الأخلاقية;procedimentalmente|إجرائيًا;estratégicamente|استراتيجيًا;persuasivamente|بإقناع",
    },
    3:<SpanishWordKind,String>{
    SpanishWordKind.noun: "atribución causal|إسناد سببي;brecha explicativa|فجوة تفسيرية;límite disciplinar|حد تخصصي;consenso académico|إجماع علمي;carga de la prueba|عبء الإثبات;inferencia formal|استدلال صوري;contraejemplo|مثال ناقض;umbral probatorio|حد كفاية الدليل;pluralismo metodológico|تعدد المناهج;implicación lógica|اقتضاء منطقي",
    SpanishWordKind.verb: "desambiguar|يزيل الالتباس;operacionalizar|يحول إلى متغير قابل للقياس;formalizar|يصوغ رسميًا;falsar|يدحض باختبار;ejemplificar|يضرب مثالًا;triangular|يتحقق من عدة مصادر;generalizar|يعمم;calibrar|يعاير;corroborar|يدعم بدليل مستقل;reinterpretar|يعيد التأويل",
    SpanishWordKind.adjective: "interdisciplinario|متعدد التخصصات;inferencial|استدلالي;causalmente sólido|متين سببيًا;refutable|قابل للدحض;generalizable|قابل للتعميم;explicativo|تفسيري;conceptual|مفاهيمي;probabilístico|احتمالي;analítico|تحليلي;metodológicamente válido|سليم منهجيًا",
    SpanishWordKind.adverb: "analíticamente|تحليليًا;probabilísticamente|احتماليًا;metodológicamente|منهجيًا;teóricamente|نظريًا;empíricamente|تجريبيًا;causalmente|سببيًا;inferencialmente|استدلاليًا;cautelosamente|بحذر;rigurosamente|بصرامة منهجية;sistemáticamente|بمنهجية",
    },
  };
  static List<SpanishA1Word> wordsFor(int unit,int number){
    if(unit<1||unit>3||number<1||number>10)throw RangeError('C1 unit/lesson');
    final result=<SpanishA1Word>[];
    for(final kind in SpanishWordKind.values){
      final a=_core[kind]!.split(';');
      final b=_focused[unit]![kind]!.split(';');
      for(var i=0;i<5;i++){
        final core=a[((number-1)*3+i)%a.length].split('|');
        final local=b[((number-1)*3+i)%b.length].split('|');
        result.add(SpanishA1Word(core[0].trim(),core[1].trim(),kind));
        result.add(SpanishA1Word(local[0].trim(),local[1].trim(),kind));
      }
    }
    return List<SpanishA1Word>.unmodifiable(result);
  }
  static List<SpanishA1Word> wordsOf(SpanishC2Lesson lesson,SpanishWordKind kind)=>
      lesson.words.where((w)=>w.kind==kind).toList(growable:false);
  static const lessons=<SpanishC2Lesson>[
    // C2_AUTHORING
  ];
  static SpanishC2Lesson find(int unit,int number)=>lessons.firstWhere(
    (l)=>l.unit==unit&&l.number==number);
  static List<String> grammarOptions(SpanishC2Lesson lesson)=>
      <String>[lesson.grammarMistakes.first,lesson.grammarExamples.first,
               lesson.grammarMistakes.last];

  /// The original six paragraphs stay intact; two advanced analytic
  /// pages provide evidence-based interpretation and vocabulary transfer.
  static List<String> reading(SpanishC2Lesson lesson){
    final n=wordsOf(lesson,SpanishWordKind.noun);
    final v=wordsOf(lesson,SpanishWordKind.verb);
    final a=wordsOf(lesson,SpanishWordKind.adjective);
    final d=wordsOf(lesson,SpanishWordKind.adverb);
    return <String>[
      ...lesson.story,
      'Al revisar los acontecimientos de «${lesson.title}», los participantes '
      'identificaron la importancia de «${n[0].es}» y «${n[1].es}». '
      'La primera interpretación parecía «${a[0].es}», pero una segunda '
      'lectura introducía una perspectiva «${a[1].es}». '
      'El grupo acordó ${v[0].es} la información ${d[0].es} antes de '
      'presentar una conclusión. También intentó ${v[1].es} '
      '${d[1].es}, aunque reconoció que ningún testimonio aislado '
      'constituía una prueba definitiva. Aquella discusión permitió '
      'distinguir los hechos documentados de las suposiciones '
      'y formular preguntas más productivas.',
      'La reunión final se centró en las consecuencias de cada propuesta. '
      'Dos expresiones, «${n[2].es}» y «${n[3].es}», aparecieron '
      'en el informe; los redactores las definieron cuidadosamente '
      'para evitar interpretaciones contradictorias. '
      'Al evaluar la decisión decidieron ${v[2].es} la evidencia '
      '${d[2].es} y ${v[3].es} las objeciones ${d[3].es}. '
      'La conclusión no eliminó todas las dudas: explicó qué '
      'condiciones justificarían una revisión futura. '
      'Así, el relato terminó sin confundir prudencia con indecisión '
      'ni el desacuerdo razonado con una falta de respeto.',
    ];
  }
  static List<String> conversation(SpanishC2Lesson lesson){
    final n=wordsOf(lesson,SpanishWordKind.noun);
    final v=wordsOf(lesson,SpanishWordKind.verb);
    final a=wordsOf(lesson,SpanishWordKind.adjective);
    final d=wordsOf(lesson,SpanishWordKind.adverb);
    return <String>[
      'Editora: ¿Hasta qué punto la «${n[0].es}» fundamenta '
          'la interpretación de «${lesson.title}»?',
      'Investigador: Debemos examinar también la «${n[1].es}», '
          'porque un relato ${a[0].es} puede ocultar otras perspectivas.',
      'Editora: ¿Qué evidencia refutaría tu hipótesis?',
      'Investigador: Antes de decidir, habría que ${v[0].es} '
          'los testimonios ${d[0].es}.',
      'Editora: ¿Y si el segundo argumento resultara ${a[1].es}?',
      'Investigador: Procuraría ${v[1].es} las interpretaciones '
          '${d[1].es}, sin ignorar sus contradicciones.',
      'Editora: Formula una conclusión que reconozca los límites.',
      'Investigador: La aceptaría provisionalmente y señalaría '
          'qué nueva información podría obligarnos a revisarla.',
    ];
  }
  static String podcast(SpanishC2Lesson lesson){
    final bank=SpanishWordKind.values.map((kind){
      final label=switch(kind){
        SpanishWordKind.noun=>'sustantivos',
        SpanishWordKind.verb=>'verbos',
        SpanishWordKind.adjective=>'adjetivos',
        SpanishWordKind.adverb=>'adverbios',
      };
      return 'Diez $label: ${wordsOf(lesson,kind).map((w)=>w.es).join(', ')}. ';
    }).join();
    return 'Bienvenidos al seminario oral de WorldVoice, español ${lesson.level}. '
      'El tema de hoy es ${lesson.title}. ${lesson.story.join(' ')} '
      'No basta con recordar los datos. Analiza la relación entre '
      'las fuentes, los supuestos y las consecuencias, y formula '
      'una objeción fundamentada antes de concluir. '
      '$bank '
      'Vuelve a escuchar e intenta utilizar los términos nuevos '
      'en un argumento coherente con la regla ${lesson.grammar}.';
  }
}
