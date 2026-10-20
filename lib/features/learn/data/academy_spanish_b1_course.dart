import 'academy_spanish_a1_course.dart';
import 'academy_spanish_a2_course.dart';

/// The CEFR B1 level is published only after authoring all 30 lessons.
/// A1 and A2 lesson identifiers, vocabulary and completion data are unchanged.
class SpanishB1Lesson extends SpanishA1Lesson {
  const SpanishB1Lesson({required super.unit, required super.number,
    required super.title, required super.titleAr, required super.grammar,
    required super.grammarAr, required super.grammarHelpAr,
    required super.grammarExamples, required super.story,
    required this.grammarMistakes});
  final List<String> grammarMistakes;
  @override
  String get id => 'worldvoice.es.b1.u$unit.l${number.toString().padLeft(2, '0')}';
  @override
  List<SpanishA1Word> get words => SpanishB1Course.wordsFor(unit, number);
}

class SpanishB1Unit extends SpanishA1Unit {
  const SpanishB1Unit(super.number, super.title, super.arabic);
  @override
  List<SpanishB1Lesson> get lessons => SpanishB1Course.lessons
      .where((lesson) => lesson.unit == number).toList(growable:false);
}

abstract final class SpanishB1Course {
  static const units = <SpanishB1Unit>[
    SpanishB1Unit(1,'Historias y experiencias','قصص وتجارب وحياة الماضي'),
    SpanishB1Unit(2,'Comunidad y relaciones','المجتمع والتواصل والعلاقات'),
    SpanishB1Unit(3,'Ideas y decisiones','الأفكار والتخطيط وصنع القرارات'),
  ];
  static const _core=<SpanishWordKind,String>{
    SpanishWordKind.noun: "compromiso|التزام;consecuencia|نتيجة مترتبة;propuesta|مقترح;desafío|تحد;responsabilidad|مسؤولية;acuerdo|اتفاق;conflicto|نزاع;investigación|بحث;influencia|تأثير;perspectiva|وجهة نظر;comportamiento|سلوك;desarrollo|تطور;experiencia|تجربة;argumento|حجة;recurso|مورد;iniciativa|مبادرة;comunidad|مجتمع;colaboración|تعاون;prioridad|أولوية;conclusión|استنتاج",
    SpanishWordKind.verb: "analizar|يحلل;colaborar|يتعاون;plantear|يطرح;resolver|يحل;promover|يعزز;establecer|يؤسس;considerar|ينظر في;afrontar|يواجه;proponer|يقترح;demostrar|يثبت;argumentar|يحاجج;investigar|يبحث;coordinar|ينسق;reflexionar|يتأمل;contribuir|يساهم;reconocer|يعترف;convencer|يقنع;anticipar|يتوقع;superar|يتجاوز;valorar|يقيّم",
    SpanishWordKind.adjective: "relevante|ذو صلة;complejo|معقد;eficaz|فعال;significativo|ذو أهمية;razonable|معقول;sostenible|مستدام;flexible|مرن;adecuado|ملائم;fundamental|أساسي;responsable|مسؤول;beneficioso|نافع;urgente|عاجل;discutible|قابل للنقاش;transparente|شفاف;probable|مرجح;concreto|محدد;colectivo|جماعي;disponible|متاح;independiente|مستقل;decisivo|حاسم",
    SpanishWordKind.adverb: "gradualmente|تدريجيًا;principalmente|أساسًا;frecuentemente|كثيرًا;probablemente|على الأرجح;claramente|بوضوح;actualmente|حاليًا;anteriormente|سابقًا;posteriormente|لاحقًا;especialmente|خصوصًا;eficazmente|بفعالية;considerablemente|بدرجة كبيرة;relativamente|نسبيًا;directamente|مباشرة;finalmente|أخيرًا;concretamente|تحديدًا;cuidadosamente|بعناية;necesariamente|بالضرورة;aparentemente|ظاهريًا;voluntariamente|طوعًا;aproximadamente|تقريبًا",
  };
  static const _focused=<int,Map<SpanishWordKind,String>>{
    1:<SpanishWordKind,String>{
      SpanishWordKind.noun: "reportaje|تقرير صحفي;entrevista|مقابلة;testimonio|شهادة;memoria|ذاكرة;diario|مذكرات;documental|فيلم وثائقي;exposición|معرض;tradición|تقليد;historiador|مؤرخ;archivo|أرشيف",
      SpanishWordKind.verb: "narrar|يسرد;publicar|ينشر;recordar|يتذكر;describir|يصف;entrevistar|يجري مقابلة;reconstruir|يعيد بناء;investigar|يتقصى;documentar|يوثق;interpretar|يفسر;comunicar|يوصل",
      SpanishWordKind.adjective: "histórico|تاريخي;personal|شخصي;inédito|غير منشور;detallado|مفصل;fiel|أمين;emocionante|مثير;auténtico|أصيل;conocido|معروف;inolvidable|لا ينسى;inesperado|غير متوقع",
      SpanishWordKind.adverb: "antiguamente|قديمًا;recientemente|مؤخرًا;entonces|حينئذ;después|بعد ذلك;antes|من قبل;mientras tanto|في هذه الأثناء;de repente|فجأة;sin embargo|مع ذلك;al principio|في البداية;al final|في النهاية",
    },
    2:<SpanishWordKind,String>{
      SpanishWordKind.noun: "vecindario|حي سكني;asociación|جمعية;voluntariado|تطوع;campaña|حملة;donación|تبرع;derecho|حق;igualdad|مساواة;diversidad|تنوع;ayuntamiento|بلدية;participación|مشاركة",
      SpanishWordKind.verb: "apoyar|يدعم;recaudar|يجمع التبرعات;organizar|ينظم;proteger|يحمي;integrar|يدمج;incluir|يشمل;negociar|يتفاوض;representar|يمثل;asistir|يحضر;mediar|يتوسط",
      SpanishWordKind.adjective: "solidario|متضامن;justo|عادل;público|عام;accesible|ميسر الوصول;igualitario|مساواتي;social|اجتماعي;participativo|تشاركي;inclusivo|شامل;local|محلي;innovador|مبتكر",
      SpanishWordKind.adverb: "conjuntamente|بشكل مشترك;socialmente|اجتماعيًا;legalmente|قانونيًا;abiertamente|بصراحة;públicamente|علانية;respetuosamente|باحترام;colectivamente|جماعيًا;amablemente|بلطف;constantemente|باستمرار;debidamente|على النحو المطلوب",
    },
    3:<SpanishWordKind,String>{
      SpanishWordKind.noun: "medioambiente|بيئة;tecnología|تقنية;innovación|ابتكار;energía|طاقة;consumo|استهلاك;presupuesto|ميزانية;seguridad|أمان;empleo|توظيف;formación|تدريب;objetivo|هدف",
      SpanishWordKind.verb: "reducir|يقلص;transformar|يحول;optimizar|يحسّن;prevenir|يمنع;invertir|يستثمر;reciclar|يعيد التدوير;planificar|يخطط;evaluar|يقيّم;adaptarse|يتكيف;garantizar|يضمن",
      SpanishWordKind.adjective: "ecológico|بيئي;digital|رقمي;renovable|متجدد;rentable|مربح;seguro|آمن;innovador|مبتكر;duradero|طويل الأمد;laboral|وظيفي;económico|اقتصادي;viable|قابل للتطبيق",
      SpanishWordKind.adverb: "tecnológicamente|تقنيًا;económicamente|اقتصاديًا;ambientalmente|بيئيًا;automáticamente|آليًا;responsablemente|بمسؤولية;sistemáticamente|بمنهجية;estratégicamente|استراتيجيًا;preventivamente|وقائيًا;eficientemente|بكفاءة;digitalmente|رقميًا",
    },
  };
  static List<SpanishA1Word> wordsFor(int unit,int lesson){
    if (unit<1||unit>3||lesson<1||lesson>10){
      throw RangeError('Spanish B1 unit/lesson outside syllabus');
    }
    final items=<SpanishA1Word>[];
    for(final kind in SpanishWordKind.values){
      final common=_core[kind]!.split(';');
      final topical=_focused[unit]![kind]!.split(';');
      for(var i=0;i<5;i++){
        final a=common[((lesson-1)*3+i)%common.length].split('|');
        final b=topical[((lesson-1)*3+i)%topical.length].split('|');
        items.add(SpanishA1Word(a[0],a[1],kind));
        items.add(SpanishA1Word(b[0],b[1],kind));
      }
    }
    return List<SpanishA1Word>.unmodifiable(items);
  }
  static List<SpanishA1Word> wordsOf(SpanishB1Lesson lesson,SpanishWordKind kind)=>
      lesson.words.where((word)=>word.kind==kind).toList(growable:false);

