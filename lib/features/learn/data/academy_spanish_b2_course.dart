import 'academy_spanish_a1_course.dart';

/// Spanish B2 only. Keeps the shared illustrated reader and completion flow
/// without changing any of the earlier Spanish levels.
class SpanishB2Lesson extends SpanishA1Lesson {
  const SpanishB2Lesson({
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
  final List<String> grammarMistakes;
  @override
  String get id =>
      'worldvoice.es.b2.u$unit.l${number.toString().padLeft(2,'0')}';
  @override
  List<SpanishA1Word> get words => SpanishB2Course.wordsFor(unit, number);
}

class SpanishB2Unit extends SpanishA1Unit {
  const SpanishB2Unit(super.number, super.title, super.arabic);
  @override
  List<SpanishB2Lesson> get lessons => SpanishB2Course.lessons
      .where((lesson) => lesson.unit == number).toList(growable:false);
}

abstract final class SpanishB2Course {
  static const units=<SpanishB2Unit>[
    SpanishB2Unit(1,'Relatos y pensamiento crítico','السرد والتحليل والنقاش'),
    SpanishB2Unit(2,'Sociedad y cultura','المجتمع والثقافة والمسؤولية'),
    SpanishB2Unit(3,'Ciencia y decisiones','العلم والبيئة وصناعة القرار'),
  ];
  static const _core=<SpanishWordKind,String>{
    SpanishWordKind.noun: "planteamiento|طرح;enfoque|منهج أو منظور;matiz|فارق دقيق;repercusión|تداعٍ;hipótesis|فرضية;fundamento|أساس;controversia|جدل;criterio|معيار;requisito|شرط;desigualdad|عدم مساواة;incertidumbre|عدم يقين;respaldo|دعم;hallazgo|اكتشاف;alcance|نطاق;sesgo|تحيز;compromiso|التزام;informe|تقرير;acuerdo|اتفاق;obstáculo|عائق;alternativa|بديل",
    SpanishWordKind.verb: "matizar|يوضح بفروق دقيقة;cuestionar|يشكك في;corroborar|يثبت بالدليل;plantear|يطرح;contrastar|يقارن نقديًا;argumentar|يحاجج;replantear|يعيد النظر;negociar|يتفاوض;reconocer|يعترف;priorizar|يمنح الأولوية;respaldar|يدعم;rebatir|يدحض;prever|يتوقع;proponer|يقترح;formular|يصوغ;examinar|يفحص;reconsiderar|يعيد النظر;mediar|يتوسط;justificar|يبرر;concluir|يستنتج",
    SpanishWordKind.adjective: "sólido|متين;fiable|موثوق;coherente|متسق;polémico|جدلي;plausible|معقول;significativo|مهم;imparcial|محايد;ambiguo|ملتبس;riguroso|صارم;viable|قابل للتنفيذ;innovador|مبتكر;contrastado|متَحقق منه;detallado|مفصل;injusto|ظالم;pertinente|ذو صلة;flexible|مرن;convincente|مقنع;cuestionable|قابل للتشكيك;probable|مرجح;decisivo|حاسم",
    SpanishWordKind.adverb: "presuntamente|على نحو مزعوم;supuestamente|من المفترض;aparentemente|ظاهريًا;indudablemente|بلا شك;prácticamente|عمليًا;gradualmente|تدريجيًا;fundamentalmente|أساسًا;comparativamente|بالمقارنة;objetivamente|بموضوعية;explícitamente|صراحة;implícitamente|ضمنيًا;cuidadosamente|بعناية;razonablemente|بشكل معقول;parcialmente|جزئيًا;simultáneamente|في الوقت نفسه;posteriormente|لاحقًا;efectivamente|بالفعل;consecuentemente|وبناء عليه;provisionalmente|مؤقتًا;cuantitativamente|من الناحية الكمية",
  };
  static const _unit=<int,Map<SpanishWordKind,String>>{
    1:<SpanishWordKind,String>{
    SpanishWordKind.noun: "crónica|سرد زمني;editorial|افتتاحية;portavoz|ناطق رسمي;declaración|تصريح;testimonio|شهادة;rumor|إشاعة;archivo|أرشيف;fuente|مصدر;credibilidad|مصداقية;desmentido|نفي رسمي",
    SpanishWordKind.verb: "divulgar|ينشر;entrevistar|يجري مقابلة;filtrar|يسرب;verificar|يتحقق;desmentir|ينفي;publicar|ينشر;interpretar|يفسر;documentar|يوثق;atribuir|ينسب;comunicar|يبلغ",
    SpanishWordKind.adjective: "periodístico|صحفي;documental|وثائقي;fidedigno|جدير بالثقة;anónimo|مجهول الهوية;inexacto|غير دقيق;verificable|قابل للتحقق;tendencioso|متحيز;mediático|إعلامي;contradictorio|متناقض;revelador|كاشف",
    SpanishWordKind.adverb: "textualmente|حرفيًا;históricamente|تاريخيًا;mediáticamente|إعلاميًا;erróneamente|بشكل خاطئ;selectivamente|بانتقائية;literalmente|بالمعنى الحرفي;retrospectivamente|بأثر رجعي;abiertamente|بصراحة;íntegramente|بالكامل;deliberadamente|عن قصد",
    },
    2:<SpanishWordKind,String>{
    SpanishWordKind.noun: "convivencia|التعايش;vivienda|سكن;subvención|دعم حكومي;municipio|بلدية;campaña|حملة;vecindario|حي سكني;impuesto|ضريبة;inclusión|إدماج;reivindicación|مطالبة بحق;asamblea|جمعية عامة",
    SpanishWordKind.verb: "fomentar|يعزز;financiar|يمول;redistribuir|يعيد التوزيع;proteger|يحمي;integrar|يدمج;regular|ينظم;coordinar|ينسق;movilizar|يحشد;concienciar|ينشر الوعي;reformar|يصلح",
    SpanishWordKind.adjective: "municipal|بلدي;comunitario|مجتمعي;participativo|تشاركي;equitativo|عادل;asequible|ميسور التكلفة;inclusivo|شامل;urbanístico|تخطيطي حضري;colectivo|جماعي;solidario|متضامن;institucional|مؤسسي",
    SpanishWordKind.adverb: "legalmente|قانونيًا;socialmente|اجتماعيًا;comunitariamente|مجتمعيًا;democráticamente|ديمقراطيًا;voluntariamente|طوعًا;equitativamente|بعدالة;institucionalmente|مؤسسيًا;conjuntamente|معًا;solidariamente|بتضامن;territorialmente|إقليميًا",
    },
    3:<SpanishWordKind,String>{
    SpanishWordKind.noun: "algoritmo|خوارزمية;sostenibilidad|استدامة;energía|طاقة;emisión|انبعاث;previsión|توقع;experimento|تجربة علمية;presupuesto|ميزانية;riesgo|مخاطرة;innovación|ابتكار;infraestructura|بنية تحتية",
    SpanishWordKind.verb: "optimizar|يحسن الكفاءة;automatizar|يؤتمت;reducir|يقلل;simular|يحاكي;prevenir|يمنع;cuantificar|يحدد كميا;desarrollar|يطور;implantar|ينفذ;reciclar|يعيد التدوير;invertir|يستثمر",
    SpanishWordKind.adjective: "tecnológico|تقني;ecológico|بيئي;renovable|متجدد;sostenible|مستدام;experimental|تجريبي;predictivo|تنبؤي;eficiente|كفء;automatizado|مؤتمت;rentable|مربح;preventivo|وقائي",
    SpanishWordKind.adverb: "tecnológicamente|تقنيًا;ambientalmente|بيئيًا;energéticamente|من ناحية الطاقة;científicamente|علميًا;digitalmente|رقميًا;experimentalmente|تجريبيًا;preventivamente|وقائيًا;estratégicamente|استراتيجيًا;eficientemente|بكفاءة;económicamente|اقتصاديًا",
    },
  };
  static List<SpanishA1Word> wordsFor(int unit,int lesson){
    if(unit<1||unit>3||lesson<1||lesson>10){
      throw RangeError('Spanish B2 unit/lesson outside 3 × 10 syllabus');
    }
    final result=<SpanishA1Word>[];
    for(final kind in SpanishWordKind.values){
      final core=_core[kind]!.split(';');
      final topic=_unit[unit]![kind]!.split(';');
      for(var i=0;i<5;i++){
        final a=core[((lesson-1)*3+i)%core.length].split('|');
        final b=topic[((lesson-1)*3+i)%topic.length].split('|');
        result.add(SpanishA1Word(a[0],a[1],kind));
        result.add(SpanishA1Word(b[0],b[1],kind));
      }
    }
    return List<SpanishA1Word>.unmodifiable(result);
  }
  static List<SpanishA1Word> wordsOf(SpanishB2Lesson lesson,SpanishWordKind kind)=>
      lesson.words.where((w)=>w.kind==kind).toList(growable:false);
  static const lessons=<SpanishB2Lesson>[
    // B2_CONTENT_ANCHOR
  ];
  static SpanishB2Lesson find(int unit,int number)=>lessons.firstWhere(
      (x)=>x.unit==unit&&x.number==number);
  static List<String> grammarOptions(SpanishB2Lesson lesson)=>
      <String>[lesson.grammarMistakes.first,lesson.grammarExamples.first,
        lesson.grammarMistakes.last];

  /// Original five authored paragraphs + a sixth, contextual word review.
  /// The review is separate from the main story to avoid forced word insertion.
  static List<String> reading(SpanishB2Lesson lesson){
    final n=wordsOf(lesson,SpanishWordKind.noun);
    final v=wordsOf(lesson,SpanishWordKind.verb);
    final a=wordsOf(lesson,SpanishWordKind.adjective);
    final d=wordsOf(lesson,SpanishWordKind.adverb);
    return <String>[
      ...lesson.story,
      'Tras la experiencia, el equipo volvió a reunirse para debatir las '
      'consecuencias de sus decisiones. Tomaron notas de dos conceptos '
      'relevantes, «${n[0].es}» y «${n[1].es}», y analizaron cómo '
      'podían aplicar «${v[0].es}» y «${v[1].es}» a la situación descrita. '
      'También discutieron si las expresiones «${a[0].es}» y '
      '«${a[1].es}» representaban realmente los hechos. '
      'En su conclusión, citaron «${d[0].es}» y «${d[1].es}» '
      'como recursos lingüísticos que conviene utilizar con precisión. '
      'Finalmente defendieron una postura razonada, reconocieron sus '
      'limitaciones y formularon preguntas para una investigación futura.',
    ];
  }

  static List<String> conversation(SpanishB2Lesson lesson){
    final n=wordsOf(lesson,SpanishWordKind.noun);
    final v=wordsOf(lesson,SpanishWordKind.verb);
    final a=wordsOf(lesson,SpanishWordKind.adjective);
    final d=wordsOf(lesson,SpanishWordKind.adverb);
    return <String>[
      'Lucía: ¿Qué implicaciones tiene el tema «${lesson.title}»?',
      'Diego: La «${n[0].es}» es fundamental, aunque la «${n[1].es}» '
          'también merece atención.',
      'Lucía: ¿Qué datos necesitaríamos para defender esa interpretación?',
      'Diego: Primero deberíamos ${v[0].es} ${d[0].es}; después podríamos '
          '${v[1].es} ${d[1].es}.',
      'Lucía: Sin embargo, ¿no podría resultar ${a[0].es} esa conclusión?',
      'Diego: Es posible que sí; debemos distinguir una explicación '
          '${a[1].es} de una mera suposición.',
      'Lucía: ¿Cómo resumirías tu postura sin ignorar las objeciones?',
      'Diego: Aceptaría el argumento provisionalmente y explicaría '
          'qué pruebas podrían hacerme reconsiderarlo.',
    ];
  }
  static String podcast(SpanishB2Lesson lesson){
    final groups=SpanishWordKind.values.map((kind){
      final name=switch(kind){
        SpanishWordKind.noun=>'sustantivos',
        SpanishWordKind.verb=>'verbos',
        SpanishWordKind.adjective=>'adjetivos',
        SpanishWordKind.adverb=>'adverbios',
      };
      final terms=wordsOf(lesson,kind).map((w)=>w.es).join(', ');
      return 'Escucha los diez $name: $terms. ';
    }).join();
    return 'Bienvenidos al pódcast de español B2 de WorldVoice. '
        'Hoy examinaremos un relato titulado ${lesson.title}. '
        '${lesson.story.join(' ')} '
        'A continuación, repasaremos las cuarenta palabras del tema. '
        '$groups'
        'Escucha otra vez y distingue los hechos de las opiniones. '
        'Formula un argumento y un contraargumento utilizando la regla '
        'gramatical ${lesson.grammar}. Señala qué datos respaldan '
        'tu conclusión y cuáles siguen siendo inciertos.';
  }
}
