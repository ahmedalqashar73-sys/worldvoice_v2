/// A real, teacher-led explanation for the first three English A1 lessons.
/// These are structured study sessions, not AI-generated replies or an
/// automatic CEFR certificate. Target pace: approximately 15–20 minutes.
class AcademyTutorExample {
  const AcademyTutorExample(this.english, this.arabic, this.note);
  final String english;
  final String arabic;
  final String note;
}

class AcademyTutorCheck {
  const AcademyTutorCheck(
    this.prompt,
    this.options,
    this.correctIndex,
    this.explanation,
  );
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class AcademyTutorLesson {
  const AcademyTutorLesson({
    required this.title,
    required this.welcomeArabic,
    required this.goalArabic,
    required this.ruleArabic,
    required this.patterns,
    required this.examples,
    required this.commonMistake,
    required this.correctForm,
    required this.mistakeExplanationArabic,
    required this.teacherTipArabic,
    required this.pronunciationGuide,
    required this.pronunciationTipArabic,
    required this.checks,
  });
  final String title;
  final String welcomeArabic;
  final String goalArabic;
  final String ruleArabic;
  final List<String> patterns;
  final List<AcademyTutorExample> examples;
  final String commonMistake;
  final String correctForm;
  final String mistakeExplanationArabic;
  final String teacherTipArabic;
  final List<String> pronunciationGuide;
  final String pronunciationTipArabic;
  final List<AcademyTutorCheck> checks;
}

abstract final class AcademyA1TutorCatalog {
  static const lessons = <AcademyTutorLesson>[
    AcademyTutorLesson(
      title: 'I am / You are',
      welcomeArabic:
          'مرحبًا! أنا إيما، معلمتك في WorldVoice. اليوم سنتعلم كيف تعرّف بنفسك، وتسأل شخصًا عن اسمه، وتبني أول جملة صحيحة باللغة الإنجليزية. سنشرح، نستمع، ثم نجرّب معًا.',
      goalArabic:
          'بعد الدرس ستستطيع قول اسمك، ووصف نفسك، والتمييز بين I am وYou are، ثم الإجابة عن سؤال بسيط دون حفظ أعمى.',
      ruleArabic:
          'في الإنجليزية نحتاج إلى الفعل be عندما نريد قول «أنا طالب» أو «أنت صديقي». مع I نستخدم am، ومع you نستخدم are. لا نحذف الفعل مثلما قد يحدث في العربية. لذلك نقول I am a student، وليس I a student.',
      patterns: [
        'I + am + name / adjective / a job',
        'You + are + name / adjective / my friend',
        'I am = I’m    •    You are = You’re',
        'Am I ...?    •    Are you ...?',
      ],
      examples: [
        AcademyTutorExample('I am Sara.', 'أنا سارة.',
          'استخدم I am قبل الاسم عندما تقدم نفسك.'),
        AcademyTutorExample('I am a student.', 'أنا طالب.',
          'لاحظ وجود a قبل كلمة student المفردة.'),
        AcademyTutorExample('You are my friend.', 'أنت صديقي.',
          'You تتبعها are، وليس am.'),
        AcademyTutorExample('Are you a student?', 'هل أنت طالب؟',
          'لصياغة السؤال نبدأ بـ Are ثم you.'),
        AcademyTutorExample('Yes, I am. / No, I am not.',
          'نعم، أنا كذلك. / لا، لست كذلك.',
          'الإجابة المختصرة تستخدم am أيضًا.'),
      ],
      commonMistake: 'I are happy.  ✕',
      correctForm: 'I am happy.  ✓',
      mistakeExplanationArabic:
          'مع I نستخدم am فقط. ومع you / we / they نستخدم are. تذكر: لا يكفي تغيير الضمير؛ يجب أن يتغير الفعل معه.',
      teacherTipArabic:
          'جرّب الآن أن تقول اسمك بصوت واضح ثلاث مرات: I am [your name]. بعدها تخيل أنك تقابل صديقًا وقل: You are my friend. لا تنتقل قبل أن تفهم الفرق.',
      pronunciationGuide: [
        'I /aɪ/',
        'am /æm/',
        'you /juː/',
        'are /ɑːr/',
        'I’m /aɪm/',
        'you’re /jʊr/',
      ],
      pronunciationTipArabic:
          'تعلم النطق من الصوت الإنجليزي الحقيقي ورموز IPA. صوت /æ/ في am ليس هو صوت /ɑː/ في are. استمع إلى الجملتين ثم قلد الإيقاع كاملًا.',
      checks: [
        AcademyTutorCheck(
          'Complete: I ___ a student.',
          ['are', 'am', 'is'], 1,
          'I always takes am: I am a student.'),
        AcademyTutorCheck(
          'Choose the correct sentence.',
          ['You am my friend.', 'You is my friend.', 'You are my friend.'], 2,
          'Use are after you: You are my friend.'),
        AcademyTutorCheck(
          'How do you ask a person if they are a student?',
          ['Are you a student?', 'You are student?', 'Am you a student?'], 0,
          'Move are before you to ask a question.'),
      ],
    ),
    AcademyTutorLesson(
      title: 'My / Your',
      welcomeArabic:
          'أهلًا بعودتك! في الدرس السابق تعرّفنا على I am وYou are. اليوم سأعلمك كيف تقول «اسمي» و«اسمك» و«كتابي» و«كتابك» بشكل طبيعي، وكيف تسأل شخصًا عن اسمه.',
      goalArabic:
          'ستميز بين my وyour وhis وher، وتسأل What is your name? وتجيب My name is ...، وتستخدم الصفات الملكية قبل الأسماء.',
      ruleArabic:
          'My وyour تسمى صفات الملكية، أي أنها توضح لمن الشيء. نضعها قبل الاسم مباشرة: my book، your name. لا نقول I book ولا you name. وعندما نتحدث عن شخص ثالث نستعمل his للمذكر وher للمؤنث.',
      patterns: [
        'my + noun     →     my name / my book',
        'your + noun     →     your name / your friend',
        'his + noun     →     his sister / his pen',
        'her + noun     →     her name / her bag',
        'What is your name?  →  My name is ...',
      ],
      examples: [
        AcademyTutorExample('My name is Maya.', 'اسمي مايا.',
          'My تسبق الاسم name.'),
        AcademyTutorExample('What is your name?', 'ما اسمك؟',
          'Your هنا تعني «الخاص بك».'),
        AcademyTutorExample('This is my book.', 'هذا كتابي.',
          'نقول my book وليس I book.'),
        AcademyTutorExample('His name is Leo.', 'اسمه ليو.',
          'his للملكية المتعلقة بشخص مذكر.'),
        AcademyTutorExample('Her name is Nina.', 'اسمها نينا.',
          'her للملكية المتعلقة بشخص مؤنث.'),
      ],
      commonMistake: 'You name is Sara.  ✕',
      correctForm: 'Your name is Sara.  ✓',
      mistakeExplanationArabic:
          'You ضمير بمعنى أنت، أما your فهي صفة ملكية بمعنى «الخاص بك». إذا جاء بعدها اسم مثل name أو book فاستخدم your.',
      teacherTipArabic:
          'جرّب حوار التعارف: اسأل What is your name? ثم أجب My name is [your name]. أشر إلى كتاب وقل This is my book. بهذه الطريقة تستخدم القاعدة في موقف حقيقي.',
      pronunciationGuide: [
        'my /maɪ/',
        'your /jʊr/',
        'name /neɪm/',
        'his /hɪz/',
        'her /hɝː/',
        'friend /frɛnd/',
      ],
      pronunciationTipArabic:
          'لاحظ الفرق بين you /juː/ وyour /jʊr/. كلمة name تحتوي على صوت /eɪ/ مثل game. استمع وكرر العبارة كاملة قبل الانتقال.',
      checks: [
        AcademyTutorCheck(
          'Complete: ___ name is Leo. (He is Leo.)',
          ['His', 'Your', 'I'], 0,
          'His shows possession for a male person: His name.'),
        AcademyTutorCheck(
          'Choose the natural question.',
          ['What is you name?', 'What is your name?', 'What your name is?'], 1,
          'Put your before name: What is your name?'),
        AcademyTutorCheck(
          'Complete: This is ___ book. (The book belongs to me.)',
          ['my', 'you', 'I'], 0,
          'Use my before a noun for something that belongs to you.'),
      ],
    ),
    AcademyTutorLesson(
      title: 'This / That',
      welcomeArabic:
          'ممتاز! صرت تعرف تقدم نفسك وتتكلم عن أشيائك. اليوم سأريك كيف تشير إلى شيء قريب أو بعيد. استخدم القاعدة وأنت تشير إلى أشياء موجودة حولك، لا تحفظ الكلمات وحدها.',
      goalArabic:
          'بعد الدرس ستقول This is my book وThat is your bag، وتفهم متى تختار this أو that، وكيف تسأل Is this your book?',
      ruleArabic:
          'This تشير إلى شيء مفرد قريب منك، وThat إلى شيء مفرد أبعد عنك. نستخدم is مع الاثنين في الجمل البسيطة: This is ... / That is ... . ولتكوين سؤال نقول Is this ...? أو Is that ...? لاحظ ترتيب الكلمات.',
      patterns: [
        'This + is + a noun     →     This is a book.',
        'That + is + a noun     →     That is a bag.',
        'Is this + your noun?     →     Is this your pen?',
        'Is that + your noun?     →     Is that your chair?',
        'Yes, it is.  •  No, it isn’t.',
      ],
      examples: [
        AcademyTutorExample('This is my pen.', 'هذا قلمي.',
          'استخدم this لقلم تمسكه أو تقف قربه.'),
        AcademyTutorExample('That is your bag.', 'تلك حقيبتك.',
          'استخدم that لحقيبة بعيدة قليلًا.'),
        AcademyTutorExample('Is this your book?', 'هل هذا كتابك؟',
          'هذا سؤال، ولذلك نقدم is على this.'),
        AcademyTutorExample('Yes, it is.', 'نعم، هو كذلك.',
          'إجابة قصيرة لسؤال يبدأ بـ Is this ...?'),
        AcademyTutorExample('No, that is not my notebook.',
          'لا، ذلك ليس دفتري.',
          'يمكن نفي الجملة بإضافة not بعد is.'),
      ],
      commonMistake: 'This my book.  ✕',
      correctForm: 'This is my book.  ✓',
      mistakeExplanationArabic:
          'لا تنسَ is بين this واسم الشيء في الجملة التعريفية. وإذا سألت: Is this my book? يتقدم is إلى بداية السؤال.',
      teacherTipArabic:
          'أمسك قلمًا وقل This is my pen. ثم أشر إلى شيء بعيد وقل That is my bag. اسأل شخصًا أمامك Is this your pen? وحاول الإجابة Yes, it is أو No, it isn’t.',
      pronunciationGuide: [
        'this /ðɪs/',
        'that /ðæt/',
        'these /ðiːz/',
        'those /ðoʊz/',
        'is /ɪz/',
        'book /bʊk/',
      ],
      pronunciationTipArabic:
          'أهم صوت اليوم /ð/ في this وthat. ضع طرف اللسان برفق بين الأسنان ودع الهواء والصوت يخرجان، ثم كرر مع صوت الإنجليزية. لا تنطقها مثل /d/ أو /z/.',
      checks: [
        AcademyTutorCheck(
          'A book is near you. Complete: ___ is my book.',
          ['That', 'This', 'Those'], 1,
          'This points to one item near you.'),
        AcademyTutorCheck(
          'Choose the complete sentence.',
          ['That your bag.', 'That are your bag.', 'That is your bag.'], 2,
          'Use is after that for one item.'),
        AcademyTutorCheck(
          'How do you ask about a nearby pen?',
          ['Is this your pen?', 'This is your pen?', 'Are this your pen?'], 0,
          'Move is to the front: Is this your pen?'),
      ],
    ),
  ];

  static AcademyTutorLesson? forUnitLesson(int unit, int lesson) {
    if (unit != 1 || lesson < 1 || lesson > 3) return null;
    return lessons[lesson - 1];
  }
}
