import 'academy_spanish_a1_course.dart';

/// Only Spanish A2. Ten units' worth of material are NOT implied:
/// three published units × ten authored integrated lessons.
class SpanishA2Lesson extends SpanishA1Lesson {
  const SpanishA2Lesson({required super.unit, required super.number,
    required super.title, required super.titleAr, required super.grammar,
    required super.grammarAr, required super.grammarHelpAr,
    required super.grammarExamples, required super.story});

  @override
  String get id => 'worldvoice.es.a2.u$unit.l${number.toString().padLeft(2, '0')}';

  @override
  List<SpanishA1Word> get words => SpanishA2Course.wordsFor(unit, number);
}

class SpanishA2Unit extends SpanishA1Unit {
  const SpanishA2Unit(super.number, super.title, super.arabic);

  @override
  List<SpanishA2Lesson> get lessons => SpanishA2Course.lessons
      .where((lesson) => lesson.unit == number).toList(growable: false);
}

abstract final class SpanishA2Course {
  static const units = <SpanishA2Unit>[
    SpanishA2Unit(1, 'Viajes y recuerdos', 'السفر والتجارب والذكريات'),
    SpanishA2Unit(2, 'Salud, hogar y proyectos', 'الصحة والمنزل والمشروعات'),
    SpanishA2Unit(3, 'Decisiones y sociedad', 'القرارات والتواصل والحياة الاجتماعية'),
  ];

  static const _core = <SpanishWordKind, String>{
    SpanishWordKind.noun: "experiencia|تجربة;recuerdo|ذكرى;decisión|قرار;oportunidad|فرصة;problema|مشكلة;solución|حل;consejo|نصيحة;costumbre|عادة;proyecto|مشروع;noticia|خبر;cambio|تغيير;opinión|رأي;objetivo|هدف;resultado|نتيجة;explicación|تفسير;invitación|دعوة;reunión|اجتماع;viaje|رحلة;compañero|زميل;vecino|جار",
    SpanishWordKind.verb: "recordar|يتذكر;explicar|يشرح;decidir|يقرر;organizar|ينظم;descubrir|يكتشف;mejorar|يحسن;recomendar|يوصي;preparar|يجهز;participar|يشارك;resolver|يحل;comparar|يقارن;conseguir|يتمكن من;aprovechar|يستفيد من;disfrutar|يستمتع;ocurrir|يحدث;preferir|يفضل;intentar|يحاول;comunicar|يوصل;proponer|يقترح;continuar|يواصل",
    SpanishWordKind.adjective: "inesperado|غير متوقع;agradable|ممتع;complicado|معقد;útil|مفيد;necesario|ضروري;posible|ممكن;emocionante|مثير;tranquilo|هادئ;difícil|صعب;importante|مهم;habitual|معتاد;especial|مميز;diferente|مختلف;sencillo|بسيط;positivo|إيجابي;negativo|سلبي;responsable|مسؤول;disponible|متاح;interesante|مثير للاهتمام;práctico|عملي",
    SpanishWordKind.adverb: "recientemente|مؤخرًا;normalmente|عادة;frecuentemente|غالبًا;raramente|نادرًا;cuidadosamente|بعناية;fácilmente|بسهولة;claramente|بوضوح;probablemente|على الأرجح;realmente|حقًا;finalmente|أخيرًا;inmediatamente|فورًا;especialmente|خصوصًا;lentamente|ببطء;rápidamente|بسرعة;tranquilamente|بهدوء;perfectamente|بشكل ممتاز;desgraciadamente|للأسف;afortunadamente|لحسن الحظ;todavía|ما زال;últimamente|في الآونة الأخيرة",
  };
  static const _focused = <int, Map<SpanishWordKind, String>>{
    1: <SpanishWordKind, String>{
      SpanishWordKind.noun: "maleta|حقيبة سفر;alojamiento|سكن مؤقت;reserva|حجز;recepción|استقبال;equipaje|أمتعة;itinerario|مسار الرحلة;billete|تذكرة;destino|وجهة;estación|محطة;excursión|رحلة قصيرة",
      SpanishWordKind.verb: "reservar|يحجز;cancelar|يلغي;saludar|يحيّي;llegar|يصل;salir|يغادر;regresar|يعود;visitar|يزور;recoger|يستلم;perder|يفقد;encontrar|يجد",
      SpanishWordKind.adjective: "puntual|دقيق بالمواعيد;retrasado|متأخر;turístico|سياحي;lejano|بعيد;local|محلي;cómodo|مريح;lleno|ممتلئ;vacío|فارغ;seguro|آمن;económico|اقتصادي",
      SpanishWordKind.adverb: "ayer|أمس;anoche|الليلة الماضية;anteayer|أول أمس;temprano|مبكرًا;tarde|متأخرًا;fuera|في الخارج;dentro|في الداخل;cerca|قريبًا;lejos|بعيدًا;después|بعد ذلك",
    },
    2: <SpanishWordKind, String>{
      SpanishWordKind.noun: "salud|صحة;receta|وصفة طبية;enfermedad|مرض;medicina|دواء;cita|موعد;ejercicio|تمرين;alimentación|تغذية;descanso|راحة;amistad|صداقة;afición|هواية",
      SpanishWordKind.verb: "descansar|يستريح;entrenar|يتدرب;recuperarse|يتعافى;consultar|يستشير;seguir|يتبع;cocinar|يطبخ;limpiar|ينظف;reparar|يصلح;compartir|يتشارك;cuidar|يعتني",
      SpanishWordKind.adjective: "saludable|صحي;cansado|متعب;ocupado|مشغول;libre|متفرغ;enfermo|مريض;fuerte|قوي;débil|ضعيف;natural|طبيعي;fresco|طازج;delicioso|لذيذ",
      SpanishWordKind.adverb: "diariamente|يوميًا;semanalmente|أسبوعيًا;regularmente|بانتظام;suavemente|برفق;mal|بشكل سيئ;bien|جيدًا;solamente|فقط;siempre|دائمًا;nunca|أبدًا;juntos|معًا",
    },
    3: <SpanishWordKind, String>{
      SpanishWordKind.noun: "comercio|تجارة;devolución|إرجاع;reclamación|شكوى;descuento|خصم;factura|فاتورة;presupuesto|ميزانية;documento|وثيقة;entrevista|مقابلة;curso|دورة;presentación|عرض تقديمي",
      SpanishWordKind.verb: "devolver|يعيد;solicitar|يطلب رسميًا;confirmar|يؤكد;quejarse|يشتكي;entregar|يسلم;elegir|يختار;contratar|يوظف;anunciar|يعلن;negociar|يتفاوض;ahorrar|يوفر المال",
      SpanishWordKind.adjective: "profesional|مهني;formal|رسمي;informal|غير رسمي;caro|غالي;barato|رخيص;correcto|صحيح;equivocado|خاطئ;justo|عادل;urgente|عاجل;adecuado|مناسب",
      SpanishWordKind.adverb: "formalmente|رسميًا;personalmente|شخصيًا;por escrito|كتابيًا;en línea|عبر الإنترنت;directamente|مباشرة;brevemente|باختصار;correctamente|بشكل صحيح;amablemente|بلطف;pacientemente|بصبر;exactamente|بدقة",
    },
  };

