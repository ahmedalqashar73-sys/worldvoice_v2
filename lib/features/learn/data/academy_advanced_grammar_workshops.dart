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
  static const _workshops = <String, AdvancedGrammarWorkshop>{
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

    'A2.2.1': AdvancedGrammarWorkshop(
      explanationEnglish: "Too goes before an adjective to show excess, as in too small. Enough usually follows an adjective (large enough), or comes before a noun (enough space).",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The room is big enough for a desk.","الغرفة كبيرة بما يكفي لوضع مكتب."),AdvancedGrammarExample("This shelf is too high to reach.","هذا الرف مرتفع جدًا للوصول إليه."),AdvancedGrammarExample("We have enough space for our books.","لدينا مساحة كافية لكتبنا.")],
      wrong: "The room is enough big.", correct: "The room is big enough.",
      question: "Which expression of degree is grammatical?", options: <String>["We have enough space.","The room is enough large.","The shelf is high enough too."],
      answer: 0,
    ),
    'A2.2.2': AdvancedGrammarWorkshop(
      explanationEnglish: "Use for to express a duration and since to mark the starting point of a situation that continues. Present perfect combines have or has with a past participle.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("I have felt tired for three days.","أشعر بالتعب منذ ثلاثة أيام."),AdvancedGrammarExample("She has worked here since Monday.","تعمل هنا منذ يوم الاثنين."),AdvancedGrammarExample("How long have you had these symptoms?","منذ متى تعاني من هذه الأعراض؟")],
      wrong: "I have felt tired since three days.", correct: "I have felt tired for three days.",
      question: "Choose the correct time expression.", options: <String>["I have waited since two hours.","I have waited for two hours.","I have wait for two hours."],
      answer: 1,
    ),
    'A2.2.3': AdvancedGrammarWorkshop(
      explanationEnglish: "Sequence instructions with first, next, then and finally. The imperative uses the base verb without to and often has an understood you as its subject.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("First, wash the vegetables.","أولًا اغسل الخضروات."),AdvancedGrammarExample("Then add the tomatoes.","ثم أضف الطماطم."),AdvancedGrammarExample("Finally, serve the stew.","أخيرًا قدم اليخنة.")],
      wrong: "First, to chop the vegetables.", correct: "First, chop the vegetables.",
      question: "Choose a correct imperative instruction.", options: <String>["Next to add the spices.","Next, add the spices.","Next, adding the spices."],
      answer: 1,
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
  };
  /// Use a distinct grammar workshop for every unit and lesson.
  /// Legacy unit-one keys stay unchanged for existing learners.
  static AdvancedGrammarWorkshop? forLesson(
      String level, int number, {int unitNumber = 1}) =>
      _workshops['$level.$unitNumber.$number'] ??
      (unitNumber == 1 ? _workshops['$level:$number'] : null);
  static int get count => _workshops.length;
}
