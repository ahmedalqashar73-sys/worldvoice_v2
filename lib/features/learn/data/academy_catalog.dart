// Curated, offline-first beginner material: five languages × two units ×
// six complete lesson activities (vocabulary, grammar, story, listening,
// speaking practice and knowledge check). No AI request or paid content.
// Advanced and intermediate courses are not advertised as completed content.

enum AcademyLessonKind { vocabulary, grammar, story, listening, speaking, quiz }

class AcademyWord {
  const AcademyWord(this.term, this.arabic, this.pronunciation);
  final String term;
  final String arabic;
  final String pronunciation;
}

class AcademyUnit {
  const AcademyUnit({
    required this.language, required this.number, required this.title,
    required this.nativeTitle, required this.words, required this.grammar,
    required this.grammarExample, required this.grammarTranslation,
    required this.story, required this.storyArabic, required this.listening,
    required this.speaking, required this.speakingHelp,
    required this.quizQuestion, required this.quizOptions,
    required this.quizCorrectIndex,
  });
  final String language;
  final int number;
  final String title;
  final String nativeTitle;
  final List<AcademyWord> words;
  final String grammar;
  final String grammarExample;
  final String grammarTranslation;
  final String story;
  final String storyArabic;
  final String listening;
  final String speaking;
  final String speakingHelp;
  final String quizQuestion;
  final List<String> quizOptions;
  final int quizCorrectIndex;
  String lessonId(AcademyLessonKind kind) => '${language}_${number}_${kind.name}';
}

class AcademyCourse {
  const AcademyCourse(this.code, this.flag, this.nativeName, this.arabicName);
  final String code;
  final String flag;
  final String nativeName;
  final String arabicName;
  List<AcademyUnit> get units => academyUnits.where((unit) => unit.language == code).toList(growable: false);
  int get lessonCount => units.length * AcademyLessonKind.values.length;
}

const academyCourses = <AcademyCourse>[
  AcademyCourse('en', '🇬🇧', 'English', 'الإنجليزية'),
  AcademyCourse('es', '🇪🇸', 'Español', 'الإسبانية'),
  AcademyCourse('zh', '🇨🇳', '中文', 'الصينية'),
  AcademyCourse('fr', '🇫🇷', 'Français', 'الفرنسية'),
  AcademyCourse('ko', '🇰🇷', '한국어', 'الكورية'),
];