  static const lessons=<SpanishB1Lesson>[
    // Authored lesson sequence is inserted below by the C1-safe generator.
  ];

  static SpanishB1Lesson find(int unit,int number)=>lessons.firstWhere(
      (x)=>x.unit==unit&&x.number==number);
  static List<String> grammarOptions(SpanishB1Lesson lesson)=>
    <String>[lesson.grammarMistakes[0],
      lesson.grammarExamples[0],lesson.grammarMistakes[1]];

  /// The learner follows five authored narrative paragraphs, then one
  /// contextual vocabulary-recall scene, not a disconnected word list.
  static List<String> reading(SpanishB1Lesson lesson){
    final nouns=wordsOf(lesson,SpanishWordKind.noun);
    final verbs=wordsOf(lesson,SpanishWordKind.verb);
    final adjectives=wordsOf(lesson,SpanishWordKind.adjective);
    final adverbs=wordsOf(lesson,SpanishWordKind.adverb);
    final extension=
      'Al terminar la experiencia, los participantes volvieron a '
      'encontrarse para analizar lo ocurrido. En sus notas aparecían '
      'los términos «${nouns[0].es}» y «${nouns[1].es}», '
      'y los verbos «${verbs[0].es}» y «${verbs[1].es}». '
      'También discutieron las diferencias entre «${adjectives[0].es}» '
      'y «${adjectives[1].es}», y aprendieron a expresar sus ideas '
      'con «${adverbs[0].es}» y «${adverbs[1].es}». '
      'En lugar de repetir palabras sin contexto, formularon ejemplos '
      'relacionados con el problema y defendieron sus propias conclusiones.';
    return <String>[...lesson.story,extension];
  }
  static List<String> conversation(SpanishB1Lesson lesson){
    final n=wordsOf(lesson,SpanishWordKind.noun);
    final v=wordsOf(lesson,SpanishWordKind.verb);
    final a=wordsOf(lesson,SpanishWordKind.adjective);
    final d=wordsOf(lesson,SpanishWordKind.adverb);
    return <String>[
      'Ana: ¿Qué conclusión has sacado de «${lesson.title}»?',
      'Luis: Me parece que la «${n[0].es}» cambió la situación.',
      'Ana: ¿Por qué piensas eso? ¿Qué ocurrió antes?',
      'Luis: Si pudiera ${v[0].es} ${d[0].es}, mejoraría el resultado.',
      'Ana: ¿Cómo describirías la «${n[1].es}»?',
      'Luis: Fue ${a[0].es}; sin embargo, también parecía ${a[1].es}.',
      'Ana: ¿Qué recomendarías a otras personas?',
      'Luis: Les propondría ${v[1].es} ${d[1].es} y hablar con respeto.',
    ];
  }
  static String podcast(SpanishB1Lesson lesson){
    final groups=SpanishWordKind.values.map((kind){
      final label=switch(kind){
        SpanishWordKind.noun=>'sustantivos',
        SpanishWordKind.verb=>'verbos',
        SpanishWordKind.adjective=>'adjetivos',
        SpanishWordKind.adverb=>'adverbios',
      };
      final terms=wordsOf(lesson,kind).map((w)=>w.es).join(', ');
      return 'Escucha diez $label: $terms. ';
    }).join();
    return 'Bienvenidos al pódcast intermedio de español B1 de WorldVoice. '
      'El episodio de hoy se titula ${lesson.title}. '
      '${lesson.story.join(' ')} '
      'Ahora vamos a recordar las cuarenta palabras del tema. '
      '$groups'
      'Para terminar, explica las causas de los acontecimientos y '
      'compara dos interpretaciones posibles. Puedes pausar la grabación, '
      'escuchar otra vez y usar la regla gramatical de esta lección.';
  }
}
