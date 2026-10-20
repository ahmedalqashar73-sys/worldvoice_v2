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
    SpanishC1Lesson(level:'C1',unit:1,number:1,title:"Un manuscrito bajo sospecha",titleAr:"تقييم مصدر تاريخي",grammar:"Aunque hubiera sido...",grammarAr:"رغم أنه كان قد حدث",grammarHelpAr:"نستخدم aunque + pluscuamperfecto de subjuntivo لتقديم عائق ماضٍ افتراضي لم يمنع وقوع النتيجة.",grammarExamples:<String>["Aunque hubiera llovido, habríamos ido.","Aunque lo hubieran afirmado, no sería concluyente.","Aunque ella hubiera llegado antes, faltaban pruebas.","Aunque hubiera habido testigos, verificaríamos sus relatos.","Aunque lo hubiésemos investigado, persistirían dudas.","Aunque hubiera sido auténtico, exigiría un análisis.","Aunque hubieras leído la carta, no conocerías el contexto.","Aunque se hubiera publicado, revisaríamos las fuentes."],grammarMistakes:<String>["Aunque habría llovido, habríamos ido.","Aunque habían afirmado eso, no sería concluyente."],story:<String>["La historiadora Elena recibió un manuscrito cuya autoría parecía confirmada por una firma antigua. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","Al examinar el papel observó diferencias entre la tinta y la fecha atribuida al documento. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","Un restaurador le mostró registros del archivo que contradecían la primera interpretación. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Elena propuso contrastar los resultados antes de anunciar el descubrimiento. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","El equipo publicó las pruebas y explicó por qué mantenía una conclusión provisional. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:2,title:"Lo que afirmó la investigadora",titleAr:"citar declaraciones con precisión",grammar:"Estilo indirecto y deixis",grammarAr:"تحويل إشارات الزمان والمكان عند نقل الكلام",grammarHelpAr:"في نقل الأقوال تتغير إشارات الوقت والمكان بحسب نقطة السرد مثل hoy إلى aquel día و aquí إلى allí.",grammarExamples:<String>["Dijo que llegaría al día siguiente.","Afirmó que allí faltaban pruebas.","Explicó que aquel día habían cerrado el archivo.","Me contó que vendría dos días después.","Anunció que entonces desconocía los resultados.","Dijo que había estado allí la víspera.","Señaló que esa semana revisarían el informe.","Aseguró que aquellos documentos eran importantes."],grammarMistakes:<String>["Dijo que llegaría mañana siguiente.","Explicó que aquí faltaban pruebas cuando el narrador estaba lejos."],story:<String>["Una periodista entrevistó a un científico que había presentado un informe controvertido. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","Durante la conversación el investigador utilizó referencias como hoy y aquí para describir los trabajos. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","La periodista revisó su grabación antes de preparar una síntesis para lectores de otra región. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Su editora señaló que una frase aislada podía perder sentido al cambiar el contexto. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","El reportaje final distinguió las citas textuales de las explicaciones indirectas. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:3,title:"Es improbable que lo hayan descubierto",titleAr:"valorar el grado de certeza",grammar:"Perfecto de subjuntivo",grammarAr:"الماضي القريب المنصوب بعد التقييم",grammarHelpAr:"نستخدم haya + participio بعد تعبيرات الاحتمال والشك لتقييم حدث سابق مرتبط بالحاضر.",grammarExamples:<String>["Es posible que lo hayan encontrado.","Dudo que haya terminado.","No creo que lo hayan entendido.","Me alegra que hayas participado.","Es improbable que hayan falsificado el documento.","Puede que hayamos confundido las fechas.","Temo que se haya difundido el rumor.","Me sorprende que hayan aceptado la propuesta."],grammarMistakes:<String>["Es posible que lo han encontrado.","Dudo que ha terminado."],story:<String>["Un museo anunció que una pieza recién hallada podía cambiar una interpretación histórica aceptada. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","Dos expertos cuestionaron la fecha asignada porque los análisis iniciales no coincidían. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","La directora pidió pruebas adicionales y recordó que un resultado aislado era insuficiente. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Un periodista acudió al laboratorio para preguntar si el hallazgo había sido verificado. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","La institución publicó un comunicado prudente que reconocía las dudas pendientes. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:4,title:"Se conservan miles de cartas",titleAr:"diferentes maneras de expresar la voz pasiva",grammar:"Pasiva refleja frente a ser + participio",grammarAr:"التمييز بين صيغة se والمبني للمجهول",grammarHelpAr:"نستخدم se مع الفعل للتركيز على عملية عامة، و ser + participio عند إبراز الإجراء أو فاعله.",grammarExamples:<String>["Se conservan miles de cartas.","Las cartas fueron conservadas por el archivo.","Se publicará el informe mañana.","El documento fue revisado por expertos.","Aquí se estudian distintas fuentes.","La decisión fue aprobada por el consejo.","Se han descubierto nuevos registros.","Los registros serán evaluados por especialistas."],grammarMistakes:<String>["Se conserva miles de cartas.","Las cartas fue conservadas por el archivo."],story:<String>["Un archivo regional recibió miles de cartas que pertenecían a familias de distintas épocas. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","La directora quería explicar cómo se habían conservado y quién había participado en su clasificación. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","Una documentalista comparó las descripciones originales con las nuevas fichas electrónicas. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","El equipo decidió mostrar algunos materiales sin revelar datos personales sensibles. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","La exposición explicó con precisión qué documentos habían sido restaurados y cuáles seguían pendientes. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:5,title:"La revisión de las pruebas",titleAr:"academic writing and nominalization",grammar:"Nominalización de procesos",grammarAr:"تحويل الأفعال إلى أسماء في الكتابة الرسمية",grammarHelpAr:"نستخدم الأسماء المشتقة من الأفعال للتعبير المكثف والرسمي، مع الحرص على وضوح من قام بالفعل.",grammarExamples:<String>["La revisión de las pruebas llevó semanas.","La publicación del informe generó dudas.","La evaluación de los datos fue rigurosa.","La conservación del archivo requiere recursos.","El análisis de las muestras confirmó la hipótesis.","La elaboración del protocolo comenzó ayer.","La interpretación del documento sigue abierta.","La verificación de la fuente evitó errores."],grammarMistakes:<String>["La revisar de las pruebas llevó semanas.","El evaluamiento de los datos fue riguroso."],story:<String>["Un grupo universitario preparó un informe sobre la autenticidad de varias fotografías. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","El primer borrador repetía demasiados verbos y no distinguía bien los procesos de sus responsables. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","La profesora mostró cómo la nominalización podía resumir procedimientos sin eliminar información esencial. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Los estudiantes revisaron las frases para mantener un estilo académico claro y preciso. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","La versión final resultó más coherente y permitió comprender el método utilizado. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:6,title:"Los testigos, que habían llegado antes",titleAr:"precisar datos esenciales y aclaratorios",grammar:"Relativas explicativas y especificativas",grammarAr:"الجمل الموصولة التوضيحية والتحديدية",grammarHelpAr:"الجملة الموصولة بين فاصلتين تضيف معلومة عن مرجع معروف؛ دون فواصل تحدد المقصود من بين مجموعة.",grammarExamples:<String>["Los testigos, que llegaron temprano, esperaron fuera.","Los testigos que llegaron temprano declararon primero.","El archivo, que está cerrado, abrirá mañana.","Los documentos que faltan son esenciales.","La historiadora, que dirigió el estudio, respondió.","Las cartas que firmó Ana fueron conservadas.","El informe, que revisamos ayer, es extenso.","Los expertos que participaron firmaron el acuerdo."],grammarMistakes:<String>["Los testigos, que llegó temprano, esperaron.","Los documentos que faltas son esenciales."],story:<String>["Durante un juicio histórico, varios testigos ofrecieron versiones parcialmente diferentes. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","Una investigadora redactó la cronología y advirtió que las comas podían cambiar la identidad de las personas mencionadas. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","Sus colegas compararon dos titulares con informaciones aparentemente idénticas. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","La discusión mostró que una frase aclaratoria no siempre identifica a un grupo concreto. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","Tras corregir el texto, publicaron una versión más fiel a los testimonios. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:7,title:"Fue la archivista quien detectó el error",titleAr:"destacar información decisiva",grammar:"Estructuras enfáticas: fue ... quien",grammarAr:"الجملة الانشطارية للتأكيد",grammarHelpAr:"نستخدم fue ... quien أو lo que para resaltar el sujeto o el hecho determinante.",grammarExamples:<String>["Fue Ana quien encontró la carta.","Fue en el archivo donde ocurrió.","Lo que necesitamos es otra muestra.","Fueron los vecinos quienes protestaron.","Fue entonces cuando cambió la opinión.","Lo que sorprendió fue la fecha.","Fue el director quien respondió.","Fue aquella explicación la que convenció."],grammarMistakes:<String>["Fue Ana que encontró la carta en esta estructura.","Fueron los vecinos quien protestaron."],story:<String>["Un museo anunció que había resuelto un antiguo misterio sobre una pintura. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","La prensa atribuyó el descubrimiento al director, aunque el trabajo había comenzado en otro departamento. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","Una archivista había encontrado la referencia decisiva durante una revisión rutinaria. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","El equipo decidió corregir el comunicado y explicar quién había realizado cada tarea. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","La nueva publicación reconoció el mérito colectivo y destacó la prueba verdaderamente decisiva. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:8,title:"Al revisar los registros",titleAr:"time relations with infinitive",grammar:"Al + infinitivo y antes de + infinitivo",grammarAr:"الربط الزمني بالمصدر",grammarHelpAr:"نستخدم al + infinitivo لحدث يقع عند حدوث فعل، و antes de + infinitivo للدلالة على حدث يسبقه.",grammarExamples:<String>["Al revisar el archivo, encontramos errores.","Antes de publicar, verificaron los datos.","Al entrar, saludó a la directora.","Antes de decidir, consultamos al equipo.","Al analizar las muestras, surgieron dudas.","Antes de citar la fuente, la leí completa.","Al terminar el estudio, redactaron un resumen.","Antes de salir, guardó el manuscrito."],grammarMistakes:<String>["Al revisando el archivo, encontramos errores.","Antes de publicamos, verificaron los datos."],story:<String>["Una investigadora visitó un depósito documental para localizar planos de un puente desaparecido. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","Al revisar los primeros registros, descubrió que las fechas no seguían un orden coherente. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","Antes de publicar una hipótesis, consultó fotografías de otras instituciones. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Durante el proceso encontró una explicación que parecía sencilla pero dependía de un documento dudoso. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","Finalmente redactó una nota metodológica sobre las limitaciones del material. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:9,title:"Venimos observando cambios",titleAr:"long ongoing processes",grammar:"Venir + gerundio",grammarAr:"تطور تدريجي مستمر",grammarHelpAr:"نستخدم venir + gerundio للدلالة على نشاط أو اتجاه يتراكم تدريجيًا حتى اللحظة الحالية.",grammarExamples:<String>["Venimos observando cambios desde enero.","La investigación viene señalando problemas.","Los expertos vienen advirtiendo del riesgo.","Vengo estudiando este archivo hace meses.","El equipo viene reuniendo testimonios.","Las universidades vienen cooperando desde 2020.","Vienen aumentando las consultas.","Se viene debatiendo esta cuestión desde hace años."],grammarMistakes:<String>["Venimos observar cambios desde enero.","La investigación viene señalado problemas."],story:<String>["Una universidad analizaba la conservación de documentos digitales a lo largo de varias décadas. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","El equipo venía observando problemas de compatibilidad entre formatos antiguos y nuevos. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","En lugar de atribuir todos los fallos a un solo programa, comparó distintos periodos de mantenimiento. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Las entrevistas con archivistas mostraron que los cambios técnicos también afectaban a las decisiones humanas. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","La universidad creó un protocolo para revisar continuamente los resultados. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
    SpanishC1Lesson(level:'C1',unit:1,number:10,title:"Solo entonces comprendimos el alcance",titleAr:"focus and restricted adverbs",grammar:"Solo entonces y marcadores de foco",grammarAr:"تقديم عناصر التوكيد في النص",grammarHelpAr:"نقدم تعبيرات مثل solo entonces أو precisamente allí لإبراز لحظة أو مكان حاسم دون تغيير تصريف الفعل.",grammarExamples:<String>["Solo entonces comprendimos el problema.","Precisamente allí encontramos la prueba.","Únicamente después aceptaron el cambio.","Fue entonces cuando surgieron dudas.","Tan solo así sería posible verificarlo.","Exactamente en ese punto apareció la discrepancia.","Solo a partir de esa fecha tenemos datos.","Precisamente por eso conviene esperar."],grammarMistakes:<String>["Solo entonces comprendieron nosotros el problema.","Precisamente allí encuentra ayer la prueba."],story:<String>["Un grupo de estudiantes investigó por qué habían desaparecido ciertos registros de un archivo local. La primera impresión provocó un debate sobre el origen de la información, las responsabilidades de quienes la difundían y los límites de las explicaciones disponibles.","Durante varios días examinaron hipótesis técnicas que no explicaban la ausencia de una fecha concreta. A medida que avanzó la investigación, aparecieron preguntas que obligaron a distinguir el dato comprobado de la simple interpretación y a revisar los supuestos iniciales.","Una bibliotecaria encontró un antiguo inventario y descubrió que parte del material había sido trasladado. El diálogo fue respetuoso, aunque no faltaron objeciones. Cada participante tuvo que justificar su postura y precisar qué pruebas podrían hacerle cambiar de opinión.","Solo entonces comprendieron que el problema no era la pérdida sino la clasificación equivocada. La decisión no eliminó toda la incertidumbre; sin embargo, permitió acordar un método de trabajo y un calendario de verificación independiente.","El equipo explicó el hallazgo y propuso una mejora para evitar confusiones futuras. El resultado fue útil precisamente porque presentó sus límites y propuso preguntas para futuros investigadores, en lugar de ofrecer una certeza aparente."]),
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
