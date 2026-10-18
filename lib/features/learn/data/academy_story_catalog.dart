import 'academy_catalog.dart';

/// Original short, readable stories. Each translation is editorial content,
/// not a machine-generated translation at display time.
class AcademyStoryPage {
  const AcademyStoryPage(this.text, this.arabic);
  final String text;
  final String arabic;
}

class AcademyStoryBook {
  const AcademyStoryBook({
    required this.title,
    required this.titleArabic,
    required this.coverSymbol,
    required this.pages,
    required this.question,
    required this.questionArabic,
    required this.options,
    required this.optionsArabic,
    required this.correctIndex,
  });
  final String title;
  final String titleArabic;
  final String coverSymbol;
  final List<AcademyStoryPage> pages;
  final String question;
  final String questionArabic;
  final List<String> options;
  final List<String> optionsArabic;
  final int correctIndex;
}

abstract final class AcademyStoryCatalog {
  static AcademyStoryBook forUnit(AcademyUnit unit) =>
      _books['${unit.language}_${unit.number}'] ??
      AcademyStoryBook(
        title: unit.nativeTitle,
        titleArabic: unit.title,
        coverSymbol: '📖',
        pages: [AcademyStoryPage(unit.story, unit.storyArabic)],
        question: unit.quizQuestion,
        questionArabic: 'ما الذي فهمته من القصة؟',
        options: unit.quizOptions,
        optionsArabic: unit.quizOptions,
        correctIndex: unit.quizCorrectIndex,
      );

