// WorldVoice Academy — Spanish A1 only. Original CEFR-aligned lessons.
// Three units × ten independent lessons. Higher Spanish levels stay unpublished.
enum SpanishWordKind { noun, verb, adjective, adverb }
class SpanishA1Word {
  const SpanishA1Word(this.es, this.ar, this.kind);
  final String es;
  final String ar;
  final SpanishWordKind kind;
}
class SpanishA1Lesson {
  const SpanishA1Lesson({required this.unit, required this.number,
    required this.title, required this.titleAr, required this.grammar,
    required this.grammarAr, required this.grammarHelpAr,
    required this.grammarExamples, required this.story});
  final int unit;
  final int number;
  String get id => 'worldvoice.es.a1.u$unit.l${number.toString().padLeft(2, '0')}';
  final String title;
  final String titleAr;
  final String grammar;
  final String grammarAr;
  final String grammarHelpAr;
  final List<String> grammarExamples;
  final List<String> story;
  List<SpanishA1Word> get words => SpanishA1Course.wordsFor(unit, number);
}
class SpanishA1Unit {
  const SpanishA1Unit(this.number, this.title, this.arabic);
  final int number;
  final String title;
  final String arabic;
  List<SpanishA1Lesson> get lessons => SpanishA1Course.lessons
      .where((x) => x.unit == number).toList(growable: false);
}
abstract final class SpanishA1Course {
  static const units = <SpanishA1Unit>[
    SpanishA1Unit(1, "¡Hola, mundo!", "التعارف والمدرسة والأسرة"),
    SpanishA1Unit(2, "Mi día a día", "الحياة اليومية والعادات"),
    SpanishA1Unit(3, "En la ciudad", "المدينة والتواصل والمواقف اليومية"),
  ];
  static const _core = <SpanishWordKind, String>{
    SpanishWordKind.noun: "persona|شخص;amigo|صديق;amiga|صديقة;familia|عائلة;nombre|اسم;país|بلد;ciudad|مدينة;casa|بيت;escuela|مدرسة;libro|كتاب;mesa|طاولة;silla|كرسي;puerta|باب;ventana|نافذة;profesor|معلم;profesora|معلمة;estudiante|طالب;niño|ولد;niña|بنت;día|يوم",
    SpanishWordKind.verb: "hablar|يتحدث;escuchar|يستمع;mirar|ينظر;leer|يقرأ;escribir|يكتب;abrir|يفتح;cerrar|يغلق;comer|يأكل;beber|يشرب;vivir|يعيش;estudiar|يدرس;trabajar|يعمل;caminar|يمشي;comprar|يشتري;buscar|يبحث;ayudar|يساعد;visitar|يزور;jugar|يلعب;aprender|يتعلم;preguntar|يسأل",
    SpanishWordKind.adjective: "grande|كبير;pequeño|صغير;nuevo|جديد;viejo|قديم;bonito|جميل;bueno|جيد;malo|سيئ;feliz|سعيد;triste|حزين;fácil|سهل;difícil|صعب;rápido|سريع;lento|بطيء;limpio|نظيف;sucio|متسخ;tranquilo|هادئ;divertido|ممتع;interesante|مثير للاهتمام;importante|مهم;amable|لطيف",
    SpanishWordKind.adverb: "hoy|اليوم;mañana|غدا;ayer|أمس;ahora|الآن;aquí|هنا;allí|هناك;siempre|دائما;nunca|أبدا;a veces|أحيانا;normalmente|عادة;despacio|ببطء;rápidamente|بسرعة;bien|جيدا;mal|بشكل سيئ;muy|جدا;bastante|إلى حد ما;también|أيضا;solo|فقط;juntos|معا;pronto|قريبا",
  };
  static const _focus = <int, Map<SpanishWordKind, String>>{
    1: <SpanishWordKind, String>{
      SpanishWordKind.noun: "saludo|تحية;apellido|لقب;pizarra|سبورة;cuaderno|دفتر;lápiz|قلم رصاص;bolígrafo|قلم حبر;mochila|حقيبة ظهر;hermano|أخ;hermana|أخت;abuela|جدة",
      SpanishWordKind.verb: "saludar|يحيّي;presentar|يقدّم;llamar|يسمّي;repetir|يكرر;contestar|يجيب;dibujar|يرسم;contar|يعد;señalar|يشير;enseñar|يدرّس;compartir|يشارك",
      SpanishWordKind.adjective: "español|إسباني;árabe|عربي;alto|طويل القامة;bajo|قصير القامة;joven|شاب;mayor|أكبر سنا;rojo|أحمر;azul|أزرق;verde|أخضر;blanco|أبيض",
      SpanishWordKind.adverb: "claramente|بوضوح;correctamente|بشكل صحيح;lentamente|ببطء;en voz alta|بصوت عال;en silencio|بصمت;otra vez|مرة أخرى;primero|أولا;después|بعد ذلك;al principio|في البداية;al final|في النهاية",
    },
    2: <SpanishWordKind, String>{
      SpanishWordKind.noun: "desayuno|فطور;almuerzo|غداء;cena|عشاء;cocina|مطبخ;baño|حمام;reloj|ساعة;autobús|حافلة;parque|حديقة عامة;tienda|متجر;calle|شارع",
      SpanishWordKind.verb: "desayunar|يتناول الفطور;almorzar|يتغدى;cenar|يتعشى;cocinar|يطبخ;lavar|يغسل;limpiar|ينظف;descansar|يرتاح;llegar|يصل;salir|يخرج;viajar|يسافر",
      SpanishWordKind.adjective: "temprano|مبكر;tardío|متأخر;caliente|ساخن;frío|بارد;saludable|صحي;delicioso|لذيذ;ocupado|مشغول;libre|متفرغ;cercano|قريب;lejano|بعيد",
      SpanishWordKind.adverb: "todos los días|كل يوم;cada semana|كل أسبوع;por la mañana|صباحا;por la tarde|عصرا;por la noche|ليلا;tempranito|مبكرا جدا;tarde|متأخرا;afuera|في الخارج;adentro|في الداخل;de camino|في الطريق",
    },
    3: <SpanishWordKind, String>{
      SpanishWordKind.noun: "mercado|سوق;hospital|مستشفى;museo|متحف;estación|محطة;billete|تذكرة;precio|سعر;regalo|هدية;fiesta|حفلة;playa|شاطئ;restaurante|مطعم",
      SpanishWordKind.verb: "pedir|يطلب;pagar|يدفع;elegir|يختار;llevar|يحمل;traer|يجلب;volver|يعود;esperar|ينتظر;necesitar|يحتاج;probar|يجرب;encontrar|يجد",
      SpanishWordKind.adjective: "barato|رخيص;caro|غالي;abierto|مفتوح;cerrado|مغلق;ocupada|مشغولة;perfecto|مثالي;especial|مميز;agradable|لطيف;seguro|آمن;preparado|مستعد",
      SpanishWordKind.adverb: "por favor|من فضلك;con cuidado|بحذر;sin problema|دون مشكلة;directamente|مباشرة;en seguida|فورا;por suerte|لحسن الحظ;por supuesto|بالطبع;cerca|بالقرب;lejos|بعيدا;finalmente|أخيرا",
    },
  };
  static List<SpanishA1Word> wordsFor(int unit, int number) {
    if (unit < 1 || unit > 3 || number < 1 || number > 10) {
      throw RangeError('Spanish A1 unit or lesson out of range');
    }
    final result = <SpanishA1Word>[];
    for (final kind in SpanishWordKind.values) {
      final common = _core[kind]!.split(';');
      final specific = _focus[unit]![kind]!.split(';');
      for (var i = 0; i < 5; i++) {
        final global = common[((number - 1) * 3 + i) % common.length].split('|');
        final local = specific[((number - 1) * 3 + i) % specific.length].split('|');
        result.add(SpanishA1Word(global[0], global[1], kind));
        result.add(SpanishA1Word(local[0], local[1], kind));
      }
    }
    return List<SpanishA1Word>.unmodifiable(result);
  }
  static List<SpanishA1Word> wordsOf(SpanishA1Lesson lesson, SpanishWordKind kind) =>
      lesson.words.where((word) => word.kind == kind).toList(growable: false);
  static const lessons = <SpanishA1Lesson>[
    SpanishA1Lesson(unit:1, number:1, title:"¡Hola! Me llamo Ana", titleAr:"التحيات والتعارف", grammar:"Me llamo: presentar el nombre", grammarAr:"قول الاسم بـ me llamo", grammarHelpAr:"نقول Me llamo قبل الاسم عند التعارف. وعند السؤال نستخدم ¿Cómo te llamas؟", grammarExamples:<String>["Me llamo Ana.","¿Cómo te llamas?","Me llamo Luis.","Ella se llama Sara.","Él se llama Omar.","Mucho gusto, Ana."], story:<String>["Ana entra en una clase de español en una escuela pequeña. Está un poco nerviosa porque no conoce a nadie.","La profesora sonríe y dice: «¡Hola! ¿Cómo te llamas?». Ana responde: «Me llamo Ana». Un estudiante dice: «Me llamo Luis».","Ana y Luis hablan despacio y repiten los nombres. Al final, los dos sonríen. Su primer día ya no parece difícil."]),
    SpanishA1Lesson(unit:1, number:2, title:"Soy de Marruecos", titleAr:"بلدي ومدينتي", grammar:"Ser: soy y eres", grammarAr:"الفعل ser مع أنا وأنت", grammarHelpAr:"نستخدم soy مع yo و eres مع tú للتعريف بالأصل والهوية.", grammarExamples:<String>["Yo soy de Marruecos.","Tú eres de España.","Soy estudiante.","¿Eres profesor?","Sí, soy profesor.","No, soy médico."], story:<String>["Samira vive en una ciudad tranquila de Marruecos. Hoy conoce a Pablo, un estudiante de España, en una biblioteca.","Pablo pregunta de dónde es. Samira dice: «Soy de Marruecos y soy estudiante». Pablo responde: «Yo soy de España».","Los dos miran un mapa grande y buscan sus países. Descubren que pueden ser amigos aunque viven lejos."]),
    SpanishA1Lesson(unit:1, number:3, title:"Un libro y una mesa", titleAr:"الأسماء وأدوات التعريف", grammar:"El y la: artículos definidos", grammarAr:"أدوات التعريف el و la", grammarHelpAr:"نستخدم el عادة مع الاسم المذكر المفرد و la مع المؤنث المفرد.", grammarExamples:<String>["El libro es nuevo.","La mesa es pequeña.","El profesor habla.","La profesora escucha.","La puerta es blanca.","El cuaderno es azul."], story:<String>["En clase hay una mesa cerca de la ventana. Sobre la mesa hay un libro verde y una libreta azul.","La profesora señala el libro y pregunta: «¿Qué es?». Sara responde: «Es el libro». Después señala la mesa: «Es la mesa».","Todos practican las palabras en voz alta. Al salir, Sara mira la puerta y dice correctamente: «La puerta». Está muy contenta."]),
    SpanishA1Lesson(unit:1, number:4, title:"Mi mochila roja", titleAr:"التذكير والتأنيث", grammar:"Un y una: artículos indefinidos", grammarAr:"أدوات التنكير un و una", grammarHelpAr:"نقول un قبل الاسم المذكر المفرد، و una قبل الاسم المؤنث المفرد.", grammarExamples:<String>["Tengo un libro.","Necesito una mochila.","Veo un lápiz.","Ella tiene una casa.","Es un amigo.","Es una amiga."], story:<String>["Luis prepara la mochila para su primer día. Tiene un libro, un lápiz y una botella pequeña.","Su hermana encuentra una mochila roja. Luis dice: «Tengo un libro, pero necesito una mochila». Ella le muestra la mochila roja.","Luis guarda las cosas y sale de casa. Está preparado y saluda a su hermana antes de ir a clase."]),
    SpanishA1Lesson(unit:1, number:5, title:"Dos hermanos", titleAr:"الجمع البسيط", grammar:"El plural: -s y -es", grammarAr:"تكوين جمع الأسماء", grammarHelpAr:"غالبا نضيف s للكلمات المنتهية بصوت متحرك، و es بعد حرف ساكن.", grammarExamples:<String>["Un libro, dos libros.","Una mesa, tres mesas.","Un profesor, dos profesores.","Una ciudad, dos ciudades.","Un lápiz, dos lápices.","Las casas son grandes."], story:<String>["Marta tiene dos hermanos y una hermana. Viven juntos en una casa cerca del parque.","Por la tarde, los niños leen libros y preparan dibujos. Marta cuenta las mesas y las sillas del comedor.","Su madre mira los dibujos y sonríe. Marta aprende que una palabra puede cambiar cuando habla de varias cosas."]),
    SpanishA1Lesson(unit:1, number:6, title:"Yo, tú y nosotros", titleAr:"الضمائر الشخصية", grammar:"Pronombres personales", grammarAr:"الضمائر الشخصية", grammarHelpAr:"الفاعل بالإسبانية يمكن أن يكون yo أو tú أو él أو ella أو nosotros، وقد نحذفه لأن الفعل يدل عليه.", grammarExamples:<String>["Yo estudio español.","Tú hablas árabe.","Él vive aquí.","Ella lee un libro.","Nosotros aprendemos.","Ellos trabajan juntos."], story:<String>["Una profesora nueva entra en el aula y escribe tres frases en la pizarra. Los estudiantes observan en silencio.","Ella dice: «Yo hablo español». Luego pregunta a Karim: «¿Tú hablas español?». Él contesta: «Sí, hablo un poco».","Después todos trabajan juntos. Ana lee, Luis escribe y nosotros escuchamos. La clase es amable y divertida."]),
    SpanishA1Lesson(unit:1, number:7, title:"Tengo un cuaderno", titleAr:"الفعل tener", grammar:"Tener: tengo y tienes", grammarAr:"التعبير عن الملكية بالفعل tener", grammarHelpAr:"نستخدم tengo بمعنى عندي، و tienes بمعنى عندك.", grammarExamples:<String>["Tengo una mochila.","¿Tienes un lápiz?","Tengo dos hermanos.","Ella tiene una casa.","No tengo un coche.","¿Cuántos libros tienes?"], story:<String>["Sara abre su mochila en la escuela y encuentra dos cuadernos y un bolígrafo.","Pedro pregunta: «¿Tienes un lápiz?». Sara responde: «Sí, tengo uno». Después ella pregunta si Pedro tiene un libro.","Los dos comparten sus materiales. La profesora observa el trabajo y dice que compartir es una buena idea."]),
    SpanishA1Lesson(unit:1, number:8, title:"Hay una ventana", titleAr:"يوجد أو توجد", grammar:"Hay: existencia", grammarAr:"استخدام hay للدلالة على الوجود", grammarHelpAr:"كلمة hay تعني يوجد أو توجد، وتستعمل مع المفرد والجمع دون تغيير.", grammarExamples:<String>["Hay una mesa.","Hay dos ventanas.","No hay un profesor.","¿Hay una silla?","Hay libros aquí.","En clase hay diez estudiantes."], story:<String>["La familia de Omar visita una casa nueva. La casa tiene una cocina, un salón y un jardín pequeño.","Omar entra en el salón y dice: «Hay dos ventanas». Su hermana encuentra tres sillas cerca de una mesa.","Todos miran las habitaciones. La madre pregunta si hay espacio para estudiar. Omar señala una mesa tranquila."]),
    SpanishA1Lesson(unit:1, number:9, title:"Estoy en clase", titleAr:"المكان والحالة", grammar:"Estar: estoy y estás", grammarAr:"استخدام estar للمكان والحالة", grammarHelpAr:"نستخدم estoy و estás لوصف المكان أو الحالة المؤقتة.", grammarExamples:<String>["Estoy en casa.","¿Estás bien?","Ella está feliz.","Estamos en la escuela.","El libro está aquí.","Los niños están cansados."], story:<String>["El primer día de clases, Leila no sabe dónde está su aula. Camina por un pasillo largo.","Un profesor la ayuda y pregunta: «¿Estás bien?». Ella responde: «Sí, estoy bien, pero estoy un poco nerviosa».","Al llegar a clase, sus amigos están allí. Leila se sienta cerca de la ventana y se siente tranquila."]),
    SpanishA1Lesson(unit:1, number:10, title:"Una casa bonita", titleAr:"توافق الصفة مع الاسم", grammar:"Concordancia del adjetivo", grammarAr:"توافق الصفات في الجنس والعدد", grammarHelpAr:"الصفة غالبا تتبع الاسم في المذكر والمؤنث والمفرد والجمع.", grammarExamples:<String>["Una casa bonita.","Un libro bonito.","Dos casas bonitas.","Dos libros bonitos.","La mesa es pequeña.","Los estudiantes son amables."], story:<String>["Elena y Pablo preparan dibujos de sus casas. Elena dibuja una casa blanca con ventanas azules.","Pablo dibuja un jardín grande y dos árboles verdes. Los dos describen sus dibujos con frases sencillas.","La profesora escucha y escribe: «Una casa bonita; dos casas bonitas». Todos aprenden a cambiar las palabras para describir bien."]),
    SpanishA1Lesson(unit:2, number:1, title:"Mi rutina de mañana", titleAr:"الروتين اليومي", grammar:"Presente de -ar", grammarAr:"تصريف أفعال -ar في الحاضر", grammarHelpAr:"مع أفعال مثل hablar نحذف ar ونضيف o مع yo و as مع tú و a مع él أو ella.", grammarExamples:<String>["Yo hablo español.","Tú estudias mucho.","Ella trabaja aquí.","Nosotros caminamos.","Ellos escuchan.","¿Tú desayunas temprano?"], story:<String>["Cada mañana, Diego se levanta temprano, desayuna y prepara su mochila.","Camina hasta la escuela y saluda a sus compañeros. En clase habla español y escucha a la profesora.","Por la tarde, Diego estudia en casa y juega con su hermana. Antes de dormir, escribe lo que hace cada día."]),
    SpanishA1Lesson(unit:2, number:2, title:"El café de Marta", titleAr:"المشروبات والطعام", grammar:"Presente de -er", grammarAr:"تصريف أفعال -er في الحاضر", grammarHelpAr:"مع أفعال مثل comer: como مع أنا، comes مع أنت، come مع هو أو هي.", grammarExamples:<String>["Yo como arroz.","Tú bebes agua.","Ella come pan.","Nosotros aprendemos español.","Ellos beben café.","¿Comes aquí?"], story:<String>["Marta visita un café cerca de la estación. El camarero saluda con una sonrisa.","Ella pide pan y agua. El camarero pregunta si también quiere café. Marta responde: «No, gracias. Como pan y bebo agua».","Después de comer, Marta mira la carta y aprende nombres nuevos de bebidas y alimentos."]),
    SpanishA1Lesson(unit:2, number:3, title:"Una tarde en el parque", titleAr:"النشاطات والهوايات", grammar:"Presente de -ir", grammarAr:"تصريف أفعال -ir في الحاضر", grammarHelpAr:"مع vivir نقول vivo و vives و vive. وللجمع nosotros vivimos.", grammarExamples:<String>["Vivo en Madrid.","¿Dónde vives?","Ella vive en casa.","Nosotros vivimos aquí.","Ellos escriben cartas.","Yo abro la puerta."], story:<String>["Los sábados, Nuria visita el parque con su familia. Vive cerca y va caminando.","En el parque ve niños que juegan y una señora que lee. Nuria se sienta y escribe una carta a su amiga.","Al volver a casa, habla de su tarde. Le gusta vivir cerca de un lugar verde y tranquilo."]),
    SpanishA1Lesson(unit:2, number:4, title:"No quiero café", titleAr:"النفي البسيط", grammar:"No + verbo", grammarAr:"النفي بوضع no قبل الفعل", grammarHelpAr:"لصنع جملة منفية نضع no مباشرة قبل الفعل المصرف.", grammarExamples:<String>["No hablo francés.","No tengo hambre.","Ella no trabaja hoy.","Nosotros no comemos carne.","No vivo allí.","¿No estudias español?"], story:<String>["El hermano de Ana prepara una taza de café. Ana prefiere agua porque hace calor.","Su hermano pregunta: «¿Quieres café?». Ella responde: «No, gracias, no quiero café».","Después los dos preparan la mesa. Ana explica que decir «no» antes del verbo cambia el significado de la frase."]),
    SpanishA1Lesson(unit:2, number:5, title:"¿Dónde está la tienda?", titleAr:"أسئلة الحياة اليومية", grammar:"Preguntas: qué y dónde", grammarAr:"السؤال بـ qué و dónde", grammarHelpAr:"نستخدم qué للسؤال عن ماذا، و dónde للسؤال عن مكان. علامة الاستفهام تبدأ بـ ¿.", grammarExamples:<String>["¿Qué estudias?","¿Dónde vives?","¿Qué es esto?","¿Dónde está el banco?","¿Qué comes hoy?","¿Dónde trabaja Ana?"], story:<String>["Pablo visita una ciudad nueva y quiere comprar un regalo. No conoce las calles.","En una esquina pregunta: «¿Dónde está la tienda?». Una mujer amable le muestra el camino.","Pablo pregunta qué venden allí. Compra un libro pequeño, da las gracias y vuelve feliz a su hotel."]),
    SpanishA1Lesson(unit:2, number:6, title:"Mi familia y tu familia", titleAr:"صفات الملكية", grammar:"Mi, tu y su", grammarAr:"صفات الملكية mi و tu و su", grammarHelpAr:"mi تعني خاصتي، tu خاصتك، su خاصته أو خاصتها، وتأتي قبل الاسم.", grammarExamples:<String>["Mi casa es pequeña.","Tu libro es azul.","Su madre está aquí.","Mis hermanos estudian.","Tus amigos son amables.","Sus libros están en casa."], story:<String>["Amina vive con su madre y sus dos hermanos. Los domingos la familia desayuna junta.","Su hermano muestra una foto y dice: «Esta es mi familia». Amina responde: «Y esta es tu abuela».","Los niños ponen fotos en un álbum. Aprenden a hablar de las personas que quieren con palabras muy sencillas."]),
    SpanishA1Lesson(unit:2, number:7, title:"Vamos al museo", titleAr:"الذهاب إلى مكان", grammar:"Ir: voy y vamos", grammarAr:"تصريف ir للدلالة على الذهاب", grammarHelpAr:"نستخدم voy بمعنى أذهب، vas تذهب، vamos نذهب؛ ومع المكان نقول voy a.", grammarExamples:<String>["Voy al parque.","Vas a la escuela.","Ella va al mercado.","Vamos al museo.","Ellos van a casa.","¿Adónde vas hoy?"], story:<String>["Luis espera a su amiga frente a la estación. Hoy quieren visitar un museo.","Su amiga llega y pregunta: «¿Adónde vamos?». Luis responde: «Vamos al museo». Caminan juntos por la ciudad.","Después de la visita van al parque. Los dos hablan del museo y planean otra salida para el sábado."]),
    SpanishA1Lesson(unit:2, number:8, title:"Son las ocho", titleAr:"الوقت والساعات", grammar:"La hora: es la / son las", grammarAr:"قول الوقت", grammarHelpAr:"نقول es la una للساعة الواحدة، و son las لبقية الساعات.", grammarExamples:<String>["Es la una.","Son las dos.","Son las ocho y media.","Son las diez y cuarto.","¿Qué hora es?","A las siete estudio."], story:<String>["Ana mira el reloj porque hoy tiene una clase de música. Son las ocho y media.","Su padre pregunta: «¿Qué hora es?». Ana contesta y prepara sus cosas rápidamente.","Llega a clase antes de las nueve. Su profesora le dice que es importante llegar a tiempo."]),
    SpanishA1Lesson(unit:2, number:9, title:"Me levanto temprano", titleAr:"الأفعال الانعكاسية", grammar:"Verbos reflexivos: me y te", grammarAr:"أفعال الانعكاس me و te", grammarHelpAr:"في أفعال مثل levantarse نستخدم me مع أنا و te مع أنت.", grammarExamples:<String>["Me levanto temprano.","¿Te duchas ahora?","Ella se viste.","Nosotros nos lavamos.","Se acuesta tarde.","Me llamo Ana."], story:<String>["Clara se levanta temprano todos los días. Después se lava la cara y se viste.","Su hermano todavía duerme. Clara llama a la puerta y dice: «¿Te levantas ahora?».","La familia desayuna junta antes de salir. Clara escribe su rutina en un cuaderno para recordar los verbos nuevos."]),
    SpanishA1Lesson(unit:2, number:10, title:"Me gusta la música", titleAr:"التعبير عن الإعجاب", grammar:"Gustar: gusta y gustan", grammarAr:"التعبير عن الإعجاب بـ gustar", grammarHelpAr:"نقول me gusta مع الشيء المفرد أو الفعل، و me gustan مع الجمع.", grammarExamples:<String>["Me gusta el parque.","Me gustan los libros.","¿Te gusta la música?","Le gusta comer.","No me gustan los gatos.","Nos gusta viajar."], story:<String>["Julia escucha música mientras prepara la cena. Le gusta la música tranquila.","Su hermana prefiere canciones rápidas, pero las dos disfrutan de la tarde juntas.","Por la noche, Julia explica que le gusta cantar y que a su hermana le gustan los libros. Las dos sonríen."]),
    SpanishA1Lesson(unit:3, number:1, title:"Puedo ayudarte", titleAr:"القدرة والاستطاعة", grammar:"Poder + infinitivo", grammarAr:"الفعل poder مع المصدر", grammarHelpAr:"بعد puedo أو puedes نضع الفعل الثاني بصيغة المصدر دون تصريف.", grammarExamples:<String>["Puedo hablar español.","¿Puedes ayudarme?","Ella puede venir.","No puedo salir.","Podemos estudiar juntos.","Ellos pueden entrar."], story:<String>["En la biblioteca, Karim ve a una estudiante con muchos libros. Una caja cae al suelo.","Karim dice: «Puedo ayudarte». La estudiante sonríe y responde: «Gracias, ¿puedes llevar esta caja?».","Los dos ordenan los libros y hablan unos minutos. Karim descubre que ayudar a otros es fácil."]),
    SpanishA1Lesson(unit:3, number:2, title:"Quiero un billete", titleAr:"الرغبات والطلبات", grammar:"Querer + infinitivo", grammarAr:"الفعل querer للتعبير عن الرغبة", grammarHelpAr:"نقول quiero أو quieres ثم المصدر للتعبير عما نريد فعله.", grammarExamples:<String>["Quiero comprar pan.","¿Quieres viajar?","Ella quiere estudiar.","Queremos comer aquí.","No quiero esperar.","Ellos quieren jugar."], story:<String>["Elena llega a la estación y pregunta por un billete de autobús. Quiere viajar al centro.","El empleado le explica el precio y los horarios. Elena dice: «Quiero comprar un billete, por favor».","Después de pagar, espera el autobús junto a otros pasajeros. Tiene tiempo para mirar su mapa."]),
    SpanishA1Lesson(unit:3, number:3, title:"Necesito descansar", titleAr:"الاحتياج", grammar:"Necesitar + infinitivo", grammarAr:"الفعل necesitar للتعبير عن الحاجة", grammarHelpAr:"نستخدم necesito و necesitas ثم الاسم أو المصدر لما نحتاج إليه.", grammarExamples:<String>["Necesito agua.","Necesitas descansar.","Ella necesita estudiar.","Necesitamos dos billetes.","¿Necesitas ayuda?","No necesito una bolsa."], story:<String>["Después de una mañana larga, Miguel está cansado. Ha caminado por toda la ciudad.","Su amiga le pregunta qué necesita. Miguel dice: «Necesito agua y necesito descansar».","Se sientan en un parque pequeño. Después de beber agua, Miguel se encuentra mucho mejor."]),
    SpanishA1Lesson(unit:3, number:4, title:"Estamos leyendo", titleAr:"فعل يحدث الآن", grammar:"Estar + gerundio", grammarAr:"المضارع المستمر الإسباني", grammarHelpAr:"نستخدم estar مع صيغة -ando أو -iendo لوصف ما يحدث الآن.", grammarExamples:<String>["Estoy leyendo.","Ella está comiendo.","Estamos hablando.","¿Qué estás haciendo?","Ellos están viviendo aquí.","Ana está escribiendo."], story:<String>["Es sábado por la tarde. En casa de Laura hay una mesa con libros y lápices.","Laura está leyendo un cuento. Su hermano está escribiendo una carta para su abuela.","Su madre pregunta qué están haciendo. Los niños responden y continúan sus actividades en silencio."]),
    SpanishA1Lesson(unit:3, number:5, title:"Mañana voy a viajar", titleAr:"المستقبل القريب", grammar:"Ir a + infinitivo", grammarAr:"التعبير عن المستقبل القريب", grammarHelpAr:"نستخدم voy a أو vas a أو vamos a ثم المصدر للخطط القريبة.", grammarExamples:<String>["Voy a estudiar mañana.","¿Vas a viajar?","Ella va a comprar pan.","Vamos a visitar a Luis.","No voy a salir.","Van a comer juntos."], story:<String>["Mañana, Salma va a viajar con su familia a una ciudad cerca del mar.","Hoy prepara su mochila y busca los billetes. Su padre dice: «Vamos a salir temprano».","Salma sonríe porque está muy contenta. Quiere visitar la playa y escribir sobre su viaje."]),
    SpanishA1Lesson(unit:3, number:6, title:"Este regalo es mejor", titleAr:"المقارنة البسيطة", grammar:"Más ... que", grammarAr:"التفضيل والمقارنة باستخدام más", grammarHelpAr:"نستخدم más قبل الصفة و que للمقارنة بين شيئين.", grammarExamples:<String>["Este libro es más grande que ese.","Ana es más alta que Luis.","El parque es más tranquilo.","Mi casa es más pequeña.","Hoy hace más frío.","Este regalo es mejor."], story:<String>["Alicia entra en una tienda para comprar un regalo. Ve dos bolsos diferentes.","El primero es grande y caro. El segundo es pequeño, pero más barato. Alicia compara los dos.","Al final elige el bolso más bonito para su hermana. Sale de la tienda contenta con su elección."]),
    SpanishA1Lesson(unit:3, number:7, title:"La farmacia está cerca", titleAr:"وصف المكان", grammar:"Preposiciones de lugar", grammarAr:"حروف الجر الخاصة بالمكان", grammarHelpAr:"نستخدم en و cerca de و al lado de لوصف موقع الأشخاص والأشياء.", grammarExamples:<String>["El libro está en la mesa.","La farmacia está cerca.","La estación está al lado del parque.","Estoy delante de la puerta.","El coche está detrás de casa.","La mochila está debajo de la silla."], story:<String>["Mariam necesita comprar medicina y busca una farmacia. No conoce bien el barrio.","Un vecino le explica que la farmacia está cerca del parque, al lado de la panadería.","Mariam sigue las indicaciones y encuentra el lugar. Después da las gracias al vecino."]),
    SpanishA1Lesson(unit:3, number:8, title:"Lo veo en el mercado", titleAr:"المفعول المباشر", grammar:"Lo y la: objeto directo", grammarAr:"ضمائر المفعول المباشر lo و la", grammarHelpAr:"نستخدم lo بدل اسم مذكر مفرد و la بدل اسم مؤنث مفرد معروف.", grammarExamples:<String>["¿Tienes el libro? Lo tengo.","¿Ves a Ana? La veo.","El regalo, lo compro hoy.","La carta, la escribo.","Lo necesito ahora.","La encuentro aquí."], story:<String>["En el mercado, Pedro ve a su amiga Ana. Ella está buscando fruta para la cena.","Pedro tiene un libro nuevo y Ana pregunta por él. Pedro responde: «Lo tengo en mi mochila».","Ana muestra una manzana roja y Pedro dice: «La veo». Continúan hablando mientras compran."]),
    SpanishA1Lesson(unit:3, number:9, title:"¿Cuánto cuesta?", titleAr:"السعر والتسوق", grammar:"Cuánto y cuántos", grammarAr:"كم للسؤال عن الكمية", grammarHelpAr:"cuánto يسأل عن المقدار و cuántos عن عدد الأسماء المذكرة الجمع.", grammarExamples:<String>["¿Cuánto cuesta el pan?","¿Cuántos libros tienes?","¿Cuánta agua necesitas?","¿Cuántas amigas vienen?","¿Cuánto dinero hay?","¿Cuántos billetes quieres?"], story:<String>["Sara visita un mercado con su madre. Quieren comprar fruta, pan y agua.","Sara pregunta al vendedor: «¿Cuánto cuesta el pan?». Después cuenta las manzanas en una bolsa.","La madre paga y Sara guarda el recibo. En casa comparan los precios y hablan de lo que compraron."]),
    SpanishA1Lesson(unit:3, number:10, title:"Un día especial", titleAr:"المراجعة والتواصل", grammar:"Conectores: y, pero, porque", grammarAr:"الربط باستخدام و لكن لأن", grammarHelpAr:"نربط الجمل البسيطة بـ y بمعنى و، و pero بمعنى لكن، و porque بمعنى لأن.", grammarExamples:<String>["Estudio y trabajo.","Quiero salir, pero llueve.","Estoy feliz porque aprendo español.","Ana come y Luis bebe.","Es pequeño, pero bonito.","Voy al parque porque hace sol."], story:<String>["Hoy es un día especial para la familia de Ana porque celebran el cumpleaños de su abuela.","Ana prepara un regalo y Luis lleva un pastel. Quieren salir temprano, pero empieza a llover.","Finalmente llegan a casa de la abuela. Todos comen juntos, hablan y se ríen porque están felices."]),
  ];
  static SpanishA1Lesson find(int unit, int number) => lessons.firstWhere(
      (x) => x.unit == unit && x.number == number);