  static List<SpanishA1Word> wordsFor(int unit, int lesson) {
    if (unit < 1 || unit > 3 || lesson < 1 || lesson > 10) {
      throw RangeError('Spanish A2 unit/lesson out of range');
    }
    final result = <SpanishA1Word>[];
    for (final kind in SpanishWordKind.values) {
      final core = _core[kind]!.split(';');
      final focused = _focused[unit]![kind]!.split(';');
      for (var i = 0; i < 5; i++) {
        final common = core[((lesson - 1) * 3 + i) % core.length].split('|');
        final local = focused[((lesson - 1) * 3 + i) % focused.length].split('|');
        result.add(SpanishA1Word(common[0], common[1], kind));
        result.add(SpanishA1Word(local[0], local[1], kind));
      }
    }
    return List<SpanishA1Word>.unmodifiable(result);
  }

  static List<SpanishA1Word> wordsOf(SpanishA2Lesson lesson, SpanishWordKind kind) =>
      lesson.words.where((w) => w.kind == kind).toList(growable: false);

  static const lessons = <SpanishA2Lesson>[
    SpanishA2Lesson(unit:1, number:1,
      title:"Ya he visitado Madrid", titleAr:"خبرات السفر",
      grammar:"Pretérito perfecto con haber", grammarAr:"الماضي القريب: he / has + التصريف الثالث",
      grammarHelpAr:"نستخدم he أو has أو ha مع اسم المفعول للتعبير عن خبرة أو حدث له صلة بالحاضر.",
      grammarExamples:<String>["He visitado Madrid.","¿Has comprado los billetes?","Ella ha llegado temprano.","Hemos preparado las maletas.","Todavía no he terminado.","¿Habéis visto el museo?"],
      story:<String>["Una estudiante de intercambio llegó a Madrid con muchas ganas de conocer la ciudad. En el tren habló con una pareja que le recomendó varios museos y barrios tranquilos. La conversación le ayudó a sentirse menos nerviosa.","Al llegar al alojamiento descubrió que había olvidado el número de la reserva. Buscó en su teléfono, pero la conexión era lenta y la recepción estaba muy ocupada.","Una empleada escuchó su explicación y encontró la reserva por su nombre. La joven pudo dejar la maleta y salir a conocer la ciudad. Esa noche escribió a su familia para contar la experiencia.","Al día siguiente visitó el museo de historia y aprendió algo nuevo sobre el barrio. Comprendió que viajar también significa resolver pequeños problemas sin perder la calma."]),
    SpanishA2Lesson(unit:1, number:2,
      title:"Ayer compré un billete", titleAr:"حدث انتهى في الماضي",
      grammar:"Pretérito indefinido: verbos -ar", grammarAr:"الماضي البسيط لأفعال -ar",
      grammarHelpAr:"لحدث مكتمل في وقت ماضٍ محدد، نحول hablar إلى hablé مع yo و habló مع él أو ella.",
      grammarExamples:<String>["Ayer compré un billete.","Ana visitó el museo.","Nosotros viajamos el sábado.","Ellos reservaron una habitación.","¿Cuándo llegaste?","Anoche cenamos juntos."],
      story:<String>["Lucía salió de casa temprano porque quería comprar un billete para visitar a su hermana. La estación estaba llena de viajeros, y las pantallas anunciaban varios cambios en los horarios.","En la ventanilla preguntó por un tren directo. El empleado le explicó que solo quedaban plazas para la tarde y que debía elegir entre dos opciones.","Lucía comparó los precios y compró el billete más económico. Después llamó a su hermana para avisarle de la hora de llegada y preparar el encuentro.","Al volver a casa colocó el billete dentro de una carpeta para no perderlo. Se alegró de haber organizado el viaje con suficiente tiempo."]),
    SpanishA2Lesson(unit:1, number:3,
      title:"Volví a casa tarde", titleAr:"أفعال الماضي المنتظمة",
      grammar:"Pretérito indefinido: -er e -ir", grammarAr:"الماضي البسيط لأفعال -er و -ir",
      grammarHelpAr:"مع الأفعال المنتظمة من نوع -er أو -ir نستخدم í مع yo و ió مع él أو ella.",
      grammarExamples:<String>["Ayer comí en un restaurante.","Luis bebió agua.","Salimos a las ocho.","Viví en Sevilla.","Ellas escribieron una carta.","¿Qué aprendiste ayer?"],
      story:<String>["Mateo vivió durante seis meses en una ciudad costera del norte. Al principio no entendía bien los horarios ni las costumbres de sus vecinos, pero pronto hizo buenos amigos.","Un viernes terminó su trabajo temprano y decidió visitar el mercado. Encontró fruta fresca, escuchó música en la plaza y habló con una señora que conocía la historia del barrio.","La mujer le recomendó un restaurante familiar. Mateo comió allí y escribió a un amigo para contarle cómo era la ciudad y qué había descubierto durante la semana.","Cuando regresó a casa, pensó en las personas amables que había conocido. Aquel día comprendió que aprender un idioma permite disfrutar mejor de los lugares nuevos."]),
    SpanishA2Lesson(unit:1, number:4,
      title:"Cuando era pequeña", titleAr:"الطفولة والذكريات",
      grammar:"Pretérito imperfecto: -aba", grammarAr:"الماضي الناقص لأفعال -ar",
      grammarHelpAr:"عند وصف عادة متكررة قديمًا، نستخدم -aba و -abas مع الأفعال التي تنتهي بـ -ar.",
      grammarExamples:<String>["De niña jugaba en el parque.","Mi abuelo caminaba cada día.","Antes estudiábamos juntos.","Ana trabajaba allí.","Cuando era niño, viajaba mucho.","¿Visitabas a tus abuelos?"],
      story:<String>["Cuando Elena era pequeña, pasaba los veranos en la casa de sus abuelos. La casa estaba cerca de un río y tenía un jardín lleno de flores, árboles y una mesa de madera.","Cada mañana su abuelo preparaba el desayuno y su abuela le contaba historias sobre la familia. Elena escuchaba con atención y después jugaba con sus primos hasta la hora de comer.","Un verano encontró una caja con fotografías antiguas. Preguntó quiénes eran las personas de las imágenes y sus abuelos le explicaron muchos recuerdos que nunca había escuchado.","Años después todavía recordaba aquellas tardes tranquilas. Decidió escribir un pequeño libro sobre su infancia para conservar las historias de la familia."]),
    SpanishA2Lesson(unit:1, number:5,
      title:"Vivíamos cerca del mar", titleAr:"الحياة في الماضي",
      grammar:"Pretérito imperfecto: -ía", grammarAr:"الماضي الناقص لأفعال -er و -ir",
      grammarHelpAr:"للعادات القديمة ووصف الخلفية في الماضي نقول vivía و comía و escribía.",
      grammarExamples:<String>["Antes vivía en Valencia.","Mi madre leía cada noche.","Nosotros comíamos temprano.","Los niños escribían historias.","¿Bebías café antes?","Ella tenía un perro."],
      story:<String>["Antes de mudarse a la ciudad, Daniel vivía junto al mar. Desde su ventana veía las barcas de los pescadores y escuchaba las olas todas las mañanas.","Su madre tenía una pequeña tienda y su padre trabajaba en una escuela. Por las tardes la familia comía junta y comentaba lo que había ocurrido durante el día.","A Daniel le gustaba leer en el balcón mientras su hermana dibujaba. En verano invitaban a sus amigos y preparaban cenas sencillas en el jardín.","Ahora trabaja lejos de la costa, pero conserva fotografías de aquella época. Cuando mira las imágenes, entiende por qué recuerda su antigua casa con tanto cariño."]),
    SpanishA2Lesson(unit:1, number:6,
      title:"Una mañana muy especial", titleAr:"قصة تجمع زمنين",
      grammar:"Indefinido frente a imperfecto", grammarAr:"الفرق بين الحدث والخلفية بالماضي",
      grammarHelpAr:"الماضي الناقص يصف الحالة المستمرة، والماضي البسيط يصف الحدث الذي وقع خلالها.",
      grammarExamples:<String>["Hacía frío cuando salí.","Estudiaba cuando llamó Ana.","Mientras caminábamos, empezó a llover.","Era tarde y perdimos el autobús.","Vivía allí cuando conocí a Luis.","Cuando llegó, estábamos cenando."],
      story:<String>["El sábado hacía buen tiempo y Sofía caminaba hacia el parque con su perro. Había pocas personas en la calle, y todos disfrutaban de una mañana especialmente tranquila.","De repente comenzó a llover con fuerza. Sofía buscó un lugar donde protegerse y encontró un pequeño café que acababa de abrir.","Mientras esperaba, conoció a una mujer que estaba leyendo un libro sobre viajes. Las dos empezaron a hablar de lugares que habían visitado y de ciudades que querían conocer.","Cuando dejó de llover, intercambiaron sus números de teléfono. Lo que había empezado como un problema inesperado se convirtió en una amistad."]),
    SpanishA2Lesson(unit:1, number:7,
      title:"Fuimos a Granada", titleAr:"رحلة في الماضي",
      grammar:"Ser e ir: fui, fue, fuimos", grammarAr:"تصريف ser و ir في الماضي البسيط",
      grammarHelpAr:"الفعلان ser و ir يتشاركان صيغ الماضي البسيط مثل fui و fue و fuimos ويحدد السياق المعنى.",
      grammarExamples:<String>["Ayer fui al mercado.","La visita fue interesante.","Fuimos a Granada.","¿Adónde fuiste?","Ella fue mi profesora.","Los niños fueron al parque."],
      story:<String>["El mes pasado, un grupo de amigos decidió viajar a Granada durante el fin de semana. Habían visto fotografías de la ciudad y querían visitar sus monumentos más conocidos.","El viaje fue largo porque una carretera estaba cerrada. Llegaron al hotel después de la hora prevista, pero el personal les ofreció ayuda y les recomendó un restaurante cercano.","Por la mañana fueron al centro histórico, pasearon por calles estrechas y escucharon a un guía. Descubrieron historias que no aparecían en los folletos turísticos.","Antes de regresar compraron pequeños regalos. Todos coincidieron en que había valido la pena cambiar el plan para conocer mejor aquella ciudad."]),
    SpanishA2Lesson(unit:1, number:8,
      title:"Tuve un problema", titleAr:"مواقف غير متوقعة",
      grammar:"Tener y hacer en pasado", grammarAr:"الفعلان tener و hacer في الماضي",
      grammarHelpAr:"بعض الأفعال غير منتظمة: tuve و tuviste و tuvo، وكذلك hice و hizo.",
      grammarExamples:<String>["Ayer tuve una reunión.","Luis tuvo un problema.","Hice la reserva.","¿Qué hiciste ayer?","Tuvimos tiempo suficiente.","Ellos hicieron una excursión."],
      story:<String>["Ayer Marcos tuvo una entrevista de trabajo en una empresa de turismo. Había preparado sus respuestas y llevaba una carpeta con todos los documentos necesarios.","Cuando llegó al edificio descubrió que había olvidado el documento de identidad. Llamó a casa, pero nadie podía llevárselo a tiempo y empezó a preocuparse.","La recepcionista escuchó su problema y habló con el responsable. Finalmente le permitieron mostrar una copia digital y realizar la entrevista sin retrasos.","Después de la reunión Marcos regresó tranquilo. Aprendió que conviene revisar los documentos la noche anterior y mantener la calma ante los imprevistos."]),
    SpanishA2Lesson(unit:1, number:9,
      title:"Vivo aquí desde 2022", titleAr:"السكن والعمل",
      grammar:"Desde, desde hace y hace", grammarAr:"التعبير عن المدة وبداية الزمن",
      grammarHelpAr:"نستخدم desde لتحديد وقت البداية، ومنذ مدة نستخدم desde hace، و hace لحدث وقع قبل مدة.",
      grammarExamples:<String>["Vivo aquí desde 2022.","Trabajo allí desde hace dos años.","Llegué hace tres meses.","Estudio español desde enero.","Hace una semana viajé.","¿Desde cuándo vives aquí?"],
      story:<String>["Nadia vive en su barrio actual desde hace tres años. Al principio conocía a pocas personas y le costaba encontrar tiendas, parques y servicios cerca de casa.","Un día se inscribió en un curso de fotografía. Durante las clases conoció a varios vecinos y descubrió lugares interesantes que nunca había visitado.","Desde entonces participa en actividades del barrio y ayuda a organizar encuentros culturales. Hace dos meses colaboró en una exposición sobre la vida cotidiana.","Ahora siente que pertenece a la comunidad. Cuando llega alguien nuevo, intenta ofrecer la misma ayuda que recibió al instalarse."]),
    SpanishA2Lesson(unit:1, number:10,
      title:"Todavía no he terminado", titleAr:"ما تم وما لم يتم",
      grammar:"Ya y todavía no", grammarAr:"استخدام ya و todavía no",
      grammarHelpAr:"ya تعني حدث بالفعل، بينما todavía no تعني لم يحدث حتى الآن.",
      grammarExamples:<String>["Ya he comprado los billetes.","Todavía no he salido.","¿Ya has desayunado?","Ella todavía no ha llegado.","Ya hemos terminado el proyecto.","No he visto el mensaje todavía."],
      story:<String>["Desde el lunes, Paula ha tenido una semana muy ocupada. Ya ha terminado un proyecto del trabajo, pero todavía no ha preparado todo para el viaje del viernes.","Su compañera le pregunta si ya ha comprado los billetes. Paula responde que sí, aunque todavía necesita confirmar el alojamiento y revisar los horarios.","Al llegar a casa abre una lista de tareas y empieza por lo más importante. Compra algunos productos y llama al hotel para preguntar por la reserva.","Por la noche se siente más tranquila. Todavía quedan pequeños detalles, pero sabe que podrá resolverlos si organiza bien su tiempo."]),
    SpanishA2Lesson(unit:2, number:1,
      title:"Mañana vamos a cocinar", titleAr:"خطط عائلية قريبة",
      grammar:"Ir a + infinitivo para planes", grammarAr:"التعبير عن الخطط القريبة",
      grammarHelpAr:"نستخدم voy a و vas a و vamos a مع المصدر عند وصف خطة مستقبلية قريبة.",
      grammarExamples:<String>["Mañana voy a cocinar.","¿Vas a llamar al médico?","Vamos a visitar a Ana.","Ella va a descansar.","No voy a salir hoy.","Van a empezar el curso."],
      story:<String>["El domingo, la familia de Andrés quiere preparar una comida especial para celebrar el cumpleaños de su abuela. Todos se han ofrecido a colaborar en algo diferente.","Andrés va a comprar las verduras, su hermana va a preparar un postre y su padre va a decorar la mesa con flores del jardín.","La abuela no sabe nada del plan. Durante la semana, la familia organiza las tareas sin hablar de la sorpresa delante de ella.","Cuando llega el domingo, todos trabajan juntos en la cocina. La celebración resulta sencilla, pero muy bonita y llena de buenos recuerdos."]),
    SpanishA2Lesson(unit:2, number:2,
      title:"El próximo año viajaré", titleAr:"خطط بعيدة",
      grammar:"Futuro simple regular", grammarAr:"المستقبل البسيط للأفعال المنتظمة",
      grammarHelpAr:"نضيف é و ás و á إلى المصدر: viajaré و viajarás و viajará.",
      grammarExamples:<String>["El próximo año viajaré.","¿Estudiarás mañana?","Ella trabajará aquí.","Viviremos cerca del mar.","Ellos aprenderán español.","El tren llegará a tiempo."],
      story:<String>["Irene está pensando en el próximo año porque quiere mejorar su español y encontrar un trabajo relacionado con el turismo. Ha comenzado a investigar cursos y becas.","Su profesor le explica que aprender un idioma requiere tiempo y práctica. Le recomienda hablar con personas diferentes y escuchar programas cortos todos los días.","Irene decide que estudiará un poco cada mañana. También viajará a otra ciudad durante las vacaciones para conocer nuevos lugares y practicar.","Aunque sabe que algunas cosas serán difíciles, tiene ganas de empezar. Confía en que el esfuerzo constante le abrirá nuevas oportunidades."]),
    SpanishA2Lesson(unit:2, number:3,
      title:"Me gustaría participar", titleAr:"الطلبات المهذبة",
      grammar:"Me gustaría + infinitivo", grammarAr:"التعبير المهذب عن الرغبات",
      grammarHelpAr:"نستخدم me gustaría مع المصدر لطلب شيء بلطف أو للتعبير عن رغبة.",
      grammarExamples:<String>["Me gustaría reservar una mesa.","¿Te gustaría venir?","Nos gustaría participar.","Me gustaría aprender más.","A ella le gustaría viajar.","Me gustaría hablar contigo."],
      story:<String>["Una asociación cultural organizó una feria en la plaza principal del barrio. Los visitantes podían conocer tradiciones, probar platos caseros y participar en talleres de música.","Laila vio un cartel sobre un taller de cocina. Le interesaba mucho, pero no sabía si todavía había plazas disponibles para nuevos participantes.","Se acercó a una voluntaria y dijo que le gustaría aprender a preparar una receta típica. La mujer le explicó el horario y la invitó a participar.","Al terminar, Laila agradeció la ayuda y se apuntó al próximo taller. Pensó que pedir las cosas con educación siempre facilita la comunicación."]),
    SpanishA2Lesson(unit:2, number:4,
      title:"Tengo que descansar", titleAr:"الضرورة اليومية",
      grammar:"Tener que + infinitivo", grammarAr:"الواجب الشخصي باستخدام tener que",
      grammarHelpAr:"يأتي tengo que مع المصدر للدلالة على شيء يجب على المتحدث فعله.",
      grammarExamples:<String>["Tengo que ir al médico.","¿Tienes que trabajar?","Tenemos que limpiar la casa.","Ella tiene que estudiar.","No tengo que salir hoy.","Tienen que llegar temprano."],
      story:<String>["Sergio trabaja muchas horas frente al ordenador y últimamente se siente cansado. Su médica le ha recomendado descansar mejor y moverse un poco más.","Al salir de la consulta decide cambiar algunos hábitos. Tiene que organizar sus tareas para terminar antes y reservar tiempo para caminar por el parque.","Al principio resulta difícil porque recibe muchas llamadas. Sin embargo, sus compañeros entienden la situación y acuerdan repartir mejor el trabajo.","Después de varias semanas, Sergio duerme mejor y se encuentra con más energía. Comprende que cuidar la salud también es una responsabilidad diaria."]),
    SpanishA2Lesson(unit:2, number:5,
      title:"Hay que cuidar la salud", titleAr:"نصائح عامة",
      grammar:"Hay que + infinitivo", grammarAr:"الواجب العام غير الشخصي",
      grammarHelpAr:"نستخدم hay que مع المصدر لنصيحة أو قاعدة عامة لا تخص شخصًا محددًا.",
      grammarExamples:<String>["Hay que beber agua.","Hay que dormir bien.","No hay que comer demasiado.","Hay que hacer ejercicio.","Hay que escuchar al médico.","Hay que respetar a los demás."],
      story:<String>["En un centro comunitario se organizó una charla sobre alimentación. La nutricionista explicó de forma sencilla cómo elegir productos frescos y preparar comidas equilibradas.","Varias familias participaron y preguntaron por ideas económicas. La especialista recordó que no hace falta comprar ingredientes caros para comer bien.","Durante el taller prepararon una ensalada y hablaron de la importancia de beber agua y dormir lo suficiente. Todos tomaron notas de las recomendaciones.","Antes de salir, cada participante eligió un cambio pequeño para la semana siguiente. Aprendieron que mejorar los hábitos es más fácil cuando se hace poco a poco."]),
    SpanishA2Lesson(unit:2, number:6,
      title:"Estoy preparando una cena", titleAr:"أفعال تجري الآن",
      grammar:"Estar + gerundio", grammarAr:"المضارع المستمر",
      grammarHelpAr:"نستخدم estoy و estás و está مع صيغة -ando أو -iendo للفعل الجاري الآن.",
      grammarExamples:<String>["Estoy preparando la cena.","Ana está leyendo.","¿Qué estás haciendo?","Estamos estudiando.","Los niños están jugando.","Mi padre está escribiendo."],
      story:<String>["Marina está preparando una cena para sus amigos porque quiere celebrar que ha terminado un curso. Ha comprado verduras, arroz y algunos ingredientes que le recomendó su madre.","Mientras cocina escucha música y habla por teléfono con su hermana. Le pregunta cómo preparar una salsa y anota los pasos importantes.","Sus amigos llegan temprano y se ofrecen a ayudar. Algunos ponen la mesa, otros preparan las bebidas y Marina termina el plato principal.","Cuando todos se sientan, comparten historias sobre el curso y las próximas vacaciones. La cena se convierte en una oportunidad para mantener la amistad."]),
    SpanishA2Lesson(unit:2, number:7,
      title:"Me he levantado temprano", titleAr:"روتين مكتمل اليوم",
      grammar:"Pretérito perfecto reflexivo", grammarAr:"الفعل الانعكاسي في الماضي القريب",
      grammarHelpAr:"نضع me أو te أو se قبل haber عند الحديث عن فعل انعكاسي اكتمل.",
      grammarExamples:<String>["Me he levantado temprano.","¿Te has duchado?","Ella se ha vestido.","Nos hemos preparado.","Los niños se han acostado.","Todavía no me he despertado."],
      story:<String>["Esta mañana Clara se ha levantado más temprano que de costumbre. Tenía una cita médica y necesitaba salir de casa antes de las ocho.","Se ha duchado rápidamente, se ha vestido y ha preparado una pequeña bolsa con sus documentos. Después ha desayunado algo ligero y ha revisado el horario del autobús.","En la parada ha encontrado a una vecina que también iba al centro. Las dos han hablado de las novedades del barrio durante el trayecto.","Al llegar a la consulta Clara se ha sentido tranquila. Había organizado bien la mañana y no ha tenido que correr para llegar a tiempo."]),
    SpanishA2Lesson(unit:2, number:8,
      title:"Menos ruido, más descanso", titleAr:"مقارنة العادات",
      grammar:"Más, menos y tan ... como", grammarAr:"مقارنة الاختلاف والتساوي",
      grammarHelpAr:"أداة más تعني أكثر و menos أقل، وللتساوي نستخدم tan مع الصفة و como.",
      grammarExamples:<String>["Mi casa es más tranquila.","Este plato es menos caro.","Ana es tan alta como Luis.","Hoy hace más calor.","Duermo menos que antes.","Esta receta es tan fácil como aquella."],
      story:<String>["En el nuevo piso de Julia hay una cocina pequeña y una sala muy luminosa. Aunque el apartamento es menos grande que el anterior, está cerca del trabajo.","Su compañero Luis vive en otra zona. Tarda más tiempo en llegar al centro, pero paga menos alquiler y tiene un jardín grande.","Los dos comparan sus casas durante la comida. Julia prefiere caminar al trabajo; Luis valora tener más espacio para practicar sus aficiones.","Al final comprenden que ninguna opción es perfecta para todos. La mejor vivienda depende de las necesidades y costumbres de cada persona."]),
    SpanishA2Lesson(unit:2, number:9,
      title:"El mejor día del verano", titleAr:"أفضل الخيارات",
      grammar:"Superlativos: el más y el mejor", grammarAr:"صيغة التفضيل العليا",
      grammarHelpAr:"نقول el más و la más ثم الصفة، ويمكن استخدام mejor أو peor عند التفضيل.",
      grammarExamples:<String>["Es el lugar más bonito.","Este es el mejor restaurante.","Ana es la más puntual.","Es la peor noticia.","Son los libros más interesantes.","Esta ha sido la mejor semana."],
      story:<String>["Una familia visitó tres pueblos durante las vacaciones de verano. Cada lugar tenía paisajes, restaurantes y actividades muy diferentes para los visitantes.","El primer pueblo estaba cerca de las montañas y era muy tranquilo. El segundo tenía una playa preciosa, pero también muchos turistas.","En el tercero encontraron una pequeña fiesta popular. Conocieron a vecinos, escucharon música y probaron platos que nunca habían comido.","Al regresar a casa, todos eligieron su lugar favorito. Coincidieron en que la mejor parte del viaje había sido compartir tiempo juntos."]),
    SpanishA2Lesson(unit:2, number:10,
      title:"Ningún problema", titleAr:"الكمية والنفي",
      grammar:"Alguno, ninguno y mucho", grammarAr:"كلمات الكمية والإثبات والنفي",
      grammarHelpAr:"نستخدم algunos بمعنى بعض و ningún قبل اسم مذكر مفرد للنفي، و mucho للكمية.",
      grammarExamples:<String>["Tengo algunos libros.","No hay ningún problema.","¿Tienes alguna pregunta?","Necesitamos mucha agua.","No tengo ninguna duda.","Hay pocos estudiantes hoy."],
      story:<String>["Al preparar una exposición para la escuela, Raúl descubrió que había muchos materiales en casa que podía utilizar. No necesitaba comprar todo en la tienda.","Encontró algunas fotografías antiguas, varios libros y una caja de colores. Sin embargo, no tenía ningún mapa de la ciudad para completar su trabajo.","Pidió ayuda a su vecina, que conocía muy bien el barrio. Ella le prestó un mapa y le recomendó visitar la biblioteca para buscar más información.","Raúl terminó la exposición con tiempo y aprendió a aprovechar los recursos disponibles antes de gastar dinero. Además, mostró a sus compañeros cómo había organizado las fotografías y explicó qué materiales había utilizado para preparar un trabajo claro."]),
    SpanishA2Lesson(unit:3, number:1,
      title:"Sigue las instrucciones", titleAr:"تعليمات واضحة",
      grammar:"Imperativo afirmativo: tú", grammarAr:"الأمر المثبت للمخاطب المفرد",
      grammarHelpAr:"لإعطاء تعليمات نستخدم صيغة الأمر مثل habla و come و abre.",
      grammarExamples:<String>["Abre la puerta.","Escucha con atención.","Compra el billete.","Escribe tu nombre.","Habla más despacio.","Ven aquí, por favor."],
      story:<String>["En el museo de ciencias, una guía recibió a un grupo de estudiantes que visitaban la ciudad. Tenían poco tiempo y querían aprender lo más importante.","La guía les pidió que escucharan atentamente y siguieran las señales. Primero les mostró una exposición sobre el agua y después una sala de inventos.","Un estudiante preguntó si podía tomar fotografías. La guía explicó las normas y recordó al grupo que debía respetar a los demás visitantes.","Al final de la visita, todos agradecieron las explicaciones. La profesora dijo que unas instrucciones claras habían ayudado a disfrutar mejor del museo."]),
    SpanishA2Lesson(unit:3, number:2,
      title:"No olvides el billete", titleAr:"النهي والتحذير",
      grammar:"Imperativo negativo: tú", grammarAr:"الأمر المنفي للمخاطب المفرد",
      grammarHelpAr:"عند النهي نستخدم no مع صيغة خاصة من المضارع: no hables و no comas و no salgas.",
      grammarExamples:<String>["No llegues tarde.","No olvides el billete.","No comas demasiado.","No abras la ventana.","No hables tan rápido.","No salgas sin abrigo."],
      story:<String>["Antes de salir de excursión, una profesora reunió a sus estudiantes frente al autobús. Les explicó que era importante llevar agua y ropa cómoda.","También les recordó que no debían alejarse del grupo ni dejar basura en el camino. Algunos estudiantes tomaron notas y preguntaron por la duración del recorrido.","Durante la caminata comenzó a hacer viento. La profesora pidió a todos que caminaran juntos y que no corrieran cerca de las rocas.","Al volver, los estudiantes comentaron lo que habían aprendido. Entendieron que seguir recomendaciones sencillas puede evitar muchos problemas. También decidieron preparar una lista de consejos para la siguiente excursión y compartirla con sus compañeros."]),
    SpanishA2Lesson(unit:3, number:3,
      title:"La compré ayer", titleAr:"الشراء والمفعول المباشر",
      grammar:"Lo, la, los y las", grammarAr:"ضمائر المفعول المباشر",
      grammarHelpAr:"نستبدل الاسم المعروف بـ lo أو la أو los أو las قبل الفعل المصرف.",
      grammarExamples:<String>["El libro, lo compré ayer.","La camisa, la vi.","Las entradas, las tengo.","Los documentos, los envié.","¿La conoces?","No los encuentro."],
      story:<String>["Ayer Elena fue a una tienda porque necesitaba comprar una chaqueta para el invierno. Había visto varias opciones en internet, pero quería probarlas antes de decidir.","La dependienta le mostró dos chaquetas. Una era demasiado grande y la otra tenía el color que Elena prefería, aunque costaba un poco más.","Después de pensar en su presupuesto, compró la segunda. Guardó el recibo por si necesitaba cambiar la talla durante la semana.","En casa enseñó la compra a su hermana. La hermana preguntó por la chaqueta y Elena respondió que la había comprado aquella mañana."]),
    SpanishA2Lesson(unit:3, number:4,
      title:"Le escribí un mensaje", titleAr:"التواصل مع الآخرين",
      grammar:"Le y les: objeto indirecto", grammarAr:"ضمائر المفعول غير المباشر",
      grammarHelpAr:"نستخدم le لشخص واحد و les لعدة أشخاص للتعبير عمن يستفيد من الفعل.",
      grammarExamples:<String>["Le envié un correo a Ana.","Les explicamos el plan.","Le compré un regalo.","¿Le has llamado?","Les escribí ayer.","Le dije la verdad."],
      story:<String>["Manuel empezó un curso de fotografía en el centro cultural de su ciudad. La profesora enviaba mensajes con los horarios y explicaba las actividades cada semana.","Un día Manuel no pudo asistir porque estaba enfermo. Escribió a la profesora para avisarle y preguntar cómo podía recuperar la clase.","La profesora le respondió amablemente y le envió las instrucciones. También explicó el ejercicio a otros dos estudiantes que habían faltado.","Manuel le agradeció la ayuda y completó el trabajo desde casa. Comprendió que mantener una comunicación clara facilita el aprendizaje."]),
    SpanishA2Lesson(unit:3, number:5,
      title:"Un regalo para mi madre", titleAr:"الغرض والسبب",
      grammar:"Por y para", grammarAr:"الفرق بين por و para",
      grammarHelpAr:"para غالبًا للدلالة على الهدف أو المستفيد، أما por فيدل على السبب أو المدة أو المرور.",
      grammarExamples:<String>["Este regalo es para mi madre.","Estudio para aprender.","Gracias por tu ayuda.","Caminamos por el parque.","Trabajo por la mañana.","Salgo para comprar pan."],
      story:<String>["Para el cumpleaños de su madre, Inés decidió preparar un regalo hecho a mano. Había visto muchas ideas en internet, pero quería hacer algo personal.","Primero compró papel de colores y fotografías familiares. Después trabajó durante dos tardes para preparar un pequeño álbum con recuerdos.","Su hermano quería ayudarla y dibujó la portada. Los dos discutieron algunas ideas, pero finalmente encontraron un diseño que les gustaba.","Cuando entregaron el álbum, su madre se emocionó. Inés comprendió que el tiempo dedicado a un regalo puede ser más importante que el dinero."]),
    SpanishA2Lesson(unit:3, number:6,
      title:"Como llovía, nos quedamos", titleAr:"الأسباب والنتائج",
      grammar:"Porque, como y por eso", grammarAr:"التعبير عن السبب والنتيجة",
      grammarHelpAr:"porque يقدم السبب، و como يمكن أن يسبق جملة السبب، و por eso يقدم النتيجة.",
      grammarExamples:<String>["Me quedé porque estaba cansado.","Como llovía, no salimos.","Estudié mucho, por eso aprobé.","Llamé porque necesitaba ayuda.","Como tenía hambre, comí.","No había billetes; por eso esperamos."],
      story:<String>["Una familia pensaba pasar el fin de semana en un pueblo cercano. Habían reservado una casa rural y preparado comida para los dos días.","El viernes por la tarde comenzó a llover. Como la carretera estaba en mal estado, decidieron cambiar el plan y quedarse en la ciudad.","La madre propuso visitar un museo y el padre buscó actividades para los niños. La familia encontró una exposición interesante y disfrutó de la tarde.","Aunque el viaje se canceló, no perdieron el buen humor. Descubrieron que un cambio inesperado puede ofrecer otras oportunidades. Al final, recordaron aquella tarde como una experiencia especial y planearon la excursión para otro fin de semana."]),
    SpanishA2Lesson(unit:3, number:7,
      title:"Cuando llego a casa", titleAr:"تتابع الأحداث المعتادة",
      grammar:"Cuando + presente (hábitos)", grammarAr:"عندما مع المضارع للعادات",
      grammarHelpAr:"مع العادات المتكررة نستعمل cuando مع المضارع؛ ولحدث مستقبلي محدد نحتاج صيغة أخرى تدرس لاحقًا.",
      grammarExamples:<String>["Cuando llego a casa, descanso.","Cuando tengo tiempo, leo.","Cuando llueve, llevo paraguas.","Cuando estudias, aprendes.","Siempre llamo cuando salgo.","Cuando veo a Ana, sonrío."],
      story:<String>["Carmen trabaja en una biblioteca y tiene una rutina bastante regular. Cuando llega por la mañana, abre las ventanas y revisa los libros que han devuelto.","Cuando algún estudiante necesita ayuda, le recomienda materiales adecuados. También organiza pequeños encuentros para practicar la lectura en grupo. Muchos vecinos participan en esas actividades y descubren autores que antes no conocían.","Un día llegó un visitante extranjero que quería encontrar un libro sobre la historia de la ciudad. Carmen buscó información y le explicó cómo utilizar el catálogo.","El visitante le dio las gracias. Carmen disfrutó de poder ayudar a alguien a conocer mejor el lugar donde vivía."]),
    SpanishA2Lesson(unit:3, number:8,
      title:"El libro que me recomendaste", titleAr:"وصف الأشخاص والأشياء",
      grammar:"Pronombre relativo que", grammarAr:"ضمير الوصل que",
      grammarHelpAr:"نستخدم que لربط اسم بجملة تصفه دون تكرار الاسم.",
      grammarExamples:<String>["Este es el libro que compré.","La persona que llamó es Ana.","Visité la ciudad que recomendaste.","Tengo un amigo que habla español.","Es la casa que vimos.","El curso que empecé es útil."],
      story:<String>["El curso de cocina de Julia comenzó con una actividad en la que cada estudiante debía presentar un plato de su región. Había participantes de varios países.","Julia explicó que su abuela le había enseñado una receta sencilla cuando era pequeña. Mostró los ingredientes y habló de las ocasiones en las que la preparaban.","Otros estudiantes compartieron historias similares. Algunos platos eran muy diferentes, pero todos estaban relacionados con recuerdos familiares importantes. La profesora les pidió que escribieran las recetas para que todos pudieran probarlas después en casa.","Al terminar la clase, la profesora reunió las recetas en un documento. El grupo creó así un pequeño libro que podían compartir con nuevos estudiantes."]),
    SpanishA2Lesson(unit:3, number:9,
      title:"Si tengo tiempo, iré", titleAr:"الشروط الممكنة",
      grammar:"Si + presente", grammarAr:"شرط قابل للتحقق",
      grammarHelpAr:"نستخدم si مع المضارع لشرط واقعي؛ ويمكن أن تكون النتيجة مستقبلًا أو أمرًا.",
      grammarExamples:<String>["Si tengo tiempo, iré.","Si llueve, nos quedaremos.","Si necesitas ayuda, llama.","Si estudias, aprenderás.","Si puedo, participaré.","Si hace frío, lleva una chaqueta."],
      story:<String>["Después de trabajar durante varios meses, Andrés decidió ahorrar para realizar un viaje. Sabía que necesitaba organizar sus gastos y evitar compras innecesarias.","Preparó una lista con el dinero que recibía y lo que gastaba cada semana. Si encontraba una oferta útil, la comparaba con otras antes de comprar.","Un amigo le recomendó llevar un registro sencillo y revisar sus objetivos cada mes. Andrés siguió el consejo y consiguió ahorrar más de lo previsto.","Al terminar el año tenía dinero suficiente para viajar. Descubrió que los pequeños cambios de hábitos pueden producir grandes resultados."]),
    SpanishA2Lesson(unit:3, number:10,
      title:"Aunque estaba cansada", titleAr:"تنظيم الكلام",
      grammar:"Aunque, sin embargo y además", grammarAr:"الربط بين الأفكار والاعتراضات",
      grammarHelpAr:"aunque تفيد رغم أن، و sin embargo تعني مع ذلك، و además تضيف معلومة.",
      grammarExamples:<String>["Aunque llovía, salimos.","Estaba cansado; sin embargo, terminé.","Además, encontramos una solución.","Aunque es difícil, lo intentaré.","No había sitio; sin embargo, esperamos.","Me gusta viajar; además, aprendo mucho."],
      story:<String>["Clara participó en una reunión vecinal para hablar de un nuevo parque. Algunas personas querían más árboles y otras preferían una zona para practicar deporte.","Clara escuchó todas las opiniones y explicó que ambas ideas podían ser útiles. Aunque no todos estaban de acuerdo, la conversación fue respetuosa.","Un vecino propuso dividir el espacio en dos partes y preparar un presupuesto antes de tomar la decisión definitiva. La mayoría consideró razonable la propuesta.","Al terminar, los participantes acordaron organizar otra reunión. Comprendieron que resolver un problema común requiere escuchar, explicar y buscar puntos de acuerdo."]),
  ];

