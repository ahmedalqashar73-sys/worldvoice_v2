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
    SpanishB1Lesson(unit:1,number:1,title:"Había preparado el viaje",titleAr:"التحضير قبل حدث ماضٍ",grammar:"Pretérito pluscuamperfecto",grammarAr:"الماضي الأسبق",grammarHelpAr:"نستخدم había + اسم المفعول لحدث وقع قبل حدث آخر في الماضي.",grammarExamples:<String>["Cuando llegué, Ana ya había salido.","Habíamos reservado antes del viaje.","Nunca había visitado aquel lugar.","La conferencia había empezado.","¿Habías leído el reportaje?","Ellos ya habían terminado.","No había visto el correo.","El museo había cerrado."],grammarMistakes:<String>["Yo había reservar una habitación.","Ana habían llegado antes."],story:<String>["Marta trabajaba en un archivo municipal y había planeado una exposición sobre fotografías antiguas. Antes de abrir las cajas, su equipo había preparado una lista de documentos importantes.","El primer día descubrió una fotografía sin fecha. Un vecino reconoció la plaza que aparecía, pero no recordaba cuándo había sido tomada.","Marta habló con una historiadora que ya había investigado la zona. Juntas compararon imágenes y encontraron un artículo publicado años atrás.","Cuando inauguraron la exposición, los visitantes escucharon la explicación con atención. Varias personas compartieron recuerdos de la ciudad que nadie había documentado.","Al cerrar el museo, Marta pensó en todo lo que había aprendido. Comprendió que una buena investigación requiere paciencia y colaboración."]),
    SpanishB1Lesson(unit:1,number:2,title:"Un día que lo cambió todo",titleAr:"ترتيب أحداث الماضي",grammar:"Pluscuamperfecto frente a indefinido",grammarAr:"الماضي البسيط والأسبق",grammarHelpAr:"نستخدم الماضي البسيط للحدث المكتمل والماضي الأسبق لما حدث قبله.",grammarExamples:<String>["Perdí el tren porque ya había salido.","Cuando llamé, ya se habían ido.","Había estudiado antes del examen.","Llegamos y vimos que habían cerrado.","El periodista escribió lo que había oído.","No pude entrar porque había olvidado la entrada.","Ya había comido cuando llegó.","Habíamos dormido antes de salir."],grammarMistakes:<String>["Perdí el tren porque había salir.","Cuando llegamos, ellos había cerrado."],story:<String>["Diego preparaba un reportaje sobre la estación antigua. Había entrevistado a varios viajeros antes de encontrar a una mujer que conocía su historia.","Ella recordó que una inundación había cambiado las rutas de los trenes. Diego buscó fotografías de aquel año y encontró un anuncio sorprendente.","Cuando publicó el reportaje, los lectores escribieron comentarios con recuerdos personales. Algunos corrigieron pequeñas fechas que habían aparecido en el primer borrador.","Diego revisó el texto con cuidado y explicó por qué había cometido los errores. Reconoció que contrastar testimonios era tan importante como escuchar buenas historias.","Al final, convirtió el trabajo en un pequeño documental. La comunidad agradeció que alguien hubiera conservado aquella parte de su memoria colectiva."]),
    SpanishB1Lesson(unit:1,number:3,title:"Dice que viene mañana",titleAr:"نقل أخبار الآخرين",grammar:"Estilo indirecto en presente",grammarAr:"نقل الكلام بالمضارع",grammarHelpAr:"نقول dice que + جملة خبرية، وللسؤال بنعم أو لا نستخدم pregunta si.",grammarExamples:<String>["Ana dice que está cansada.","Luis comenta que vendrá mañana.","La profesora explica que hay examen.","Marta dice que no tiene tiempo.","Pedro pregunta si podemos ayudar.","El guía afirma que el museo abre a las diez.","Mi amiga cree que es interesante.","Ellos dicen que conocen el barrio."],grammarMistakes:<String>["Ana dice de que viene mañana.","Luis pregunta que si vienes."],story:<String>["En una escuela de idiomas, varios alumnos prepararon una entrevista con un escritor local. Cada estudiante debía formular una pregunta diferente.","Al comenzar, la profesora explicó que el invitado llegaría después del recreo. Pablo dijo que quería conocer sus primeras experiencias como autor.","Cuando el escritor entró, los estudiantes escucharon atentamente. Una alumna preguntó si era difícil publicar un libro y otro quiso saber cómo encontraba ideas.","Después de la visita, los alumnos resumieron las respuestas para un pequeño periódico escolar. Compararon lo que habían entendido y corrigieron algunos detalles.","La profesora felicitó al grupo porque había trabajado de forma respetuosa. Todos comprendieron la importancia de reproducir correctamente las palabras de otra persona."]),
    SpanishB1Lesson(unit:1,number:4,title:"Me dijo que estaba ocupado",titleAr:"نقل الكلام في الماضي",grammar:"Estilo indirecto en pasado",grammarAr:"نقل الخبر في الماضي",grammarHelpAr:"عند نقل قول قديم قد يتغير المضارع إلى الماضي الناقص حسب السياق.",grammarExamples:<String>["Ana dijo que estaba cansada.","Luis explicó que vivía en Madrid.","Mi jefe comentó que tenía tiempo.","Ellos dijeron que no podían ir.","La vecina contó que trabajaba allí.","Me dijo que necesitaba ayuda.","El profesor afirmó que era importante.","María pensó que todo iba bien."],grammarMistakes:<String>["Luis dijo que estábamos ocupado.","Ana me dijiste que vivía en Madrid."],story:<String>["Clara entrevistó a su abuelo para preparar una historia de familia. Él le contó que antes vivía en un pueblo pequeño junto al mar.","También explicó que las personas se conocían bien y que solían ayudarse cuando había problemas. Clara escribió sus palabras sin interrumpir.","Al día siguiente comentó la entrevista con su madre. Dijo que el abuelo recordaba las fiestas populares y que todavía conservaba fotografías.","Su madre le enseñó una carta que había guardado durante muchos años. La información coincidía con varios de los recuerdos del abuelo.","Clara escribió un relato basado en ambas fuentes. Aprendió que una historia resulta más rica cuando recoge distintas voces."]),
    SpanishB1Lesson(unit:1,number:5,title:"Mientras leía, sonó el teléfono",titleAr:"حدث أثناء فعل مستمر",grammar:"Mientras + imperfecto",grammarAr:"بينما كان الفعل مستمرًا",grammarHelpAr:"نستخدم mientras مع الماضي الناقص لوصف فعل جارٍ، والماضي البسيط للحدث الذي قطعه.",grammarExamples:<String>["Mientras leía, sonó el teléfono.","Cocinábamos cuando llegaron.","Mientras esperaban, empezó a llover.","Yo estudiaba cuando llamaste.","Mientras ella escribía, entró el director.","Íbamos por la calle cuando vimos el cartel.","Mientras escuchaba, tomó notas.","Jugábamos cuando se apagó la luz."],grammarMistakes:<String>["Mientras leí, sonaba el teléfono de repente.","Mientras esperaba, empezó llovía."],story:<String>["Pablo estaba leyendo en la biblioteca cuando escuchó un ruido extraño. Levantó la vista y vio que varias personas miraban hacia la entrada.","Mientras una empleada llamaba al responsable, un visitante explicó que había perdido una carpeta importante. Pablo se ofreció a buscarla.","Recorrieron las mesas y preguntaron a otros estudiantes. Una mujer recordó que había visto la carpeta junto a los periódicos.","Cuando la encontraron, el visitante dio las gracias a todos. La carpeta contenía documentos que necesitaba para una entrevista.","Pablo volvió a su libro y pensó que la colaboración había resuelto un problema. Aquella tarde aprendió algo más que lo que decía el texto."]),
    SpanishB1Lesson(unit:1,number:6,title:"Se publican los resultados",titleAr:"المبني للمجهول دون فاعل",grammar:"Pasiva refleja con se",grammarAr:"المجهول باستخدام se",grammarHelpAr:"الفعل يتفق في العدد مع الاسم: se vende una casa و se venden casas.",grammarExamples:<String>["Se publican las noticias cada día.","Se vende una casa.","Se venden entradas aquí.","Se organizan visitas guiadas.","Se necesita personal.","Se buscan voluntarios.","Se preparan comidas tradicionales.","Se aceptan sugerencias."],grammarMistakes:<String>["Se venden una casa.","Se publica las noticias diariamente."],story:<String>["El centro cultural del barrio anunció un concurso de relatos. Las normas se publicaron en internet y también se colocaron en la entrada del edificio.","Se aceptaban textos de estudiantes de distintas edades. Los organizadores explicaron que se valorarían especialmente las historias relacionadas con la ciudad.","Durante dos semanas llegaron numerosos trabajos. Se organizaron reuniones para leerlos y elegir los que mejor representaban la diversidad de experiencias.","Finalmente se anunciaron los resultados en una exposición. Los participantes escucharon fragmentos de sus relatos y compartieron ideas sobre escritura.","El equipo se sintió orgulloso porque se habían creado nuevas oportunidades para los vecinos. Decidieron repetir el concurso el año siguiente."]),
    SpanishB1Lesson(unit:1,number:7,title:"La persona con quien hablé",titleAr:"الإشارة إلى الأشخاص",grammar:"Quien y quienes",grammarAr:"ضمائر الوصل للأشخاص",grammarHelpAr:"نستخدم quien و quienes غالبًا بعد حرف جر أو في جملة توضيحية للإشارة إلى أشخاص.",grammarExamples:<String>["La mujer con quien hablé es historiadora.","Los alumnos a quienes invité llegaron.","Mi abuelo, quien vive aquí, nos ayudó.","Las personas con quienes trabajo son amables.","El vecino de quien hablamos llegó.","Ana, quien organizó el taller, sonrió.","La guía con quien viajamos era excelente.","Son amigos en quienes confío."],grammarMistakes:<String>["La mujer con quienes hablé es amable.","Los alumnos a quien invité llegaron."],story:<String>["Nuria organizó una exposición sobre antiguos oficios. Buscó personas con quienes pudiera hablar y encontró a una artesana que llevaba décadas trabajando la madera.","La artesana, quien había aprendido de su padre, mostró herramientas antiguas y explicó cómo habían cambiado las costumbres.","Nuria invitó también a varios estudiantes a quienes les interesaba el tema. Prepararon preguntas y grabaron las entrevistas con permiso.","Durante la exposición, los visitantes reconocieron objetos que habían utilizado sus familiares. Algunos compartieron experiencias personales y enriquecieron el contenido.","Al terminar, Nuria agradeció a todas las personas con quienes había colaborado. Sintió que conservar la memoria también ayuda a comprender el presente."]),
    SpanishB1Lesson(unit:1,number:8,title:"Lo que más me sorprendió",titleAr:"الإشارة إلى فكرة كاملة",grammar:"Lo que + oración",grammarAr:"اسم الموصول lo que",grammarHelpAr:"نستخدم lo que للإشارة إلى شيء أو فكرة كاملة، مثل lo que dijiste بمعنى ما قلته.",grammarExamples:<String>["Lo que dijiste fue útil.","No entiendo lo que pasó.","Me gustó lo que propusiste.","Lo que aprendí cambió mi opinión.","Explica lo que necesitas.","Lo que importa es colaborar.","Lo que me preocupa es el tiempo.","Recuerda lo que prometimos."],grammarMistakes:<String>["La que dijiste fue útil sin sustantivo.","No entiendo que lo pasó."],story:<String>["Una periodista visitó un pueblo que había cambiado mucho en pocos años. Quería escuchar a los habitantes para comprender lo que había ocurrido.","Los vecinos mostraron fotografías y explicaron lo que más les preocupaba. Algunos hablaban del empleo y otros del cuidado de los espacios naturales.","La periodista tomó notas y preguntó qué soluciones habían intentado. Lo que descubrió fue más complejo de lo que esperaba.","De regreso al periódico, comparó las entrevistas con documentos oficiales. Decidió presentar distintas perspectivas sin exagerar las diferencias.","Cuando se publicó el artículo, la comunidad reconoció su trabajo. Lo que todos valoraron fue el respeto con que se habían contado las historias."]),
    SpanishB1Lesson(unit:1,number:9,title:"Esta semana he aprendido mucho",titleAr:"اختيار الزمن بحسب الفترة",grammar:"Perfecto frente a indefinido",grammarAr:"الماضي القريب والماضي البسيط",grammarHelpAr:"نستخدم perfecto مع فترة مرتبطة بالحاضر و indefinido مع فترة ماضية انتهت، حسب المنطقة والسياق.",grammarExamples:<String>["Esta semana he leído dos artículos.","Ayer leí uno muy interesante.","Hoy hemos aprendido mucho.","El año pasado viajé a Chile.","¿Alguna vez has participado?","Hace dos días terminé el proyecto.","Últimamente he estudiado más.","El lunes pasado fui a clase."],grammarMistakes:<String>["Ayer he compré un billete.","Hoy ayer viajé he viajado."],story:<String>["El curso de fotografía de Inés comenzó hace un mes. Esta semana ha aprendido técnicas nuevas para hacer retratos en exteriores.","El sábado pasado visitó un mercado y tomó numerosas fotografías. Allí habló con comerciantes que compartieron historias sobre el barrio.","Hoy ha revisado las imágenes con su profesora. Juntas han elegido las mejores para una pequeña exposición al final del curso.","Inés recordó que al principio le costaba pedir permiso para fotografiar. Ahora se siente más segura y sabe explicar su proyecto con claridad.","Al volver a casa escribió un breve diario de aprendizaje. Comparó lo que hizo el mes pasado con lo que ha logrado esta semana."]),
    SpanishB1Lesson(unit:1,number:10,title:"La información más fiable",titleAr:"التعبير عن المقارنة في النقاش",grammar:"Comparativos con más, menos y tan",grammarAr:"مقارنة المعلومات والآراء",grammarHelpAr:"نستخدم más ... que أو menos ... que للمقارنة و tan ... como للتساوي.",grammarExamples:<String>["Esta fuente es más fiable que aquella.","El informe es menos completo que el artículo.","Mi conclusión es tan clara como la tuya.","La entrevista fue más útil de lo previsto.","Esta explicación es menos precisa.","El estudio es tan relevante como el anterior.","La segunda opinión parece mejor.","Un ejemplo concreto resulta más convincente."],grammarMistakes:<String>["Esta fuente es más fiable como aquella.","El informe es menos completo de aquel."],story:<String>["Dos estudiantes prepararon un reportaje sobre el transporte de su ciudad. Buscaron información en varios sitios y encontraron datos diferentes.","Una fuente era más reciente, pero la otra explicaba mejor el problema. Los estudiantes compararon los números antes de escribir su propuesta.","La profesora les recordó que una fuente popular no siempre es más fiable. Debían comprobar la fecha, el origen y el contexto de cada dato.","Después entrevistaron a personas que utilizaban el autobús todos los días. Los testimonios aportaron ejemplos que los números no mostraban.","Al presentar el trabajo, defendieron sus conclusiones con respeto. Comprendieron que comparar críticamente ayuda a evitar decisiones precipitadas."]),
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
