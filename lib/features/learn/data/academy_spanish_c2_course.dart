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
    SpanishC2Lesson(level:'C2',unit:1,number:1,title:"Aun cuando lo hubiera negado",titleAr:"الاستدراك الافتراضي المركب",grammar:"Aun cuando + pluscuamperfecto de subjuntivo",grammarAr:"الاستدراك الافتراضي المركب",grammarHelpAr:"نستخدم aun cuando مع الماضي الأسبق المنصوب لحدث ماضٍ مفترض لم يكن ليغيّر النتيجة.",grammarExamples:<String>["Aun cuando lo hubiera negado, investigaríamos.","Aun cuando hubieran firmado, faltaban pruebas.","Aun cuando ella hubiera llegado, no bastaría.","Aun cuando lo hubiésemos leído, dudaríamos.","Aun cuando hubieran protestado, continuaríamos.","Aun cuando hubiera sido auténtico, lo revisaríamos.","Aun cuando hubieras preguntado, no lo sabría.","Aun cuando hubieran publicado, necesitaríamos fuentes."],grammarMistakes:<String>["Aun cuando lo habría negado, investigaríamos.","Aun cuando habían firmado, faltarían pruebas."],story:<String>["Una archivista recibió una carta atribuida a una autora famosa. Los periódicos afirmaban que revelaba una contradicción histórica, pero ninguno había explicado dónde se conservaba el original.","Una especialista observó que el papel parecía posterior a la época descrita. Invitó a colegas de distintas disciplinas para contrastar su impresión y evitar un juicio demasiado apresurado.","Durante el debate, un editor sostuvo que la firma bastaba para confirmar la autoría. La archivista respondió que, aun cuando fuera auténtica, también importaba el contexto de transmisión.","Al consultar un inventario antiguo, encontraron una transcripción que omitía una frase decisiva. El equipo explicó públicamente cómo aquella diferencia modificaba las interpretaciones anteriores.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:2,title:"Por más que insistan",titleAr:"una objeción persistente",grammar:"Por más que + subjuntivo",grammarAr:"una objeción persistente",grammarHelpAr:"نستخدم por más que مع المنصوب عندما لا تغير محاولة أو اعتراض محتمل النتيجة.",grammarExamples:<String>["Por más que insistan, no publicaré sin pruebas.","Por más que lo expliquemos, habrá dudas.","Por más que protesten, revisaremos el informe.","Por más que lo mire, encuentro errores.","Por más que busquemos, no aparece la fuente.","Por más que se esfuerce, necesita ayuda.","Por más que modifiquen el texto, lo contrastaremos.","Por más que parezca convincente, falta evidencia."],grammarMistakes:<String>["Por más que insisten, no publicaré.","Por más que buscamos, no aparece el original."],story:<String>["Una editorial preparaba una nueva traducción de un texto clásico. Dos traductores discutían una frase que admitía interpretaciones muy diferentes según el contexto.","El primer traductor defendía la fidelidad literal, mientras el segundo prefería reproducir el efecto literario. Ninguno aceptaba con facilidad los argumentos de su colega.","La editora recordó que, por más que insistieran, no podrían demostrar una única lectura sin examinar manuscritos y usos históricos. Solicitó notas metodológicas claras.","La traducción publicada explicó el desacuerdo y mostró alternativas razonables. Muchos lectores valoraron que la edición no ocultara los límites de sus decisiones.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:3,title:"Ni siquiera si apareciera la prueba",titleAr:"شرط افتراضي متطرف",grammar:"Ni siquiera si + imperfecto de subjuntivo",grammarAr:"شرط افتراضي متطرف",grammarHelpAr:"نستخدم ni siquiera si مع الشرط الافتراضي المتطرف للدلالة على أن النتيجة لن تتغير.",grammarExamples:<String>["Ni siquiera si apareciera la carta, bastaría.","Ni siquiera si lo afirmaran, aceptaríamos.","Ni siquiera si tuvieran más fondos, asegurarían nada.","Ni siquiera si llegáramos temprano, entraríamos.","Ni siquiera si lo supiéramos, lo publicaríamos.","Ni siquiera si cambiara la ley, terminaría la disputa.","Ni siquiera si insistieras, modificaría los datos.","Ni siquiera si pareciera auténtico, confiaría."],grammarMistakes:<String>["Ni siquiera si aparecería la carta, bastaría.","Ni siquiera si tuvieron fondos, podrían garantizarlo."],story:<String>["Un historiador descubrió una referencia a un documento perdido que parecía resolver un conflicto sobre la fundación de una ciudad. Varias instituciones ofrecieron financiar su búsqueda.","Un coleccionista declaró poseer una copia, pero rechazó informar de su procedencia. La prensa empezó a presentar aquella afirmación como si fuera un descubrimiento confirmado.","El historiador explicó que ni siquiera si apareciera el documento podría interpretarse sin conocer su origen, fecha y función. Una evidencia nueva podía generar otras preguntas.","El museo organizó una exposición sobre las fuentes disponibles y dejó claramente identificadas las incertidumbres. La comunidad comprendió que una prueba aislada rara vez cierra una controversia compleja.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:4,title:"De ahí que exijamos cautela",titleAr:"نتيجة مبررة بحجة",grammar:"De ahí que + subjuntivo",grammarAr:"نتيجة مبررة بحجة",grammarHelpAr:"نستخدم de ahí que مع المنصوب لربط الأدلة باستنتاج أو إجراء يترتب عليها.",grammarExamples:<String>["La muestra es pequeña; de ahí que dudemos.","Faltan documentos; de ahí que pidamos cautela.","No hay consenso; de ahí que investiguemos más.","Los datos difieren; de ahí que revisemos.","La fuente es anónima; de ahí que no la citemos.","El coste aumentó; de ahí que busquemos alternativas.","Faltan pruebas; de ahí que comparemos informes.","El texto es ambiguo; de ahí que admitamos matices."],grammarMistakes:<String>["Faltan documentos; de ahí que pedimos cautela.","Los datos difieren; de ahí que revisamos el método."],story:<String>["Un laboratorio universitario anunció un procedimiento capaz de conservar archivos digitales durante periodos prolongados. La noticia atrajo a instituciones preocupadas por la pérdida de documentos.","Una investigadora independiente señaló que los ensayos solo incluían condiciones muy controladas. Explicó por qué una muestra limitada impide generalizar inmediatamente los resultados.","Los responsables reconocieron la limitación; de ahí que propusieran colaborar con bibliotecas de diferentes tamaños. También publicaron el protocolo para facilitar la repetición.","Al terminar la primera fase, los equipos presentaron éxitos y errores con transparencia. La evaluación permitió precisar qué situaciones justificaban aplicar el procedimiento.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:5,title:"Como si hubiera presenciado los hechos",titleAr:"وصف مظهر يخالف الواقع الماضي",grammar:"Como si + pluscuamperfecto de subjuntivo",grammarAr:"وصف مظهر يخالف الواقع الماضي",grammarHelpAr:"نستخدم como si hubiera + participio للتشبيه بحالة ماضية ليست مؤكدة أو لم تقع.",grammarExamples:<String>["Habló como si hubiera estado allí.","Actúa como si lo hubiera escrito él.","Respondieron como si hubieran visto el original.","Me miró como si me hubiera reconocido.","Explicó todo como si lo hubiera investigado.","La narradora habla como si hubiera conocido al autor.","Lo relató como si hubiera vivido esa época.","Se comportan como si hubieran descubierto todo."],grammarMistakes:<String>["Habló como si había estado allí.","Actúa como si lo ha escrito él."],story:<String>["Un conferenciante narró con gran detalle una batalla antigua. Describía conversaciones privadas entre personajes de los que no se conservaban testimonios directos.","Una investigadora de la audiencia observó que hablaba como si hubiera presenciado aquellos acontecimientos. Le preguntó qué documentos sustentaban una descripción tan precisa.","El conferenciante explicó que había incluido escenas imaginadas para hacer comprensible el relato. La investigadora pidió distinguir expresamente la dramatización del conocimiento histórico.","Los organizadores revisaron la presentación y añadieron notas sobre las fuentes utilizadas. El resultado conservó fuerza narrativa sin confundir ficción documental y hecho comprobado.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:6,title:"Examinadas las fuentes",titleAr:"صيغة اسم المفعول المطلقة",grammar:"Construcciones absolutas de participio",grammarAr:"صيغة اسم المفعول المطلقة",grammarHelpAr:"نستخدم اسم المفعول المتفق مع الاسم في تركيب مستقل لبيان حدث مكتمل قبل النتيجة.",grammarExamples:<String>["Examinadas las fuentes, cambiamos la hipótesis.","Una vez revisado el texto, publicaron la nota.","Concluida la reunión, redactaron el acta.","Analizados los datos, surgieron dudas.","Aprobada la propuesta, comenzó la obra.","Restaurado el manuscrito, lo estudiaron.","Terminadas las entrevistas, contrastaron versiones.","Comparadas las copias, detectaron una alteración."],grammarMistakes:<String>["Examinado las fuentes, cambiamos.","Concluidas el estudio, redactaron el acta."],story:<String>["Una profesora organizó un seminario de crítica textual con tres copias de una obra antigua. Cada ejemplar contenía variantes que podían cambiar el significado.","Los estudiantes compararon errores y observaron que dos copias compartían una omisión poco habitual. Propusieron un vínculo entre sus historias de transmisión.","Examinadas las fuentes, abandonaron la hipótesis de que la copia más elegante fuera también la más fiel. Documentaron las razones del cambio de criterio.","El seminario concluyó con una reconstrucción provisional y una lista de problemas pendientes. La profesora destacó el valor de explicar tanto las pruebas favorables como las objeciones.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:7,title:"La obra cuya autoría se discute",titleAr:"موصول الملكية في السجل الرسمي",grammar:"Cuyo y concordancia con el poseído",grammarAr:"موصول الملكية في السجل الرسمي",grammarHelpAr:"نستخدم cuyo وما اشتق منه وفق جنس وعدد الشيء المملوك لا صاحب الملكية.",grammarExamples:<String>["La obra cuya autoría se discute es antigua.","El autor cuyos textos leímos era conocido.","La ciudad cuyas murallas se restauraron cambió.","La investigadora cuyo informe citamos llegó.","El archivo cuyos registros faltan cerró.","La teoría cuya validez se cuestiona persiste.","Los vecinos cuyas cartas conservamos participaron.","La persona cuyo testimonio citamos respondió."],grammarMistakes:<String>["La obra cuyo autoría se discute es antigua.","La investigadora cuya informe leí llegó."],story:<String>["Una biblioteca abrió una exposición sobre una obra cuya autoría era discutida. Los catálogos antiguos atribuían el texto a un escritor reconocido sin aportar documentos suficientes.","Una filóloga estudió ediciones cuyos prólogos contenían referencias contradictorias. Después encontró correspondencia cuya fecha podía aclarar una parte del problema.","El equipo comparó testimonios y explicó por qué las semejanzas de estilo no garantizaban una atribución definitiva. Algunos visitantes se sorprendieron ante tantas incertidumbres.","La biblioteca corrigió el catálogo y publicó enlaces a los documentos. La exposición invitaba a comprender la complejidad de la producción y transmisión literarias.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:8,title:"De haberlo sabido",titleAr:"الشرط المضاد للواقع المختصر",grammar:"De haber + participio + condicional",grammarAr:"الشرط المضاد للواقع المختصر",grammarHelpAr:"نستخدم de haber + participio مع الشرط الافتراضي الماضي لصياغة رسمية مختصرة.",grammarExamples:<String>["De haberlo sabido, habríamos cambiado el plan.","De haber llegado antes, habrían participado.","De haber existido una copia, la consultaríamos.","De haber sido auténtico, lo habrían anunciado.","De haber previsto el riesgo, habríamos esperado.","De haber leído las notas, no lo habría afirmado.","De haber recibido el aviso, habrían respondido.","De haberse verificado, el resultado sería distinto."],grammarMistakes:<String>["De habríamos sabido, habríamos actuado.","De haber saberlo, cambiaríamos."],story:<String>["Un congreso internacional sufrió errores de comunicación cuando el horario de una conferencia cambió. Algunos participantes habían viajado desde lugares muy lejanos.","La coordinadora reconoció que, de haber conocido antes el problema, habría ofrecido sesiones alternativas. Evitó atribuir culpas antes de revisar los mensajes enviados.","El equipo estudió los procedimientos y encontró que una modificación no había sido confirmada por todos los responsables. Preparó un plan de reparación.","Los organizadores ofrecieron nuevas oportunidades a las personas afectadas. La experiencia mostró cómo analizar una decisión pasada puede mejorar futuras responsabilidades.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:9,title:"No fue un error, sino una omisión",titleAr:"تصحيح معنى سابق",grammar:"No ... sino / sino que",grammarAr:"تصحيح معنى سابق",grammarHelpAr:"نستخدم no ... sino لتصحيح فكرة، ومع جملة فعلية يُستعمل غالبًا sino que.",grammarExamples:<String>["No fue un error, sino una omisión.","No rechazó el dato, sino la interpretación.","No querían ocultarlo, sino que pedían tiempo.","No fue Ana quien habló, sino Marta.","No faltaban recursos, sino coordinación.","No presentó una teoría, sino una hipótesis.","No negamos los hechos, sino sus consecuencias.","No era una traducción literal, sino una adaptación."],grammarMistakes:<String>["No fue un error, pero una omisión.","No querían ocultarlo, sino pedían tiempo."],story:<String>["Una revista científica publicó una corrección de un artículo ambiental. El primer comunicado describía una cifra como errónea, pero otros especialistas detectaron un problema diferente.","Los valores eran correctos; el texto había omitido las condiciones en que se habían obtenido. La diferencia modificaba de forma sustancial la interpretación.","La editora explicó que no se trataba de un error de cálculo, sino de una omisión metodológica. Solicitó a los autores ampliar sus explicaciones.","La revista publicó una versión revisada y dejó disponibles los datos originales. La transparencia permitió evaluar las conclusiones sin convertir la corrección en una acusación.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
    SpanishC2Lesson(level:'C2',unit:1,number:10,title:"Sea cual sea la interpretación",titleAr:"التنازل العام",grammar:"Sea cual sea + subjuntivo",grammarAr:"التنازل العام",grammarHelpAr:"نستخدم sea cual sea مع الاسم للدلالة على أن الشرط لا يتغير مهما كانت القراءة أو الإمكانية.",grammarExamples:<String>["Sea cual sea la interpretación, necesitamos pruebas.","Sea cual sea el resultado, lo explicaremos.","Sean cuales sean las objeciones, escucharemos.","Sea cual sea la fuente, comprobaremos su origen.","Sea cual sea el método, debe ser transparente.","Sean cuales sean los costes, deben justificarse.","Sea cual sea la conclusión, será provisional.","Sean cuales sean las alternativas, habrá debate."],grammarMistakes:<String>["Es cual sea la interpretación, necesitamos pruebas.","Sean cualquiera las objeciones, escucharemos."],story:<String>["Un grupo de filósofos debatió distintas interpretaciones de un texto clásico sobre justicia. Algunos destacaban el contexto histórico y otros las consecuencias contemporáneas.","La moderadora recordó que, sea cual sea la interpretación, las afirmaciones deben justificarse con argumentos comprensibles. Pidió distinguir crítica intelectual de ataque personal.","Los participantes compararon traducciones y descubrieron que varias palabras habían cambiado de significado durante siglos. Reconocieron los límites de cada enfoque.","Al concluir, redactaron un documento con los desacuerdos fundamentales. El seminario mostró que aceptar el pluralismo no exige tratar todas las afirmaciones como igualmente fundadas.","El análisis permitió distinguir claramente entre observaciones comprobadas, interpretaciones razonables y afirmaciones que todavía requerían una justificación independiente. Ninguno de los participantes consideró aceptable ocultar las pruebas contrarias.","La discusión se cerró con una conclusión provisional que reconocía sus propias limitaciones. El equipo conservó los documentos y propuso preguntas que podrían orientar nuevas investigaciones más rigurosas."]),
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