  /// Lesson-specific wrong examples, so grammar choices assess this
  /// lesson's rule instead of unrelated beginner-language mistakes.
  static const _grammarMistakes = <List<String>>[
    <String>["Yo has visitado Madrid.", "Ella hemos llegado temprano."],
    <String>["Ayer yo compró un billete.", "Ana visitamos el museo ayer."],
    <String>["Ayer yo comió arroz.", "Ellos viví en Sevilla."],
    <String>["De niña yo jugabas.", "Mi abuelo caminábamos."],
    <String>["Antes nosotros vivía aquí.", "Ella comíamos a las ocho."],
    <String>["Hacía frío cuando salía ayer de repente.", "Mientras caminaba, llovió siempre cada día."],
    <String>["Ayer yo fue al museo.", "Nosotros fui a Granada."],
    <String>["Ayer yo tuvo una reunión.", "Ella hice la reserva."],
    <String>["Vivo aquí desde hace 2022.", "Llegué desde tres meses."],
    <String>["Ya no he terminado todavía ayer.", "Todavía no ya he comprado los billetes."],
    <String>["Mañana yo vamos a cocinar.", "Ella voy a descansar."],
    <String>["El próximo año yo viajará.", "Nosotros estudiarán español."],
    <String>["Me gustaría reservaré una mesa.", "Yo gustaría participar."],
    <String>["Tengo que estudiaré más.", "Ella tienen que descansar."],
    <String>["Hay que bebemos agua.", "Hay que comiendo verduras."],
    <String>["Estoy preparar la cena.", "Ellos está jugando."],
    <String>["Me ha levantado temprano.", "Ella se hemos vestido."],
    <String>["Ana es más alta como Luis.", "Mi casa es tan grande que la tuya."],
    <String>["Esta es el más bonito lugar.", "Es la mejor restaurante."],
    <String>["No tengo ningún preguntas.", "Tengo alguno libros."],
    <String>["Abres la puerta, por favor.", "Escuchando con atención ahora."],
    <String>["No habla tan rápido, por favor.", "No salgas sin abrigos ayer."],
    <String>["Las entradas, lo tengo.", "El libro, la compré."],
    <String>["A Ana les envié un correo.", "A mis amigos le escribí."],
    <String>["Este regalo es por mi madre.", "Gracias para tu ayuda."],
    <String>["Como estaba cansado porque, no salí.", "No había billetes por eso porque esperamos."],
    <String>["Cuando llega mañana, avísame.", "Cuando lloviendo, uso paraguas."],
    <String>["La persona donde llamó es Ana.", "El libro quien compré está aquí."],
    <String>["Si tendré tiempo, iré.", "Si lloverá, no saldremos."],
    <String>["Aunque pero llovía, salimos.", "Sin embargo además sin embargo fuimos."],
  ];