  /// A fourth reading page explicitly reuses this lesson's taught words.
  static List<String> reading(SpanishA1Lesson lesson) {
    final nouns = wordsOf(lesson, SpanishWordKind.noun);
    final verbs = wordsOf(lesson, SpanishWordKind.verb);
    final adjectives = wordsOf(lesson, SpanishWordKind.adjective);
    final adverbs = wordsOf(lesson, SpanishWordKind.adverb);
    return <String>[
      ...lesson.story,
      'Al final, los estudiantes preparan una página sobre el tema. '
      'Escriben las palabras «${nouns[0].es}» y «${nouns[1].es}» '
      'en su cuaderno. Practican los verbos «${verbs[0].es}» '
      'y «${verbs[1].es}». Después leen dos adjetivos: '
      '«${adjectives[0].es}» y «${adjectives[1].es}». '
      'Todos escuchan ${adverbs[0].es} y repiten '
      '${adverbs[1].es}. Así recuerdan el vocabulario de hoy.',
    ];
  }

  static List<String> dialogue(SpanishA1Lesson lesson) {
    final ns=wordsOf(lesson, SpanishWordKind.noun);
    final vs=wordsOf(lesson, SpanishWordKind.verb);
    final as=wordsOf(lesson, SpanishWordKind.adjective);
    final ds=wordsOf(lesson, SpanishWordKind.adverb);
    return <String>[
      'Ana: ¡Hola! Hoy hablamos de ${lesson.title.toLowerCase()}.',
      'Luis: ¡Qué bien! Yo recuerdo las palabras «${ns[0].es}» y «${ns[1].es}».',
      'Ana: ¿Puedes decir dos verbos nuevos?',
      'Luis: Claro: «${vs[0].es}» y «${vs[1].es}».',
      'Ana: ¿Y dos adjetivos?',
      'Luis: «${as[0].es}» y «${as[1].es}».',
      'Ana: Muy bien. Repite «${ds[0].es}» y «${ds[1].es}».',
      'Luis: ¡Gracias! Ahora entiendo mejor las palabras de la historia.',
    ];
  }

  static String podcast(SpanishA1Lesson lesson) {
    final groups=SpanishWordKind.values.map((kind) {
      final category=switch(kind){
        SpanishWordKind.noun => 'sustantivos',
        SpanishWordKind.verb => 'verbos',
        SpanishWordKind.adjective => 'adjetivos',
        SpanishWordKind.adverb => 'adverbios',
      };
      final terms=wordsOf(lesson, kind).map((x)=>x.es).join(', ');
      return 'Escucha diez $category: $terms.';
    }).join(' ');
    return 'Bienvenidos al pódcast de español A1 de WorldVoice. '
      'Hoy estudiamos: ${lesson.title}. '
      '${lesson.story.join(' ')} '
      '$groups Ahora vuelve a escuchar. Repite cada palabra y '
      'escribe una frase sencilla con la regla de hoy: ${lesson.grammar}.';
  }
}