const academyUnits = <AcademyUnit>[
  AcademyUnit(
    language: 'en',
    number: 1,
    title: 'التعارف والتحية',
    nativeTitle: 'Greetings & Introductions',
    grammar: 'استخدم I am لتعريف نفسك وYou are عند الحديث عن شخص آخر.',
    grammarExample: 'I am Sara. You are my friend.',
    grammarTranslation: 'أنا سارة. أنت صديقي.',
    story: 'Hello! My name is Sara. I am a student. This is my friend Tom. We are happy to meet you.',
    storyArabic: 'مرحبًا! اسمي سارة. أنا طالبة. هذا صديقي توم. سعداء بلقائك.',
    listening: 'Hello, my name is Sara. What is your name? Nice to meet you.',
    speaking: 'Hello! My name is ... Nice to meet you.',
    speakingHelp: 'عرّف بنفسك، وقل اسمك ثم حيِّ شخصًا جديدًا.',
    quizQuestion: 'What do you say when you meet someone?',
    quizCorrectIndex: 0,
    words: [AcademyWord('hello', 'مرحبًا', 'hello'), AcademyWord('name', 'اسم', 'name'), AcademyWord('friend', 'صديق', 'friend'), AcademyWord('please', 'من فضلك', 'please'), AcademyWord('thanks', 'شكرًا', 'thanks')],
    quizOptions: ['Nice to meet you.', 'See you yesterday.', 'I am apple.'],
  ),
  AcademyUnit(
    language: 'en',
    number: 2,
    title: 'الروتين اليومي',
    nativeTitle: 'My Daily Routine',
    grammar: 'في المضارع البسيط نستعمل الفعل مباشرة مع I، ونضيف s غالبًا مع he أو she.',
    grammarExample: 'I study English. She studies English.',
    grammarTranslation: 'أنا أدرس الإنجليزية. هي تدرس الإنجليزية.',
    story: 'Every morning, Lina eats breakfast at seven. She studies English at eight. In the evening, she calls her family.',
    storyArabic: 'كل صباح تتناول لينا الفطور في السابعة، وتدرس الإنجليزية في الثامنة، وتتصل بعائلتها مساءً.',
    listening: 'I wake up at seven. I eat breakfast and go to work. I study English at night.',
    speaking: 'I wake up at ... I study ... in the evening.',
    speakingHelp: 'صف صباحك في جملتين واذكر متى تدرس.',
    quizQuestion: 'Choose the correct present simple sentence.',
    quizCorrectIndex: 1,
    words: [AcademyWord('morning', 'صباح', 'morning'), AcademyWord('breakfast', 'فطور', 'breakfast'), AcademyWord('work', 'عمل', 'work'), AcademyWord('study', 'دراسة', 'study'), AcademyWord('evening', 'مساء', 'evening')],
    quizOptions: ['She study English.', 'She studies English.', 'She studying English.'],
  ),
  AcademyUnit(
    language: 'es',
    number: 1,
    title: 'التعارف والتحية',
    nativeTitle: 'Saludos y presentaciones',
    grammar: 'للتعريف بنفسك استخدم Me llamo، وللتحية Hola.',
    grammarExample: 'Hola, me llamo Ana. ¿Cómo te llamas?',
    grammarTranslation: 'مرحبًا، اسمي آنا. ما اسمك؟',
    story: 'Hola, soy Ana. Vivo en Madrid. Luis es mi amigo. Hablamos español juntos.',
    storyArabic: 'مرحبًا، أنا آنا. أعيش في مدريد. لويس صديقي. نتحدث الإسبانية معًا.',
    listening: '¡Hola! Me llamo Ana. ¿Cómo te llamas? Mucho gusto.',
    speaking: 'Hola, me llamo ... Mucho gusto.',
    speakingHelp: 'قدّم نفسك بالإسبانية وقل اسمك ثم رحّب بالشخص الآخر.',
    quizQuestion: '¿Cómo dices «شكرًا» en español?',
    quizCorrectIndex: 1,
    words: [AcademyWord('hola', 'مرحبًا', 'o-la'), AcademyWord('nombre', 'اسم', 'nom-bre'), AcademyWord('amigo', 'صديق', 'a-mi-go'), AcademyWord('gracias', 'شكرًا', 'gra-sias'), AcademyWord('adiós', 'وداعًا', 'a-dios')],
    quizOptions: ['Adiós', 'Gracias', 'Amigo'],
  ),
  AcademyUnit(
    language: 'es',
    number: 2,
    title: 'الروتين اليومي',
    nativeTitle: 'La rutina diaria',
    grammar: 'في المضارع يتغيّر شكل الفعل حسب الضمير: Yo estudio وElla estudia.',
    grammarExample: 'Yo estudio por la mañana. Ella trabaja por la tarde.',
    grammarTranslation: 'أنا أدرس صباحًا. هي تعمل بعد الظهر.',
    story: 'Cada mañana, María desayuna en casa. Después estudia español. Por la noche lee un libro.',
    storyArabic: 'كل صباح تتناول ماريا الفطور في المنزل، ثم تدرس الإسبانية، وتقرأ كتابًا ليلًا.',
    listening: 'Me levanto a las siete. Desayuno y voy al trabajo. Estudio por la noche.',
    speaking: 'Por la mañana, yo ... Por la noche, yo ...',
    speakingHelp: 'احكِ روتينك الصباحي والمساءي بالإسبانية.',
    quizQuestion: 'Completa: «Ella ___ español».',
    quizCorrectIndex: 1,
    words: [AcademyWord('mañana', 'صباح', 'ma-nya-na'), AcademyWord('desayuno', 'فطور', 'de-sa-yu-no'), AcademyWord('trabajo', 'عمل', 'tra-ba-ho'), AcademyWord('estudio', 'دراسة', 'es-tu-dio'), AcademyWord('noche', 'ليل', 'no-che')],
    quizOptions: ['estudio', 'estudia', 'estudiar'],
  ),
  AcademyUnit(
    language: 'zh',
    number: 1,
    title: 'التعارف والتحية',
    nativeTitle: '问候与介绍',
    grammar: 'للتعريف بنفسك بالصينية استعمل 我叫 (wǒ jiào) ثم اسمك؛ وترتيب الجملة غالبًا فاعل ثم فعل.',
    grammarExample: '你好！我叫小明。你叫什么名字？',
    grammarTranslation: 'مرحبًا! اسمي شياو مينغ. ما اسمك؟',
    story: '你好！我叫小美。我是学生。小明是我的朋友。我们一起学习中文。',
    storyArabic: 'مرحبًا! اسمي شياو مي. أنا طالبة. شياو مينغ صديقي. نتعلم الصينية معًا.',
    listening: '你好！我叫小美。你叫什么名字？很高兴认识你。',
    speaking: '你好！我叫……。很高兴认识你。',
    speakingHelp: 'قل مرحبًا بالصينية، واذكر اسمك، ثم قل إنك سعيد بالتعارف.',
    quizQuestion: '哪个词表示“谢谢”？',
    quizCorrectIndex: 1,
    words: [AcademyWord('你好', 'مرحبًا', 'nǐ hǎo'), AcademyWord('名字', 'اسم', 'míng zi'), AcademyWord('朋友', 'صديق', 'péng you'), AcademyWord('谢谢', 'شكرًا', 'xiè xie'), AcademyWord('再见', 'إلى اللقاء', 'zài jiàn')],
    quizOptions: ['再见', '谢谢', '朋友'],
  ),
  AcademyUnit(
    language: 'zh',
    number: 2,
    title: 'الروتين اليومي',
    nativeTitle: '我的日常生活',
    grammar: 'للتعبير عن الزمن ضع ظرف الوقت قبل الفعل، مثل 我早上学习. لا تُصرف الأفعال الصينية بحسب الفاعل.',
    grammarExample: '我早上学习中文。她晚上工作。',
    grammarTranslation: 'أدرس الصينية صباحًا. هي تعمل مساءً.',
    story: '小王每天早上七点起床。他吃早饭，然后去工作。晚上他学习中文。',
    storyArabic: 'يستيقظ شياو وانغ يوميًا الساعة السابعة، ويتناول الفطور ثم يذهب إلى العمل، ويدرس الصينية مساءً.',
    listening: '我早上七点起床。我吃早饭，然后去工作。晚上我学习中文。',
    speaking: '我早上……。我晚上……。',
    speakingHelp: 'صف ما تفعله في الصباح والمساء بصيغتين صينيتين قصيرتين.',
    quizQuestion: '“晚上”是什么意思？',
    quizCorrectIndex: 1,
    words: [AcademyWord('早上', 'الصباح', 'zǎo shang'), AcademyWord('吃饭', 'تناول الطعام', 'chī fàn'), AcademyWord('工作', 'عمل', 'gōng zuò'), AcademyWord('学习', 'دراسة', 'xué xí'), AcademyWord('晚上', 'المساء', 'wǎn shang')],
    quizOptions: ['الصباح', 'المساء', 'الصديق'],
  ),
  AcademyUnit(
    language: 'fr',
    number: 1,
    title: 'التعارف والتحية',
    nativeTitle: 'Salutations et présentations',
    grammar: 'استعمل Je m\'appelle لتعريف اسمك. الفعل être يأتي Je suis مع ضمير أنا.',
    grammarExample: 'Bonjour, je m\'appelle Léa. Je suis étudiante.',
    grammarTranslation: 'مرحبًا، اسمي ليا. أنا طالبة.',
    story: 'Bonjour ! Je m\'appelle Léa. J\'habite à Paris. Paul est mon ami. Nous apprenons le français ensemble.',
    storyArabic: 'مرحبًا! اسمي ليا وأعيش في باريس. بول صديقي ونتعلم الفرنسية معًا.',
    listening: 'Bonjour ! Je m\'appelle Léa. Et toi, comment tu t\'appelles ? Enchantée !',
    speaking: 'Bonjour, je m\'appelle ... Enchanté !',
    speakingHelp: 'حيِّ شخصًا بالفرنسية وقل اسمك وعرّف بنفسك.',
    quizQuestion: 'Comment dit-on «شكرًا» en français ?',
    quizCorrectIndex: 0,
    words: [AcademyWord('bonjour', 'مرحبًا/صباح الخير', 'bon-zhoor'), AcademyWord('prénom', 'الاسم الأول', 'pré-nom'), AcademyWord('ami', 'صديق', 'a-mi'), AcademyWord('merci', 'شكرًا', 'mer-si'), AcademyWord('au revoir', 'إلى اللقاء', 'o-re-vwar')],
    quizOptions: ['Merci', 'Bonjour', 'Ami'],
  ),
  AcademyUnit(
    language: 'fr',
    number: 2,
    title: 'الروتين اليومي',
    nativeTitle: 'Ma journée',
    grammar: 'في المضارع يتغير تصريف فعل -er: Je parle، Il parle، Nous parlons.',
    grammarExample: 'Je parle français. Nous parlons français.',
    grammarTranslation: 'أنا أتحدث الفرنسية. نحن نتحدث الفرنسية.',
    story: 'Chaque matin, Emma prend son petit-déjeuner. Elle va au travail. Le soir, elle étudie le français.',
    storyArabic: 'تتناول إيما فطورها كل صباح وتذهب إلى العمل، وتدرس الفرنسية مساءً.',
    listening: 'Je me lève à sept heures. Je prends mon petit-déjeuner et je vais au travail.',
    speaking: 'Le matin, je ... Le soir, je ...',
    speakingHelp: 'صف صباحك ثم ما تفعله في المساء بالفرنسية.',
    quizQuestion: 'Choisis la phrase correcte.',
    quizCorrectIndex: 1,
    words: [AcademyWord('matin', 'صباح', 'ma-tin'), AcademyWord('petit-déjeuner', 'فطور', 'pe-ti-dé-jeu-né'), AcademyWord('travail', 'عمل', 'tra-vai'), AcademyWord('étudier', 'يدرس', 'é-tu-di-é'), AcademyWord('soir', 'مساء', 'swar')],
    quizOptions: ['Nous parle français.', 'Nous parlons français.', 'Nous parler français.'],
  ),
  AcademyUnit(
    language: 'ko',
    number: 1,
    title: 'التعارف والتحية',
    nativeTitle: '인사와 자기소개',
    grammar: 'للحديث بأدب في الكورية نستخدم النهاية -요، وللتعريف بالنفس 저는…이에요/예요.',
    grammarExample: '안녕하세요. 저는 민지예요. 이름이 뭐예요?',
    grammarTranslation: 'مرحبًا. أنا مينجي. ما اسمك؟',
    story: '안녕하세요! 저는 민지예요. 저는 학생이에요. 준호는 제 친구예요. 우리는 한국어를 공부해요.',
    storyArabic: 'مرحبًا! أنا مينجي وطالبة. جونو صديقي ونتعلم الكورية معًا.',
    listening: '안녕하세요. 저는 민지예요. 이름이 뭐예요? 만나서 반가워요.',
    speaking: '안녕하세요. 저는 ...예요. 만나서 반가워요.',
    speakingHelp: 'رحّب بشخص بالكورية، وعرّف باسمك بأسلوب مهذب.',
    quizQuestion: '«감사합니다»의 뜻은 무엇인가요?',
    quizCorrectIndex: 1,
    words: [AcademyWord('안녕하세요', 'مرحبًا', 'annyeonghaseyo'), AcademyWord('이름', 'اسم', 'ireum'), AcademyWord('친구', 'صديق', 'chingu'), AcademyWord('감사합니다', 'شكرًا', 'gamsahamnida'), AcademyWord('안녕히 가세요', 'مع السلامة لمن يغادر', 'annyeonghi gaseyo')],
    quizOptions: ['مرحبًا', 'شكرًا', 'صديق'],
  ),
  AcademyUnit(
    language: 'ko',
    number: 2,
    title: 'الروتين اليومي',
    nativeTitle: '나의 하루',
    grammar: 'ترتيب الجملة الكورية غالبًا فاعل ثم مفعول ثم فعل. يأتي الفعل في النهاية، مثل 한국어를 공부해요.',
    grammarExample: '저는 아침에 한국어를 공부해요. 저녁에 일해요.',
    grammarTranslation: 'أدرس الكورية في الصباح وأعمل في المساء.',
    story: '지수는 아침 일곱 시에 일어나요. 아침밥을 먹고 학교에 가요. 저녁에는 책을 읽어요.',
    storyArabic: 'تستيقظ جيسو في السابعة صباحًا وتتناول الفطور وتذهب إلى المدرسة، وتقرأ كتابًا مساءً.',
    listening: '저는 아침 일곱 시에 일어나요. 밥을 먹고 공부해요. 저녁에는 쉬어요.',
    speaking: '저는 아침에 ...해요. 저녁에는 ...해요.',
    speakingHelp: 'قل جملتين بالكورية عن نشاطك صباحًا ومساءً.',
    quizQuestion: '«저녁»은 언제인가요?',
    quizCorrectIndex: 1,
    words: [AcademyWord('아침', 'صباح', 'achim'), AcademyWord('아침밥', 'فطور', 'achimbap'), AcademyWord('일하다', 'يعمل', 'ilhada'), AcademyWord('공부하다', 'يدرس', 'gongbuhada'), AcademyWord('저녁', 'مساء', 'jeonyeok')],
    quizOptions: ['صباحًا', 'مساءً', 'أمس'],
  ),
];
