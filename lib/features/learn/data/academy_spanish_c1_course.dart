import 'academy_spanish_a1_course.dart';

/// Spanish C1: a separate thirty-lesson syllabus with advanced reading,
/// oral argument and CEFR-scoped completion IDs. Shared B2-stage UI retained.
class SpanishC1Lesson extends SpanishA1Lesson {
  const SpanishC1Lesson({
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
  List<SpanishA1Word> get words => SpanishC1Course.wordsFor(unit,number);
}

class SpanishC1Unit extends SpanishA1Unit {
  const SpanishC1Unit(super.number,super.title,super.arabic);
  @override
  List<SpanishC1Lesson> get lessons => SpanishC1Course.lessons
      .where((e)=>e.unit==number).toList(growable:false);
}

abstract final class SpanishC1Course {
  static const units=<SpanishC1Unit>[
    SpanishC1Unit(1,'Investigación y memoria','البحث العلمي والذاكرة'),
    SpanishC1Unit(2,'Ética y debate social','الأخلاق والنقاش الاجتماعي'),
    SpanishC1Unit(3,'Futuro y sostenibilidad','المستقبل والاستدامة'),
  ];
  static const _core=<SpanishWordKind,String>{
    SpanishWordKind.noun: "inferencia|استدلال;procedencia|منشأ;corroboración|تأييد مستقل;metodología|منهجية;discrepancia|تباين;deliberación|مداولة;legitimidad|مشروعية;ambigüedad|غموض;premisa|مقدمة حجاجية;repercusión|تداعٍ;matiz|فارق دقيق;contingencia|احتمال مشروط;atribución|إسناد;rendición de cuentas|مساءلة;consenso|إجماع;contraargumento|حجة مضادة;verosimilitud|معقولية;testimonio|شهادة;concesión|تنازل حجاجي;salvedad|تحفظ",
    SpanishWordKind.verb: "escrutar|يمحص;corroborar|يثبت بمصدر آخر;contextualizar|يضع في السياق;fundamentar|يسند بالدليل;conciliar|يوفق;dilucidar|يوضح;interrogar|يفحص نقديًا;reevaluar|يعيد التقييم;discernir|يميز;admitir|يقر;documentar|يوثق;reconstruir|يعيد بناء;impugnar|يطعن في;articular|يصوغ بدقة;matizar|يضيف تحفظًا;mediar|يتوسط;divulgar|يفصح;reconsiderar|يعيد النظر;diferenciar|يفرق;justificar|يبرر",
    SpanishWordKind.adjective: "provisional|مؤقت;controvertido|مثير للجدل;fidedigno|موثوق;metodológico|منهجي;ambiguo|ملتبس;defendible|يمكن الدفاع عنه;inconcluyente|غير حاسم;sistémico|نظامي;matizado|دقيق الفروق;convincente|مقنع;desproporcionado|غير متناسب;transparente|شفاف;tentativo|مبدئي;irreconciliable|متعذر التوفيق;infundado|غير مدعوم;contextual|سياقي;riguroso|صارم;multifacético|متعدد الجوانب;disputado|متنازع عليه;trascendental|ذو عواقب كبيرة",
    SpanishWordKind.adverb: "tentativamente|مبدئيًا;concluyentemente|بصورة حاسمة;explícitamente|صراحة;implícitamente|ضمنيًا;críticamente|نقديًا;sistemáticamente|بمنهجية;independientemente|باستقلالية;posiblemente|ربما;presuntamente|بحسب المزاعم;desproporcionadamente|بشكل غير متناسب;posteriormente|لاحقًا;no obstante|مع ذلك;en consecuencia|بناء عليه;presumiblemente|على الأرجح;provisionalmente|بصورة مؤقتة;sustancialmente|بشكل جوهري;por el contrario|على النقيض;empíricamente|تجريبيًا;inequívocamente|بلا لبس;prudentemente|بحكمة",
  };
  static const _focused=<int,Map<SpanishWordKind,String>>{
    $u:<SpanishWordKind,String>{
    SpanishWordKind.noun: "manuscrito|مخطوطة;objeto arqueológico|قطعة أثرية;archivo|أرشيف;repositorio|مستودع بحثي;protocolo|بروتوكول;conjunto de datos|مجموعة بيانات;hipótesis|فرضية;revisión por pares|تحكيم علمي;cronología|تسلسل زمني;consentimiento|موافقة مستنيرة",
    SpanishWordKind.verb: "autentificar|يوثق الأصالة;transcribir|ينسخ نصيًا;replicar|يكرر التجربة;triangular|يتحقق بمصادر متعددة;validar|يتحقق من صحة;anotar|يعلق;interpretar|يفسر;calibrar|يعاير;extrapolar|يستقرئ;verificar|يتحقق",
    SpanishWordKind.adjective: "archivístico|أرشيفي;revisado por pares|محكم علميًا;replicable|قابل للتكرار;no verificado|غير متحقق منه;longitudinal|طولي عبر الزمن;histórico|تاريخي;anómalo|شاذ;predictivo|تنبؤي;interdisciplinario|متعدد التخصصات;autentificado|موثق",
    SpanishWordKind.adverb: "históricamente|تاريخيًا;estadísticamente|إحصائيًا;científicamente|علميًا;retrospectivamente|بأثر رجعي;cronológicamente|حسب التسلسل;analíticamente|تحليليًا;experimentalmente|تجريبيًا;precisamente|بدقة;comparativamente|بالمقارنة;reproduciblemente|بشكل قابل للتكرار",
    },
    $u:<SpanishWordKind,String>{
    SpanishWordKind.noun: "restitución|استرداد مقتنيات;denunciante|مبلغ عن مخالفات;supervisión|رقابة;agravio|تظلم;custodia|حفظ مسؤول;mandato|تفويض;gobernanza|حوكمة;consulta|مشاورة;reparación|جبر ضرر;actor implicado|طرف معني",
    SpanishWordKind.verb: "legislar|يشرع;subsanar|يعالج الخلل;abogar|يناصر;regular|ينظم;consultar|يستشير;negociar|يتفاوض;representar|يمثل;salvaguardar|يصون;arbitrar|يفصل في النزاع;implementar|ينفذ",
    SpanishWordKind.adjective: "institucional|مؤسسي;equitativo|منصف;participativo|تشاركي;vinculante|ملزم;representativo|تمثيلي;deliberativo|تداولي;inclusivo|شامل;ilícito|غير قانوني;recíproco|متبادل;procedimental|إجرائي",
    SpanishWordKind.adverb: "jurídicamente|قانونيًا;institucionalmente|مؤسسيًا;colectivamente|جماعيًا;democráticamente|ديمقراطيًا;equitativamente|بعدل;formalmente|رسميًا;públicamente|علانية;transnacionalmente|عبر الحدود;colaborativamente|بالتعاون;éticamente|أخلاقيًا",
    },
    $u:<SpanishWordKind,String>{
    SpanishWordKind.noun: "resiliencia|قدرة على التكيف;ecosistema|نظام بيئي;contratación pública|مشتريات عامة;factor de confusión|متغير مربك;probabilidad|احتمال;emisiones|انبعاثات;distribución|توزيع;mitigación|تخفيف أضرار;adaptación|تكيف;disyuntiva|مفاضلة",
    SpanishWordKind.verb: "modelizar|ينمذج;pronosticar|يتنبأ;cuantificar|يحدد كميًا;mitigar|يخفف;diversificar|ينوع;asignar|يخصص;simular|يحاكي;supervisar|يراقب;evaluar|يقيّم;priorizar|يعطي الأولوية",
    SpanishWordKind.adjective: "ecológico|بيئي;probabilístico|احتمالي;climático|مناخي;resiliente|مرن; sostenible|مستدام;basado en datos|قائم على البيانات;contrafactual|افتراضي مضاد للواقع;mensurable|قابل للقياس;incierto|غير يقيني;adaptativo|تكيفي",
    SpanishWordKind.adverb: "medioambientalmente|بيئيًا;probabilísticamente|احتماليًا;regionalmente|إقليميًا;globalmente|عالميًا;cuantitativamente|كميًا;ecológicamente|بيئيًا من منظور النظام;económicamente|اقتصاديًا;gradualmente|تدريجيًا;estratégicamente|استراتيجيًا;previsiblemente|بشكل متوقع",
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
  static List<SpanishA1Word> wordsOf(SpanishC1Lesson lesson,SpanishWordKind kind)=>
      lesson.words.where((w)=>w.kind==kind).toList(growable:false);
  static const lessons=<SpanishC1Lesson>[
    // C1_AUTHORING
  ];
  static SpanishC1Lesson find(int unit,int number)=>lessons.firstWhere(
    (l)=>l.unit==unit&&l.number==number);
  static List<String> grammarOptions(SpanishC1Lesson lesson)=>
      <String>[lesson.grammarMistakes.first,lesson.grammarExamples.first,
               lesson.grammarMistakes.last];

  /// The original five/six paragraphs stay intact; two advanced analytic
  /// pages provide evidence-based interpretation and vocabulary transfer.
  static List<String> reading(SpanishC1Lesson lesson){
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
  static List<String> conversation(SpanishC1Lesson lesson){
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
  static String podcast(SpanishC1Lesson lesson){
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
