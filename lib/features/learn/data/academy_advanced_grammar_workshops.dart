/// Additional CEFR-appropriate teaching examples for every published
/// advanced grammar lesson, beyond the original three simple examples.
/// These are original sentences, not duplicated story paragraphs.
class AdvancedGrammarExample {
  const AdvancedGrammarExample(this.english, this.arabic);
  final String english;
  final String arabic;
}
class AdvancedGrammarWorkshop {
  const AdvancedGrammarWorkshop({
    required this.explanationEnglish, required this.examples,
    required this.wrong, required this.correct,
    required this.question, required this.options, required this.answer,
  });
  final String explanationEnglish;
  final List<AdvancedGrammarExample> examples;
  final String wrong;
  final String correct;
  final String question;
  final List<String> options;
  final int answer;
}
abstract final class AdvancedGrammarWorkshops {
  static const _unit3A2 = <int, AdvancedGrammarWorkshop>{
    1: AdvancedGrammarWorkshop(
      explanationEnglish: "Use Could you + base verb to ask someone politely to do something. Use Could I + base verb to ask permission. Do not add to after could.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Could you show me the elevator?", "هل يمكنك إرشادي إلى المصعد؟"), AdvancedGrammarExample("Could I have a second key card?", "هل يمكنني الحصول على بطاقة مفتاح ثانية؟"), AdvancedGrammarExample("Could you tell me the breakfast hours?", "هل يمكنك إخباري بساعات الإفطار؟")],
      wrong: "Could you to check the booking?", correct: "Could you check the booking?",
      question: "Choose the grammatically correct sentence.",
      options: <String>["Could you checks the booking?", "Could you check the booking?", "Could you to check the booking?"], answer: 1,
    ),
    2: AdvancedGrammarWorkshop(
      explanationEnglish: "Would like to + base verb expresses a polite wish. Want to is more direct. Use a noun after would like when you are requesting a thing.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("We would like to arrive on Saturday.", "نود الوصول يوم السبت."), AdvancedGrammarExample("Would you like another night?", "هل ترغب في ليلة أخرى؟"), AdvancedGrammarExample("I want to read the new booking summary.", "أريد قراءة ملخص الحجز الجديد.")],
      wrong: "I would like change my dates.", correct: "I would like to change my dates.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["I would like changing my dates.", "I would like to changing my dates.", "I would like to change my dates."], answer: 2,
    ),
    3: AdvancedGrammarWorkshop(
      explanationEnglish: "Use must + base verb for a rule or strong obligation. Use must not for something that is forbidden. The verb after must never takes an extra s.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("You must leave large bags outside.", "يجب أن تترك الحقائب الكبيرة بالخارج."), AdvancedGrammarExample("We must not use a flash here.", "يُمنع أن نستخدم الفلاش هنا."), AdvancedGrammarExample("Everyone must follow the guide.", "يجب أن يتبع الجميع المرشد.")],
      wrong: "Visitors must to keep their tickets.", correct: "Visitors must keep their tickets.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["You must not touch the glass case.", "You must not touching the glass case.", "You must not to touch the glass case."], answer: 0,
    ),
    4: AdvancedGrammarWorkshop(
      explanationEnglish: "Use am, is or are + verb-ing for a future arrangement, especially with a future time expression. The time expression distinguishes the arrangement from an action happening now.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("My cousin is meeting me tonight.", "سيقابلني ابن عمي الليلة."), AdvancedGrammarExample("They are leaving on Friday morning.", "سيغادرون صباح الجمعة."), AdvancedGrammarExample("Are you taking the early flight tomorrow?", "هل ستستقل الرحلة المبكرة غدًا؟")],
      wrong: "We is flying tomorrow.", correct: "We are flying tomorrow.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["We are fly tomorrow.", "We are flying tomorrow.", "We is flying tomorrow."], answer: 1,
    ),
    5: AdvancedGrammarWorkshop(
      explanationEnglish: "Use Shall I + base verb to offer help as a question. Use I will or I will not to make a decision or offer at the moment of speaking. In conversation, I will is often contracted to I'll.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Shall I open the door for you?", "هل أفتح الباب لك؟"), AdvancedGrammarExample("I will put the box beside the wall.", "سأضع الصندوق بجوار الحائط."), AdvancedGrammarExample("Shall I bring a larger screwdriver?", "هل أحضر مفكًا أكبر؟")],
      wrong: "Shall I to carry the box?", correct: "Shall I carry the box?",
      question: "Choose the grammatically correct sentence.",
      options: <String>["Shall I carrying the box?", "Shall I carries the box?", "Shall I carry the box?"], answer: 2,
    ),
    6: AdvancedGrammarWorkshop(
      explanationEnglish: "Ask about a finished past job with Did + subject + base verb. Use the past simple in the answer. Do not put the main verb in the past form after did.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("When did your last job finish?", "متى انتهت وظيفتك السابقة؟"), AdvancedGrammarExample("She answered every question clearly.", "أجابت عن كل سؤال بوضوح."), AdvancedGrammarExample("Did they ask about your working hours?", "هل سألوا عن ساعات عملك؟")],
      wrong: "Did you worked in a shop?", correct: "Did you work in a shop?",
      question: "Choose the grammatically correct sentence.",
      options: <String>["Did you work in a shop?", "Did you worked in a shop?", "Did you working in a shop?"], answer: 0,
    ),
    7: AdvancedGrammarWorkshop(
      explanationEnglish: "Put usually, often and rarely before the main verb but after be. Ask How often to find out the frequency. Expressions such as twice a week usually come at the end.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("She rarely misses a class.", "نادرًا ما تفوتها حصة."), AdvancedGrammarExample("They are usually ready by six.", "يكونون عادة جاهزين بحلول السادسة."), AdvancedGrammarExample("How often do you walk to work?", "كم مرة تمشي إلى العمل؟")],
      wrong: "He is often be early.", correct: "He is often early.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["He goes twice a week to always.", "He usually goes to class on Monday.", "He goes usually to class on Monday."], answer: 1,
    ),
    8: AdvancedGrammarWorkshop(
      explanationEnglish: "Use if + present simple for a possible future condition, and will + base verb for its result. The if clause can come first or second. Do not use will inside the if clause in this pattern.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("If the rain stops, we will visit the farmyard.", "إذا توقف المطر، فسنزور ساحة المزرعة."), AdvancedGrammarExample("They will wait here if the coach is late.", "سينتظرون هنا إذا تأخرت الحافلة."), AdvancedGrammarExample("If you bring boots, your feet will stay dry.", "إذا أحضرت أحذية مطاطية، فستبقى قدماك جافتين.")],
      wrong: "If it will rain, we will go inside.", correct: "If it rains, we will go inside.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["If it raining, we will go inside.", "If it will rain, we go inside.", "If it rains, we will go inside."], answer: 2,
    ),
    9: AdvancedGrammarWorkshop(
      explanationEnglish: "Too comes before an adjective and suggests a problem: too cold. Enough comes after an adjective: warm enough. Enough comes before a noun: enough time.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The drink is too hot to drink now.", "الشراب ساخن أكثر من اللازم لشربه الآن."), AdvancedGrammarExample("This table is big enough for us.", "هذه الطاولة كبيرة بما يكفي لنا."), AdvancedGrammarExample("There are enough napkins for everyone.", "توجد مناديل كافية للجميع.")],
      wrong: "The meal is enough warm.", correct: "The meal is warm enough.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["The meal is warm enough.", "The meal is enough warm.", "The meal warm is too enough."], answer: 0,
    ),
    10: AdvancedGrammarWorkshop(
      explanationEnglish: "Use am, is or are going to + base verb for an intention or plan. Use if + present simple and will + base verb to describe an alternative if circumstances change.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("I am going to buy a new sketchbook.", "أنوي شراء دفتر رسم جديد."), AdvancedGrammarExample("Are they going to travel by bus?", "هل ينوون السفر بالحافلة؟"), AdvancedGrammarExample("If the course is full, we will choose another week.", "إذا كانت الدورة ممتلئة، فسنختار أسبوعًا آخر.")],
      wrong: "We going to visit the village.", correct: "We are going to visit the village.",
      question: "Choose the grammatically correct sentence.",
      options: <String>["We are going visit the village.", "We are going to visit the village.", "We going to visiting the village."], answer: 1,
    ),
  };
  static const _unit2A2 = <int, AdvancedGrammarWorkshop>{
    1: AdvancedGrammarWorkshop(
      explanationEnglish: 'Comparatives describe differences: brighter than, more comfortable than. Enough follows an adjective but precedes a noun.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('This bedroom is brighter than my old one.', 'غرفة النوم هذه أكثر إضاءة من غرفتي القديمة.'),
        AdvancedGrammarExample('The desk is small enough for the corner.', 'المكتب صغير بما يكفي للزاوية.'),
        AdvancedGrammarExample('We have enough space for two chairs.', 'لدينا مساحة كافية لكرسيين.'),
      ],
      wrong: 'My room is more brighter than yours.',
      correct: 'My room is brighter than yours.',
      question: 'Which comparison is correct?',
      options: <String>['My room is more brighter.', 'The lamp is enough small.', 'The room is brighter than before.'],
      answer: 2,
    ),
    2: AdvancedGrammarWorkshop(
      explanationEnglish: 'Use should for advice, should not for warnings, and must for strong requirements. Follow each modal with the base verb.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('You should drink more water.', 'ينبغي أن تشرب ماءً أكثر.'),
        AdvancedGrammarExample('You should not ignore a high fever.', 'لا ينبغي تجاهل الحمى المرتفعة.'),
        AdvancedGrammarExample('You must follow the medicine instructions.', 'يجب اتباع تعليمات الدواء.'),
      ],
      wrong: 'You should to stay at home.',
      correct: 'You should stay at home.',
      question: 'Choose the correct advice.',
      options: <String>['You should to rest.', 'You should rest.', 'You must to rest.'],
      answer: 1,
    ),
    3: AdvancedGrammarWorkshop(
      explanationEnglish: 'Sequence instructions with first, then, next and finally. Begin an imperative with its base verb, not with to.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('First, wash the vegetables.', 'أولًا اغسل الخضار.'),
        AdvancedGrammarExample('Then, add the broth.', 'ثم أضف المرق.'),
        AdvancedGrammarExample('Finally, serve the meal.', 'أخيرًا قدّم الوجبة.'),
      ],
      wrong: 'Finally, to serve the meal.',
      correct: 'Finally, serve the meal.',
      question: 'Choose the natural instruction.',
      options: <String>['Then, to add the onions.', 'Next, added some broth.', 'Finally, serve the meal.'],
      answer: 2,
    ),
    4: AdvancedGrammarWorkshop(
      explanationEnglish: 'Use have or has followed by the past participle. Just describes something recent; already describes completed work; yet often appears in questions and negatives.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('The mechanic has just fixed the tire.', 'الميكانيكي أصلح الإطار لتوه.'),
        AdvancedGrammarExample('I have already checked the chain.', 'لقد فحصت السلسلة بالفعل.'),
        AdvancedGrammarExample('Have you tested the brakes yet?', 'هل فحصت المكابح حتى الآن؟'),
      ],
      wrong: 'She has just fix the wheel.',
      correct: 'She has just fixed the wheel.',
      question: 'Which sentence uses the present perfect correctly?',
      options: <String>['She has fix the tire.', 'She has just fixed the tire.', 'She have fixed the tire.'],
      answer: 1,
    ),
    5: AdvancedGrammarWorkshop(
      explanationEnglish: 'Have to indicates an obligation. Do not have to means something is optional. Must not expresses prohibition, not a lack of obligation.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('You have to feed your new pet.', 'يجب أن تطعم حيوانك الجديد.'),
        AdvancedGrammarExample('You do not have to buy expensive toys.', 'ليس عليك شراء ألعاب غالية.'),
        AdvancedGrammarExample('You must not leave the door open.', 'ممنوع ترك الباب مفتوحًا.'),
      ],
      wrong: 'You must not buy expensive toys if you do not want to.',
      correct: 'You do not have to buy expensive toys if you do not want to.',
      question: 'Which sentence means a choice rather than a ban?',
      options: <String>['You must not buy a toy.', 'You do not have to buy a toy.', 'You cannot buy a toy.'],
      answer: 1,
    ),
    6: AdvancedGrammarWorkshop(
      explanationEnglish: 'Would you like is a polite way to offer something or invite a person. Use Shall I to offer help and I would love to for a polite acceptance.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('Would you like some tea?', 'هل ترغب في بعض الشاي؟'),
        AdvancedGrammarExample('Would you like to join us on Friday?', 'هل ترغب في الانضمام إلينا يوم الجمعة؟'),
        AdvancedGrammarExample('Shall I help with the cups?', 'هل أساعد في الأكواب؟'),
      ],
      wrong: 'Would you like joining us?',
      correct: 'Would you like to join us?',
      question: 'Which is the most polite invitation?',
      options: <String>['You will come now?', 'Would you like to join us?', 'You join us yesterday?'],
      answer: 1,
    ),
    7: AdvancedGrammarWorkshop(
      explanationEnglish: 'For tells us how long an activity lasts. Since tells us its starting point. Use them with the present perfect for actions continuing to now.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('We have practised for two months.', 'تدرّبنا منذ شهرين لمدة شهرين.'),
        AdvancedGrammarExample('I have studied since January.', 'درست منذ يناير.'),
        AdvancedGrammarExample('How long have you known your partner?', 'منذ متى تعرف شريكك؟'),
      ],
      wrong: 'We have practised since three weeks.',
      correct: 'We have practised for three weeks.',
      question: 'Which sentence uses since correctly?',
      options: <String>['I have studied since Monday.', 'I have studied since three weeks.', 'I study since tomorrow.'],
      answer: 0,
    ),
    8: AdvancedGrammarWorkshop(
      explanationEnglish: 'A defining relative clause identifies a person or thing. Use who for people, which for things and that for either when the meaning is clear.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('The driver who found the phone called Lina.', 'السائق الذي وجد الهاتف اتصل بلينا.'),
        AdvancedGrammarExample('This is the phone that she lost.', 'هذا هو الهاتف الذي فقدته.'),
        AdvancedGrammarExample('The screen which was broken is now repaired.', 'الشاشة التي كانت مكسورة صُلحت الآن.'),
      ],
      wrong: 'The driver which found the phone was kind.',
      correct: 'The driver who found the phone was kind.',
      question: 'Which relative clause is correct?',
      options: <String>['The person which helped me was kind.', 'The officer who helped was friendly.', 'The phone who I lost is blue.'],
      answer: 1,
    ),
    9: AdvancedGrammarWorkshop(
      explanationEnglish: 'Use be going to for a plan you already made. Use will for a decision made while speaking or for a promise.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('I am going to buy a birthday gift.', 'سأشتري هدية عيد ميلاد وفق خطة.'),
        AdvancedGrammarExample('I will wrap it for you.', 'سأغلفها لك، وهو قرار لحظي.'),
        AdvancedGrammarExample('She is going to enjoy the surprise.', 'ستستمتع بالمفاجأة على الأغلب.'),
      ],
      wrong: 'I going to buy a present.',
      correct: 'I am going to buy a present.',
      question: 'Which sentence describes a planned purchase?',
      options: <String>['I am going to buy a gift.', 'I going to buy a gift.', 'I am going buy a gift.'],
      answer: 0,
    ),
    10: AdvancedGrammarWorkshop(
      explanationEnglish: 'Used to + base verb describes a repeated habit or state in the past that is no longer true. After did, use use to without -d.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('We used to visit the sea every summer.', 'كنا نزور البحر كل صيف سابقًا.'),
        AdvancedGrammarExample('I did not use to like the cold water.', 'لم أكن أحب الماء البارد سابقًا.'),
        AdvancedGrammarExample('Did you use to collect seashells?', 'هل كنت تجمع الأصداف سابقًا؟'),
      ],
      wrong: 'Did you used to swim here?',
      correct: 'Did you use to swim here?',
      question: 'Which sentence describes a past habit correctly?',
      options: <String>['We use to went to the beach.', 'We used to visit this beach.', 'Did you used to live here?'],
      answer: 1,
    ),
  };

  static const _workshops = <String, AdvancedGrammarWorkshop>{
    'B2:4': AdvancedGrammarWorkshop(
      explanationEnglish: 'Use must or have to for essential duties and should or ought to for recommendations. The base verb follows modal verbs without to, except ought to. Be specific about safety versus advice.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('Food must be kept at a safe temperature.', 'يجب حفظ الطعام في درجة حرارة آمنة.'),
        AdvancedGrammarExample('Schools ought to review how much food is wasted.', 'ينبغي للمدارس مراجعة كمية الطعام المهدور.'),
        AdvancedGrammarExample('Students need not finish food if they are full.', 'ليس ضروريًا أن يُكمل الطلاب طعامهم إن كانوا شبعانين.'),
      ],
      wrong: 'The cafeteria should to check food temperatures.',
      correct: 'The cafeteria should check food temperatures.',
      question: 'Which sentence states a mandatory food-safety rule?',
      options: <String>[
        'Food could be stored safely if convenient.',
        'Food must be stored at a safe temperature.',
        'Food ought check the temperature.',
      ],
      answer: 1,
    ),

    'B2:3': AdvancedGrammarWorkshop(
      explanationEnglish: 'In a balanced argument, although introduces an opposing fact, provided that states a condition, and would expresses a hypothetical consequence. Explain uncertainty rather than presenting projections as guarantees.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('Although solar power is cheaper in the long run, installation is costly.', 'رغم أن الشمسية أرخص على المدى الطويل، فالتركيب مكلف.'),
        AdvancedGrammarExample('The plan may succeed provided that maintenance is funded.', 'قد تنجح الخطة بشرط تمويل الصيانة.'),
        AdvancedGrammarExample('Savings would increase if consumption fell.', 'ستزداد الوفورات افتراضيا لو انخفض الاستهلاك.'),
      ],
      wrong: 'Despite the panels are efficient, costs remain high.',
      correct: 'Although the panels are efficient, costs remain high.',
      question: 'Choose the correct concessive construction.',
      options: <String>['Despite the costs are high, we proceed.', 'Although costs are high, we may proceed.', 'Although high costs, we proceed.'],
      answer: 1,
    ),
    'C1:3': AdvancedGrammarWorkshop(
      explanationEnglish: 'Scientific reporting must separate observation from causal inference. Use suggest, appear to, cannot establish, and remains uncertain to describe what research supports without overstating a relationship.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('The particles appear to come from several sources.', 'يبدو أن الجسيمات تأتي من عدة مصادر.'),
        AdvancedGrammarExample('The association does not establish causation.', 'الارتباط لا يثبت السببية.'),
        AdvancedGrammarExample('It remains uncertain whether the factory was the main contributor.', 'لا يزال غير مؤكد إن كان المصنع المساهم الرئيسي.'),
      ],
      wrong: 'The samples prove that the factory caused every particle.',
      correct: 'The samples suggest that the factory may be one contributing source.',
      question: 'Which statement accurately qualifies the evidence?',
      options: <String>['The correlation proves a single cause.', 'The results may suggest several contributing pathways.', 'A large sample eliminates every uncertainty.'],
      answer: 1,
    ),
    'C2:3': AdvancedGrammarWorkshop(
      explanationEnglish: 'Elevated counterfactuals can omit if and invert had with the subject. Evidential modals (might have, must have, cannot have) encode different levels of certainty. Coherent testimony is not automatically conclusive evidence.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('Had the diplomat compared the records, he might have noticed the error.', 'لو قارن الدبلوماسي السجلات لربما لاحظ الخطأ.'),
        AdvancedGrammarExample('The witness may have conflated two meetings.', 'ربما خلط الشاهد بين اجتماعين.'),
        AdvancedGrammarExample('Only after the notebook surfaced did the panel revise its view.', 'لم تراجع اللجنة موقفها إلا بعد ظهور الدفتر.'),
      ],
      wrong: 'Had the witness checked, he would noticed the date.',
      correct: 'Had the witness checked, he would have noticed the date.',
      question: 'Which C2-level counterfactual is correctly formed?',
      options: <String>['Had the judges read the notes, they might have reached another conclusion.', 'Had the judges read the notes, they might reached another conclusion.', 'If had they read the notes, they would reached another conclusion.'],
      answer: 0,
    ),

    'A2:6': AdvancedGrammarWorkshop(
      explanationEnglish: "Use be going to for a plan already decided and will for a decision made now. The verb after will remains in its base form.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("I am going to leave class earlier.","سأغادر الحصة مبكرًا وفقًا لخطة."),AdvancedGrammarExample("The bus is gone, so I will call a taxi.","فاتت الحافلة، لذا سأتصل بسيارة أجرة الآن."),AdvancedGrammarExample("Is Mina going to check the timetable?","هل تنوي مينا مراجعة الجدول؟")],
      wrong: "I will to call a taxi.", correct: "I will call a taxi.",
      question: "Which sentence describes a prior plan?",
      options: <String>["I am going to leave earlier.","I going leave earlier.","I will to leaving early."], answer: 0,
    ),
    'A2:7': AdvancedGrammarWorkshop(
      explanationEnglish: "Use have or has plus the past participle for experiences when no definite past time is given. Use the past simple with yesterday or last week.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Have you ever joined an art club?","هل سبق وانضممت إلى نادٍ فني؟"),AdvancedGrammarExample("She has never visited that room.","لم تزر تلك الغرفة من قبل."),AdvancedGrammarExample("Hana met Leo on Monday.","قابلت هانا ليو يوم الاثنين.")],
      wrong: "I have never visit the club.", correct: "I have never visited the club.",
      question: "Which present-perfect experience is correct?",
      options: <String>["I has never seen it.","She has never drawn a poster.","She has never drew a poster."], answer: 1,
    ),
    'A2:8': AdvancedGrammarWorkshop(
      explanationEnglish: "Could I and Would it be possible to are polite ways to request assistance. Would you mind requires an -ing form.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Could I return this lamp, please?","هل يمكنني إرجاع هذا المصباح من فضلك؟"),AdvancedGrammarExample("Would it be possible to receive a replacement?","هل سيكون من الممكن الحصول على بديل؟"),AdvancedGrammarExample("Would you mind checking the switch?","هل تمانع فحص المفتاح؟")],
      wrong: "Would you mind to check it?", correct: "Would you mind checking it?",
      question: "Choose the polite and grammatical request.",
      options: <String>["Could I to return this?","Would you mind check it?","Could I return this, please?"], answer: 2,
    ),
    'A2:9': AdvancedGrammarWorkshop(
      explanationEnglish: "Before, after and when organize events. In future time clauses after when and as soon as, use the present simple rather than will.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Before we left, we checked the weather.","قبل أن نغادر راجعنا الطقس."),AdvancedGrammarExample("After we reached the hill, we rested.","بعد وصولنا إلى التل استرحنا."),AdvancedGrammarExample("We will stop when we find water.","سنتوقف عندما نجد ماء.")],
      wrong: "We will stop when we will reach the hill.", correct: "We will stop when we reach the hill.",
      question: "Which future time clause is correct?",
      options: <String>["I will call you when I arrive.","I will call when I will arrive.","I calling you when arrive."], answer: 0,
    ),
    'A2:10': AdvancedGrammarWorkshop(
      explanationEnglish: "Comparatives compare two people or things, while superlatives identify the highest degree in a group. Use -est for short adjectives and most for many longer adjectives.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Sara was the youngest volunteer.","كانت سارة أصغر المتطوعين."),AdvancedGrammarExample("The relay was the most exciting event.","كان التتابع أكثر الأحداث إثارة."),AdvancedGrammarExample("Our runners were faster than last year.","كان عداؤونا أسرع من العام الماضي.")],
      wrong: "This was the more exciting event of all.", correct: "This was the most exciting event of all.",
      question: "Which superlative is correct?",
      options: <String>["She is fastest than me.","This is the most exciting race.","This is the more exciting race of all."], answer: 1,
    ),
    'A2:5': AdvancedGrammarWorkshop(
      explanationEnglish: 'Some is common in positive statements and polite offers. Any is common in questions and negatives. Use many with countable nouns and much with uncountable nouns, such as rice or milk.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('How many carrots do we need?', 'كم جزرة نحتاج؟'),
        AdvancedGrammarExample('There is not much rice in the cupboard.', 'لا يوجد الكثير من الأرز في الخزانة.'),
        AdvancedGrammarExample('Would you like some soup?', 'هل ترغب في بعض الحساء؟'),
      ],
      wrong: 'How many rice do we need?',
      correct: 'How much rice do we need?',
      question: 'Choose the correct quantity question.',
      options: <String>['How many rice do you want?', 'How much rice do we need?', 'How much carrots are there?'],
      answer: 1,
    ),
    'B1:3': AdvancedGrammarWorkshop(
      explanationEnglish: 'Must expresses a strong rule or requirement. Have to often describes an obligation imposed by the situation. Should gives advice, while could suggests a possible choice. A modal is followed by the base form of the verb.',
      examples: <AdvancedGrammarExample>[
        AdvancedGrammarExample('Every bridge must carry the required weight.', 'يجب أن يتحمل كل جسر الوزن المطلوب.'),
        AdvancedGrammarExample('We have to record the failed attempt.', 'علينا تسجيل المحاولة الفاشلة.'),
        AdvancedGrammarExample('We could improve the supports.', 'يمكننا تحسين الدعامات.'),
      ],
      wrong: 'We should to test the bridge.',
      correct: 'We should test the bridge.',
      question: 'Choose the correct recommendation.',
      options: <String>['We must to revise it.', 'We should to check it.', 'We should check it.'],
      answer: 2,
    ),

    'A2:1': AdvancedGrammarWorkshop(
      explanationEnglish: "Use the past simple to tell completed events in chronological order. Regular verbs often end in -ed, while irregular verbs must be learned. Questions use Did + base verb.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The station clerk checked the receipt.","تحقق موظف المحطة من الإيصال."),AdvancedGrammarExample("Lina found the ticket in her bag.","وجدت لينا التذكرة في حقيبتها."),AdvancedGrammarExample("Did the train leave on time?","هل غادر القطار في الوقت المحدد؟")],
      wrong: "I did not found the ticket.", correct: "I did not find the ticket.",
      question: "Which question is grammatical?", options: <String>["Did Lina found her ticket?","Did Lina find her ticket?","Does Lina found her ticket?"], answer: 1,
    ),
    'A2:2': AdvancedGrammarWorkshop(
      explanationEnglish: "Use some with uncountable nouns such as flour; measure them with containers or quantities. Use a/an with a single countable item, and plural forms after numbers.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("How many loaves do we have?","كم رغيفًا لدينا؟"),AdvancedGrammarExample("We need a little sugar.","نحتاج إلى قليل من السكر."),AdvancedGrammarExample("She bought three rolls and some bread.","اشترت ثلاث قطع خبز وبعض الخبز.")],
      wrong: "I bought a flour.", correct: "I bought some flour.",
      question: "Which sentence is correct?", options: <String>["We need two breads.","We need two loaves of bread.","We need a breads."], answer: 1,
    ),
    'A2:3': AdvancedGrammarWorkshop(
      explanationEnglish: "Comparatives compare two things. Short adjectives often use -er than, while longer adjectives use more ... than. Irregular forms include better and worse.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("This apartment is larger than that one.","هذه الشقة أكبر من الأخرى."),AdvancedGrammarExample("A balcony is more useful in summer.","الشرفة أكثر فائدة في الصيف."),AdvancedGrammarExample("The older house is less expensive.","المنزل الأقدم أقل تكلفة.")],
      wrong: "This room is more cheaper.", correct: "This room is cheaper.",
      question: "Choose the best comparison.", options: <String>["The second apartment is quieter than the first.","This flat is quiet than that.","The rent is more cheap."], answer: 0,
    ),
    'A2:4': AdvancedGrammarWorkshop(
      explanationEnglish: "Should expresses advice, not a strict command. Shouldn't expresses advice against an action. After should, use the base verb without to.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("You should read the label.","ينبغي أن تقرأ الملصق."),AdvancedGrammarExample("He shouldn't ignore a serious symptom.","ينبغي ألا يتجاهل عرضًا خطيرًا."),AdvancedGrammarExample("If you feel worse, ask a professional.","إذا ساءت حالتك، فاسأل مختصًا.")],
      wrong: "You should to rest.", correct: "You should rest.",
      question: "Choose the correct advice.", options: <String>["She should drinks water.","She should drink water.","She should drinking water."], answer: 1,
    ),
    'B1:1': AdvancedGrammarWorkshop(
      explanationEnglish: "The first conditional combines a realistic future possibility (if + present simple) with a likely consequence (will + base verb). Unless means if not.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("If the sponsor agrees, we will reopen.","إذا وافقت الجهة الراعية، سنعيد الافتتاح."),AdvancedGrammarExample("Unless the budget improves, the library may close.","إن لم تتحسن الميزانية، قد تغلق المكتبة."),AdvancedGrammarExample("We will invite families if the hall is free.","سندعو العائلات إذا كانت القاعة متاحة.")],
      wrong: "If we will raise money, we save it.", correct: "If we raise money, we will save it.",
      question: "Which first conditional is correct?", options: <String>["If it rains, we will move inside.","If it will rain, we move inside.","If rains, we will move."], answer: 0,
    ),
    'B1:2': AdvancedGrammarWorkshop(
      explanationEnglish: "Use had + past participle for the earlier of two past events. The past simple marks the later event. By the time often introduces this sequence.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The concert had begun before we arrived.","كان الحفل قد بدأ قبل وصولنا."),AdvancedGrammarExample("Tessa had checked the stage by noon.","كانت تيسا قد فحصت المسرح بحلول الظهر."),AdvancedGrammarExample("They were relieved because they had found a cable.","شعروا بالارتياح لأنهم وجدوا كابلًا.")],
      wrong: "When I arrived, he had leave.", correct: "When I arrived, he had left.",
      question: "Choose a correct past perfect sentence.", options: <String>["After she had prepared, she spoke.","After she has prepared, she speak.","After she had prepare, she speaks."], answer: 0,
    ),
    'B2:1': AdvancedGrammarWorkshop(
      explanationEnglish: "Use passive voice (be + past participle) to emphasize an action or its result. Add by only when the agent matters. Combine passive claims with caution about uncertain sources.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The report was reviewed by an editor.","راجع محرر التقرير."),AdvancedGrammarExample("The figures might have been misunderstood.","ربما أسيء فهم الأرقام."),AdvancedGrammarExample("A visible correction has been published.","نُشر تصحيح واضح للجمهور.")],
      wrong: "The data were misinterpret.", correct: "The data were misinterpreted.",
      question: "Choose a correctly formed passive.", options: <String>["The article was corrected yesterday.","The article corrected was yesterday.","The article was correct yesterday by editor."], answer: 0,
    ),
    'B2:2': AdvancedGrammarWorkshop(
      explanationEnglish: "A mixed conditional connects an unreal past cause to a present result. If + past perfect, would + base verb describes how today might be different.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("If she had received mentoring, she would feel confident now.","لو حصلت على إرشاد، لشعرت بالثقة الآن."),AdvancedGrammarExample("The team might work better if managers had listened.","قد يعمل الفريق أفضل لو استمع المديرون سابقًا."),AdvancedGrammarExample("Had they consulted staff, they might understand the problem today.","لو استشاروا الموظفين، لفهموا المشكلة اليوم.")],
      wrong: "If they had trained staff, they would had better systems now.", correct: "If they had trained staff, they would have better systems now.",
      question: "Which mixed conditional is correct?", options: <String>["If we had planned ahead, we would be ready now.","If we planned yesterday, we will ready now.","If we had plan, we are ready now."], answer: 0,
    ),
    'C1:1': AdvancedGrammarWorkshop(
      explanationEnglish: "Academic claims need calibrated certainty. Use appears to, may suggest and cannot rule out to distinguish evidence from interpretation without weakening justified conclusions.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The provenance remains uncertain.","ما زال مصدر المخطوطة غير مؤكد."),AdvancedGrammarExample("These notes could indicate a second author.","قد تشير هذه الملاحظات إلى مؤلف آخر."),AdvancedGrammarExample("The data do not rule out an alternative chronology.","لا تستبعد البيانات تسلسلًا زمنيًا بديلًا.")],
      wrong: "The manuscript proves everything without doubt.", correct: "The manuscript appears to support one interpretation.",
      question: "Which sentence hedges an uncertain conclusion appropriately?", options: <String>["The evidence may indicate a later revision.","The evidence definitely proves all motives.","No other explanation is possible."], answer: 0,
    ),
    'C1:2': AdvancedGrammarWorkshop(
      explanationEnglish: "A rigorous academic synthesis distinguishes observation, hypothesis and inference. Use whereas, nevertheless and not only ... but also to present complementary or competing explanations.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("While some colonies survived, fish populations declined.","رغم بقاء بعض المستعمرات، انخفضت أعداد الأسماك."),AdvancedGrammarExample("The sensor readings may suggest greater thermal stress.","قد توحي قراءات المستشعر بإجهاد حراري أكبر."),AdvancedGrammarExample("The report combines field samples with local observations.","يجمع التقرير بين العينات الميدانية والملاحظات المحلية.")],
      wrong: "The reef recovered, so every species is safe.", correct: "Some coral survived, yet broader recovery remains uncertain.",
      question: "Which statement best distinguishes evidence from inference?", options: <String>["The observations suggest resilience but do not establish full recovery.","One surviving coral proves the whole reef is healthy.","All hypotheses have been confirmed."], answer: 0,
    ),
    'C2:1': AdvancedGrammarWorkshop(
      explanationEnglish: "Use inversion without if in elevated counterfactuals: Had + subject + participle, ... would have + participle. Modal verbs signal how strongly an inference follows from the evidence.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Had Elena ignored the ledger, she would have missed a warning.","لو تجاهلت إلينا السجل، لفاتها تحذير."),AdvancedGrammarExample("Rarely had the council faced such conflicting evidence.","نادرًا ما واجه المجلس أدلة متعارضة كهذه."),AdvancedGrammarExample("The testimony might have been mistaken for proof.","ربما اعتُبرت الشهادة خطأً دليلًا قاطعًا.")],
      wrong: "Had they known, they would investigated.", correct: "Had they known, they would have investigated.",
      question: "Choose accurate conditional inversion.", options: <String>["Had the council acted sooner, the damage might have been limited.","Had the council acted sooner, the damage might limited.","Had the council acts sooner, the damage is limited."], answer: 0,
    ),
    'C2:2': AdvancedGrammarWorkshop(
      explanationEnglish: "At C2, counterfactual syntax can expose interpretive costs. Had ... been ... and Were ... to ... frame unreal alternatives; use careful verbs such as imply and suggest, not prove without evidence.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Had she removed the ambiguity, the meaning would have narrowed.","لو أزالت اللبس، لضاق المعنى."),AdvancedGrammarExample("Were the translator to add a note, readers might understand more.","لو أضاف المترجم ملاحظة، فقد يفهم القراء أكثر."),AdvancedGrammarExample("Not until the revisions emerged did the editor reconsider the choice.","لم يُعِد المحرر النظر في الاختيار إلا بعد ظهور التنقيحات.")],
      wrong: "Had the translator simplified the idiom, the nuance will vanish.", correct: "Had the translator simplified the idiom, the nuance would have vanished.",
      question: "Choose the most precise alternative.", options: <String>["Were the phrase translated literally, its rhythm might suffer.","Were the phrase translate literally, its rhythm suffered.","If the phrase translated, rhythm surely disappears."], answer: 0,
    ),
    'B1:4': AdvancedGrammarWorkshop(
      explanationEnglish: "Use have/has + past participle to describe life experience without a finished time expression. When the time is fixed (yesterday or last Monday), use the past simple.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("I have never introduced a radio programme.", "لم يسبق لي تقديم برنامج إذاعي."), AdvancedGrammarExample("Huda read the announcement yesterday.", "قرأت هدى الإعلان أمس."), AdvancedGrammarExample("Have you ever used studio headphones?", "هل استخدمت سماعات الاستوديو من قبل؟")],
      wrong: "I have visited the studio last Tuesday.", correct: "I visited the studio last Tuesday.",
      question: "Choose the correct present-perfect sentence.", options: <String>["Have you ever used a microphone?", "Did you ever used a microphone?", "I have used a microphone yesterday."], answer: 0,
    ),
    'B1:5': AdvancedGrammarWorkshop(
      explanationEnglish: "A defining relative clause specifies a particular person or thing. Use who for people and that or which for things, without extra commas around an essential clause.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The resident who signed the petition lives next door.", "يسكن الجار الذي وقّع العريضة في المنزل المجاور."), AdvancedGrammarExample("The crossing that the council inspected is near the school.", "يقع المعبر الذي فحصه المجلس قرب المدرسة."), AdvancedGrammarExample("The signs which warn drivers must be clear.", "يجب أن تكون العلامات التي تحذر السائقين واضحة.")],
      wrong: "The school who needs a crossing is nearby.", correct: "The school that needs a crossing is nearby.",
      question: "Choose the correct defining relative clause.", options: <String>["The parents which met the officer were worried.", "The road that needs repairs is busy.", "The sign who fell was dangerous."], answer: 1,
    ),
    'B1:6': AdvancedGrammarWorkshop(
      explanationEnglish: "Use if + past simple followed by would + base verb for imagined present or future situations. Were is especially common in hypothetical clauses with any subject.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("If I were in charge, I would train the helpers.", "لو كنت مسؤولة لدربت المساعدين."), AdvancedGrammarExample("Samira would wait if the puppy were nervous.", "ستنتظر سميرة إذا كان الجرو متوترًا."), AdvancedGrammarExample("If we had more space, we could rescue more pets.", "لو كانت لدينا مساحة أكبر لتمكنا من إنقاذ حيوانات أكثر.")],
      wrong: "If the puppy were afraid, I will wait.", correct: "If the puppy were afraid, I would wait.",
      question: "Which sentence shows an imagined situation correctly?", options: <String>["If I would see a frightened puppy, I ask a worker.", "If the puppy were afraid, I would speak softly.", "If the puppy is afraid yesterday, I waited."], answer: 1,
    ),
    'B1:7': AdvancedGrammarWorkshop(
      explanationEnglish:"Use decide and plan with to + base verb. Use enjoy with -ing and suggest with -ing when recommending activities.",
      examples:<AdvancedGrammarExample>[AdvancedGrammarExample("Farah planned to open a small cart.","خططت فرح لافتتاح عربة صغيرة."),AdvancedGrammarExample("She enjoyed interviewing customers.","استمتعت بمقابلة الزبائن."),AdvancedGrammarExample("Her mentor suggested testing the menu first.","اقترح المرشد تجربة القائمة أولًا.")],
      wrong:"She decided selling healthy food.", correct:"She decided to sell healthy food.",
      question:"Which sentence uses the verb pattern correctly?", options:<String>["She enjoys to meet customers.","She decided to test the menu.","She planned opening a shop."],answer:1,
    ),
    'B1:8': AdvancedGrammarWorkshop(
      explanationEnglish:"Must and have to express obligation, while should expresses advice. Mustn't indicates prohibition; don't have to means there is no obligation.",
      examples:<AdvancedGrammarExample>[AdvancedGrammarExample("Runners must follow the marked course.","يجب على العدائين اتباع المسار المحدد."),AdvancedGrammarExample("Participants should bring their own water.","يُنصح المشاركون بإحضار مياههم."),AdvancedGrammarExample("Visitors do not have to run.","الزوار ليسوا ملزمين بالجري.")],
      wrong:"You must to wear your bib number.", correct:"You must wear your bib number.",
      question:"Choose the correct sentence about race rules.", options:<String>["Runners must to follow the signs.","Participants should to bring water.","Volunteers have to arrive early."],answer:2,
    ),
    'B1:9': AdvancedGrammarWorkshop(
      explanationEnglish:"A defining relative clause identifies a person or thing. Use who for people and which or that for things.",
      examples:<AdvancedGrammarExample>[AdvancedGrammarExample("The neighbor who helped was kind.","كان الجار الذي ساعد لطيفًا."),AdvancedGrammarExample("The plants that need shade grow here.","النباتات التي تحتاج ظلًا تنمو هنا."),AdvancedGrammarExample("The beds which face south get more sun.","تتلقى الأحواض المواجهة للجنوب ضوءًا أكثر.")],
      wrong:"The gardener which helped us was experienced.", correct:"The gardener who helped us was experienced.",
      question:"Choose the correct relative clause.", options:<String>["The resident which lives here watered the plants.","The gardener who works here knows the soil.","The flowers who need water are near the gate."],answer:1,
    ),
    'B1:10': AdvancedGrammarWorkshop(
      explanationEnglish:"Although precedes a full clause, despite precedes a noun or -ing phrase, and however introduces a contrasting point in another clause or sentence.",
      examples:<AdvancedGrammarExample>[AdvancedGrammarExample("Although she was unsure, she applied.","رغم أنها كانت مترددة، قدمت طلبها."),AdvancedGrammarExample("Despite the distance, she accepted the offer.","رغم المسافة، قبلت العرض."),AdvancedGrammarExample("The fees were high; however, the course was valuable.","كانت الرسوم مرتفعة، ومع ذلك كان الكورس مفيدًا.")],
      wrong:"Despite she had a scholarship, she hesitated.", correct:"Although she had a scholarship, she hesitated.",
      question:"Which sentence uses contrast correctly?", options:<String>["Despite the campus was distant, she enrolled.","Although the campus was distant, she enrolled.","However the campus was distant she enrolled."],answer:1,
    ),
  };
  static AdvancedGrammarWorkshop? forLesson(String level, int number,
      {int unitNumber = 1}) {
    if (unitNumber == 3 && level == 'A2') return _unit3A2[number];
    if (unitNumber == 2 && level == 'A2') return _unit2A2[number];
    if (unitNumber != 1) return null;
    return _workshops['$level:$number'];
  }
  static int get count =>
      _workshops.length + _unit2A2.length + _unit3A2.length;
}