  /// Two additional lesson-specific, spoken grammar examples for all 30
  /// Spanish A2 lessons. Preserve the six original examples and their
  /// lesson-level assessments.
  static const _extraGrammarExamples = <List<String>>[
    <String>["Esta semana hemos visitado Sevilla.", "¿Alguna vez has viajado en tren?"],
    <String>["Reservamos la habitación el lunes.", "El guía explicó la ruta ayer."],
    <String>["Ayer aprendí una expresión nueva.", "Los alumnos escribieron una postal."],
    <String>["De niño jugaba en el parque.", "Mi madre cocinaba cada sábado."],
    <String>["Antes vivíamos en un pueblo.", "El abuelo leía todos los días."],
    <String>["Mientras caminaba, empezó a llover.", "Hacía frío cuando salimos."],
    <String>["Mi amiga fue al mercado.", "La excursión fue muy interesante."],
    <String>["Tuvimos que cambiar la reserva.", "Ella hizo la compra antes de salir."],
    <String>["Trabajo aquí desde enero.", "Esperamos desde hace media hora."],
    <String>["Ya he enviado el mensaje.", "Todavía no hemos recibido respuesta."],
    <String>["Esta noche voy a preparar arroz.", "El sábado vamos a visitar a Luis."],
    <String>["Mañana estudiaré una hora.", "¿Cuándo visitarás a tu familia?"],
    <String>["Nos gustaría aprender a cocinar.", "¿Te gustaría venir mañana?"],
    <String>["Tengo que tomar el medicamento.", "Tenemos que ordenar la habitación."],
    <String>["Hay que descansar después de trabajar.", "Para mejorar, hay que practicar."],
    <String>["Estamos buscando las llaves.", "Mi hermana está estudiando."],
    <String>["Me he duchado después del ejercicio.", "¿Te has vestido ya?"],
    <String>["Esta calle es menos ruidosa que aquella.", "Mi dormitorio es tan cómodo como el tuyo."],
    <String>["Este es el restaurante más tranquilo.", "Fue el mejor momento del viaje."],
    <String>["No hay ninguna farmacia abierta.", "Tengo algunos libros para prestar."],
    <String>["Escribe tu nombre aquí.", "Abre la ventana, por favor."],
    <String>["No comas tan deprisa.", "No llegues tarde a la cita."],
    <String>["Las encontré en la mochila.", "Lo compré para mi hermana."],
    <String>["Les expliqué el problema.", "Le mandamos un correo al profesor."],
    <String>["Pasamos por la plaza ayer.", "He comprado el regalo para Elena."],
    <String>["Como no tenía tiempo, llamé.", "Estaba enfermo; por eso me quedé en casa."],
    <String>["Cuando vuelvo a casa, descanso.", "Cuando tengo tiempo, llamo a mi familia."],
    <String>["La mujer que conocimos habla francés.", "Tengo una vecina que trabaja en el hospital."],
    <String>["Si ahorras, podrás viajar.", "Si mañana llueve, nos quedaremos en casa."],
    <String>["Aunque tenía sueño, siguió estudiando.", "Hicimos la compra; además, visitamos el mercado."],
  ];

