/// Teacher-led grammar expansion for the A1 lessons that previously
/// displayed only one English example and an unrelated mini-dialogue.
/// Each workshop has a rule, four genuine English-Arabic examples, a
/// misconception and a corrective comprehension question.
class AcademyGrammarExample {
  const AcademyGrammarExample(this.english, this.arabic);
  final String english;
  final String arabic;
}
class AcademyGrammarWorkshop {
  const AcademyGrammarWorkshop({
    required this.ruleEnglish,
    required this.examples,
    required this.wrong,
    required this.correct,
    required this.question,
    required this.options,
    required this.answer,
  });
  final String ruleEnglish;
  final List<AcademyGrammarExample> examples;
  final String wrong;
  final String correct;
  final String question;
  final List<String> options;
  final int answer;
}
abstract final class AcademyGrammarWorkshops {
  static const _lessons = <String, AcademyGrammarWorkshop>{
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use a before a consonant sound and an before a vowel sound. Listen to the next SOUND, not simply its written first letter.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I have a book.", "لدي كتاب."), AcademyGrammarExample("She has an apple.", "لديها تفاحة."), AcademyGrammarExample("It is an orange.", "إنها برتقالة."), AcademyGrammarExample("This is a university.", "هذه جامعة.")],
      wrong: "I have a apple.", correct: "I have an apple.",
      question: "Which phrase is correct?", options: <String>["a orange", "an orange", "an university"],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "He refers to a male person; she refers to a female person. Both take is, not are, in a simple description.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("He is Tom.", "هو توم."), AcademyGrammarExample("She is Sara.", "هي سارة."), AcademyGrammarExample("He is a student.", "هو طالب."), AcademyGrammarExample("Is she your friend?", "هل هي صديقتك؟")],
      wrong: "She are my sister.", correct: "She is my sister.",
      question: "Choose the correct sentence.", options: <String>["He are my teacher.", "She is my teacher.", "She am my teacher."],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "There is tells us one person or thing exists somewhere. Put the object after is and its location at the end.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("There is a notebook on the desk.", "يوجد دفتر على الطاولة."), AcademyGrammarExample("There is an apple in the bag.", "توجد تفاحة في الحقيبة."), AcademyGrammarExample("There is a tree outside.", "توجد شجرة في الخارج."), AcademyGrammarExample("Is there a library here?", "هل توجد مكتبة هنا؟")],
      wrong: "There is two books.", correct: "There is a book.",
      question: "Complete: There ___ a pen on the desk.", options: <String>["are", "am", "is"],
      answer: 2,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "To make a yes/no question with be, move is or are before the subject; answer with the same verb.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("Is this your book?", "هل هذا كتابك؟"), AcademyGrammarExample("Yes, it is.", "نعم، هو كذلك."), AcademyGrammarExample("Is she a teacher?", "هل هي معلمة؟"), AcademyGrammarExample("No, she is not.", "لا، هي ليست كذلك.")],
      wrong: "This is your bag?", correct: "Is this your bag?",
      question: "Choose the correct question.", options: <String>["Is that your pen?", "That is your pen?", "Am that your pen?"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Most nouns add -s in the plural, but nouns ending in -ch or -sh often add -es; a few plurals are irregular.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("One book, two books.", "كتاب واحد، كتابان."), AcademyGrammarExample("One pen, four pens.", "قلم واحد، أربعة أقلام."), AcademyGrammarExample("One box, two boxes.", "صندوق واحد، صندوقان."), AcademyGrammarExample("One child, two children.", "طفل واحد، طفلان.")],
      wrong: "Two book are here.", correct: "Two books are here.",
      question: "Choose the correct plural.", options: <String>["three boxs", "three boxes", "three box"],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Adjectives describe people and things. In English a full sentence usually needs am/is/are before an adjective.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I am happy.", "أنا سعيد."), AcademyGrammarExample("She is tired.", "هي متعبة."), AcademyGrammarExample("We are ready.", "نحن مستعدون."), AcademyGrammarExample("Are you okay?", "هل أنت بخير؟")],
      wrong: "She happy today.", correct: "She is happy today.",
      question: "Choose the correct sentence.", options: <String>["We is happy.", "We are happy.", "We am happy."],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Where asks about a place. Use Where is for one thing and Where are for more than one thing.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("Where is the library?", "أين المكتبة؟"), AcademyGrammarExample("It is next to the school.", "إنها بجانب المدرسة."), AcademyGrammarExample("Where are my keys?", "أين مفاتيحي؟"), AcademyGrammarExample("They are on the table.", "إنها على الطاولة.")],
      wrong: "Where the library is?", correct: "Where is the library?",
      question: "Ask about two books.", options: <String>["Where are the books?", "Where is the books?", "Where am the books?"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use the present simple for regular routines, not for actions happening only now. I/you/we/they use the base verb.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I wake up early.", "أستيقظ مبكرًا."), AcademyGrammarExample("I eat breakfast at eight.", "أتناول الإفطار عند الثامنة."), AcademyGrammarExample("We walk to school.", "نمشي إلى المدرسة."), AcademyGrammarExample("They read every day.", "يقرؤون كل يوم.")],
      wrong: "I wakes up at seven.", correct: "I wake up at seven.",
      question: "Choose a daily routine.", options: <String>["I wake up at six.", "I waking up at six.", "I wakes up at six."],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "In the present simple, he/she/it usually adds -s to the verb. For verbs ending in consonant + y, change y to -ies.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("She wakes up at seven.", "تستيقظ عند السابعة."), AcademyGrammarExample("He walks to school.", "يمشي إلى المدرسة."), AcademyGrammarExample("Maya studies English.", "تدرس مايا الإنجليزية."), AcademyGrammarExample("My brother plays football.", "يلعب أخي كرة القدم.")],
      wrong: "She walk to school.", correct: "She walks to school.",
      question: "Choose the correct sentence.", options: <String>["He study every day.", "He studies every day.", "He studying every day."],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use at for an exact clock time. Use in for parts of the day and on for a named day.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I wake up at seven.", "أستيقظ عند السابعة."), AcademyGrammarExample("The bus leaves at noon.", "تغادر الحافلة عند الظهر."), AcademyGrammarExample("I study at eight thirty.", "أدرس عند الثامنة والنصف."), AcademyGrammarExample("We meet at midnight.", "نلتقي عند منتصف الليل.")],
      wrong: "I leave in seven o'clock.", correct: "I leave at seven o'clock.",
      question: "Choose the correct time phrase.", options: <String>["at eight thirty", "on eight thirty", "in eight thirty"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use in the morning, in the afternoon, and in the evening; but at night is the common exception.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I run in the morning.", "أركض في الصباح."), AcademyGrammarExample("We eat in the afternoon.", "نأكل بعد الظهر."), AcademyGrammarExample("She reads in the evening.", "تقرأ في المساء."), AcademyGrammarExample("I sleep at night.", "أنام ليلًا.")],
      wrong: "I study on the morning.", correct: "I study in the morning.",
      question: "Choose the correct expression.", options: <String>["at the evening", "in the evening", "on the evening"],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use on before a day or date; at is for clock times and in is for months, years and many dayparts.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I work on Monday.", "أعمل يوم الاثنين."), AcademyGrammarExample("We meet on Friday.", "نلتقي يوم الجمعة."), AcademyGrammarExample("Her birthday is on June fifth.", "عيد ميلادها في الخامس من يونيو."), AcademyGrammarExample("The shop is closed on Sunday.", "المتجر مغلق يوم الأحد.")],
      wrong: "We study in Monday.", correct: "We study on Monday.",
      question: "Complete: The lesson is ___ Friday.", options: <String>["on", "at", "in"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use do before I/you/we/they to ask about routines; keep the main verb in its base form. With he/she use does.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("Do you study English?", "هل تدرس الإنجليزية؟"), AcademyGrammarExample("Yes, I do.", "نعم، أدرسها."), AcademyGrammarExample("Does he work here?", "هل يعمل هنا؟"), AcademyGrammarExample("No, he does not.", "لا، لا يعمل هنا.")],
      wrong: "Do you studies English?", correct: "Do you study English?",
      question: "Choose the correct question.", options: <String>["Do she play tennis?", "Does she plays tennis?", "Does she play tennis?"],
      answer: 2,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use do not/don't with I/you/we/they and does not/doesn't with he/she/it. After doesn't, the verb loses its -s.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I don't drink coffee.", "لا أشرب القهوة."), AcademyGrammarExample("She doesn't drive.", "هي لا تقود."), AcademyGrammarExample("They don't work today.", "هم لا يعملون اليوم."), AcademyGrammarExample("He doesn't like rain.", "هو لا يحب المطر.")],
      wrong: "She doesn't works today.", correct: "She doesn't work today.",
      question: "Which negative is correct?", options: <String>["He don't like milk.", "He doesn't like milk.", "He doesn't likes milk."],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Before and after place events in time. Before means earlier than; after means later than. They can introduce a noun or an action.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I wash my hands before lunch.", "أغسل يدي قبل الغداء."), AcademyGrammarExample("We play after school.", "نلعب بعد المدرسة."), AcademyGrammarExample("She reads before bed.", "تقرأ قبل النوم."), AcademyGrammarExample("They walk after dinner.", "يتمشون بعد العشاء.")],
      wrong: "I wash after breakfast before I eat.", correct: "I wash before breakfast.",
      question: "Which sentence means you eat, then leave?", options: <String>["I leave before lunch.", "I leave after lunch.", "I lunch after leave."],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Have is used with I/you/we/they. Has is used with he/she/it. Both mean owning or having something.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I have a cat.", "لدي قطة."), AcademyGrammarExample("She has a dog.", "لديها كلب."), AcademyGrammarExample("We have two bags.", "لدينا حقيبتان."), AcademyGrammarExample("Does he have a car?", "هل لديه سيارة؟")],
      wrong: "She have a new bike.", correct: "She has a new bike.",
      question: "Choose the correct sentence.", options: <String>["He has a dog.", "He have a dog.", "He haves a dog."],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "With he/she/it, go becomes goes. With I/you/we/they it stays go. Questions with does use go, not goes.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I go to school.", "أذهب إلى المدرسة."), AcademyGrammarExample("He goes by bus.", "يذهب بالحافلة."), AcademyGrammarExample("We go home after work.", "نعود إلى المنزل بعد العمل."), AcademyGrammarExample("Does she go on foot?", "هل تذهب سيرًا؟")],
      wrong: "He go by bus.", correct: "He goes by bus.",
      question: "Choose the correct question.", options: <String>["Does she goes home?", "Does she go home?", "Do she go home?"],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use where is to ask for the location of one place, and where are for multiple places. Give directions in short steps.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("Where is the bank?", "أين البنك؟"), AcademyGrammarExample("It is across from the park.", "إنه مقابل الحديقة."), AcademyGrammarExample("Where is the nearest bus stop?", "أين أقرب موقف للحافلة؟"), AcademyGrammarExample("It is on this street.", "إنه في هذا الشارع.")],
      wrong: "Where the bank?", correct: "Where is the bank?",
      question: "Choose the correct question.", options: <String>["Where is the museum?", "Where are the museum?", "Where museum is?"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Give simple directions with an imperative: go, turn, stop or cross. Add then to show the next step.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("Go straight.", "امشِ مباشرة."), AcademyGrammarExample("Turn left at the shop.", "انعطف يسارًا عند المتجر."), AcademyGrammarExample("Cross the street carefully.", "اعبر الشارع بحذر."), AcademyGrammarExample("Stop at the traffic lights.", "توقف عند إشارة المرور.")],
      wrong: "You turning left now.", correct: "Turn left now.",
      question: "Which instruction is correct?", options: <String>["Go straight and turn right.", "Goes straight and turn right.", "Going straight turn right."],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use next to when one place is directly beside another. Use opposite when they face each other across a space.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("The café is next to the shop.", "المقهى بجانب المتجر."), AcademyGrammarExample("My chair is next to the window.", "كرسيّي بجانب النافذة."), AcademyGrammarExample("The bank is opposite the museum.", "البنك مقابل المتحف."), AcademyGrammarExample("Is the pharmacy next to the hospital?", "هل الصيدلية بجانب المستشفى؟")],
      wrong: "The café next to the shop.", correct: "The café is next to the shop.",
      question: "Complete: The school is ___ the bank.", options: <String>["next to", "next", "next of"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "There is introduces one thing, while there are introduces two or more. A question begins Is there...? or Are there...?",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("There is a bakery here.", "يوجد مخبز هنا."), AcademyGrammarExample("There are two parks nearby.", "توجد حديقتان بالقرب."), AcademyGrammarExample("Is there a museum?", "هل يوجد متحف؟"), AcademyGrammarExample("Are there any cafés?", "هل توجد مقاهٍ؟")],
      wrong: "There is three shops.", correct: "There are three shops.",
      question: "Choose the correct question.", options: <String>["Is there two parks?", "Are there two parks?", "There are two parks?"],
      answer: 1,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use How much is ...? to ask the price of one thing. Use How much are ...? for plural items. Much also asks about uncountable quantity.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("How much is this apple?", "كم سعر هذه التفاحة؟"), AcademyGrammarExample("It costs two dollars.", "سعرها دولاران."), AcademyGrammarExample("How much are these shoes?", "كم سعر هذا الحذاء؟"), AcademyGrammarExample("How much water do you need?", "كم تحتاج من الماء؟")],
      wrong: "How many is this water?", correct: "How much is this water?",
      question: "Which question asks the price of apples?", options: <String>["How much are these apples?", "How much is these apples?", "How many is these apples?"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Can I have...? makes a polite request. Add please to soften the request. The next verb remains in the base form.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("Can I have some water, please?", "هل يمكنني الحصول على بعض الماء من فضلك؟"), AcademyGrammarExample("Can I see the menu?", "هل يمكنني رؤية قائمة الطعام؟"), AcademyGrammarExample("Can I pay by card?", "هل يمكنني الدفع بالبطاقة؟"), AcademyGrammarExample("Yes, of course.", "نعم، بالطبع.")],
      wrong: "Can I to have tea?", correct: "Can I have tea?",
      question: "Choose the polite request.", options: <String>["Can I have a menu, please?", "Can I having a menu?", "Can I to have a menu?"],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use want + noun to say what you desire; use want to + verb to say an action you want to do.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I want a blue book.", "أريد كتابًا أزرق."), AcademyGrammarExample("She wants a new bag.", "تريد حقيبة جديدة."), AcademyGrammarExample("I want to buy fruit.", "أريد شراء الفاكهة."), AcademyGrammarExample("Do you want to go?", "هل تريد الذهاب؟")],
      wrong: "I want buy a ticket.", correct: "I want to buy a ticket.",
      question: "Choose the correct sentence.", options: <String>["I want to visit the park.", "I want visiting the park.", "I want visit the park."],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Use like + noun or like + -ing to talk about preferences. He/she/it normally takes likes.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("I like this garden.", "أحب هذه الحديقة."), AcademyGrammarExample("She likes flowers.", "تحب الزهور."), AcademyGrammarExample("We like walking outside.", "نحب المشي في الخارج."), AcademyGrammarExample("Do you like music?", "هل تحب الموسيقى؟")],
      wrong: "He like this park.", correct: "He likes this park.",
      question: "Choose the correct sentence.", options: <String>["I like reading stories.", "I liking read stories.", "I like read stories."],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Between locates one thing in the middle of two or more points. Behind tells us it is at the back of another object.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("The park is between two shops.", "الحديقة بين متجرين."), AcademyGrammarExample("The bus is behind the school.", "الحافلة خلف المدرسة."), AcademyGrammarExample("The café is between the bank and the library.", "المقهى بين البنك والمكتبة."), AcademyGrammarExample("The cat is hiding behind the door.", "القطة تختبئ خلف الباب.")],
      wrong: "The library between the shops.", correct: "The library is between the shops.",
      question: "Which sentence uses behind correctly?", options: <String>["The bus is behind the school.", "The bus behind school.", "The bus is between of the school."],
      answer: 0,
    ),
    '$u:$n': AcademyGrammarWorkshop(
      ruleEnglish: "Near means a short distance away; far means a long distance away. Use far from (not far to) when comparing locations.",
      examples: <AcademyGrammarExample>[AcademyGrammarExample("The market is near my house.", "السوق قريب من منزلي."), AcademyGrammarExample("The museum is far from here.", "المتحف بعيد عن هنا."), AcademyGrammarExample("Is the pharmacy nearby?", "هل الصيدلية قريبة؟"), AcademyGrammarExample("The hotel is near the station.", "الفندق قريب من المحطة.")],
      wrong: "The bank is far to here.", correct: "The bank is far from here.",
      question: "Complete: The station is ___ my house.", options: <String>["near", "near of", "near to of"],
      answer: 0,
    ),
  };
  static AcademyGrammarWorkshop? forLesson(int unit, int lesson) =>
      _lessons['$unit:$lesson'];
  static int get count => _lessons.length;
}
