/// WorldVoice English A1: three authored units with twelve different,
/// assessable learning activities each. Progress is device-only until an
/// Academy-specific, server-validated sync mechanism is deployed.
enum EnglishA1Kind {
  dialogue, vocabulary, pronunciation, grammar, listening, story, practice, quiz,
}

class EnglishA1Lesson {
  const EnglishA1Lesson({
    required this.id,
    required this.kind,
    required this.title,
    required this.titleAr,
    required this.teaching,
    required this.arabic,
    required this.spoken,
    required this.question,
    required this.options,
    required this.answer,
    this.storyId,
  });
  final String id;
  final EnglishA1Kind kind;
  final String title;
  final String titleAr;
  final String teaching;
  final String arabic;
  final String spoken;
  final String question;
  final List<String> options;
  final int answer;
  final String? storyId;
}

class EnglishA1Unit {
  const EnglishA1Unit(this.id, this.title, this.titleAr, this.goal, this.lessons);
  final int id;
  final String title;
  final String titleAr;
  final String goal;
  final List<EnglishA1Lesson> lessons;
}

class EnglishA1StoryPage {
  const EnglishA1StoryPage(this.text, this.arabic);
  final String text;
  final String arabic;
}

class EnglishA1Story {
  const EnglishA1Story({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.scene,
    required this.pages,
    required this.question,
    required this.options,
    required this.answer,
  });
  final String id;
  final String title;
  final String titleAr;
  final int scene;
  final List<EnglishA1StoryPage> pages;
  final String question;
  final List<String> options;
  final int answer;
}

EnglishA1Lesson _a(
  String id, EnglishA1Kind kind, String title, String titleAr,
  String teaching, String arabic, String spoken,
  String question, List<String> choices, int answer, {String? storyId}
) => EnglishA1Lesson(
  id: id, kind: kind, title: title, titleAr: titleAr, teaching: teaching,
  arabic: arabic, spoken: spoken, question: question, options: choices,
  answer: answer, storyId: storyId,
);

