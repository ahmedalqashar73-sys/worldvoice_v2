import 'academy_english_a1_catalog.dart';

/// Nine original A1 readers. Each chapter is a complete narrative paragraph,
/// not a disconnected one-sentence slide. Four paragraphs per story.
abstract final class EnglishA1LongStories {
  static const stories = <EnglishA1Story>[
    EnglishA1Story(
      id: 'en_u1_notebook', title: 'The Notebook with a Star',
      titleAr: 'الدفتر والنجمة الذهبية', scene: 0,
      pages: [
        EnglishA1StoryPage(
          'Sara is new at school. She has a small blue notebook and a gold star on its cover. Her mother gives her the notebook on her first day. Sara writes her name on the first page. She is happy, but a little nervous.',
          'سارة جديدة في المدرسة. معها دفتر أزرق صغير وعلى غلافه نجمة ذهبية. أعطتها أمها الدفتر في يومها الأول. تكتب سارة اسمها في الصفحة الأولى. إنها سعيدة لكنها متوترة قليلًا.',
        ),
        EnglishA1StoryPage(
          'At lunch, Sara opens her bag. The notebook is not there! She looks on the table and under her chair. She asks her friend Tom, “Do you see my blue notebook?” Tom says, “No, but I can help you.” Together they search the classroom.',
          'وقت الغداء تفتح سارة حقيبتها، لكن الدفتر ليس فيها! تنظر على الطاولة وتحت الكرسي. تسأل صديقها توم: «هل رأيت دفتري الأزرق؟» يجيب: «لا، لكن يمكنني مساعدتك». ويبحثان معًا في الصف.',
        ),
        EnglishA1StoryPage(
          'There is a little gold star on the classroom floor. Sara follows it to the library door. Another star is on a green book. Tom laughs and points to the window. The blue notebook is on a chair beside the window.',
          'هناك نجمة ذهبية صغيرة على أرض الصف. تتبعها سارة حتى باب المكتبة. وهناك نجمة ثانية فوق كتاب أخضر. يضحك توم ويشير إلى النافذة. الدفتر الأزرق على كرسي بجانب النافذة.',
        ),
        EnglishA1StoryPage(
          'Sara opens the notebook. Inside is a new message: “Welcome to our school, Sara!” It is from her classmates. Tom smiles and says, “We want to be your friends.” Sara feels warm and happy. She writes one more sentence: “Today is a good day.”',
          'تفتح سارة الدفتر، فتجد فيه رسالة جديدة: «مرحبًا بك في مدرستنا يا سارة!» إنها من زملائها. يبتسم توم ويقول: «نريد أن نكون أصدقاءك». تشعر سارة بالسعادة وتكتب جملة أخرى: «اليوم يوم جميل».',
        ),
      ],
      question: 'Who writes the welcome message?',
      options: ['Sara’s classmates', 'A shopkeeper', 'The bus driver'], answer: 0,
    ),
    EnglishA1Story(
      id: 'en_u1_library', title: 'The Book on the Wrong Shelf',
      titleAr: 'الكتاب على الرف الخطأ', scene: 1,
      pages: [
        EnglishA1StoryPage(
          'Maya likes quiet places. Every Friday, she goes to the library with her friend Leo. Today she sees a red book on the blue shelf. The book has no title, only a picture of a little green tree. “This is strange,” she says.',
          'تحب مايا الأماكن الهادئة. تذهب كل جمعة إلى المكتبة مع صديقها ليو. اليوم ترى كتابًا أحمر على رف أزرق. ليس للكتاب عنوان، فقط صورة شجرة خضراء صغيرة. تقول: «هذا غريب».',
        ),
        EnglishA1StoryPage(
          'Leo opens the book carefully. Page one says, “Hello, reader!” Page two shows a map of their town. Page three has a picture of a big clock. On page four, there is a simple question: “Where is the oldest tree?” Maya wants to know the answer.',
          'يفتح ليو الكتاب بحذر. تقول الصفحة الأولى: «مرحبًا أيها القارئ!» وتعرض الثانية خريطة بلدتهما. وفي الثالثة صورة ساعة كبيرة. وفي الرابعة سؤال بسيط: «أين أقدم شجرة؟» تريد مايا معرفة الجواب.',
        ),
        EnglishA1StoryPage(
          'They take the map to the librarian. She is an older woman with friendly eyes. “Ah, this is our town book!” she says. “It is on the wrong shelf. The old tree is in the park, near the little fountain.” The two friends thank her.',
          'يعرض الصديقان الخريطة على أمينة المكتبة. إنها سيدة كبيرة ذات عينين ودودتين. تقول: «آه، هذا كتاب بلدتنا! إنه على الرف الخطأ. الشجرة القديمة في الحديقة قرب النافورة الصغيرة». يشكرها الصديقان.',
        ),
        EnglishA1StoryPage(
          'Maya and Leo walk to the park. There is the tree, big and beautiful. They sit in its shade and read the last page together. It says, “A good story begins with one question.” Maya smiles. Next Friday, she will look for another book.',
          'تمشي مايا وليو إلى الحديقة. وهناك الشجرة كبيرة وجميلة. يجلسان في ظلها ويقرآن الصفحة الأخيرة معًا. تقول: «تبدأ القصة الجميلة بسؤال واحد». تبتسم مايا. في الجمعة القادمة ستبحث عن كتاب آخر.',
        ),
      ],
      question: 'Where is the old tree?',
      options: ['At the station', 'In the park', 'Inside the library'], answer: 1,
    ),
    EnglishA1Story(
      id: 'en_u1_letter', title: 'A Letter for Someone New',
      titleAr: 'رسالة لشخص جديد', scene: 6,
      pages: [
        EnglishA1StoryPage(
          'Omar comes to a new town with his family. He does not know many people. On Monday morning, he finds a white letter under the door. It has his name in big blue letters. He looks at his sister and asks, “Who is it from?”',
          'يصل عمر إلى بلدة جديدة مع عائلته. لا يعرف كثيرًا من الناس. صباح الاثنين يجد رسالة بيضاء تحت الباب. اسمه مكتوب عليها بحروف زرقاء كبيرة. ينظر إلى أخته ويسأل: «من أرسلها؟»',
        ),
        EnglishA1StoryPage(
          'The letter says, “Hello, Omar! My name is Emma. I live next door. Welcome to our street!” There is a little picture of a cat at the bottom. Omar feels happy. He wants to thank Emma, but he does not know her door.',
          'تقول الرسالة: «مرحبًا يا عمر! اسمي إيما. أسكن في البيت المجاور. أهلًا بك في شارعنا!» وفي أسفلها صورة قطة صغيرة. يشعر عمر بالسعادة. يريد شكر إيما لكنه لا يعرف بابها.',
        ),
        EnglishA1StoryPage(
          'Outside, he sees a girl with a small orange cat. “Hi! Are you Emma?” he asks. The girl smiles and says, “Yes! This is my cat, Sunny.” Omar says, “Thank you for your nice letter.” Emma says she likes drawing and reading books.',
          'في الخارج يرى فتاة مع قطة برتقالية صغيرة. يسأل: «أهلًا! هل أنت إيما؟» تبتسم وتقول: «نعم! وهذه قطتي ساني». يقول عمر: «شكرًا على رسالتك الجميلة». تخبره إيما بأنها تحب الرسم والقراءة.',
        ),
        EnglishA1StoryPage(
          'In the afternoon, Omar writes a reply. He draws a blue house and a gold sun. Under the picture he writes, “Hello, Emma. I am Omar. I am your new friend!” He puts it in her mailbox. Now the street feels like home.',
          'بعد الظهر يكتب عمر ردًا. يرسم بيتًا أزرق وشمسًا ذهبية. وتحت الصورة يكتب: «مرحبًا يا إيما. أنا عمر. أنا صديقك الجديد!» يضعها في صندوق بريدها. الآن يشعر أن الشارع بيته.',
        ),
      ],
      question: 'What pet does Emma have?',
      options: ['A rabbit', 'A cat', 'A bird'], answer: 1,
    ),
    EnglishA1Story(
      id: 'en_u2_breakfast', title: 'The Breakfast Surprise',
      titleAr: 'مفاجأة الفطور', scene: 2,
      pages: [
        EnglishA1StoryPage(
          'Lina wakes up at seven every morning. Today is Saturday, so she does not go to school. She wants to make breakfast for her family. She puts two plates on the table and looks in the fridge. There are eggs and milk, but there is no bread.',
          'تستيقظ لينا في السابعة كل صباح. اليوم السبت، لذلك لا تذهب إلى المدرسة. تريد أن تصنع الفطور لعائلتها. تضع طبقين على الطاولة وتنظر في الثلاجة. هناك بيض وحليب، لكن لا يوجد خبز.',
        ),
        EnglishA1StoryPage(
          'Her little cat Mimi sits under the chair. Lina sees a paper bag near the cat and thinks, “Is my bread inside?” She opens the bag. There is one red apple and a funny drawing, but no bread. She laughs and gives Mimi some water.',
          'تجلس قطتها الصغيرة ميمي تحت الكرسي. ترى لينا كيسًا ورقيًا بالقرب منها وتفكر: «هل خبزي بداخله؟» تفتح الكيس. تجد تفاحة حمراء ورسمة مضحكة، لكن ليس فيه خبز. تضحك وتعطي ميمي ماء.',
        ),
        EnglishA1StoryPage(
          'Lina hears the front door. Her father comes into the kitchen with a warm bag. “Good morning!” he says. “I have fresh bread for everyone.” Her mother brings orange juice, and her brother brings cheese. Now the breakfast table is ready.',
          'تسمع لينا الباب الأمامي. يدخل والدها إلى المطبخ ومعه كيس دافئ. يقول: «صباح الخير! أحضرت خبزًا طازجًا للجميع». تجلب أمها عصير البرتقال، ويحضر أخوها الجبن. الآن مائدة الفطور جاهزة.',
        ),
        EnglishA1StoryPage(
          'The family sits together and eats. Lina tells everyone about the apple and the funny drawing. Her father says, “That drawing is from your brother!” Her brother smiles. Lina has a wonderful idea: next Saturday, they can make breakfast together.',
          'تجلس العائلة معًا وتتناول الطعام. تحكي لينا عن التفاحة والرسمة المضحكة. يقول أبوها: «هذه الرسمة من أخيك!» يبتسم أخوها. تخطر للينا فكرة رائعة: في السبت القادم يستطيعون صنع الفطور معًا.',
        ),
      ],
      question: 'Who brings fresh bread?',
      options: ['Her father', 'Mimi', 'Her teacher'], answer: 0,
    ),
    EnglishA1Story(
      id: 'en_u2_bus', title: 'The Yellow Umbrella',
      titleAr: 'المظلة الصفراء', scene: 3,
      pages: [
        EnglishA1StoryPage(
          'Ben goes to school by bus every Monday. Today he leaves home early, but dark clouds fill the sky. He has a blue school bag and a small lunch box. He looks for his umbrella, but it is not by the door. “I hope the rain stops,” he says.',
          'يذهب بن إلى المدرسة بالحافلة كل اثنين. اليوم يغادر منزله مبكرًا، لكن الغيوم الداكنة تملأ السماء. معه حقيبة مدرسة زرقاء وصندوق غداء صغير. يبحث عن مظلته، لكنها ليست بجانب الباب. يقول: «أتمنى أن يتوقف المطر».',
        ),
        EnglishA1StoryPage(
          'At the bus stop, the rain begins. Ben waits under a little roof. His friend Noor arrives with a large yellow umbrella. “Good morning, Ben! You can stand with me,” she says. The two friends stay dry and talk about their day.',
          'عند محطة الحافلة يبدأ المطر. ينتظر بن تحت سقف صغير. تصل صديقته نور بمظلة صفراء كبيرة. تقول: «صباح الخير يا بن! يمكنك الوقوف معي». يبقى الصديقان جافين ويتحدثان عن يومهما.',
        ),
        EnglishA1StoryPage(
          'On the bus, an older woman cannot find a seat. Ben stands up and says, “Please, sit here.” She smiles and thanks him. Noor watches and says, “That is very kind.” Ben feels proud. Outside the window, the rain gets lighter.',
          'في الحافلة لا تجد سيدة كبيرة مقعدًا. يقف بن ويقول: «تفضلي، اجلسي هنا». تبتسم وتشكره. تراه نور وتقول: «هذا تصرف لطيف جدًا». يشعر بن بالفخر. وخارج النافذة يخف المطر.',
        ),
        EnglishA1StoryPage(
          'They get off the bus near their school. Noor opens her yellow umbrella again. The sun comes out for a moment, and a small rainbow appears. Ben says, “Thank you for helping me.” Noor replies, “That is what friends do!”',
          'ينزلان من الحافلة قرب مدرستهما. تفتح نور مظلتها الصفراء من جديد. تظهر الشمس للحظة ويظهر قوس قزح صغير. يقول بن: «شكرًا لمساعدتك». ترد نور: «هذا ما يفعله الأصدقاء!»',
        ),
      ],
      question: 'What color is Noor’s umbrella?',
      options: ['Yellow', 'Red', 'Black'], answer: 0,
    ),
    EnglishA1Story(
      id: 'en_u2_cake', title: 'The Cake on Sunday',
      titleAr: 'كعكة يوم الأحد', scene: 7,
      pages: [
        EnglishA1StoryPage(
          'It is Sunday morning. Adam is at home with his mother and sister. Tomorrow is his grandmother’s birthday. They want to make a small cake for her. Adam reads the recipe: eggs, flour, milk and sugar. He checks the kitchen cupboards.',
          'إنه صباح الأحد. آدم في المنزل مع أمه وأخته. غدًا عيد ميلاد جدته. يريدون صنع كعكة صغيرة لها. يقرأ آدم الوصفة: بيض ودقيق وحليب وسكر. ويفحص خزائن المطبخ.',
        ),
        EnglishA1StoryPage(
          'There are eggs and milk, but the sugar jar is empty. Adam goes to the little shop near the park. He says, “Good morning. Can I have some sugar, please?” The shopkeeper gives him a bag of sugar. Adam pays and runs home.',
          'هناك بيض وحليب، لكن مرطبان السكر فارغ. يذهب آدم إلى المتجر الصغير قرب الحديقة. يقول: «صباح الخير. هل يمكنني الحصول على بعض السكر، من فضلك؟» يعطيه البائع كيس سكر. يدفع آدم ويعود للبيت.',
        ),
        EnglishA1StoryPage(
          'Back at home, the family mixes the ingredients carefully. His sister wants to put three red strawberries on top. Their mother wants one little candle. Adam draws a birthday card with flowers. Soon the kitchen smells sweet and warm.',
          'عند عودته تمزج العائلة المكونات بعناية. تريد أخته وضع ثلاث حبات فراولة حمراء فوق الكعكة. وتريد أمه شمعة صغيرة. يرسم آدم بطاقة عيد ميلاد مزينة بالزهور. بعد قليل تفوح رائحة حلوة ودافئة من المطبخ.',
        ),
        EnglishA1StoryPage(
          'On Monday, Grandma opens the door and sees the cake. “What a lovely surprise!” she says. The family sings and laughs together. Grandma reads Adam’s card and gives him a hug. He says, “Happy birthday! We love you!”',
          'يوم الاثنين تفتح الجدة الباب وترى الكعكة. تقول: «يا لها من مفاجأة جميلة!» تغني العائلة وتضحك معًا. تقرأ الجدة بطاقة آدم وتعانقه. يقول: «عيد ميلاد سعيد! نحن نحبك!»',
        ),
      ],
      question: 'Why does Adam make a cake?',
      options: ['For his grandmother’s birthday', 'For school', 'For a football game'], answer: 0,
    ),
    EnglishA1Story(
      id: 'en_u3_star', title: 'The Door with the Gold Star',
      titleAr: 'الباب ذو النجمة الذهبية', scene: 4,
      pages: [
        EnglishA1StoryPage(
          'Omar wants to buy a little guitar for his brother. His friend Eva knows a music shop in the city. She draws a simple map on a piece of paper. “Go straight from the park and turn left at the bakery,” she says. Omar thanks her.',
          'يريد عمر شراء غيتار صغير لأخيه. تعرف صديقته إيفا متجر موسيقى في المدينة. ترسم له خريطة بسيطة على ورقة. تقول: «امشِ مستقيمًا من الحديقة ثم انعطف يسارًا عند المخبز». يشكرها عمر.',
        ),
        EnglishA1StoryPage(
          'Omar walks past a café and sees a red door. “Is this the shop?” he thinks. He opens the door and smells fresh bread. It is a bakery, not a music shop! The baker is friendly and points to a blue building farther down the street.',
          'يمشي عمر بجانب مقهى ويرى بابًا أحمر. يفكر: «هل هذا المتجر؟» يفتح الباب ويشم رائحة خبز طازج. إنه مخبز وليس متجر موسيقى! يشير الخباز بلطف إلى مبنى أزرق أبعد قليلًا في الشارع.',
        ),
        EnglishA1StoryPage(
          'At the next corner, Omar sees a blue door with a gold star. Music comes from inside. He goes in and sees guitars, pianos and little drums. A shopkeeper asks, “Can I help you?” Omar says, “Yes, please. I want a small guitar.”',
          'عند الزاوية التالية يرى عمر بابًا أزرق عليه نجمة ذهبية. يسمع موسيقى من الداخل. يدخل ويرى غيتارات وبيانو وطبولًا صغيرة. يسأله البائع: «هل يمكنني مساعدتك؟» يقول عمر: «نعم من فضلك. أريد غيتارًا صغيرًا».',
        ),
        EnglishA1StoryPage(
          'The shopkeeper shows him a beautiful brown guitar. Omar likes it, and the price is good. He buys it and walks home, holding the box carefully. His brother opens the gift and plays one happy note. Omar smiles: the little adventure is a success.',
          'يعرض عليه البائع غيتارًا بنيًا جميلًا. يعجب عمر به وسعره مناسب. يشتريه ويعود للمنزل حاملًا الصندوق بحذر. يفتح أخوه الهدية ويعزف نغمة سعيدة. يبتسم عمر: لقد نجحت مغامرته الصغيرة.',
        ),
      ],
      question: 'What does Omar buy?',
      options: ['A guitar', 'A book', 'A hat'], answer: 0,
    ),
    EnglishA1Story(
      id: 'en_u3_garden', title: 'The Lights in Grandma’s Garden',
      titleAr: 'أضواء حديقة الجدة', scene: 5,
      pages: [
        EnglishA1StoryPage(
          'Nina visits her grandmother in a quiet little town. Grandma has a garden full of roses, trees and colorful flowers. Nina helps give water to the plants in the afternoon. Before dinner, Grandma says, “I have a surprise for you tonight.”',
          'تزور نينا جدتها في بلدة صغيرة هادئة. لدى الجدة حديقة مليئة بالورود والأشجار والزهور الملونة. تساعد نينا في سقي النباتات بعد الظهر. قبل العشاء تقول الجدة: «عندي مفاجأة لك هذه الليلة».',
        ),
        EnglishA1StoryPage(
          'After dinner, Grandma gives Nina a small lantern. They walk slowly to the garden gate. The sky is dark, and the moon is bright. Nina hears the sound of water from the fountain. Suddenly, little golden lights appear near a tree.',
          'بعد العشاء تعطي الجدة نينا فانوسًا صغيرًا. تمشيان ببطء نحو بوابة الحديقة. السماء مظلمة والقمر مشرق. تسمع نينا صوت الماء من النافورة. فجأة تظهر أضواء ذهبية صغيرة قرب شجرة.',
        ),
        EnglishA1StoryPage(
          '“Are those tiny stars?” Nina asks. Grandma laughs softly. “No, they are fireflies! They are little insects that make light.” Nina watches the fireflies move above the flowers. They look like tiny lanterns in the air. She has never seen anything like this.',
          'تسأل نينا: «هل هذه نجوم صغيرة؟» تضحك الجدة بهدوء. «لا، إنها يراعات! حشرات صغيرة تصدر الضوء». تراقب نينا اليراعات وهي تتحرك فوق الزهور. تبدو مثل فوانيس صغيرة في الهواء. لم ترَ شيئًا كهذا من قبل.',
        ),
        EnglishA1StoryPage(
          'Grandma and Nina sit on a bench and watch the beautiful lights. Nina says, “This is better than a big city light show!” Grandma puts an arm around her and smiles. Before bed, Nina draws a picture of the garden. She calls it “Our Little Night Sky.”',
          'تجلس الجدة ونينا على مقعد وتراقبان الأضواء الجميلة. تقول نينا: «هذا أجمل من عرض الأضواء في مدينة كبيرة!» تضمها جدتها وتبتسم. قبل النوم ترسم نينا صورة الحديقة وتسميها «سماؤنا الليلية الصغيرة».',
        ),
      ],
      question: 'What are the golden lights?',
      options: ['Fireflies', 'Phones', 'Cars'], answer: 0,
    ),
    EnglishA1Story(
      id: 'en_u3_market', title: 'The Map in the Market',
      titleAr: 'خريطة السوق الغامضة', scene: 8,
      pages: [
        EnglishA1StoryPage(
          'Layla goes to the weekend market with her cousin Sam. They want to buy fruit and a little gift for their aunt. The market is busy and colorful. There are red apples, yellow bananas and beautiful flowers everywhere. Sam finds a folded map near a basket.',
          'تذهب ليلى إلى سوق نهاية الأسبوع مع ابن عمها سام. يريدان شراء فاكهة وهدية صغيرة لعمتهما. السوق مزدحم وملون. توجد تفاحات حمراء وموز أصفر وزهور جميلة في كل مكان. يجد سام خريطة مطوية قرب سلة.',
        ),
        EnglishA1StoryPage(
          'The map shows three places: the bakery, the flower shop and the old fountain. A small blue star is on the fountain. “Maybe this is part of a game,” says Sam. Layla asks the fruit seller about it. He smiles and says, “Follow the map, and you will see!”',
          'تعرض الخريطة ثلاثة أماكن: المخبز ومتجر الزهور والنافورة القديمة. توجد نجمة زرقاء صغيرة على النافورة. يقول سام: «ربما هذه جزء من لعبة». تسأل ليلى بائع الفاكهة عنها. يبتسم ويقول: «اتبعا الخريطة وستعرفان!»',
        ),
        EnglishA1StoryPage(
          'First, they turn right at the bakery. Then they go straight past the flower shop. Soon they see the fountain and a blue box under a bench. Inside the box are many colorful postcards from people around the world. Each postcard says “Hello” in a different language.',
          'أولًا ينعطفان يمينًا عند المخبز. ثم يمشيان مستقيمين بجانب متجر الزهور. بعد قليل يريان النافورة وصندوقًا أزرق تحت مقعد. داخل الصندوق بطاقات بريدية ملونة من أشخاص حول العالم. تقول كل بطاقة «مرحبًا» بلغة مختلفة.',
        ),
        EnglishA1StoryPage(
          'A sign says, “Take one postcard and leave one kind message.” Layla and Sam choose a card with a picture of the sea. They write, “Hello, friend! Have a wonderful day!” Then they put it in the box for someone else to find. Their ordinary shopping trip becomes a happy adventure.',
          'تقول لافتة: «خذ بطاقة واترك رسالة لطيفة». تختار ليلى وسام بطاقة عليها صورة البحر. يكتبان: «مرحبًا أيها الصديق! أتمنى لك يومًا رائعًا!» ثم يضعانها في الصندوق ليجدها شخص آخر. تتحول رحلة التسوق العادية إلى مغامرة سعيدة.',
        ),
      ],
      question: 'What is inside the blue box?',
      options: ['Postcards', 'Coins', 'Shoes'], answer: 0,
    ),
  ];

  static EnglishA1Story forLesson(int unit, int lesson) {
    if (unit < 1 || unit > 3 || lesson < 1 || lesson > 12) {
      throw RangeError('Unknown English A1 story lesson');
    }
    return stories[(unit - 1) * 3 + ((lesson - 1) ~/ 4)];
  }

  static List<EnglishA1Story> forUnit(int unit) {
    if (unit < 1 || unit > 3) throw RangeError('Unknown unit');
    return stories.skip((unit - 1) * 3).take(3).toList(growable: false);
  }
}
