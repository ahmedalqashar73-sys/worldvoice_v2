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
    SpanishB2Lesson(unit:1,number:1,title:"Ojalá cambiara la historia",titleAr:"التعبير عن الأمنية",grammar:"Ojalá + imperfecto de subjuntivo",grammarAr:"الأماني غير المتحققة أو البعيدة",grammarHelpAr:"بعد ojalá نستخدم الماضي الناقص من subjuntivo للتعبير عن أمنية يصعب تحقيقها الآن.",grammarExamples:<String>["Ojalá tuviera más tiempo.","Ojalá pudiéramos participar.","Ojalá la noticia fuera cierta.","Ojalá hablaras con el director.","Ojalá no hubiera tantos rumores.","Ojalá el archivo estuviera abierto.","Ojalá alguien explicara el problema.","Ojalá supiéramos la verdad."],grammarMistakes:<String>["Ojalá tengo más tiempo.","Ojalá nosotros podemos participar."],story:<String>["Una periodista llegó al archivo municipal para investigar una fotografía que circulaba por internet. Muchos vecinos afirmaban reconocer a la persona que aparecía en ella, pero sus testimonios no coincidían entre sí.","El archivero le mostró el documento original y explicó que faltaba una parte del registro. La periodista pensó que ojalá existiera una copia completa, porque podría aclarar el origen de la imagen.","Al entrevistar a los vecinos, descubrió que algunos recordaban hechos de distintas épocas. Un testigo reconoció que había repetido una historia sin comprobar nunca su fuente.","En lugar de publicar una explicación apresurada, la periodista comparó las fechas con otros documentos. Su editor aceptó retrasar el reportaje para evitar una conclusión engañosa.","Cuando finalmente salió el artículo, no ofrecía una respuesta definitiva, pero mostraba qué datos podían verificarse. Los lectores agradecieron aquella cautela poco habitual."]),
    SpanishB2Lesson(unit:1,number:2,title:"Era necesario que escucháramos",titleAr:"exigir un cambio en الماضي",grammar:"Era necesario que + imperfecto de subjuntivo",grammarAr:"الضرورة في الماضي",grammarHelpAr:"مع era necesario que نستخدم فعلًا في الماضي الناقص من subjuntivo لوصف أمر كان مطلوبًا.",grammarExamples:<String>["Era necesario que todos escucharan.","Era importante que revisáramos el informe.","Hacía falta que aclararas la fecha.","Era urgente que el portavoz respondiera.","Era conveniente que contrastaran los datos.","Era imprescindible que llegáramos a un acuerdo.","Era mejor que consultaras el archivo.","Era necesario que la reunión continuara."],grammarMistakes:<String>["Era necesario que todos escuchaban.","Era importante que nosotros revisamos el informe."],story:<String>["El consejo escolar reunió a familias y docentes para tratar el cierre de una biblioteca. La propuesta había provocado una controversia porque el barrio carecía de otros espacios de estudio gratuitos.","La directora explicó que era necesario que todos escucharan antes de votar. Una asociación había preparado cifras sobre el uso de la biblioteca, mientras varios vecinos aportaban experiencias personales.","El debate se complicó cuando aparecieron dos presupuestos diferentes. Para comparar correctamente los datos, el consejo pidió a los responsables que aclararan sus criterios.","Una profesora propuso mantener abierto el edificio durante un periodo de prueba. Su alternativa parecía viable, pero exigía que la comunidad colaborara y revisara los resultados.","Al terminar la reunión, nadie afirmó que el conflicto estuviera resuelto. Sin embargo, el grupo acordó analizar nuevas opciones con mayor transparencia."]),
    SpanishB2Lesson(unit:1,number:3,title:"Aunque resulte difícil",titleAr:"dos perspectivas sobre un hecho",grammar:"Aunque + indicativo o subjuntivo",grammarAr:"التمييز بين الواقع والاحتمال مع aunque",grammarHelpAr:"مع aunque نستعمل indicativo لحقيقة معروفة، وsubjuntivo لافتراض أو معلومة غير مؤكدة.",grammarExamples:<String>["Aunque llueve, salimos.","Aunque llueva, saldremos.","Aunque el informe es largo, resulta claro.","Aunque el informe sea largo, lo leeré.","Aunque conozco el barrio, consulto el mapa.","Aunque no se conozca la causa, investigaremos.","Aunque ya terminó, seguimos hablando.","Aunque parezca improbable, merece estudiarse."],grammarMistakes:<String>["Aunque lloverá mañana, saldremos.","Aunque sea una verdad que el informe es largo, resulta claro."],story:<String>["Una guía organizó una ruta cultural para mostrar lugares poco conocidos de la ciudad. Aunque el recorrido era corto, incluía edificios cuya historia resultaba difícil de reconstruir.","Algunos participantes dudaban de que mereciera la pena entrar en un archivo pequeño. La guía respondió que, aunque pareciera menos interesante que un museo famoso, contenía testimonios valiosos.","Durante la visita encontraron dos versiones diferentes sobre un antiguo puente. Una procedía de una crónica oficial y otra de una carta familiar conservada por un vecino.","La guía explicó por qué una fuente no debía rechazarse únicamente por ser personal. Animó al grupo a contrastar cada interpretación con documentos de la época.","Al final, los visitantes redactaron sus propias conclusiones. Aunque no llegaron a un acuerdo absoluto, aprendieron a expresar desacuerdos sin confundir hipótesis con hechos."]),
    SpanishB2Lesson(unit:1,number:4,title:"Si tuviera los datos",titleAr:"hipótesis del presente",grammar:"Si + imperfecto de subjuntivo + condicional",grammarAr:"الشرط الافتراضي في الحاضر",grammarHelpAr:"لوصف موقف غير حقيقي أو بعيد الاحتمال نستخدم si + imperfecto de subjuntivo ثم condicional.",grammarExamples:<String>["Si tuviera tiempo, investigaría más.","Si supiéramos la respuesta, la explicaríamos.","Si hubiera una copia, la consultaríamos.","Si fueras portavoz, ¿qué dirías?","Si la fuente fuera fiable, la citaría.","Si pudieran participar, aportarían ideas.","Si encontráramos pruebas, cambiaríamos la conclusión.","Si yo estuviera allí, escucharía a todos."],grammarMistakes:<String>["Si tendría tiempo, investigaría más.","Si sabemos la respuesta, la explicaríamos en una hipótesis irreal."],story:<String>["Una estudiante de periodismo preparaba un reportaje sobre una fábrica abandonada. Quería saber si el edificio podía convertirse en un espacio cultural, pero no encontraba información reciente sobre su estado.","En una reunión, su compañero dijo que si tuvieran los datos necesarios podrían comparar varios proyectos. Otra estudiante sugirió entrevistar a residentes antes de formular propuestas.","El equipo examinó antiguos presupuestos y descubrió que las cifras no incluían el coste de las reparaciones. Comprendieron que una alternativa atractiva no siempre era económicamente viable.","Mientras trabajaban, discutieron qué preguntas debían formular al ayuntamiento. Decidieron distinguir lo que sabían de aquello que todavía necesitaban comprobar.","Su reportaje terminó con diferentes escenarios posibles, no con una recomendación definitiva. La profesora destacó que reconocer la incertidumbre era una muestra de pensamiento crítico."]),
    SpanishB2Lesson(unit:1,number:5,title:"Habríamos llegado antes",titleAr:"posibilidades no realizadas",grammar:"Condicional compuesto",grammarAr:"ما كان يمكن أن يحدث",grammarHelpAr:"نستخدم habría + participio للتعبير عن نتيجة افتراضية أو posibilidad no realizada en el pasado.",grammarExamples:<String>["Habríamos llegado antes.","Yo habría publicado otra versión.","Ella habría revisado la noticia.","¿Habrías aceptado la propuesta?","No habrían podido entrar.","El director habría solicitado otro informe.","Habría sido una decisión arriesgada.","Los vecinos habrían apoyado la iniciativa."],grammarMistakes:<String>["Yo habría publica otra versión.","Ellos habría llegado antes."],story:<String>["Un equipo de documentalistas viajó a una comarca montañosa para entrevistar a personas mayores. Habían preparado una agenda cuidadosa, pero una avería retrasó el autobús durante varias horas.","La investigadora principal comentó que habrían llegado antes con otro transporte. Sin embargo, reconoció que nadie podía prever aquella avería y que culpar al conductor sería injusto.","Cuando llegaron, una de las entrevistadas ya había salido de viaje. Los documentalistas decidieron no inventar su testimonio y reorganizar el calendario para volver otro día.","Aprovecharon la tarde para consultar fotografías antiguas y conversar con el bibliotecario. Aquellos documentos ofrecieron información que no aparecía en las fuentes publicadas.","De regreso, el equipo revisó sus decisiones y explicó las limitaciones del proyecto. El documental final mostró tanto los hallazgos como las oportunidades perdidas."]),
    SpanishB2Lesson(unit:1,number:6,title:"Esperaba que hubieran respondido",titleAr:"expectativas anteriores",grammar:"Pluscuamperfecto de subjuntivo",grammarAr:"حدث كان مأمولًا قبل نقطة ماضية",grammarHelpAr:"نستخدم hubiera o hubiese + participio بعد أفعال التوقع والتقييم الماضية للإشارة إلى حدث سابق غير مؤكد.",grammarExamples:<String>["Esperaba que hubieran respondido.","Me alegró que hubieras venido.","Dudaba que lo hubieran publicado.","Era lógico que hubiésemos preguntado.","No creía que el rumor se hubiera extendido.","Ojalá hubieran conservado el archivo.","Temíamos que se hubiese perdido.","Me sorprendió que hubieran rectificado."],grammarMistakes:<String>["Esperaba que habían respondido.","Me alegró que tú has venido ayer."],story:<String>["Una investigadora regresó a su universidad después de visitar varios archivos locales. Esperaba que los expertos hubieran respondido a sus preguntas antes de una conferencia internacional.","Al revisar el correo descubrió que algunos documentos todavía no estaban disponibles. Una colega dudaba que la institución hubiera digitalizado los registros más antiguos.","La investigadora llamó al archivo para conocer los plazos reales. La empleada explicó que el equipo había tenido problemas técnicos y que necesitaba tiempo para resolverlos.","En la conferencia, la investigadora presentó los datos que podía verificar y reconoció las lagunas restantes. Rechazó utilizar un gráfico atractivo cuya procedencia no estaba clara.","Sus compañeros valoraron especialmente esa decisión. Entendieron que una investigación rigurosa debe explicar qué pruebas faltan y no solo qué resultados se han obtenido."]),
    SpanishB2Lesson(unit:1,number:7,title:"Si hubiéramos sabido la verdad",titleAr:"situaciones irreales pasadas",grammar:"Si + pluscuamperfecto de subjuntivo",grammarAr:"شرط مستحيل التحقق في الماضي",grammarHelpAr:"نستخدم si hubiera + participio ثم habría + participio لوصف شرط ماضٍ لم يحدث ونتيجته المفترضة.",grammarExamples:<String>["Si hubiéramos sabido la verdad, habríamos actuado antes.","Si hubiera llovido, habrían cancelado el acto.","Si me hubieras avisado, habría acudido.","Si el informe hubiera llegado, lo habríamos leído.","Si ella hubiera tenido pruebas, habría cambiado de idea.","Si hubieran escuchado, habrían evitado el conflicto.","Si hubiera sido posible, habríamos esperado.","Si no hubiéramos perdido el mapa, habríamos llegado."],grammarMistakes:<String>["Si habríamos sabido la verdad, habríamos actuado.","Si hubiera sabido, habría actuar antes."],story:<String>["Una asociación vecinal organizó una jornada para recuperar un jardín comunitario. Los voluntarios llegaron temprano, pero encontraron la entrada cerrada y el material almacenado en otro edificio.","El coordinador explicó que la reserva había sido modificada sin que el grupo recibiera el aviso. Algunas personas dijeron que, si lo hubieran sabido, habrían elegido otra fecha.","En vez de abandonar el proyecto, buscaron una alternativa en un parque cercano. Tuvieron que modificar el programa y reducir el número de actividades previstas.","Durante la tarde, los organizadores revisaron sus procedimientos de comunicación. Reconocieron que habían confiado demasiado en un único mensaje que nunca fue confirmado.","El encuentro terminó con nuevas propuestas para el futuro. Aprendieron que analizar errores pasados resulta útil cuando conduce a decisiones más responsables."]),
    SpanishB2Lesson(unit:1,number:8,title:"Me contó que viajaría",titleAr:"reported speech retrospectivo",grammar:"Estilo indirecto: condicional de futuro",grammarAr:"نقل المستقبل من نقطة زمنية ماضية",grammarHelpAr:"عندما ننقل توقعًا مستقبليًا قيل في الماضي، غالبًا يتحول viajaré إلى dijo que viajaría.",grammarExamples:<String>["Me dijo: «Viajaré». Luego me contó que viajaría.","Ana afirmó que regresaría pronto.","El guía anunció que comenzarían a las nueve.","El portavoz aseguró que explicarían la decisión.","Luis prometió que escribiría después.","Ella creyó que encontraría pruebas.","Nos dijeron que volverían mañana.","El profesor comentó que habría cambios."],grammarMistakes:<String>["Me contó que viajará el mes siguiente en ese pasado.","El portavoz dijo que explicarán ayer."],story:<String>["Una periodista entrevistó a un portavoz después de una reunión importante. Él afirmó que presentaría un informe completo la semana siguiente y respondería a las preguntas pendientes.","La periodista anotó sus palabras y comprobó el calendario oficial. Un compañero le advirtió de que las promesas no equivalían todavía a decisiones confirmadas.","Días después, el documento aún no se había publicado. Algunos medios afirmaban que el portavoz había incumplido el plazo, aunque el anuncio original era ambiguo.","La periodista revisó la grabación y distinguió entre una fecha concreta y una intención general. Decidió citar el fragmento completo para evitar interpretaciones engañosas.","Su artículo explicó qué se había prometido, qué seguía pendiente y por qué importaba esa diferencia. El editor valoró la precisión con que trató la información."]),
    SpanishB2Lesson(unit:1,number:9,title:"Buscamos a alguien que conozca",titleAr:"referentes desconocidos",grammar:"Relativas: subjuntivo con antecedente indefinido",grammarAr:"الموصول مع شخص أو شيء غير محدد",grammarHelpAr:"نستخدم subjuntivo بعد que إذا كنا نبحث عن شخص أو شيء غير معروف أو غير مؤكد الوجود.",grammarExamples:<String>["Busco a alguien que hable árabe.","Necesitamos un informe que sea fiable.","¿Conoces a alguien que pueda ayudar?","Quieren un lugar donde haya silencio.","No encuentro una fuente que confirme el dato.","Buscamos personas que tengan experiencia.","Necesito un guía que conozca la ciudad.","Queremos una solución que funcione."],grammarMistakes:<String>["Busco a alguien que habla árabe y no conozco a nadie.","Necesitamos un informe que es fiable pero no sabemos si existe."],story:<String>["Un museo local buscaba una persona que conociera la historia de un antiguo mercado. La directora quería preparar una exposición, pero apenas disponía de documentos sobre los comerciantes originales.","El equipo publicó una convocatoria para encontrar a alguien que pudiera explicar las tradiciones del barrio. Varias personas respondieron y ofrecieron fotografías familiares y recuerdos personales.","Una candidata había trabajado en el archivo municipal y conocía bien la zona. Sin embargo, reconoció que todavía existían preguntas que no podía responder con seguridad.","La directora decidió crear un pequeño grupo de investigación con diferentes especialistas. Prefería una explicación incompleta pero verificable a un relato emocionante sin fundamento.","La exposición abrió con documentos originales y testimonios identificados. Los visitantes pudieron conocer distintas perspectivas y formular sus propias preguntas."]),
    SpanishB2Lesson(unit:1,number:10,title:"Es posible que existan pruebas",titleAr:"duda frente a certeza",grammar:"Es posible que + subjuntivo",grammarAr:"الاحتمال وعدم الجزم",grammarHelpAr:"نستخدم subjuntivo بعد es posible que، أما es evidente que في الجمل المثبتة فيتبعه indicativo.",grammarExamples:<String>["Es posible que existan pruebas.","Puede que el testigo se equivoque.","Es posible que lleguen tarde.","No es seguro que el documento sea auténtico.","Es evidente que el archivo está cerrado.","Es posible que haya otra versión.","Quizá el informe contenga errores.","Es posible que necesitemos más datos."],grammarMistakes:<String>["Es posible que existen pruebas.","Es evidente que el documento sea auténtico en una afirmación."],story:<String>["Dos investigadores analizaron una noticia sobre un hallazgo arqueológico. El titular afirmaba que se había descubierto un objeto único, pero el informe original utilizaba expresiones mucho más prudentes.","Una especialista explicó que era posible que la pieza perteneciera a una época anterior. Todavía necesitaban estudiar los materiales y comparar otros objetos semejantes.","Un periodista preguntó por qué no podían ofrecer una conclusión definitiva. La investigadora aclaró que una hipótesis prometedora no debe presentarse como una certeza demostrada.","El equipo decidió publicar imágenes y métodos de análisis para facilitar la revisión de otros expertos. El proceso requería tiempo, pero aumentaba la credibilidad del trabajo.","Al terminar, el periodista cambió el titular por uno más preciso. Comprendió que informar con rigor también significa expresar correctamente la duda."]),
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
