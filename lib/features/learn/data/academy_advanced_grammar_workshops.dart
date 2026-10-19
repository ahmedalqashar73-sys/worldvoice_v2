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
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Use the past simple to tell completed events in chronological order. Regular verbs often end in -ed, while irregular verbs must be learned. Questions use Did + base verb.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The station clerk checked the receipt.","تحقق موظف المحطة من الإيصال."),AdvancedGrammarExample("Lina found the ticket in her bag.","وجدت لينا التذكرة في حقيبتها."),AdvancedGrammarExample("Did the train leave on time?","هل غادر القطار في الوقت المحدد؟")],
      wrong: "I did not found the ticket.", correct: "I did not find the ticket.",
      question: "Which question is grammatical?", options: <String>["Did Lina found her ticket?","Did Lina find her ticket?","Does Lina found her ticket?"], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Use some with uncountable nouns such as flour; measure them with containers or quantities. Use a/an with a single countable item, and plural forms after numbers.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("How many loaves do we have?","كم رغيفًا لدينا؟"),AdvancedGrammarExample("We need a little sugar.","نحتاج إلى قليل من السكر."),AdvancedGrammarExample("She bought three rolls and some bread.","اشترت ثلاث قطع خبز وبعض الخبز.")],
      wrong: "I bought a flour.", correct: "I bought some flour.",
      question: "Which sentence is correct?", options: <String>["We need two breads.","We need two loaves of bread.","We need a breads."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Comparatives compare two things. Short adjectives often use -er than, while longer adjectives use more ... than. Irregular forms include better and worse.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("This apartment is larger than that one.","هذه الشقة أكبر من الأخرى."),AdvancedGrammarExample("A balcony is more useful in summer.","الشرفة أكثر فائدة في الصيف."),AdvancedGrammarExample("The older house is less expensive.","المنزل الأقدم أقل تكلفة.")],
      wrong: "This room is more cheaper.", correct: "This room is cheaper.",
      question: "Choose the best comparison.", options: <String>["The second apartment is quieter than the first.","This flat is quiet than that.","The rent is more cheap."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Should expresses advice, not a strict command. Shouldn't expresses advice against an action. After should, use the base verb without to.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("You should read the label.","ينبغي أن تقرأ الملصق."),AdvancedGrammarExample("He shouldn't ignore a serious symptom.","ينبغي ألا يتجاهل عرضًا خطيرًا."),AdvancedGrammarExample("If you feel worse, ask a professional.","إذا ساءت حالتك، فاسأل مختصًا.")],
      wrong: "You should to rest.", correct: "You should rest.",
      question: "Choose the correct advice.", options: <String>["She should drinks water.","She should drink water.","She should drinking water."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "The first conditional combines a realistic future possibility (if + present simple) with a likely consequence (will + base verb). Unless means if not.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("If the sponsor agrees, we will reopen.","إذا وافقت الجهة الراعية، سنعيد الافتتاح."),AdvancedGrammarExample("Unless the budget improves, the library may close.","إن لم تتحسن الميزانية، قد تغلق المكتبة."),AdvancedGrammarExample("We will invite families if the hall is free.","سندعو العائلات إذا كانت القاعة متاحة.")],
      wrong: "If we will raise money, we save it.", correct: "If we raise money, we will save it.",
      question: "Which first conditional is correct?", options: <String>["If it rains, we will move inside.","If it will rain, we move inside.","If rains, we will move."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Use had + past participle for the earlier of two past events. The past simple marks the later event. By the time often introduces this sequence.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The concert had begun before we arrived.","كان الحفل قد بدأ قبل وصولنا."),AdvancedGrammarExample("Tessa had checked the stage by noon.","كانت تيسا قد فحصت المسرح بحلول الظهر."),AdvancedGrammarExample("They were relieved because they had found a cable.","شعروا بالارتياح لأنهم وجدوا كابلًا.")],
      wrong: "When I arrived, he had leave.", correct: "When I arrived, he had left.",
      question: "Choose a correct past perfect sentence.", options: <String>["After she had prepared, she spoke.","After she has prepared, she speak.","After she had prepare, she speaks."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Use passive voice (be + past participle) to emphasize an action or its result. Add by only when the agent matters. Combine passive claims with caution about uncertain sources.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The report was reviewed by an editor.","راجع محرر التقرير."),AdvancedGrammarExample("The figures might have been misunderstood.","ربما أسيء فهم الأرقام."),AdvancedGrammarExample("A visible correction has been published.","نُشر تصحيح واضح للجمهور.")],
      wrong: "The data were misinterpret.", correct: "The data were misinterpreted.",
      question: "Choose a correctly formed passive.", options: <String>["The article was corrected yesterday.","The article corrected was yesterday.","The article was correct yesterday by editor."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "A mixed conditional connects an unreal past cause to a present result. If + past perfect, would + base verb describes how today might be different.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("If she had received mentoring, she would feel confident now.","لو حصلت على إرشاد، لشعرت بالثقة الآن."),AdvancedGrammarExample("The team might work better if managers had listened.","قد يعمل الفريق أفضل لو استمع المديرون سابقًا."),AdvancedGrammarExample("Had they consulted staff, they might understand the problem today.","لو استشاروا الموظفين، لفهموا المشكلة اليوم.")],
      wrong: "If they had trained staff, they would had better systems now.", correct: "If they had trained staff, they would have better systems now.",
      question: "Which mixed conditional is correct?", options: <String>["If we had planned ahead, we would be ready now.","If we planned yesterday, we will ready now.","If we had plan, we are ready now."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Academic claims need calibrated certainty. Use appears to, may suggest and cannot rule out to distinguish evidence from interpretation without weakening justified conclusions.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("The provenance remains uncertain.","ما زال مصدر المخطوطة غير مؤكد."),AdvancedGrammarExample("These notes could indicate a second author.","قد تشير هذه الملاحظات إلى مؤلف آخر."),AdvancedGrammarExample("The data do not rule out an alternative chronology.","لا تستبعد البيانات تسلسلًا زمنيًا بديلًا.")],
      wrong: "The manuscript proves everything without doubt.", correct: "The manuscript appears to support one interpretation.",
      question: "Which sentence hedges an uncertain conclusion appropriately?", options: <String>["The evidence may indicate a later revision.","The evidence definitely proves all motives.","No other explanation is possible."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "A rigorous academic synthesis distinguishes observation, hypothesis and inference. Use whereas, nevertheless and not only ... but also to present complementary or competing explanations.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("While some colonies survived, fish populations declined.","رغم بقاء بعض المستعمرات، انخفضت أعداد الأسماك."),AdvancedGrammarExample("The sensor readings may suggest greater thermal stress.","قد توحي قراءات المستشعر بإجهاد حراري أكبر."),AdvancedGrammarExample("The report combines field samples with local observations.","يجمع التقرير بين العينات الميدانية والملاحظات المحلية.")],
      wrong: "The reef recovered, so every species is safe.", correct: "Some coral survived, yet broader recovery remains uncertain.",
      question: "Which statement best distinguishes evidence from inference?", options: <String>["The observations suggest resilience but do not establish full recovery.","One surviving coral proves the whole reef is healthy.","All hypotheses have been confirmed."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "Use inversion without if in elevated counterfactuals: Had + subject + participle, ... would have + participle. Modal verbs signal how strongly an inference follows from the evidence.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Had Elena ignored the ledger, she would have missed a warning.","لو تجاهلت إلينا السجل، لفاتها تحذير."),AdvancedGrammarExample("Rarely had the council faced such conflicting evidence.","نادرًا ما واجه المجلس أدلة متعارضة كهذه."),AdvancedGrammarExample("The testimony might have been mistaken for proof.","ربما اعتُبرت الشهادة خطأً دليلًا قاطعًا.")],
      wrong: "Had they known, they would investigated.", correct: "Had they known, they would have investigated.",
      question: "Choose accurate conditional inversion.", options: <String>["Had the council acted sooner, the damage might have been limited.","Had the council acted sooner, the damage might limited.","Had the council acts sooner, the damage is limited."], answer: $answer,
    ),
    '$lv:$n': AdvancedGrammarWorkshop(
      explanationEnglish: "At C2, counterfactual syntax can expose interpretive costs. Had ... been ... and Were ... to ... frame unreal alternatives; use careful verbs such as imply and suggest, not prove without evidence.",
      examples: <AdvancedGrammarExample>[AdvancedGrammarExample("Had she removed the ambiguity, the meaning would have narrowed.","لو أزالت اللبس، لضاق المعنى."),AdvancedGrammarExample("Were the translator to add a note, readers might understand more.","لو أضاف المترجم ملاحظة، فقد يفهم القراء أكثر."),AdvancedGrammarExample("Not until the revisions emerged did the editor reconsider the choice.","لم يُعِد المحرر النظر في الاختيار إلا بعد ظهور التنقيحات.")],
      wrong: "Had the translator simplified the idiom, the nuance will vanish.", correct: "Had the translator simplified the idiom, the nuance would have vanished.",
      question: "Choose the most precise alternative.", options: <String>["Were the phrase translated literally, its rhythm might suffer.","Were the phrase translate literally, its rhythm suffered.","If the phrase translated, rhythm surely disappears."], answer: $answer,
    ),
  };
  static AdvancedGrammarWorkshop? forLesson(String level, int number) =>
      _workshops['$level:$number'];
  static int get count => _workshops.length;
}