abstract final class EnglishA1Catalog {
  static const storyOne = EnglishA1Story(
    id: 'u1_lost', title: 'The Lost Notebook', titleAr: 'الدفتر المفقود', scene: 0,
    pages: [
      EnglishA1StoryPage('Sara has a blue notebook. It is her favorite notebook.', 'لدى سارة دفتر أزرق، وهو دفترها المفضل.'),
      EnglishA1StoryPage('Today, the notebook is not in her bag. “Oh no!” says Sara.', 'اليوم لا تجد الدفتر في حقيبتها. تقول سارة: «يا إلهي!»'),
      EnglishA1StoryPage('She looks under her chair. A little paper star is there.', 'تنظر تحت كرسيها وتجد نجمة ورقية صغيرة.'),
      EnglishA1StoryPage('Tom smiles. “Hello, Sara! Is this your blue notebook?”', 'يبتسم توم: «مرحبًا يا سارة! هل هذا دفترك الأزرق؟»'),
      EnglishA1StoryPage('“Yes! Thank you, Tom!” The star is a gift from her friend.', '«نعم! شكرًا يا توم!» والنجمة هدية من صديقها.'),
    ],
    question: 'Who has Sara’s notebook?',
    options: ['The teacher', 'Tom', 'Her sister'], answer: 1,
  );
  static const storyTwo = EnglishA1Story(
    id: 'u1_bluebook', title: 'A Secret in the Library',
    titleAr: 'سر صغير في المكتبة', scene: 1,
    pages: [
      EnglishA1StoryPage('Maya goes to the library with her friend Leo.', 'تذهب مايا إلى المكتبة مع صديقها ليو.'),
      EnglishA1StoryPage('She finds a small blue book. Inside it is a note.', 'تجد كتابًا أزرق صغيرًا. وفي داخله ورقة.'),
      EnglishA1StoryPage('The note says, “Look at page ten!” Maya opens page ten.', 'تقول الورقة: «انظري إلى الصفحة العاشرة!» فتفتح مايا الصفحة.'),
      EnglishA1StoryPage('There is a picture of a big green tree. Leo laughs.', 'تجد صورة شجرة خضراء كبيرة. يضحك ليو.'),
      EnglishA1StoryPage('“This is our tree!” says Leo. It is a book about their town.', 'يقول ليو: «هذه شجرتنا!» إنه كتاب عن بلدتهما.'),
    ],
    question: 'What is on page ten?',
    options: ['A green tree', 'A red car', 'A yellow hat'], answer: 0,
  );
  static const storyThree = EnglishA1Story(
    id: 'u2_breakfast', title: 'The Missing Breakfast',
    titleAr: 'لغز الفطور', scene: 2,
    pages: [
      EnglishA1StoryPage('Lina wakes up at seven. She is hungry.', 'تستيقظ لينا في السابعة وتشعر بالجوع.'),
      EnglishA1StoryPage('She goes to the kitchen. “Where is my bread?” she asks.', 'تذهب إلى المطبخ وتسأل: «أين خبزي؟»'),
      EnglishA1StoryPage('Her cat Mimi is under the table. There is a little bag near Mimi.', 'قطتها ميمي تحت الطاولة، وبجانبها كيس صغير.'),
      EnglishA1StoryPage('Lina opens the bag. There is an apple, but no bread!', 'تفتح لينا الكيس فتجد تفاحة، لكن لا تجد خبزًا!'),
      EnglishA1StoryPage('Dad comes home with fresh bread. “Good morning!” he says.', 'يعود والدها ومعه خبز طازج ويقول: «صباح الخير!»'),
    ],
    question: 'Who brings the bread?',
    options: ['Mimi', 'Dad', 'Lina'], answer: 1,
  );
  static const storyFour = EnglishA1Story(
    id: 'u2_rain', title: 'The Rainy Bus Ride', titleAr: 'رحلة الحافلة الممطرة', scene: 3,
    pages: [
      EnglishA1StoryPage('It is Monday. Ben goes to school by bus.', 'اليوم الاثنين. يذهب بن إلى المدرسة بالحافلة.'),
      EnglishA1StoryPage('It starts to rain. Ben has no umbrella.', 'يبدأ المطر، وليس لدى بن مظلة.'),
      EnglishA1StoryPage('His friend Noor sits next to him. She has a big yellow umbrella.', 'تجلس صديقته نور بجانبه ولديها مظلة صفراء كبيرة.'),
      EnglishA1StoryPage('They get off the bus. “Let’s walk together,” says Noor.', 'ينزلان من الحافلة. تقول نور: «لنمشِ معًا».'),
      EnglishA1StoryPage('At school, Ben says, “Thank you!” Noor smiles. “You’re welcome!”', 'في المدرسة يقول بن: «شكرًا!» فتبتسم نور: «على الرحب والسعة!»'),
    ],
    question: 'What color is Noor’s umbrella?',
    options: ['Blue', 'Green', 'Yellow'], answer: 2,
  );
  static const storyFive = EnglishA1Story(
    id: 'u3_star', title: 'The Door with a Star', titleAr: 'الباب ذو النجمة', scene: 4,
    pages: [
      EnglishA1StoryPage('Omar has a map. He wants to find a little music shop.', 'لدى عمر خريطة. يريد العثور على متجر موسيقى صغير.'),
      EnglishA1StoryPage('“Go straight and turn left,” says his friend Eva.', 'تقول صديقته إيفا: «امشِ مستقيمًا ثم انعطف يسارًا».'),
      EnglishA1StoryPage('Omar sees a red door, but it is a bakery.', 'يرى عمر بابًا أحمر، لكنه باب مخبز.'),
      EnglishA1StoryPage('Then he sees a blue door with a gold star.', 'ثم يرى بابًا أزرق عليه نجمة ذهبية.'),
      EnglishA1StoryPage('Music comes from inside. “I found it!” says Omar.', 'تأتي الموسيقى من الداخل. يقول عمر: «لقد وجدته!»'),
    ],
    question: 'What is on the music shop door?',
    options: ['A gold star', 'A cat', 'A red flower'], answer: 0,
  );
  static const storySix = EnglishA1Story(
    id: 'u3_garden', title: 'The Night Garden', titleAr: 'حديقة الليل', scene: 5,
    pages: [
      EnglishA1StoryPage('Nina visits her grandmother in a small town.', 'تزور نينا جدتها في بلدة صغيرة.'),
      EnglishA1StoryPage('At night, Grandma gives her a little lantern.', 'في الليل تعطيها جدتها فانوسًا صغيرًا.'),
      EnglishA1StoryPage('They walk to the garden. There are flowers and tiny lights.', 'تسيران إلى الحديقة، وفيها زهور وأضواء صغيرة.'),
      EnglishA1StoryPage('“Are these stars?” asks Nina. “No, they are fireflies,” says Grandma.', 'تسأل نينا: «هل هذه نجوم؟» فتقول جدتها: «لا، إنها يراعات».'),
      EnglishA1StoryPage('Nina smiles. “This is my favorite place!”', 'تبتسم نينا: «هذا مكاني المفضل!»'),
    ],
    question: 'What are the tiny lights?',
    options: ['Cars', 'Fireflies', 'Phones'], answer: 1,
  );
  static const stories = <EnglishA1Story>[
    storyOne, storyTwo, storyThree, storyFour, storyFive, storySix,
  ];

