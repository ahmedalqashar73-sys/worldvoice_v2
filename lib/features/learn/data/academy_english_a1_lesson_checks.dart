class EnglishA1Check {
  const EnglishA1Check(this.question, this.options, this.answer);
  final String question;
  final List<String> options;
  final int answer;
}

class EnglishA1Grammar {
  const EnglishA1Grammar(this.title, this.example, this.helpArabic);
  final String title;
  final String example;
  final String helpArabic;
}

abstract final class EnglishA1LessonChecks {
  static const comprehension = <int, List<EnglishA1Check>>{
    1: [
      EnglishA1Check("What does Sara lose?", ["A blue notebook", "A red bicycle", "A yellow hat"], 0),
      EnglishA1Check("Where does Sara find the blue ribbon?", ["In the garden", "On her desk", "On the bus"], 1),
      EnglishA1Check("Who points to the table behind the books?", ["The teacher", "The bus driver", "Her brother"], 0),
      EnglishA1Check("What does Tom make for Sara?", ["A glass of juice", "A toy car", "A paper star"], 2),
      EnglishA1Check("What is hidden in the green book?", ["A small note", "A key", "A ticket"], 0),
      EnglishA1Check("What can Maya see on page ten?", ["A blue bus", "A green tree", "A red apple"], 1),
      EnglishA1Check("Who explains the old photograph?", ["A doctor", "The librarian", "The teacher"], 1),
      EnglishA1Check("What do Maya and Leo leave behind?", ["A new note", "A pencil case", "A red bag"], 0),
      EnglishA1Check("What color is Nora's envelope?", ["Blue", "Yellow", "White"], 1),
      EnglishA1Check("Where do the paper stars lead?", ["To the garden", "To the station", "To the market"], 0),
      EnglishA1Check("Who is waiting in the garden?", ["A police officer", "Nora's classmates", "A shopkeeper"], 1),
      EnglishA1Check("What does Sam give Nora?", ["A small notebook", "A new bicycle", "A green apple"], 0),
    ],
    2: [
      EnglishA1Check("What time does Lina wake up?", ["Seven", "Ten", "Nine"], 0),
      EnglishA1Check("What does Lina find in the wrong bag?", ["A shoe", "An apple", "A phone"], 1),
      EnglishA1Check("Who arrives with fresh bread?", ["Lina's father", "Her teacher", "Her friend"], 0),
      EnglishA1Check("Who makes tea at breakfast?", ["Mimi the cat", "Their mother", "The bus driver"], 1),
      EnglishA1Check("What day is Ben going to school?", ["Monday", "Sunday", "Friday"], 0),
      EnglishA1Check("What color is Noor's umbrella?", ["Blue", "Yellow", "Green"], 1),
      EnglishA1Check("Why do Ben and Noor wait beside the bus?", ["It is late", "A car splashes water", "They forget their bags"], 1),
      EnglishA1Check("How does Ben thank Noor?", ["He carries her books", "He buys a car", "He sends a map"], 0),
      EnglishA1Check("Who does Ella visit?", ["Her grandmother", "A doctor", "Her teacher"], 0),
      EnglishA1Check("What animal do they find in the park?", ["A kitten", "A puppy", "A horse"], 1),
      EnglishA1Check("What name is on the puppy's ribbon?", ["Sunny", "Mimi", "Leo"], 0),
      EnglishA1Check("What does Grandma say a small light can do?", ["Make a big noise", "Help us do a big thing", "Stop the rain"], 1),
    ],
    3: [
      EnglishA1Check("What does Eva give Omar?", ["A map", "A bicycle", "A red hat"], 0),
      EnglishA1Check("What is behind the red door?", ["A museum", "A bakery", "A music shop"], 1),
      EnglishA1Check("What mark is above the blue shop door?", ["A golden star", "A green flag", "A big clock"], 0),
      EnglishA1Check("What does Omar try inside the shop?", ["A keyboard", "A football", "A train"], 0),
      EnglishA1Check("Where does Nina visit her grandmother?", ["In a town", "On a plane", "On a mountain"], 0),
      EnglishA1Check("What are the small golden lights?", ["Streetlights", "Fireflies", "Phones"], 1),
      EnglishA1Check("What does Nina hear near the fountain?", ["Water", "Traffic", "Loud music"], 0),
      EnglishA1Check("What does Nina draw in her notebook?", ["A bus stop", "A market", "The night garden"], 2),
      EnglishA1Check("What ribbon is on the lost basket?", ["Green", "Blue", "Red"], 0),
      EnglishA1Check("Who recognizes the green ribbon?", ["The fruit seller", "A doctor", "A driver"], 0),
      EnglishA1Check("What picture is on the card?", ["A sunflower", "A star", "A cat"], 0),
      EnglishA1Check("What does the grateful woman give Mila?", ["A sunflower", "A notebook", "A red coat"], 0),
    ],
  };

