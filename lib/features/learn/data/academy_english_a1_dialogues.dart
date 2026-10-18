/// Original spoken conversations and listening passages for English A1.
/// One distinct dialogue and audio reading per complete lesson.
/// Grammar remains owned by academy_english_a1_lesson_checks.dart.
class EnglishA1Dialogue {
  const EnglishA1Dialogue(this.dialogue, this.listening);
  final String dialogue;
  final String listening;
}

EnglishA1Dialogue _d(String dialogue, String listening) =>
    EnglishA1Dialogue(dialogue, listening);

abstract final class EnglishA1DialogueCatalog {
  static final lessons = <List<EnglishA1Dialogue>>[
    [
      _d('Sara: Hello! My name is Sara.\nLeo: Hi, Sara! I am Leo. Nice to meet you.', 'Hello, my name is Sara. I am a student. Leo is my new friend.'),
      _d('Maya: Is that your sister?\nLeo: Yes, she is. Her name is Nina.', 'This is my family. I have one sister and one brother. We live together.'),
      _d('Sara: How many books do you have?\nLeo: I have three books.', 'I have two pens and three books. I put five things in my bag.'),
      _d('Maya: What color is your bag?\nTom: It is blue. My notebook is green.', 'I see a red door, a green tree and a blue book near the window.'),
      _d('Sara: Is this your pen?\nLeo: No, it is your pen. My pen is on the desk.', 'There is a notebook on my desk. There is a pencil next to my chair.'),
      _d('Leo: Are you happy today?\nSara: Yes, I am. My friend is very kind.', 'Maya is excited. Leo is calm. Sara smiles because her friends are here.'),
      _d('Tom: Is the book big?\nMaya: No. It is a small book.', 'A big green tree is near the small blue house. The street is quiet.'),
      _d('Sara: Do you speak English?\nTom: Yes, I do. I read English stories.', 'I read a book. My teacher speaks English. We listen and repeat.'),
      _d('Maya: Is the library near here?\nLeo: Yes, it is there, behind the park.', 'My bag is beside the table. My notebook is inside the bag.'),
      _d('Tom: Where is the café?\nSara: The café is next to the library.', 'Our town has a library, a café and a park. The café is near my school.'),
      _d('Maya: What is that in the sky?\nLeo: It is a bird! Look at the tree.', 'The sun is bright. A bird sits in a tree. There are flowers in the garden.'),
      _d('Sara: Can you help me find my book?\nTom: Of course! Let us look together.', 'Sara looks for her notebook. Her friend helps her. Together they find it.'),
    ],
    [
      _d('Lina: What time do you wake up?\nBen: I wake up at seven every day.', 'I wake up at seven. I wash my face. Then I eat breakfast and leave home.'),
      _d('Dad: What do you want for breakfast?\nLina: I want bread and an egg, please.', 'For breakfast I have an egg and bread. My sister drinks milk.'),
      _d('Ben: Is it eight o’clock now?\nNoor: No, it is seven thirty.', 'It is Monday morning. We meet at eight o’clock and start class at nine.'),
      _d('Lina: Do you study on Saturday?\nBen: No, I study on Monday.', 'We study from Monday to Friday. On Saturday, we play in the park.'),
      _d('Noor: Where is the kitchen?\nLina: It is next to the living room.', 'Our house has a kitchen and two bedrooms. The cat sleeps on the sofa.'),
      _d('Ben: Does this bus go to school?\nDriver: Yes. Please take a seat.', 'I wait for the bus at seven. I sit by the window. Then I go to school.'),
      _d('Lina: Where is Mimi the cat?\nDad: She is sleeping under the table.', 'My little cat is sleepy. She likes milk and plays near the window.'),
      _d('Noor: What does your mother do?\nBen: She is a doctor. My father is a chef.', 'My mother works at a hospital. My father cooks in a restaurant.'),
      _d('Lina: What is your favorite subject?\nBen: I like science and English.', 'At school, I study math and science. My friend likes history.'),
      _d('Noor: Is it raining?\nBen: Yes! Please take your umbrella.', 'It is rainy today. I wear my jacket and take a yellow umbrella.'),
      _d('Ben: How is the weather today?\nNoor: It is cold and cloudy.', 'In the morning it is cloudy. In the afternoon the sun is warm.'),
      _d('Lina: Are you free after school?\nNoor: Yes. Let us read together.', 'I usually study at home. After dinner, I sometimes listen to music.'),
    ],
    [
      _d('Omar: Excuse me, where is the library?\nEva: Go straight and turn left.', 'Walk along this street. Turn left at the corner. The library is near the bank.'),
      _d('Layla: Is there a pharmacy near here?\nSam: Yes, it is beside the bakery.', 'Our town has a bank, a bakery and a small pharmacy beside the market.'),
      _d('Sam: How much is this book?\nSeller: It is five dollars.', 'I want to buy a notebook. It costs five dollars. I pay with cash.'),
      _d('Layla: Do you have any apples?\nSeller: Yes, we have red apples.', 'The market has bananas, apples and carrots. I buy two red apples.'),
      _d('Omar: Can I see the menu, please?\nWaiter: Certainly! Here you are.', 'We are at a restaurant. I order soup and my friend orders juice.'),
      _d('Nina: Are there flowers in the garden?\nGrandma: Yes, there are many roses.', 'I see butterflies, a pond and pink flowers in the little garden.'),
      _d('Omar: Do you play the piano?\nEva: No, but I play the guitar.', 'I like music. My friend plays the piano, and I sing in the band.'),
      _d('Layla: Where are you going today?\nSam: I am going to the beach.', 'Today we visit the old town. We take a camera and a small map.'),
      _d('Sam: What is your hobby?\nLayla: I like drawing and reading.', 'My hobby is painting. On Saturday I draw pictures with my friend.'),
      _d('Omar: Could you help me, please?\nClerk: Of course. What do you need?', 'Excuse me. Could I have some water? Thank you very much for your help.'),
      _d('Nina: Are you feeling well?\nGrandma: I am a little tired today.', 'I am tired, so I drink some water and rest at home today.'),
      _d('Layla: Are you ready for the party?\nSam: Yes! I have a special gift.', 'Today is a special day. We have a cake, balloons and a little present.'),
    ],
  ];

  static EnglishA1Dialogue forLesson(int unit, int lesson) {
    if (unit < 1 || unit > 3 || lesson < 1 || lesson > 12) {
      throw RangeError('Unknown English A1 unit/lesson');
    }
    return lessons[unit - 1][lesson - 1];
  }
}