  static final units = <EnglishA1Unit>[
    EnglishA1Unit(1, 'Hello, World!', 'التحيات والتعارف',
        'Meet new friends, introduce yourself and read two mysteries.', [
      _a('en_a1_1_01', EnglishA1Kind.dialogue, 'A Friendly Hello', 'أول محادثة',
        'A: Hello! My name is Sara. B: Hi, Sara! I am Leo.',
        'تعلّم تحية شخص جديد وتقديم اسمك.',
        'Hello! My name is Sara. Hi, Sara! I am Leo.',
        'What is a friendly reply to “Hello”?', ['Goodbye!', 'Hi!', 'Yesterday'], 1),
      _a('en_a1_1_02', EnglishA1Kind.vocabulary, 'Five First Words', 'خمس كلمات أساسية',
        'Hello = مرحبًا • Name = اسم • Friend = صديق • Please = من فضلك • Thanks = شكرًا',
        'هذه كلمات مفيدة للتعارف.', 'Hello. Name. Friend. Please. Thanks.',
        'Which word means صديق?', ['Thanks', 'Friend', 'Please'], 1),
      _a('en_a1_1_03', EnglishA1Kind.pronunciation, 'Say Hello Clearly', 'نطق التحيات',
        'Say “hello” slowly. Stress the second syllable: he-LLO.',
        'استمع ثم كرر. التشديد في المقطع الثاني.', 'Hello. Hello! Nice to meet you.',
        'Which phrase is a greeting?', ['Nice to meet you', 'Under the table', 'At seven'], 0),
      _a('en_a1_1_04', EnglishA1Kind.grammar, 'I Am / You Are', 'قاعدة أنا وأنت',
        'I am Sara. You are Leo. We use “am” with I and “are” with you.',
        'نستخدم am مع I وare مع you.', 'I am Sara. You are my friend.',
        'Choose the correct sentence.', ['I are Sara.', 'I am Sara.', 'I is Sara.'], 1),
      _a('en_a1_1_05', EnglishA1Kind.listening, 'Who Is Speaking?', 'استمع وحدد الشخص',
        'Listen to a short introduction, then answer.',
        'استمع إلى التعارف وأجب.', 'Hi! I am Maya. This is my friend Tom.',
        'Who is Maya’s friend?', ['Tom', 'Sara', 'Lina'], 0),
      _a('en_a1_1_06', EnglishA1Kind.story, 'The Lost Notebook', 'قصة الدفتر المفقود',
        'Read a mystery about friendship and a blue notebook.',
        'اقرأ الصفحات ثم أجب عن سؤال الفهم.', 'Sara has a blue notebook.',
        'Who finds the notebook?', ['Leo', 'Tom', 'Maya'], 1, storyId: 'u1_lost'),
      _a('en_a1_1_07', EnglishA1Kind.vocabulary, 'Colors & Objects', 'الألوان والأشياء',
        'Blue notebook. Green tree. Red bag. Small star. Big book.',
        'أزرق، أخضر، أحمر، صغير، كبير.', 'Blue notebook. Green tree. Red bag.',
        'Which color is a tree in our story?', ['Green', 'Purple', 'Orange'], 0),
      _a('en_a1_1_08', EnglishA1Kind.dialogue, 'Meet My Friend', 'عرّف بصديقك',
        'A: This is my friend Leo. B: Nice to meet you, Leo!',
        'قدّم صديقًا جديدًا بشكل مهذب.', 'This is my friend Leo. Nice to meet you, Leo.',
        'What do you say after an introduction?', ['Nice to meet you.', 'It is ten.', 'Turn left.'], 0),
      _a('en_a1_1_09', EnglishA1Kind.grammar, 'This Is / That Is', 'هذا وذاك',
        'This is my notebook. That is your book. “This” is near; “that” is farther.',
        'This للقريب وThat للأبعد.', 'This is my notebook. That is your book.',
        'Which phrase points to a nearby object?', ['This is my book.', 'Yesterday I ran.', 'I will call.'], 0),
      _a('en_a1_1_10', EnglishA1Kind.story, 'The Secret Library', 'سر المكتبة',
        'Maya and Leo find a special page in a library book.',
        'اكتشف ماذا يوجد في الصفحة العاشرة.', 'Look at page ten!',
        'What does Maya see?', ['A car', 'A tree', 'A phone'], 1, storyId: 'u1_bluebook'),
      _a('en_a1_1_11', EnglishA1Kind.practice, 'Build a Greeting', 'تحدي التحيات',
        'Put these ideas together: Hello. My name is __. Nice to meet you.',
        'تدرّب على تكوين تعارف كامل.', 'Hello! My name is Ali. Nice to meet you.',
        'Choose the natural introduction.', ['Name is friend hello.', 'Hello! My name is Ali.', 'Yesterday are Ali.'], 1),
      _a('en_a1_1_12', EnglishA1Kind.quiz, 'Unit One Challenge', 'اختبار الوحدة الأولى',
        'Review greetings, friends, colors and “I am”.',
        'اختبر ما تعلمته في الوحدة.', 'I am Sara. This is my blue notebook.',
        'Complete: I ___ Sara.', ['are', 'is', 'am'], 2),
    ]),
    EnglishA1Unit(2, 'A Day with Friends', 'العائلة والروتين اليومي',
        'Use everyday verbs, tell the time and follow two everyday adventures.', [
      _a('en_a1_2_01', EnglishA1Kind.dialogue, 'Good Morning!', 'محادثة الصباح',
        'A: Good morning! B: Good morning! How are you?',
        'تدرّب على تحية الصباح.', 'Good morning! How are you?',
        'What is a good morning greeting?', ['Good morning!', 'Good night!', 'Goodbye!'], 0),
      _a('en_a1_2_02', EnglishA1Kind.vocabulary, 'My Morning Words', 'مفردات الصباح',
        'Wake up = أستيقظ • Breakfast = فطور • School = مدرسة • Work = عمل • Bus = حافلة',
        'كلمات أساسية للحياة اليومية.', 'Wake up. Breakfast. School. Work. Bus.',
        'What do you eat in the morning?', ['A map', 'Breakfast', 'A bus'], 1),
      _a('en_a1_2_03', EnglishA1Kind.pronunciation, 'Days and Times', 'نطق الوقت',
        'Seven. Eight. Morning. Evening. Say each number and word clearly.',
        'استمع للأرقام وأوقات اليوم.', 'Seven. Eight. Morning. Evening.',
        'Which word means مساء?', ['Morning', 'Evening', 'Seven'], 1),
      _a('en_a1_2_04', EnglishA1Kind.grammar, 'I Wake Up', 'المضارع البسيط',
        'I wake up at seven. She wakes up at eight. Add -s for she.',
        'نضيف s غالبًا مع she في المضارع البسيط.',
        'I wake up at seven. She wakes up at eight.',
        'Choose the correct sentence.', ['She wake up.', 'She wakes up.', 'She waking up.'], 1),
      _a('en_a1_2_05', EnglishA1Kind.listening, 'What Time?', 'استمع إلى الوقت',
        'Listen to Lina describe her morning.',
        'استمع وحدد وقت استيقاظ لينا.', 'I wake up at seven. I eat breakfast at eight.',
        'What time does Lina wake up?', ['Six', 'Seven', 'Nine'], 1),
      _a('en_a1_2_06', EnglishA1Kind.story, 'The Missing Breakfast', 'قصة لغز الفطور',
        'Lina, her cat Mimi, and a missing breakfast.',
        'اقرأ القصة واكتشف من أحضر الخبز.', 'Lina wakes up at seven.',
        'Who brings the bread?', ['Dad', 'Mimi', 'Ben'], 0, storyId: 'u2_breakfast'),
      _a('en_a1_2_07', EnglishA1Kind.vocabulary, 'Family & Pets', 'العائلة والحيوانات',
        'Mother. Father. Sister. Brother. Cat. Dog.',
        'تعلّم كلمات العائلة والحيوانات.', 'Mother. Father. Sister. Brother. Cat.',
        'Which animal says meow?', ['Dog', 'Cat', 'Bird'], 1),
      _a('en_a1_2_08', EnglishA1Kind.dialogue, 'On the Bus', 'محادثة في الحافلة',
        'A: Is this seat free? B: Yes, please sit here.',
        'تدرّب على السؤال عن مقعد فارغ.', 'Is this seat free? Yes, please sit here.',
        'What is a polite answer?', ['Yes, please sit here.', 'It is a cat.', 'At midnight.'], 0),
      _a('en_a1_2_09', EnglishA1Kind.grammar, 'At / In / On', 'حروف الجر',
        'At seven. In the morning. On Monday. These mark times and days.',
        'at للساعة، in لفترة اليوم، on ليوم الأسبوع.',
        'At seven. In the morning. On Monday.',
        'Complete: ___ Monday.', ['On', 'At', 'In'], 0),
      _a('en_a1_2_10', EnglishA1Kind.story, 'The Rainy Bus', 'رحلة الحافلة الممطرة',
        'Ben meets a helpful friend on a rainy day.',
        'اقرأ عن التعاون في يوم ممطر.', 'It starts to rain. Ben has no umbrella.',
        'What does Noor share?', ['Her lunch', 'Her umbrella', 'Her phone'], 1, storyId: 'u2_rain'),
      _a('en_a1_2_11', EnglishA1Kind.practice, 'Tell Me Your Day', 'احكِ عن يومك',
        'I wake up at seven. I go to school. I study in the evening.',
        'كوّن ثلاث جمل عن يومك.', 'I wake up at seven. I go to school.',
        'Which sentence describes a daily habit?', ['I go to school every day.', 'Hello, apple!', 'Go left tomorrow yesterday.'], 0),
      _a('en_a1_2_12', EnglishA1Kind.quiz, 'Unit Two Challenge', 'اختبار الوحدة الثانية',
        'Review time, routine, family and the rainy bus story.',
        'اختبار قصير لما تعلمته.', 'She goes to school on Monday.',
        'Choose the correct sentence.', ['She go to school.', 'She goes to school.', 'She going to school.'], 1),
    ]),
    EnglishA1Unit(3, 'Explore the City', 'الأماكن والتسوق والمغامرات',
        'Ask for directions, shop politely and discover a little night garden.', [
      _a('en_a1_3_01', EnglishA1Kind.dialogue, 'Where Is the Shop?', 'أين المتجر؟',
        'A: Excuse me! Where is the shop? B: It is next to the café.',
        'تعلّم السؤال عن مكان.', 'Excuse me! Where is the shop?',
        'How do you ask for a location?', ['Where is the shop?', 'I like green.', 'Seven is my friend.'], 0),
      _a('en_a1_3_02', EnglishA1Kind.vocabulary, 'Places in Town', 'أماكن المدينة',
        'Library. Shop. Café. Park. School. Station.',
        'تعلم أسماء الأماكن.', 'Library. Shop. Café. Park. Station.',
        'Where can you borrow books?', ['At a library', 'On a bus', 'In a shoe'], 0),
      _a('en_a1_3_03', EnglishA1Kind.pronunciation, 'Left or Right?', 'نطق الاتجاهات',
        'Left. Right. Straight. Near. Far. Listen and repeat.',
        'استمع ثم كرر الاتجاهات.', 'Left. Right. Go straight. Turn left.',
        'Which word is the opposite of left?', ['Straight', 'Right', 'Near'], 1),
      _a('en_a1_3_04', EnglishA1Kind.grammar, 'There Is / There Are', 'هناك مفرد وجمع',
        'There is one door. There are two doors.',
        'There is للمفرد وThere are للجمع.',
        'There is a shop. There are two shops.',
        'Complete: There ___ two shops.', ['is', 'are', 'am'], 1),
      _a('en_a1_3_05', EnglishA1Kind.listening, 'Follow the Map', 'استمع إلى الطريق',
        'Listen and follow the directions.',
        'استمع وحدد الاتجاه المطلوب.', 'Go straight. Turn left at the park.',
        'Where do you turn?', ['Right', 'Left', 'Back'], 1),
      _a('en_a1_3_06', EnglishA1Kind.story, 'The Door with a Star', 'الباب ذو النجمة',
        'Omar searches for a shop marked by a gold star.',
        'اتبع الخريطة مع عمر.', 'Go straight and turn left.',
        'What is on the door?', ['A star', 'A cat', 'A tree'], 0, storyId: 'u3_star'),
      _a('en_a1_3_07', EnglishA1Kind.vocabulary, 'At the Market', 'مفردات التسوق',
        'How much? Apple. Bread. Water. Money. Thank you.',
        'عبارات التسوق الأساسية.', 'How much is the apple? Three dollars, please.',
        'What question asks for a price?', ['How much is it?', 'Where are you from?', 'What day is it?'], 0),
      _a('en_a1_3_08', EnglishA1Kind.dialogue, 'Can I Have Water?', 'طلب مهذب',
        'A: Can I have some water, please? B: Of course!',
        'اسأل بطريقة مهذبة في المتجر.', 'Can I have some water, please? Of course!',
        'Which request is polite?', ['Water now!', 'Can I have water, please?', 'Where are tomorrow?'], 1),
      _a('en_a1_3_09', EnglishA1Kind.grammar, 'I Like / I Want', 'أحب وأريد',
        'I like flowers. I want a book. Like is preference; want is a wish.',
        'like للتفضيل وwant للرغبة.', 'I like flowers. I want a book.',
        'What do you say for a wish?', ['I want a book.', 'I am yesterday.', 'She are two.'], 0),
      _a('en_a1_3_10', EnglishA1Kind.story, 'The Night Garden', 'قصة حديقة الليل',
        'Nina discovers something magical-looking with her grandma.',
        'اقرأ عن أضواء الحديقة المدهشة.', 'Are these stars? No, they are fireflies.',
        'What shines in the garden?', ['Fireflies', 'Trains', 'Phones'], 0, storyId: 'u3_garden'),
      _a('en_a1_3_11', EnglishA1Kind.practice, 'A Day in Town', 'تحدي المدينة',
        'Ask for a shop, buy water and give directions to a friend.',
        'اربط بين المحادثة والاتجاهات والتسوق.',
        'Excuse me. Where is the café? Go straight. Thank you!',
        'Choose a clear direction.', ['Turn left at the park.', 'Park is on yesterday.', 'Turn thank you.'], 0),
      _a('en_a1_3_12', EnglishA1Kind.quiz, 'A1 Final Adventure', 'اختبار مغامرة A1',
        'Review introductions, routine, directions, stories and polite requests.',
        'مراجعة شاملة للمحتوى المبدئي من A1.', 'Hello! My name is Sara. Where is the library?',
        'Choose the correct phrase.', ['There are one shop.', 'There is a shop.', 'There am a shop.'], 1),
    ]),
  ];

  static int get lessonCount => units.fold(0, (n, u) => n + u.lessons.length);

  static EnglishA1Story? findStory(String id) {
    for (final story in stories) {
      if (story.id == id) return story;
    }
    return null;
  }
}
