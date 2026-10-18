/// One purposeful language rule per English A1 lesson.
/// Curated examples and Arabic explanation avoid repeating the same grammar
/// sheet twelve times per unit.
class EnglishA1GrammarNote {
  const EnglishA1GrammarNote({
    required this.title,
    required this.examples,
    required this.arabic,
  });
  final String title;
  final String examples;
  final String arabic;
}

abstract final class EnglishA1GrammarCatalog {
  static const _units = <List<EnglishA1GrammarNote>>[
    [
      EnglishA1GrammarNote(title: "I am / You are", examples: "I am Sara. You are my friend. Use am with I and are with you.", arabic: "استخدم am مع I وare مع you."),
      EnglishA1GrammarNote(title: "Subject pronouns", examples: "I am happy. You are kind. He is Tom. She is Sara. We are friends.", arabic: "ضمائر الفاعل I وyou وhe وshe وwe تأخذ صيغة مناسبة من فعل be."),
      EnglishA1GrammarNote(title: "My / Your / His / Her", examples: "This is my name. Is that your name? His book is blue. Her book is red.", arabic: "صفات الملكية my وyour وhis وher تأتي قبل الاسم."),
      EnglishA1GrammarNote(title: "A and an", examples: "This is a book. She has an apple. Use an before vowel sounds.", arabic: "نستخدم a قبل الصوت الساكن وan قبل الصوت المتحرك."),
      EnglishA1GrammarNote(title: "Singular and plural", examples: "One book, two books. One pen, three pens. Most regular plurals add -s.", arabic: "غالبًا نضيف s إلى الاسم للجمع."),
      EnglishA1GrammarNote(title: "This is a / That is a", examples: "This is my bag. That is a table. This is near; that is farther.", arabic: "this للقريب وthat للبعيد."),
      EnglishA1GrammarNote(title: "Adjectives before nouns", examples: "A blue book. A happy friend. A small room. Put the describing word before the noun.", arabic: "في الإنجليزية تأتي الصفة غالبًا قبل الاسم."),
      EnglishA1GrammarNote(title: "Meet and introduce", examples: "This is my friend Leo. His name is Leo. Nice to meet you!", arabic: "استخدم This is my friend لتقديم شخص لشخص آخر."),
      EnglishA1GrammarNote(title: "What is / Who is", examples: "What is this? It is a notebook. Who is she? She is my friend.", arabic: "What للسؤال عن الأشياء وWho للسؤال عن الأشخاص."),
      EnglishA1GrammarNote(title: "In / On / Under", examples: "The notebook is in the bag. The book is on the table. The pen is under the chair.", arabic: "in داخل، on على، under تحت."),
      EnglishA1GrammarNote(title: "Have / Has", examples: "I have a friend. She has a new book. Use has with he and she.", arabic: "نستخدم have غالبًا مع I وyou، وhas مع he وshe."),
      EnglishA1GrammarNote(title: "Questions with be", examples: "Are you a student? Yes, I am. Is he your teacher? No, he is not.", arabic: "ابدأ السؤال بـ am أو is أو are عند استخدام فعل be."),
    ],
    [
      EnglishA1GrammarNote(title: "Simple present for I", examples: "I wake up early. I eat breakfast. I go to school every day.", arabic: "استخدم المضارع البسيط للروتين والعادات."),
      EnglishA1GrammarNote(title: "He / She with -s", examples: "She wakes up at seven. He walks to school. Usually add -s with he and she.", arabic: "غالبًا نضيف s للفعل مع he وshe في المضارع البسيط."),
      EnglishA1GrammarNote(title: "At / In / On for time", examples: "At seven. In the morning. On Monday. Choose the correct time preposition.", arabic: "at للساعة، in لفترة اليوم، on ليوم الأسبوع."),
      EnglishA1GrammarNote(title: "How often?", examples: "I always eat breakfast. I sometimes walk. I never drink coffee.", arabic: "always دائمًا، sometimes أحيانًا، never أبدًا."),
      EnglishA1GrammarNote(title: "Can / Cannot", examples: "I can read English. I cannot drive a bus. Can you swim?", arabic: "can للقدرة وcannot للنفي."),
      EnglishA1GrammarNote(title: "Do / Does questions", examples: "Do you study English? Does she go to school? Use does with he or she.", arabic: "في أسئلة المضارع نستخدم do مع I وyou، وdoes مع he وshe."),
      EnglishA1GrammarNote(title: "There is / There are", examples: "There is a cat under the table. There are two cats in the garden.", arabic: "there is للمفرد وthere are للجمع."),
      EnglishA1GrammarNote(title: "Object pronouns", examples: "I see him. She helps me. We know them. These pronouns follow a verb or preposition.", arabic: "ضمائر المفعول مثل me وhim وthem تأتي بعد الفعل أو حرف الجر."),
      EnglishA1GrammarNote(title: "Present simple negatives", examples: "I do not work on Sunday. He does not study at night.", arabic: "نستخدم do not مع I، وdoes not مع he وshe."),
      EnglishA1GrammarNote(title: "Polite imperatives", examples: "Please sit here. Wait for the bus. Do not run in the rain.", arabic: "الأمر يبدأ بالفعل، ويمكن إضافة please ليكون مهذبًا."),
      EnglishA1GrammarNote(title: "Yesterday and the past", examples: "Yesterday I walked home. I visited my friend. Regular past verbs often add -ed.", arabic: "غالبًا نضيف ed في الماضي للأفعال المنتظمة."),
      EnglishA1GrammarNote(title: "Review your routine", examples: "I wake up at seven, but my sister wakes up at eight. We go to school on Monday.", arabic: "راجع المضارع البسيط وs مع الغائب وحروف الجر الخاصة بالوقت."),
    ],
    [
      EnglishA1GrammarNote(title: "There is / There are in town", examples: "There is one museum. There are two cafés. Use is for one and are for many.", arabic: "there is مع المفرد، وthere are مع الجمع."),
      EnglishA1GrammarNote(title: "Directions", examples: "Go straight. Turn left. Then turn right at the library.", arabic: "عبارات الاتجاهات تبدأ غالبًا بفعل أمر: Go أو Turn."),
      EnglishA1GrammarNote(title: "Next to / Opposite", examples: "The bakery is next to the bank. The park is opposite the school.", arabic: "next to تعني بجانب، وopposite تعني مقابل."),
      EnglishA1GrammarNote(title: "How much / How many", examples: "How much is this apple? How many apples do you want?", arabic: "How much للسعر أو غير المعدود، وHow many للسؤال عن العدد."),
      EnglishA1GrammarNote(title: "Would like", examples: "I would like some water, please. Would you like a sandwich?", arabic: "would like طريقة مهذبة للتعبير عن الرغبة."),
      EnglishA1GrammarNote(title: "Some and any", examples: "I have some bread. Do you have any milk?", arabic: "غالبًا نستخدم some في الإثبات وany في الأسئلة والنفي."),
      EnglishA1GrammarNote(title: "Want and need", examples: "I want a new book. I need water. Want رغبة وneed ضرورة.", arabic: "want للرغبة، وneed للحاجة."),
      EnglishA1GrammarNote(title: "Where / Which", examples: "Where is the station? Which bus goes to the museum?", arabic: "Where للسؤال عن المكان وWhich للاختيار."),
      EnglishA1GrammarNote(title: "Going to plans", examples: "I am going to visit the park. She is going to buy a book.", arabic: "be going to للتعبير عن خطة مستقبلية."),
      EnglishA1GrammarNote(title: "Polite requests", examples: "Can I have some tea, please? Could you help me?", arabic: "الطلب المهذب يبدأ غالبًا بـ Can I أو Could you."),
      EnglishA1GrammarNote(title: "Comparative adjectives", examples: "This bag is smaller than that bag. This street is longer than that street.", arabic: "للمقارنة نضيف er لكثير من الصفات القصيرة ثم than."),
      EnglishA1GrammarNote(title: "A1 city review", examples: "There is a shop next to the bank. I would like two apples, please. Go straight.", arabic: "راجع المكان والاتجاهات والطلبات المهذبة قبل إنهاء الوحدة."),
    ],
  ];

  static EnglishA1GrammarNote forLesson(int unit, int lesson) {
    if (unit < 1 || unit > 3 || lesson < 1 || lesson > 12) {
      throw RangeError('No A1 grammar note for unit/lesson');
    }
    return _units[unit - 1][lesson - 1];
  }

  static int get totalNotes => _units.fold(0, (sum, unit) => sum + unit.length);
}