  static List<String> grammarExamplesFor(SpanishA2Lesson lesson) {
    final index=(lesson.unit-1)*10+lesson.number-1;
    return List<String>.unmodifiable(<String>[
      ...lesson.grammarExamples,
      ..._extraGrammarExamples[index],
    ]);
  }

  static List<String> grammarOptions(SpanishA2Lesson lesson) {
    final wrong = _grammarMistakes[(lesson.unit - 1) * 10 + lesson.number - 1];
    return <String>[wrong[0], lesson.grammarExamples.first, wrong[1]];
  }

  static SpanishA2Lesson find(int unit, int number) =>
      lessons.firstWhere((x) => x.unit == unit && x.number == number);

  /// Keep the four original story paragraphs and continue using the
  /// vocabulary from the same lesson, without replacing its original plot.
  static List<String> reading(SpanishA2Lesson lesson) {
    final ns = wordsOf(lesson, SpanishWordKind.noun);
    final vs = wordsOf(lesson, SpanishWordKind.verb);
    final as = wordsOf(lesson, SpanishWordKind.adjective);
    final ds = wordsOf(lesson, SpanishWordKind.adverb);
    return <String>[
      ...lesson.story,
      'Después de la experiencia, los participantes se reunieron '
      'para escribir una página de su diario. Cada persona recordó '
      'un momento importante de la historia y explicó cómo se '
      'había sentido al tomar sus decisiones. '
      'Primero repasaron dos palabras del tema: «${ns[0].es}» y '
      '«${ns[1].es}». Después trabajaron con los verbos '
      '«${vs[0].es}» y «${vs[1].es}» y los adjetivos '
      '«${as[0].es}» y «${as[1].es}». '
      'Al finalizar, escucharon atentamente dos expresiones, '
      '«${ds[0].es}» y «${ds[1].es}», y explicaron '
      'su significado con ejemplos propios. '
      'Esta revisión les ayudó a comprender mejor los hechos '
      'del día y a contar experiencias con palabras nuevas.',
    ];
  }