  static const grammar = <int, List<EnglishA1Grammar>>{
    1: [
      EnglishA1Grammar("I am / You are", "I am a student. You are my friend.", "أستخدم am مع I وare مع you."),
      EnglishA1Grammar("My / Your", "My name is Sara. Your name is Leo.", "My للملكية الخاصة بي وYour للملكية الخاصة بك."),
      EnglishA1Grammar("This / That", "This is my book. That is your bag.", "This للقريب وThat للبعيد."),
      EnglishA1Grammar("A / An", "I have a book and an apple.", "تأتي an غالبًا قبل صوت حرف علة."),
      EnglishA1Grammar("He / She", "He is Tom. She is Sara.", "He للمذكر وShe للمؤنث."),
      EnglishA1Grammar("There is", "There is a blue notebook on the table.", "نستخدم there is لوجود شيء واحد."),
      EnglishA1Grammar("Simple questions", "Is this your book? Yes, it is.", "ابدأ السؤال بـ is في هذه الجملة."),
      EnglishA1Grammar("Plural -s", "One book, two books.", "أضف s غالبًا للجمع."),
      EnglishA1Grammar("Be + happy", "We are happy. She is happy.", "نستخدم am/is/are قبل الصفات."),
      EnglishA1Grammar("Where is ...?", "Where is the library? It is here.", "اسأل Where is عن مكان شيء مفرد."),
      EnglishA1Grammar("Can + verb", "Can you help me? Yes, I can.", "يتبع can الفعل بصيغته الأساسية."),
      EnglishA1Grammar("Nice to meet you", "Nice to meet you. Nice to meet you too.", "استخدم too للرد بالمثل."),
    ],
    2: [
      EnglishA1Grammar("I wake up", "I wake up at seven.", "جملة مضارع بسيطة عن الروتين."),
      EnglishA1Grammar("She wakes up", "She wakes up at eight.", "نضيف s مع she عادة."),
      EnglishA1Grammar("At + time", "At seven. At eight thirty.", "at مع وقت الساعة."),
      EnglishA1Grammar("In + daypart", "In the morning. In the evening.", "in مع فترات اليوم."),
      EnglishA1Grammar("On + day", "On Monday. On Friday.", "on مع أيام الأسبوع."),
      EnglishA1Grammar("Do you ...?", "Do you study English? Yes, I do.", "استخدم do لعمل سؤال في المضارع."),
      EnglishA1Grammar("Don't / doesn't", "I don't work today. She doesn't work today.", "doesn't مع he وshe."),
      EnglishA1Grammar("Before / After", "I eat breakfast before school.", "before قبل وafter بعد."),
      EnglishA1Grammar("Have / Has", "I have a cat. She has a dog.", "has مع he أو she."),
      EnglishA1Grammar("Go / Goes", "We go by bus. He goes on foot.", "نستخدم goes مع he/she."),
      EnglishA1Grammar("There are", "There are two umbrellas.", "there are للجمع."),
      EnglishA1Grammar("Every day", "I read every day.", "every day تعبر عن عادة متكررة."),
    ],
    3: [
      EnglishA1Grammar("Where is ...?", "Where is the shop?", "اسأل عن الموقع باستخدام Where is."),
      EnglishA1Grammar("Go straight", "Go straight, then turn left.", "تعليمات الاتجاهات مع الفعل المباشر."),
      EnglishA1Grammar("Next to", "The café is next to the shop.", "next to تعني بجانب."),
      EnglishA1Grammar("There is / are", "There is one shop. There are two parks.", "There is للمفرد وthere are للجمع."),
      EnglishA1Grammar("How much?", "How much is this apple?", "السؤال عن السعر."),
      EnglishA1Grammar("Can I ...?", "Can I have some water, please?", "طلب مهذب باستخدام Can I."),
      EnglishA1Grammar("I want", "I want a blue book.", "want للرغبة."),
      EnglishA1Grammar("I like", "I like this garden.", "like للتفضيل."),
      EnglishA1Grammar("Between / behind", "The park is between the shops.", "between بين وbehind خلف."),
      EnglishA1Grammar("Near / far", "The market is near my house.", "Near قريب وFar بعيد."),
      EnglishA1Grammar("Is there ...?", "Is there a museum near here?", "استفهام عن وجود مكان."),
      EnglishA1Grammar("Review questions", "Where is the library? How much is the water?", "مراجعة أسئلة الأماكن والتسوق."),
    ],
  };

  static EnglishA1Check storyCheck(int unit, int lessonNumber) =>
      comprehension[unit]![lessonNumber - 1];

  static EnglishA1Grammar grammarFor(int unit, int lessonNumber) =>
      grammar[unit]![lessonNumber - 1];
}
