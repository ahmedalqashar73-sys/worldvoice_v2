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
    'a2.2.8': EnglishAdvancedDialogue(
      lines: <String>[
        'Lina: I lost the phone that I used on the bus.',
        'Friend: Did you ask the driver who was on duty?',
        'Lina: Not yet. Can we visit the lost property office?',
        'Friend: Yes, we can describe the screen and ringtone.',
        'Lina: Thank you. I hope someone has found it.',
      ],
      tip: 'Link who and that to the words they describe, with natural stress.',
      tipArabic: 'اربط who وthat بالأسماء التي تصفها دون وقفة طويلة.',
      pronunciation: <String>[
        'notification /ˌnoʊtɪfɪˈkeɪʃən/', 'ringtone /ˈrɪŋtoʊn/', 'contact /ˈkɑːntækt/',
      ],
    ),
    'a2.2.9': EnglishAdvancedDialogue(
      lines: <String>[
        'Tariq: I am going to buy a gift for my sister.',
        'Seller: Would you like her initials on the mug?',
        'Tariq: That sounds great. How long will it take?',
        'Seller: About twenty minutes. I will wrap it for you.',
        'Tariq: Perfect! I am going to give it to her tonight.',
      ],
      tip: 'Contrast an existing plan with a spontaneous offer using will.',
      tipArabic: 'فرق بين خطة going to والعرض اللحظي باستخدام will.',
      pronunciation: <String>[
        'engraved /ɪnˈɡreɪvd/', 'ceramic /səˈræmɪk/', 'initials /ɪˈnɪʃəlz/',
      ],
    ),
    'a2.2.10': EnglishAdvancedDialogue(
      lines: <String>[
        'Amal: Did you use to visit the beach as a child?',
        'Cousin: Yes, we used to build sandcastles every summer.',
        'Amal: I did not use to enjoy swimming in cold water.',
        'Cousin: Let us walk to the lighthouse instead.',
        'Amal: Good idea. We can watch the tide from there.',
      ],
      tip: 'Practise the smooth sound of used to in affirmative sentences.',
      tipArabic: 'تدرّب على used to في الإثبات وuse to بعد did.',
      pronunciation: <String>[
        'lighthouse /ˈlaɪthaʊs/', 'seashell /ˈsiːʃel/', 'coastline /ˈkoʊstlaɪn/',
      ],
    ),

    'a2.2.4': EnglishAdvancedDialogue(
      lines: <String>[
        'Yusuf: Can you check my bicycle? The front tire is flat.',
        'Mechanic: I have just found a hole near the valve.',
        'Yusuf: Have you checked the chain yet?',
        'Mechanic: Yes, I have already tightened it.',
        'Yusuf: Great! I will test the brakes before riding.',
      ],
      tip: 'Stress just and already when explaining what has been repaired.',
      tipArabic: 'شدّد على just وalready لتوضيح زمن إكمال التصليح.',
      pronunciation: <String>[
        'mechanic /məˈkænɪk/', 'bicycle /ˈbaɪsɪkəl/', 'valve /vælv/',
      ],
    ),
    'a2.2.5': EnglishAdvancedDialogue(
      lines: <String>[
        'Layla: Do I have to complete this adoption form today?',
        'Worker: Yes, but you do not have to take the kitten home today.',
        'Layla: Must I buy special food?',
        'Worker: Please ask the vet about the best choice.',
        'Layla: Thank you. I will prepare a quiet place first.',
      ],
      tip: 'Contrast have to with do not have to using clear pauses.',
      tipArabic: 'لاحظ الفرق بين الإلزام وعدم الضرورة في have to وdon’t have to.',
      pronunciation: <String>[
        'adoption /əˈdɑːpʃən/', 'kitten /ˈkɪtən/', 'veterinary /ˈvɛtərɪnɛri/',
      ],
    ),
    'a2.2.6': EnglishAdvancedDialogue(
      lines: <String>[
        'Host: Would you like some tea?',
        'Hana: Yes, please. That would be lovely.',
        'Host: Would you like to try the homemade biscuits?',
        'Hana: I would love to. Shall I help with the cups?',
        'Host: Thank you, but please relax and enjoy the visit.',
      ],
      tip: 'Keep invitations and polite offers soft and friendly.',
      tipArabic: 'استخدم نبرة هادئة ومهذبة عند تقديم الدعوات والعروض.',
      pronunciation: <String>[
        'hospitality /ˌhɑːspɪˈtæləti/', 'pastries /ˈpeɪstriz/', 'invitation /ˌɪnvɪˈteɪʃən/',
      ],
    ),
    'a2.2.7': EnglishAdvancedDialogue(
      lines: <String>[
        'Ken: How long have you practised speaking English?',
        'Fatima: I have studied for about two years.',
        'Ken: Have you worked with a partner since January?',
        'Fatima: Yes. We have met every Wednesday.',
        'Ken: Great! Let us practise a short role-play today.',
      ],
      tip: 'Give for and since clear stress to mark duration and starting point.',
      tipArabic: 'ميّز بين مدة التعلم ونقطة البداية باستخدام for وsince.',
      pronunciation: <String>[
        'exchange /ɪksˈtʃeɪndʒ/', 'fluently /ˈfluːəntli/', 'feedback /ˈfiːdbæk/',
      ],
    ),

    'a2.2.1': EnglishAdvancedDialogue(
      lines: <String>[
        'Salma: Do you think this desk is too large for the bedroom?',
        'Nadia: No, it is small enough to fit beside the window.',
        'Salma: Is the blue rug more expensive than the green one?',
        'Nadia: Yes, but the green rug is softer and easier to clean.',
        'Salma: Great! Then I have enough money for a reading lamp.',
      ],
      tip: 'Use a clear stress on brighter, enough, and more expensive.',
      tipArabic: 'تدرّب على نبر المقارنة والتشديد على brighter وenough.',
      pronunciation: <String>[
        'wardrobe /ˈwɔːr.droʊb/', 'mirror /ˈmɪr.ər/', 'comfortable /ˈkʌmf.tə.bəl/',
      ],
    ),
    'a2.2.2': EnglishAdvancedDialogue(
      lines: <String>[
        'Omar: I feel dizzy. Should I go to work today?',
        'Nurse: You should rest and drink enough water.',
        'Omar: Do I have to take the medicine after food?',
        'Nurse: Please follow the instructions on the label.',
        'Omar: Thank you. I will call again if I feel worse.',
      ],
      tip: 'Practise polite requests with should and have to.',
      tipArabic: 'لاحظ النبرة المهذبة عند طلب النصيحة باستخدام should.',
      pronunciation: <String>[
        'clinic /ˈklɪn.ɪk/', 'infection /ɪnˈfek.ʃən/', 'medicine /ˈmed.ɪ.sən/',
      ],
    ),
    'a2.2.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Mira: Can you help me make the family dish?',
        'Sam: Sure! What should I do first?',
        'Mira: First, wash the vegetables. Then, chop the onions.',
        'Sam: Should I add the broth now?',
        'Mira: Yes. Finally, taste it before adding any salt.',
      ],
      tip: 'Mark each step with first, then, and finally.',
      tipArabic: 'اجعل صوتك واضحًا عند ترتيب الخطوات: first، then، finally.',
      pronunciation: <String>[
        'broth /brɔːθ/', 'vegetables /ˈvedʒ.tə.bəlz/', 'onions /ˈʌn.jənz/',
      ],
    ),

    'b2.1.4': EnglishAdvancedDialogue(
      lines: <String>[
        'Amira: Could we donate every lunch that students do not eat?',
        'Manager: Not all of them. Food must meet storage and temperature requirements.',
        'Amira: Should we give everyone a smaller serving?',
        'Manager: Offer a choice. Some pupils need a larger meal.',
        'Amira: Then we should measure the results before expanding the scheme.',
      ],
      tip: 'Use strong stress on must for safety rules and softer intonation with should for advice.',
      tipArabic: 'استخدم تشديدًا واضحًا على must للتعليمات الملزمة، ونبرة ألطف مع should للنصيحة.',
      pronunciation: <String>[
        'edible /ˈɛdəbəl/',
        'surplus /ˈsɝːpləs/',
        'hygiene /ˈhaɪdʒiːn/',
      ],
    ),

    'b2.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Tenant: Will the solar project actually reduce our bills?',
        'Engineer: It could, although the savings will vary by season.',
        'Tenant: Who pays for battery storage and future repairs?',
        'Engineer: The proposal includes a maintenance reserve and clear billing rules.',
        'Tenant: Then we should test a smaller installation before expanding.',
      ],
      tip: 'Contrast realistic forecasts with guarantees and stress although, could and provided that.',
      tipArabic: 'استخدم نبرة تحفظ مع could وalthough عند الحديث عن التوقعات، ولا تحول الاحتمال إلى ضمان.',
      pronunciation: <String>[
        'photovoltaic /ˌfoʊtoʊvɑːlˈteɪɪk/',
        'warranty /ˈwɔːrənti/',
        'efficiency /ɪˈfɪʃənsi/',
      ],
    ),
    'c1.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Official: Does the evidence prove that the factory polluted the river?',
        'Chemist: No. Similar particles were also found upstream.',
        'Official: Could the rainfall explain the increase in concentration?',
        'Chemist: It may contribute, but correlation is not proof of causation.',
        'Official: What should we do while the source remains uncertain?',
      ],
      tip: 'Practise precise scientific hedging: may, suggest, and cannot establish.',
      tipArabic: 'تدرّب على لغة البحث الدقيقة والتمييز بين suggest وprove، مع التأكيد على حدود النتائج.',
      pronunciation: <String>[
        'microplastic /ˌmaɪkroʊˈplæstɪk/',
        'polymer /ˈpɑːlɪmər/',
        'contamination /kənˌtæməˈneɪʃən/',
      ],
    ),
    'c2.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Counsel: Are you suggesting that the diplomat deliberately misled us?',
        'Expert: Not necessarily. Memory can absorb details learned afterward.',
        'Counsel: But surely a precise recollection ought to be trusted?',
        'Expert: Coherence does not, by itself, establish historical accuracy.',
        'Judge: Then we must weigh the testimony against contemporaneous records.',
      ],
      tip: 'Distinguish rhetorical certainty from evidential caution and practise complex stress patterns.',
      tipArabic: 'لاحظ الفرق في النبرة بين الاعتراض القاطع والتحفظ المبني على الأدلة، خصوصًا not necessarily.',
      pronunciation: <String>[
        'retrospective /ˌrɛtrəˈspɛktɪv/',
        'testimony /ˈtɛstəmoʊni/',
        'corroborate /kəˈrɑːbəreɪt/',
      ],
    ),

    'a2.1.6': EnglishAdvancedDialogue(
      lines: <String>["Mina: Excuse me, has the last bus left?","Waiter: I'm afraid it has. Would you like me to call a licensed taxi?","Mina: Yes, please. I am going to check the timetable next time.","Waiter: You can wait inside while the driver is on the way.","Mina: Thank you. I will send my sister the meeting point."],
      tip: "Practise going to for plans and will for an immediate decision.", tipArabic: "فرّق في النطق بين going to للخطة وwill للقرار اللحظي.",
      pronunciation: <String>["reminder /rɪˈmaɪndər/","licensed /ˈlaɪsənst/","timetable /ˈtaɪmˌteɪbəl/"],
    ),
    'a2.1.7': EnglishAdvancedDialogue(
      lines: <String>["Leo: Have you ever joined an art club?","Hana: No, I've never been to one before.","Leo: Our club makes posters and works on creative projects.","Hana: That sounds interesting. Can beginners join?","Leo: Of course! I'll show you the room after class."],
      tip: "Listen for contractions I've and I'll in friendly conversation.", tipArabic: "انتبه إلى نطق I've وI'll كاختصارات إنجليزية طبيعية.",
      pronunciation: <String>["sketching /ˈskɛtʃɪŋ/","corridor /ˈkɔːrɪdɔːr/","classmate /ˈklæsˌmeɪt/"],
    ),
    'a2.1.8': EnglishAdvancedDialogue(
      lines: <String>["Daniel: Excuse me, could I return this lamp?","Assistant: Certainly. What seems to be wrong with it?","Daniel: The switch doesn't work. Would a replacement be possible?","Assistant: Yes, I'll check the fault and bring another one.","Daniel: Thank you for your help. I appreciate it."],
      tip: "Maintain a calm, polite tone for could and would questions.", tipArabic: "درّب نبرة الطلب المهذب مع could وwould في المتجر.",
      pronunciation: <String>["replacement /rɪˈpleɪsmənt/","warranty /ˈwɔːrənti/","inconvenience /ˌɪnkənˈviːniəns/"],
    ),
    'a2.1.9': EnglishAdvancedDialogue(
      lines: <String>["Emma: Should we take this shortcut?","Cousin: No, let's follow the marked forest trail.","Emma: Good idea. We will stop when we reach the viewpoint.","Ranger: Please stay on the path and keep your rubbish with you.","Emma: We will. Thank you for the safety advice."],
      tip: "Practise natural stress in sequencing: before, after and when.", tipArabic: "درّب النبرة الصحيحة على before وafter وwhen عند ترتيب الأحداث.",
      pronunciation: <String>["shortcut /ˈʃɔːrtkʌt/","viewpoint /ˈvjuːˌpɔɪnt/","forecast /ˈfɔːrkæst/"],
    ),
    'a2.1.10': EnglishAdvancedDialogue(
      lines: <String>["Sara: Which team is the fastest today?","Coach: The blue team, but the relay isn't over yet.","Sara: That was the most exciting final lap!","Coach: The runners showed great sportsmanship when the baton fell.","Sara: I agree. Helping others matters more than winning."],
      tip: "Stress comparisons: faster than, the fastest and the most exciting.", tipArabic: "أكّد صوتيًا على صيغ المقارنة والتفضيل بدل حفظها دون فهم.",
      pronunciation: <String>["relay /ˈriːleɪ/","baton /bəˈtɑːn/","sportsmanship /ˈspɔːrtsmənʃɪp/"],
    ),
    'a2.1.5': EnglishAdvancedDialogue(
      lines: <String>[
        'Salma: Do we have any rice for dinner?',
        'Mother: No, but we have some vegetables.',
        'Salma: How many carrots should I buy?',
        'Mother: Three carrots and two tomatoes, please.',
        'Salma: Great! I will write them on my shopping list.',
      ],
      tip: 'Practise how much for uncountable food and how many for countable items.',
      tipArabic: 'تدرب على السؤال عن كميات الطعام بتمييز how much عن how many مع نبرة سؤال طبيعية.',
      pronunciation: <String>[
        'vegetable /ˈvɛdʒtəbəl/',
        'carrot /ˈkærət/',
        'quantity /ˈkwɑːntəti/',
      ],
    ),
    'b1.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Yusuf: The model bridge is bending under pressure.',
        'Hana: We should strengthen the supports before testing again.',
        'Yusuf: Could we use another material instead?',
        'Hana: We have to check the budget first.',
        'Yusuf: Agreed. We must record the failed test in our report.',
      ],
      tip: 'Use must, have to, should and could to express different degrees of obligation.',
      tipArabic: 'جرّب الاختلاف في النبرة بين الاقتراح could والنصيحة should والضرورة must.',
      pronunciation: <String>[
        'structural /ˈstrʌktʃərəl/',
        'pressure /ˈprɛʃər/',
        'durability /ˌdʊrəˈbɪləti/',
      ],
    ),

    'a2.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Amira: Is this apartment still available to rent?',
        'Agent: Yes. Would you like to see the living room first?',
        'Amira: Please. Is the apartment furnished?',
        'Agent: Yes, and the balcony faces the park.',
        'Amira: Are the utility bills included in the rent?',
      ],
      tip: 'Practise polite comparisons with cheaper than, nearer than, and more comfortable than.',
      tipArabic: 'تدرّب على المقارنة الطبيعية بين خيارين باستخدام cheaper than وnearer than، مع نبرة سؤال مهذبة.',
      pronunciation: <String>[
        'apartment /əˈpɑːrtmənt/',
        'landlord /ˈlændlɔːrd/',
        'deposit /dɪˈpɑːzɪt/',
      ],
    ),
    'a2.1.4': EnglishAdvancedDialogue(
      lines: <String>[
        'Omar: Hello. I have a sore throat. Could you help me?',
        'Pharmacist: Of course. Do you have any allergies?',
        'Omar: No serious allergies, but I have a headache too.',
        'Pharmacist: Please read the label and follow the dosage instructions.',
        'Omar: Thank you. I will ask a doctor if the symptoms get worse.',
      ],
      tip: 'Use should for advice and pronounce warnings clearly in connected English speech.',
      tipArabic: 'تعلّم طلب النصيحة بوضوح وتدرب على نطق should بسلاسة قبل الفعل الأساسي.',
      pronunciation: <String>[
        'pharmacy /ˈfɑːrməsi/',
        'symptoms /ˈsɪmptəmz/',
        'dosage /ˈdoʊsɪdʒ/',
      ],
    ),
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
    'b1.1.4': EnglishAdvancedDialogue(
      lines: <String>["Producer: Have you ever worked at a radio station?", "Huda: No, I haven't, but I have practised reading announcements.", "Producer: You introduced the segment very clearly yesterday.", "Huda: Thank you. I was nervous when I started.", "Producer: Next time, pause before the important information."],
      tip: "Practise asking about experience with Have you ever and compare it with an event at a specific past time.", tipArabic: "اسأل عن الخبرة باستخدام Have you ever، ثم استخدم الماضي البسيط عند الحديث عن وقت محدد.",
      pronunciation: <String>["producer /prəˈduːsər/", "broadcast /ˈbrɔːdkæst/", "headset /ˈhɛdsɛt/"],
    ),
    'b1.1.5': EnglishAdvancedDialogue(
      lines: <String>["Parent: Is this the crossing that parents complained about?", "Leila: Yes. It is the crossing that needs brighter lighting.", "Parent: Who will inspect the street?", "Leila: An officer who works for the council will visit tomorrow.", "Parent: I will write a statement about what I saw."],
      tip: "Use who for identifying people and that for identifying things. Read the clauses without unnatural long pauses.", tipArabic: "استخدم who لتحديد الأشخاص وthat لتحديد الأشياء، واقرأ جملة الصلة دون فواصل صوتية غير طبيعية.",
      pronunciation: <String>["petition /pəˈtɪʃən/", "pedestrian /pəˈdɛstriən/", "crossing /ˈkrɔːsɪŋ/"],
    ),
    'b1.1.6': EnglishAdvancedDialogue(
      lines: <String>["Coordinator: What would you do if a puppy became frightened?", "Samira: I would give it space and speak softly.", "Coordinator: Would you try to pick it up immediately?", "Samira: No. I would ask a trained worker for guidance.", "Coordinator: Excellent. Safety and patience come first."],
      tip: "Practise hypothetical If ... were ... I would ... sentences, with natural linking and stress on would.", tipArabic: "تدرّب على الشرط الافتراضي If ... were ... I would مع ربط الكلمات وتشديد مناسب.",
      pronunciation: <String>["volunteer /ˌvɑːlənˈtɪr/", "shelter /ˈʃɛltər/", "veterinary /ˈvɛtərənɛri/"],
    ),
    'b1.1.7': EnglishAdvancedDialogue(
      lines:<String>["Mentor: What are you planning to sell?","Farah: I want to test a small breakfast menu.","Mentor: Have you considered speaking to customers?","Farah: Yes, and I enjoyed doing the survey.","Mentor: Plan to expand only after the trial works."],
      tip:"Practise decide to and enjoy -ing as natural chunks; stress the verb.",tipArabic:"تدرّب على decide to مع الفعل وenjoy مع ing، وكرر الجمل بإيقاع إنجليزي طبيعي.",
      pronunciation:<String>["entrepreneur /ˌɑːntrəprəˈnɝː/","supplier /səˈplaɪər/","profit /ˈprɑːfɪt/"],
    ),
    'b1.1.8': EnglishAdvancedDialogue(
      lines:<String>["Runner: Must I wear my number throughout the race?","Omar: Yes, it must stay visible.","Runner: Should I bring my own drinking water?","Omar: You should. There are also two water stations.","Runner: Where can I find the first-aid team?"],
      tip:"Give clear instructions with emphasis on must and should.",tipArabic:"استخدم نبرة واضحة للفرق بين must للإلزام وshould للنصيحة.",
      pronunciation:<String>["participant /pɑːrˈtɪsəpənt/","marshal /ˈmɑːrʃəl/","hydration /haɪˈdreɪʃən/"],
    ),
    'b1.1.9': EnglishAdvancedDialogue(
      lines:<String>["Neighbor: Is this the area that will become the vegetable garden?","Leila: Yes, and the section which faces west will have flowers.","Neighbor: Who will look after the raised beds?","Leila: Residents who sign up for the maintenance rota.","Neighbor: That sounds fair. I can help on Saturdays."],
      tip:"Link relative clauses smoothly and distinguish who and which.",tipArabic:"اربط جمل الصلة دون توقف غير طبيعي؛ who للأشخاص وwhich للأشياء.",
      pronunciation:<String>["rotation /roʊˈteɪʃən/","irrigation /ˌɪrəˈɡeɪʃən/","harvest /ˈhɑːrvɪst/"],
    ),
    'b1.1.10': EnglishAdvancedDialogue(
      lines:<String>["Adviser: Which university are you considering?","Yara: Although the first offers a scholarship, the second has more placements.","Adviser: Have you compared accommodation costs?","Yara: Yes. Despite the distance, the course suits my ambitions.","Adviser: Then choose the programme that supports your goals."],
      tip:"Stress the central contrasts in although, despite and however.",tipArabic:"شدّد على الكلمات التي توضّح المقارنة أثناء استعمال although وdespite وhowever.",
      pronunciation:<String>["scholarship /ˈskɑːlərʃɪp/","accommodation /əˌkɑːməˈdeɪʃən/","ambition /æmˈbɪʃən/"],
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