  static List<String> conversation(SpanishA2Lesson lesson) {
    final ns = wordsOf(lesson, SpanishWordKind.noun);
    final vs = wordsOf(lesson, SpanishWordKind.verb);
    final as = wordsOf(lesson, SpanishWordKind.adjective);
    final ds = wordsOf(lesson, SpanishWordKind.adverb);
    return <String>[
      'Ana: ¿Qué opinas de «${lesson.title}»?',
      'Luis: La historia habla de «${ns[0].es}» y «${ns[1].es}».',
      'Ana: ¿Qué ocurrió y por qué fue importante?',
      'Luis: Los personajes intentaron ${vs[0].es} ${ds[0].es}.',
      'Ana: ¿Puedes describir la situación con más precisión?',
      'Luis: En mi opinión, fue ${as[0].es}, pero también ${as[1].es}.',
      'Ana: ¿Qué habrías recomendado tú?',
      'Luis: Podría ${vs[1].es} ${ds[1].es} y escuchar a los demás.',
    ];
  }

  static String podcast(SpanishA2Lesson lesson) {
    final groups = SpanishWordKind.values.map((kind) {
      final label = switch(kind) {
        SpanishWordKind.noun => 'sustantivos',
        SpanishWordKind.verb => 'verbos',
        SpanishWordKind.adjective => 'adjetivos',
        SpanishWordKind.adverb => 'adverbios',
      };
      final terms = wordsOf(lesson, kind).map((w) => w.es).join(', ');
      return 'Escucha estos diez $label: $terms. ';
    }).join();
    return 'Bienvenidos a WorldVoice Español A2. '
      'En este episodio escucharemos una historia titulada ${lesson.title}. '
      '${lesson.story.join(' ')} '
      'Ahora repasamos el vocabulario del mismo tema. $groups'
      'Piensa en lo que ocurrió, identifica el problema y explica '
      'qué habrías hecho en esa situación. Vuelve a escuchar el episodio '
      'para practicar la comprensión, la gramática y la pronunciación.';
  }
}