  static const _books = <String, AcademyStoryBook>{
    'en_1': AcademyStoryBook(
      title: 'The Lost Notebook',
      titleArabic: 'الدفتر المفقود',
      coverSymbol: '📗',
      pages: [
        AcademyStoryPage('Sara has a small blue notebook. It is a gift from her mother.', 'لدى سارة دفتر أزرق صغير. إنه هدية من أمها.'),
        AcademyStoryPage('One morning, the notebook is not in her bag. Sara is worried.', 'في صباح أحد الأيام، لم تجد الدفتر في حقيبتها. شعرت سارة بالقلق.'),
        AcademyStoryPage('Her friend Tom says, “Hello, Sara! Is this your notebook?”', 'قال صديقها توم: «مرحبًا يا سارة! هل هذا دفترك؟»'),
        AcademyStoryPage('“Yes! Thank you, Tom.” Sara smiles. “You are a good friend!”', '«نعم! شكرًا لك يا توم». ابتسمت سارة وقالت: «أنت صديق جيد!»'),
      ],
      question: 'Who finds Sara’s notebook?',
      questionArabic: 'من وجد دفتر سارة؟',
      options: ['Her mother', 'Tom', 'A teacher'],
      optionsArabic: ['أمها', 'توم', 'المعلم'],
      correctIndex: 1,
    ),
    'en_2': AcademyStoryBook(
      title: 'A Very Busy Morning',
      titleArabic: 'صباح مزدحم جدًا',
      coverSymbol: '⏰',
      pages: [
        AcademyStoryPage('Lina wakes up at seven. Her alarm clock is very loud.', 'تستيقظ لينا في السابعة. صوت منبهها مرتفع جدًا.'),
        AcademyStoryPage('She makes breakfast and looks for her shoes. One shoe is under the bed!', 'تحضّر الفطور وتبحث عن حذائها. تجد فردة منه تحت السرير!'),
        AcademyStoryPage('She runs to the bus. The driver smiles and waits for her.', 'تركض إلى الحافلة. يبتسم السائق وينتظرها.'),
        AcademyStoryPage('At work, Lina laughs. “Tomorrow, I will wake up earlier!”', 'تضحك لينا في العمل: «غدًا سأستيقظ أبكر!»'),
      ],
      question: 'Where is Lina’s shoe?',
      questionArabic: 'أين وجدت لينا حذاءها؟',
      options: ['Under her bed', 'On the bus', 'At work'],
      optionsArabic: ['تحت السرير', 'في الحافلة', 'في العمل'],
      correctIndex: 0,
    ),
    'es_1': AcademyStoryBook(
      title: 'La nota misteriosa',
      titleArabic: 'الرسالة الغامضة',
      coverSymbol: '✉️',
      pages: [
        AcademyStoryPage('Ana está en una cafetería. Ve una nota pequeña en la mesa.', 'آنا في مقهى. ترى رسالة صغيرة على الطاولة.'),
        AcademyStoryPage('La nota dice: «Hola, Ana. Busca el libro azul».', 'تقول الرسالة: «مرحبًا يا آنا. ابحثي عن الكتاب الأزرق».'),
        AcademyStoryPage('Ana ve un libro azul. Su amigo Luis está detrás del libro.', 'ترى آنا كتابًا أزرق. صديقها لويس يقف خلف الكتاب.'),
        AcademyStoryPage('«¡Feliz cumpleaños!», dice Luis. Ana ríe: «¡Gracias, amigo!»', 'يقول لويس: «عيد ميلاد سعيد!» فتضحك آنا: «شكرًا يا صديقي!»'),
      ],
      question: '¿Qué color tiene el libro?',
      questionArabic: 'ما لون الكتاب في القصة؟',
      options: ['Rojo', 'Verde', 'Azul'],
      optionsArabic: ['أحمر', 'أخضر', 'أزرق'],
      correctIndex: 2,
    ),
    'es_2': AcademyStoryBook(
      title: 'El desayuno sorpresa',
      titleArabic: 'فطور المفاجأة',
      coverSymbol: '🥐',
      pages: [
        AcademyStoryPage('María se levanta temprano. Hoy prepara el desayuno para su hermano.', 'تستيقظ ماريا مبكرًا. اليوم تعد الفطور لأخيها.'),
        AcademyStoryPage('Busca el pan, pero no está en la cocina. «¿Dónde está?», pregunta.', 'تبحث عن الخبز لكنه ليس في المطبخ. تسأل: «أين هو؟»'),
        AcademyStoryPage('Su hermano entra con pan fresco. «¡Buenos días!», dice.', 'يدخل أخوها ومعه خبز طازج ويقول: «صباح الخير!»'),
        AcademyStoryPage('Los dos desayunan juntos. Después, María va a estudiar español.', 'يتناول الاثنان الفطور معًا. بعدها تذهب ماريا لدراسة الإسبانية.'),
      ],
      question: '¿Quién trae el pan?',
      questionArabic: 'من أحضر الخبز؟',
      options: ['Su hermano', 'Su amiga', 'Su profesora'],
      optionsArabic: ['أخوها', 'صديقتها', 'معلمتها'],
      correctIndex: 0,
    ),
    'zh_1': AcademyStoryBook(
      title: '蓝色的书',
      titleArabic: 'الكتاب الأزرق',
      coverSymbol: '📘',
      pages: [
        AcademyStoryPage('小美在图书馆。她看到一本蓝色的书。', 'شياو مي في المكتبة. ترى كتابًا أزرق.'),
        AcademyStoryPage('书里有一张小纸条。纸条上写着一个名字：小明。', 'داخل الكتاب ورقة صغيرة. مكتوب عليها اسم: شياو مينغ.'),
        AcademyStoryPage('小美问：“你好，你是小明吗？”一个男孩说：“是的！”', 'تسأل شياو مي: «مرحبًا، هل أنت شياو مينغ؟» فيجيب فتى: «نعم!»'),
        AcademyStoryPage('“这是你的书。”小明说：“谢谢！我们做朋友吧！”', '«هذا كتابك». ويقول شياو مينغ: «شكرًا! لنصبح صديقين!»'),
      ],
      question: '书是什么颜色的？',
      questionArabic: 'ما لون الكتاب؟',
      options: ['红色', '蓝色', '绿色'],
      optionsArabic: ['أحمر', 'أزرق', 'أخضر'],
      correctIndex: 1,
    ),
    'zh_2': AcademyStoryBook(
      title: '早上的小惊喜',
      titleArabic: 'مفاجأة صباحية صغيرة',
      coverSymbol: '🌅',
      pages: [
        AcademyStoryPage('小王早上七点起床。他要去工作。', 'يستيقظ شياو وانغ الساعة السابعة صباحًا. عليه الذهاب إلى العمل.'),
        AcademyStoryPage('他想吃早饭，但是家里没有面包。', 'يريد تناول الفطور، لكن لا يوجد خبز في المنزل.'),
        AcademyStoryPage('他出门，看见朋友小李。小李给他一个包子。', 'يخرج ويرى صديقه شياو لي. يعطيه شياو لي كعكة محشوة مطهوة على البخار.'),
        AcademyStoryPage('小王说：“谢谢！今天真是好日子！”', 'يقول شياو وانغ: «شكرًا! إنه يوم جميل حقًا!»'),
      ],
      question: '小李给小王什么？',
      questionArabic: 'ماذا أعطى شياو لي لصديقه؟',
      options: ['一本书', '一个包子', '一杯茶'],
      optionsArabic: ['كتابًا', 'كعكة محشوة', 'كوب شاي'],
      correctIndex: 1,
    ),
    'fr_1': AcademyStoryBook(
      title: 'Le petit parapluie',
      titleArabic: 'المظلة الصغيرة',
      coverSymbol: '☂️',
      pages: [
        AcademyStoryPage('Léa est dans un café à Paris. Il commence à pleuvoir.', 'ليا في مقهى بباريس. يبدأ المطر بالهطول.'),
        AcademyStoryPage('Léa n’a pas de parapluie. Elle regarde la pluie et soupire.', 'ليس لدى ليا مظلة. تنظر إلى المطر وتتنهد.'),
        AcademyStoryPage('Son ami Paul arrive avec deux parapluies. «Bonjour, Léa !»', 'يصل صديقها بول ومعه مظلتان: «مرحبًا يا ليا!»'),
        AcademyStoryPage('«Merci, Paul !» Ils marchent ensemble sous la pluie.', '«شكرًا يا بول!» ويسيران معًا تحت المطر.'),
      ],
      question: 'Qui apporte les parapluies ?',
      questionArabic: 'من أحضر المظلات؟',
      options: ['Paul', 'Léa', 'Le serveur'],
      optionsArabic: ['بول', 'ليا', 'النادل'],
      correctIndex: 0,
    ),
    'fr_2': AcademyStoryBook(
      title: 'Le matin d’Emma',
      titleArabic: 'صباح إيما',
      coverSymbol: '☕',
      pages: [
        AcademyStoryPage('Emma se lève à sept heures. Elle prépare son petit-déjeuner.', 'تستيقظ إيما الساعة السابعة. وتعد فطورها.'),
        AcademyStoryPage('Elle veut boire du café, mais il n’y a plus de lait.', 'تريد شرب القهوة، لكن الحليب قد نفد.'),
        AcademyStoryPage('Au travail, son amie lui offre un café. Emma sourit.', 'في العمل تقدم لها صديقتها قهوة. تبتسم إيما.'),
        AcademyStoryPage('Le soir, Emma étudie le français et lit une petite histoire.', 'في المساء تدرس إيما الفرنسية وتقرأ قصة صغيرة.'),
      ],
      question: 'Qu’est-ce qu’Emma étudie le soir ?',
      questionArabic: 'ماذا تدرس إيما مساءً؟',
      options: ['L’espagnol', 'Le français', 'Le chinois'],
      optionsArabic: ['الإسبانية', 'الفرنسية', 'الصينية'],
      correctIndex: 1,
    ),
    'ko_1': AcademyStoryBook(
      title: '민지의 작은 우산',
      titleArabic: 'مظلة مينجي الصغيرة',
      coverSymbol: '🌂',
      pages: [
        AcademyStoryPage('민지는 학교에 가요. 오늘은 비가 와요.', 'تذهب مينجي إلى المدرسة. اليوم تمطر.'),
        AcademyStoryPage('민지는 작은 우산을 봐요. 우산 옆에 이름이 있어요.', 'ترى مينجي مظلة صغيرة. بجانب المظلة اسم.'),
        AcademyStoryPage('“준호 씨, 이 우산은 준호 씨 거예요?” 준호가 웃어요.', '«يا جونو، هل هذه مظلتك؟» يبتسم جونو.'),
        AcademyStoryPage('“네, 감사합니다!” 두 사람은 좋은 친구가 돼요.', '«نعم، شكرًا!» ويصبح الاثنان صديقين جيدين.'),
      ],
      question: '오늘 날씨는 어때요?',
      questionArabic: 'كيف هو الطقس اليوم؟',
      options: ['눈이 와요', '비가 와요', '해가 나요'],
      optionsArabic: ['تتساقط الثلوج', 'تمطر', 'مشمس'],
      correctIndex: 1,
    ),
    'ko_2': AcademyStoryBook(
      title: '지수의 바쁜 아침',
      titleArabic: 'صباح جيسو المزدحم',
      coverSymbol: '🚌',
      pages: [
        AcademyStoryPage('지수는 아침 일곱 시에 일어나요. 학교에 가야 해요.', 'تستيقظ جيسو الساعة السابعة صباحًا. عليها الذهاب إلى المدرسة.'),
        AcademyStoryPage('지수는 아침밥을 먹고 가방을 찾아요.', 'تتناول جيسو الفطور وتبحث عن حقيبتها.'),
        AcademyStoryPage('가방은 의자 아래에 있어요! 지수는 빨리 버스를 타요.', 'الحقيبة تحت الكرسي! تركب جيسو الحافلة بسرعة.'),
        AcademyStoryPage('학교에서 친구를 만나요. “안녕하세요!” 오늘도 좋은 하루예요.', 'تقابل صديقتها في المدرسة. «مرحبًا!» إنه يوم جميل آخر.'),
      ],
      question: '가방은 어디에 있어요?',
      questionArabic: 'أين كانت الحقيبة؟',
      options: ['의자 아래', '버스 안', '책상 위'],
      optionsArabic: ['تحت الكرسي', 'في الحافلة', 'على المكتب'],
      correctIndex: 0,
    ),
  };
}
