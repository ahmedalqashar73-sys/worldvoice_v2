part of 'academy_english_advanced_models.dart';

/// Original two-speaker guided dialogue and real IPA cues for every
/// currently published advanced English lesson. Audio plays English text.
class EnglishAdvancedDialogue {
  const EnglishAdvancedDialogue({
    required this.lines, required this.tip,
    required this.tipArabic, required this.pronunciation,
  });
  final List<String> lines;
  final String tip;
  final String tipArabic;
  final List<String> pronunciation;
}

abstract final class EnglishAdvancedDialogues {
  static const _dialogues = <String, EnglishAdvancedDialogue>{
    'a2.1.1': EnglishAdvancedDialogue(
      lines: <String>["Lina: Excuse me, which platform is the train leaving from?", "Clerk: It leaves from platform four in ten minutes.", "Lina: I cannot find my ticket. Can you check my booking?", "Clerk: Of course. Please show me the receipt.", "Lina: Thank you! I found it in my suitcase."],
      tip: "Practise polite questions with 'Excuse me' and 'Can you ...?'.", tipArabic: "تدرّب على السؤال المهذب باستخدام Excuse me وCan you، مع تقليد نبرة السؤال.",
      pronunciation: <String>["platform /ˈplætfɔːrm/", "receipt /rɪˈsiːt/", "ticket /ˈtɪkɪt/"],
    ),
    'a2.1.2': EnglishAdvancedDialogue(
      lines: <String>["Customer: Good morning. Do you have fresh bread?", "Nora: Yes. Would you like one loaf or two?", "Customer: One loaf, please. How much is it?", "Nora: Three pounds. Would you also like a sweet roll?", "Customer: Yes, thank you. Here is the money."],
      tip: "Use 'How much' for prices and 'How many' for countable items.", tipArabic: "استخدم How much للسعر وHow many للعدد، واستمع إلى الكلمات التي تربط الجمل.",
      pronunciation: <String>["flour /ˈflaʊər/", "dough /doʊ/", "bakery /ˈbeɪkəri/"],
    ),
    'b1.1.1': EnglishAdvancedDialogue(
      lines: <String>["Nadia: If we organize a concert, will people support the library?", "Volunteer: I think they will, especially if we invite local schools.", "Nadia: We should prepare a realistic budget first.", "Volunteer: Agreed. I can contact a sponsor this afternoon.", "Nadia: Great. Let's review the plan before the deadline."],
      tip: "Stress the result in first-conditionals: 'If we organize..., people WILL support...'.", tipArabic: "لاحظ نبرة تأكيد النتيجة في الشرط الأول واستمع إلى إيقاع الجملة الشرطية.",
      pronunciation: <String>["volunteer /ˌvɑːlənˈtɪr/", "proposal /prəˈpoʊzəl/", "budget /ˈbʌdʒɪt/"],
    ),
    'b1.1.2': EnglishAdvancedDialogue(
      lines: <String>["Tessa: The microphone has stopped working. What should we do?", "Engineer: I have checked the cables, but we need a replacement.", "Tessa: Could we arrange a short acoustic performance?", "Musician: I can perform without electronic equipment.", "Tessa: Excellent. Please tell the audience about the change."],
      tip: "Listen for weak forms in connected speech, especially 'could we' and 'should we'.", tipArabic: "تدرّب على النطق المتصل في could we وshould we وتجنب فصل كل كلمة بوقف طويل.",
      pronunciation: <String>["rehearsal /rɪˈhɝːsəl/", "audience /ˈɔːdiəns/", "festival /ˈfɛstəvəl/"],
    ),
    'b2.1.1': EnglishAdvancedDialogue(
      lines: <String>["Editor: The article implies that results collapsed nationwide.", "Journalist: Yet the sample includes different age groups in different years.", "Editor: Are you suggesting that our interpretation is misleading?", "Journalist: Potentially. We need an independent analysis before publishing a conclusion.", "Editor: Then prepare a transparent correction with the relevant context."],
      tip: "Distinguish emphasis on 'implies', 'potentially', and 'misleading' while making a qualified claim.", tipArabic: "ركّز على مواضع التشديد في الكلمات التي تعبّر عن احتمال أو تحفظ بدل الجزم.",
      pronunciation: <String>["misleading /ˌmɪsˈliːdɪŋ/", "credibility /ˌkrɛdəˈbɪləti/", "verification /ˌvɛrəfɪˈkeɪʃən/"],
    ),
    'b2.1.2': EnglishAdvancedDialogue(
      lines: <String>["Manager: Staff surveys suggest that flexible schedules improve morale.", "Researcher: That's true for experienced employees, but not necessarily for new recruits.", "Manager: Would mandatory office days address that problem?", "Researcher: They might, provided that mentoring is structured and equitable.", "Manager: Let's pilot the change before making the policy permanent."],
      tip: "Practise contrastive stress on 'experienced' versus 'new' and cautious 'might'.", tipArabic: "عند عرض رأيين مختلفين أظهر التباين في التشديد بين experienced وnew.",
      pronunciation: <String>["autonomy /ɔːˈtɑːnəmi/", "mentoring /ˈmɛntɔːrɪŋ/", "productivity /ˌproʊdʌkˈtɪvəti/"],
    ),
    'c1.1.1': EnglishAdvancedDialogue(
      lines: <String>["Curator: Immediate exhibition would make the manuscript accessible to the public.", "Conservator: But accessibility must be balanced against irreversible deterioration.", "Curator: Could digital copies meet the public interest temporarily?", "Conservator: They might, provided we disclose the limits of our interpretation.", "Curator: Then the provisional catalogue should explicitly acknowledge uncertainty."],
      tip: "Practise thought-grouping in complex sentences, pausing at 'provided' and 'against'.", tipArabic: "قسّم الجمل المعقدة إلى مجموعات معنوية قصيرة، واحفظ الوقف عند الروابط دون قطع الفكرة.",
      pronunciation: <String>["provenance /ˈprɑːvənəns/", "authenticity /ˌɔːθɛnˈtɪsəti/", "provisional /prəˈvɪʒənəl/"],
    ),
    'c1.1.2': EnglishAdvancedDialogue(
      lines: <String>["Oceanographer: Some coral colonies survived the recent heatwave.", "Ecologist: Nevertheless, that alone doesn't establish ecosystem recovery.", "Oceanographer: The evidence may indicate localized resilience.", "Ecologist: But the monitoring period is too short for a definitive claim.", "Oceanographer: Then we should present the findings as provisional."],
      tip: "Practise the rhythmic contrast between 'Nevertheless' and the claim that follows.", tipArabic: "تدرّب على نبرة Nevertheless بوصفها انتقالًا حجاجيًا مع المحافظة على الإيقاع الطبيعي.",
      pronunciation: <String>["biodiversity /ˌbaɪoʊdaɪˈvɝːsəti/", "resilience /rɪˈzɪliəns/", "ecosystem /ˈiːkoʊsɪstəm/"],
    ),
    'c2.1.1': EnglishAdvancedDialogue(
      lines: <String>["Historian: The charts present conflicting accounts of the harbor's alteration.", "Commissioner: Surely the sediment record can settle the matter conclusively?", "Historian: Not without conflating geological evidence with human intention.", "Commissioner: So the documentation establishes prior awareness, not deliberate sabotage?", "Historian: Precisely. Any broader verdict would exceed the evidentiary threshold."],
      tip: "Shape intonation to distinguish a rhetorical challenge from qualified agreement.", tipArabic: "استخدم النبرة لتمييز الاستفهام الاعتراضي عن الموافقة المقيدة، وراقب قوة التشديد في evidentiary.",
      pronunciation: <String>["corroboration /kəˌrɑːbəˈreɪʃən/", "chronology /krəˈnɑːlədʒi/", "ambiguity /ˌæmbɪˈɡjuːəti/"],
    ),
    'c2.1.2': EnglishAdvancedDialogue(
      lines: <String>["Editor: Your rendering preserves the idiom's ambiguity but may unsettle readers.", "Translator: That discomfort is arguably integral to the narrator's voice.", "Editor: Couldn't a more transparent paraphrase convey the same intention?", "Translator: It might clarify the plot while inadvertently foreclosing competing readings.", "Editor: Then perhaps a restrained annotation offers the least intrusive compromise."],
      tip: "Practise subtle pragmatic emphasis on 'arguably', 'might', and 'inadvertently'.", tipArabic: "تدرّب على النبرة التي تميز التحفظ الدقيق عن الرفض القطعي، خصوصًا arguably وmight.",
      pronunciation: <String>["polysemy /pəˈlɪsəmi/", "paraphrase /ˈpærəfreɪz/", "hermeneutics /ˌhɝːməˈnuːtɪks/"],
    ),
  };

  static EnglishAdvancedDialogue forLesson(EnglishAdvancedLesson lesson) {
    final key = '${lesson.level.toLowerCase()}.${lesson.unitNumber}.${lesson.number}';
    final dialogue = _dialogues[key];
    if (dialogue == null) {
      throw StateError('No authored dialogue for $key');
    }
    return dialogue;
  }
}
