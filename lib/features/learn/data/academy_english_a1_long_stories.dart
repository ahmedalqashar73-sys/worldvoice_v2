class EnglishA1StoryParagraph {
  const EnglishA1StoryParagraph(this.english, this.arabic);
  final String english;
  final String arabic;
}

class EnglishA1StoryChapter {
  const EnglishA1StoryChapter(this.title, this.titleArabic, this.paragraphs);
  final String title;
  final String titleArabic;
  final List<EnglishA1StoryParagraph> paragraphs;
}

class EnglishA1LongStory {
  const EnglishA1LongStory({
    required this.id, required this.unit, required this.title,
    required this.titleArabic, required this.scene, required this.chapters,
  });
  final String id;
  final int unit;
  final String title;
  final String titleArabic;
  final int scene;
  final List<EnglishA1StoryChapter> chapters;
}

abstract final class EnglishA1StorySyllabus {
  /// 9 major stories, 3 per unit, and 4 consecutive integrated lesson
  /// chapters per story. Each lesson chapter contains three authored paragraphs.
  static const stories = <EnglishA1LongStory>[
    EnglishA1LongStory(
      id: "the_lost_notebook", unit: 1,
      title: "The Lost Notebook", titleArabic: "الدفتر المفقود",
      scene: 0,
      chapters: [
        EnglishA1StoryChapter(
          "A Blue Surprise", "مفاجأة زرقاء",
          [EnglishA1StoryParagraph("Sara loves her blue notebook. She writes a new English word in it every morning before school.", "تحب سارة دفترها الأزرق. تكتب فيه كلمة إنجليزية جديدة كل صباح قبل المدرسة."),
          EnglishA1StoryParagraph("Today, Sara opens her school bag. The notebook is not there, and she feels very worried.", "اليوم تفتح سارة حقيبتها المدرسية. لا تجد دفترها وتشعر بقلق شديد."),
          EnglishA1StoryParagraph("Her friend Tom sees her face. “What is wrong?” he asks. “My notebook is lost,” says Sara.", "يرى صديقها توم ملامح وجهها. يسألها: «ما المشكلة؟» فتقول: «دفترِي مفقود».")],
        ),
        EnglishA1StoryChapter(
          "A Small Clue", "دليل صغير",
          [EnglishA1StoryParagraph("Tom says, “Do not worry. We can look together.” They walk back to their classroom.", "يقول توم: «لا تقلقي. يمكننا البحث معًا». ويعودان إلى فصلهما الدراسي."),
          EnglishA1StoryParagraph("There is a little blue ribbon on Sara's desk. It belongs to her notebook, but the notebook is gone.", "يوجد شريط أزرق صغير على مكتب سارة. إنه يخص دفترها، لكن الدفتر غير موجود."),
          EnglishA1StoryParagraph("Sara remembers reading near the window. She and Tom go to the window and look under the chairs.", "تتذكر سارة أنها كانت تقرأ قرب النافذة. تذهب مع توم وينظران تحت الكراسي.")],
        ),
        EnglishA1StoryChapter(
          "Behind the Books", "خلف الكتب",
          [EnglishA1StoryParagraph("The library is quiet. A teacher is putting books on a high shelf, and Sara asks for help.", "المكتبة هادئة. ترتب معلمة كتبًا على رف عالٍ، وتطلب سارة المساعدة."),
          EnglishA1StoryParagraph("“Is your notebook small and blue?” the teacher asks. Sara smiles and says, “Yes, it is!”", "تسأل المعلمة: «هل دفترِك صغير وأزرق؟» فتبتسم سارة وتقول: «نعم!»"),
          EnglishA1StoryParagraph("The teacher points to a table behind the books. The notebook is there, next to a paper star.", "تشير المعلمة إلى طاولة خلف الكتب. تجد سارة دفترها بجانب نجمة ورقية.")],
        ),
        EnglishA1StoryChapter(
          "A Friend's Gift", "هدية صديق",
          [EnglishA1StoryParagraph("Tom picks up the paper star. “I made this for you,” he says. Sara is very happy.", "يلتقط توم النجمة الورقية ويقول: «صنعتها من أجلك». تشعر سارة بسعادة كبيرة."),
          EnglishA1StoryParagraph("Sara opens her notebook and writes two words: “Thank you.” Then she draws a happy face.", "تفتح سارة دفترها وتكتب كلمتين: «شكرًا لك». ثم ترسم وجهًا مبتسمًا."),
          EnglishA1StoryParagraph("On the last page, she writes, “A good friend can help you find more than a notebook.”", "وفي الصفحة الأخيرة تكتب: «الصديق الجيد يساعدك على العثور على أكثر من مجرد دفتر».")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "library_secret", unit: 1,
      title: "The Secret Library Message", titleArabic: "الرسالة السرية في المكتبة",
      scene: 1,
      chapters: [
        EnglishA1StoryChapter(
          "A Strange Note", "ورقة غريبة",
          [EnglishA1StoryParagraph("Maya and Leo visit the old library after school. The library has tall windows and many colorful books.", "تزور مايا وليو المكتبة القديمة بعد المدرسة. للمكتبة نوافذ عالية وكتب ملونة كثيرة."),
          EnglishA1StoryParagraph("Maya finds a small note inside a green book. The note says, “Find the picture on page ten.”", "تجد مايا ورقة صغيرة داخل كتاب أخضر. تقول الورقة: «ابحثي عن الصورة في الصفحة العاشرة»."),
          EnglishA1StoryParagraph("“Is this a game?” asks Leo. Maya laughs. “Maybe! Let us open the book.”", "يسأل ليو: «هل هذه لعبة؟» فتضحك مايا وتقول: «ربما! لنفتح الكتاب».")],
        ),
        EnglishA1StoryChapter(
          "The Green Tree", "الشجرة الخضراء",
          [EnglishA1StoryParagraph("On page ten they see a picture of a big tree. There are three blue birds above it.", "في الصفحة العاشرة يريان صورة شجرة كبيرة، وفوقها ثلاثة طيور زرقاء."),
          EnglishA1StoryParagraph("Leo knows the tree. “It is near our school,” he says, “but why is it in this book?”", "يعرف ليو الشجرة. يقول: «إنها قرب مدرستنا، لكن لماذا هي في هذا الكتاب؟»"),
          EnglishA1StoryParagraph("Maya turns the page. She finds another note with one word: “Yesterday.”", "تقلب مايا الصفحة وتعثر على ورقة أخرى تحمل كلمة واحدة: «أمس».")],
        ),
        EnglishA1StoryChapter(
          "The Old Photograph", "الصورة القديمة",
          [EnglishA1StoryParagraph("A kind librarian sees the children reading. “That book is about our town,” she says.", "ترى أمينة المكتبة الطيبة الطفلين يقرآن، فتقول: «هذا الكتاب عن بلدتنا»."),
          EnglishA1StoryParagraph("She shows them an old photograph. Their green tree was very small many years ago.", "تريهما صورة قديمة. كانت شجرتهما الخضراء صغيرة جدًا منذ سنوات طويلة."),
          EnglishA1StoryParagraph("“The notes are from students,” she explains. “They write about places they love.”", "تشرح: «الأوراق من طلاب. يكتبون عن الأماكن التي يحبونها».")],
        ),
        EnglishA1StoryChapter(
          "Our Own Message", "رسالتنا الخاصة",
          [EnglishA1StoryParagraph("Maya gets a pencil and a fresh piece of paper. She writes, “Hello, future reader!”", "تأخذ مايا قلم رصاص وورقة جديدة وتكتب: «مرحبًا يا قارئ المستقبل!»"),
          EnglishA1StoryParagraph("Leo adds, “Our town is full of stories. Look for the green tree!”", "ويضيف ليو: «بلدتنا مليئة بالقصص. ابحث عن الشجرة الخضراء!»"),
          EnglishA1StoryParagraph("They leave their note with the librarian and walk home smiling. A new mystery can begin tomorrow.", "يتركان الورقة عند أمينة المكتبة ويعودان إلى المنزل مبتسمين. وقد يبدأ لغز جديد غدًا.")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "invitation", unit: 1,
      title: "The Unexpected Invitation", titleArabic: "الدعوة المفاجئة",
      scene: 6,
      chapters: [
        EnglishA1StoryChapter(
          "An Envelope at School", "ظرف في المدرسة",
          [EnglishA1StoryParagraph("Nora arrives at school and finds a yellow envelope on her chair. There is no name on it.", "تصل نورا إلى المدرسة وتجد ظرفًا أصفر على كرسيها. لا يوجد اسم على الظرف."),
          EnglishA1StoryParagraph("Inside, she reads, “Hello, friend! Come to the garden after class.” She does not know who wrote it.", "تقرأ في داخله: «مرحبًا يا صديقتي! تعالي إلى الحديقة بعد الدرس». لا تعرف من كتب الرسالة."),
          EnglishA1StoryParagraph("Nora asks her friend Sam, “Is this from you?” He shakes his head and says, “No, but I can help.”", "تسأل صديقها سام: «هل هذه منك؟» فيهز رأسه ويقول: «لا، لكن يمكنني المساعدة».")],
        ),
        EnglishA1StoryChapter(
          "A Trail of Stars", "طريق من النجوم",
          [EnglishA1StoryParagraph("After class, Nora and Sam see three small paper stars near the school door.", "بعد الدرس، ترى نورا وسام ثلاث نجوم ورقية صغيرة قرب باب المدرسة."),
          EnglishA1StoryParagraph("One star says, “Go left.” Another says, “Look near the big tree.”", "تقول إحداها: «اتجه يسارًا». وتقول أخرى: «انظر قرب الشجرة الكبيرة»."),
          EnglishA1StoryParagraph("The children follow the stars carefully. They hear laughter behind the garden wall.", "يتبع الطفلان النجوم بحذر، ويسمعان ضحكات خلف سور الحديقة.")],
        ),
        EnglishA1StoryChapter(
          "Friends in the Garden", "أصدقاء في الحديقة",
          [EnglishA1StoryParagraph("The garden gate opens. Their friends are waiting with colorful paper flowers and a big sign.", "تفتح بوابة الحديقة. ينتظر أصدقاؤهما بزهور ورقية ملونة ولافتة كبيرة."),
          EnglishA1StoryParagraph("The sign says, “Welcome, Nora!” Her new classmates smile and say hello together.", "تقول اللافتة: «أهلًا يا نورا!» ويبتسم زملاؤها الجدد ويحيونها معًا."),
          EnglishA1StoryParagraph("Nora feels shy at first. Then she smiles and says, “Nice to meet you all!”", "تشعر نورا بالخجل أولًا، ثم تبتسم وتقول: «تشرفت بمعرفتكم جميعًا!»")],
        ),
        EnglishA1StoryChapter(
          "A New Beginning", "بداية جديدة",
          [EnglishA1StoryParagraph("Sam gives Nora a small notebook. “This is for our English words,” he says.", "يعطي سام نورا دفترًا صغيرًا ويقول: «هذا لكلماتنا الإنجليزية»."),
          EnglishA1StoryParagraph("Everyone writes a friendly word inside it: hello, friend, happy, and together.", "يكتب الجميع كلمة ودية فيه: مرحبًا، صديق، سعيد، ومعًا."),
          EnglishA1StoryParagraph("On the way home, Nora says, “Today was my first happy day in a new school.”", "وفي طريق العودة تقول نورا: «كان اليوم أول يوم سعيد لي في المدرسة الجديدة».")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "breakfast_mystery", unit: 2,
      title: "The Breakfast Mystery", titleArabic: "لغز الفطور",
      scene: 2,
      chapters: [
        EnglishA1StoryChapter(
          "Where Is My Breakfast?", "أين فطوري؟",
          [EnglishA1StoryParagraph("Lina wakes up at seven every morning. Today she is hungry and goes straight to the kitchen.", "تستيقظ لينا الساعة السابعة كل صباح. واليوم تشعر بالجوع وتتجه مباشرة إلى المطبخ."),
          EnglishA1StoryParagraph("There is milk on the table, but there is no bread. “That is strange,” she says.", "يوجد حليب على الطاولة، لكن لا يوجد خبز. تقول: «هذا غريب»."),
          EnglishA1StoryParagraph("Her little cat Mimi sits under a chair and looks at a paper bag. Lina starts to smile.", "تجلس قطتها الصغيرة ميمي تحت كرسي وتنظر إلى كيس ورقي. تبدأ لينا بالابتسام.")],
        ),
        EnglishA1StoryChapter(
          "The Wrong Bag", "الكيس الخطأ",
          [EnglishA1StoryParagraph("Lina opens the bag near Mimi. Inside she finds one apple, a pencil, and a yellow ribbon.", "تفتح لينا الكيس قرب ميمي، فتجد تفاحة وقلمًا وشريطًا أصفر."),
          EnglishA1StoryParagraph("“This is not my breakfast,” she says. Her brother walks into the kitchen.", "تقول: «هذا ليس فطوري». ويدخل أخوها إلى المطبخ."),
          EnglishA1StoryParagraph("He laughs. “That is my school bag! I put it here before breakfast.”", "يضحك ويقول: «هذه حقيبتي المدرسية! وضعتها هنا قبل الفطور».")],
        ),
        EnglishA1StoryChapter(
          "A Knock at the Door", "طرقة على الباب",
          [EnglishA1StoryParagraph("There is a knock at the front door. Lina opens it and sees her father with a shopping bag.", "تُسمع طرقة على الباب. تفتحه لينا وترى والدها يحمل كيس تسوق."),
          EnglishA1StoryParagraph("“Good morning!” he says. “I went to the bakery before work.”", "يقول: «صباح الخير! ذهبت إلى المخبز قبل العمل»."),
          EnglishA1StoryParagraph("He takes out warm bread and a small box of cheese. The kitchen smells wonderful.", "يخرج خبزًا دافئًا وعلبة جبن صغيرة. تمتلئ رائحة المطبخ بالشهية.")],
        ),
        EnglishA1StoryChapter(
          "Breakfast Together", "فطور معًا",
          [EnglishA1StoryParagraph("Lina puts plates on the table. Her brother brings water and their mother makes tea.", "تضع لينا الأطباق على الطاولة. يحضر أخوها الماء وتعد أمها الشاي."),
          EnglishA1StoryParagraph("Mimi sits beside the table, but she does not touch the food this time.", "تجلس ميمي بجانب الطاولة لكنها لا تلمس الطعام هذه المرة."),
          EnglishA1StoryParagraph("The family eats together. Lina says, “The best breakfast is breakfast with you!”", "تأكل العائلة معًا. وتقول لينا: «أفضل فطور هو الفطور معكم!»")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "rainy_bus", unit: 2,
      title: "The Rainy Bus Ride", titleArabic: "رحلة الحافلة الممطرة",
      scene: 3,
      chapters: [
        EnglishA1StoryChapter(
          "A Cloudy Monday", "اثنين غائم",
          [EnglishA1StoryParagraph("Ben gets up early on Monday and puts his books in his bag. The sky is dark.", "ينهض بن مبكرًا يوم الاثنين ويضع كتبه في حقيبته. السماء مظلمة."),
          EnglishA1StoryParagraph("He checks the weather and sees a picture of rain. “I need an umbrella,” he says.", "يتفقد الطقس ويرى رمز المطر. يقول: «أحتاج إلى مظلة»."),
          EnglishA1StoryParagraph("But his umbrella is not near the door. He runs to catch the bus without it.", "لكن مظلته ليست قرب الباب، فيركض ليلحق بالحافلة من دونها.")],
        ),
        EnglishA1StoryChapter(
          "A Seat by the Window", "مقعد قرب النافذة",
          [EnglishA1StoryParagraph("On the bus, Ben sits next to his friend Noor. She has a big yellow umbrella.", "في الحافلة يجلس بن بجانب صديقته نور، ولديها مظلة صفراء كبيرة."),
          EnglishA1StoryParagraph("“Is it going to rain?” he asks. Noor points to the window. Little drops begin to fall.", "يسأل: «هل ستمطر؟» فتشير نور إلى النافذة. تبدأ قطرات صغيرة بالتساقط."),
          EnglishA1StoryParagraph("The driver says, “Please stay in your seats until the bus stops.” Ben listens carefully.", "يقول السائق: «ابقوا في مقاعدكم حتى تتوقف الحافلة». يستمع بن باهتمام.")],
        ),
        EnglishA1StoryChapter(
          "The Big Splash", "الرشة الكبيرة",
          [EnglishA1StoryParagraph("The bus stops near school. A car passes through a puddle, and water splashes on the road.", "تتوقف الحافلة قرب المدرسة. تمر سيارة عبر بركة ماء فترش الماء على الطريق."),
          EnglishA1StoryParagraph("Ben jumps back. Noor opens her big umbrella, and they wait for the car to leave.", "يقفز بن إلى الخلف. تفتح نور مظلتها الكبيرة وينتظران مرور السيارة."),
          EnglishA1StoryParagraph("“That was close!” says Ben. Noor laughs. “Now let us walk together.”", "يقول بن: «كانت قريبة!» فتضحك نور وتقول: «هيا نمشِ معًا».")],
        ),
        EnglishA1StoryChapter(
          "A Small Thank You", "شكر صغير",
          [EnglishA1StoryParagraph("At school, Ben helps Noor carry her heavy books into class.", "في المدرسة يساعد بن نور في حمل كتبها الثقيلة إلى الصف."),
          EnglishA1StoryParagraph("“Thank you for the umbrella,” he says. “Thank you for the help,” Noor answers.", "يقول: «شكرًا على المظلة». فتجيب نور: «شكرًا على المساعدة»."),
          EnglishA1StoryParagraph("They plan to bring two umbrellas tomorrow. Being prepared is a good idea.", "يقرران إحضار مظلتين غدًا. الاستعداد مسبقًا فكرة جيدة.")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "little_lantern", unit: 2,
      title: "The Little Lantern", titleArabic: "الفانوس الصغير",
      scene: 7,
      chapters: [
        EnglishA1StoryChapter(
          "Evening at Grandma's", "مساء عند الجدة",
          [EnglishA1StoryParagraph("After dinner, Ella visits her grandmother. Grandma lives in a small house near a quiet park.", "بعد العشاء تزور إيلا جدتها. تعيش الجدة في بيت صغير قرب حديقة هادئة."),
          EnglishA1StoryParagraph("Grandma has a little lantern on the table. “We can use this tonight,” she says.", "لدى الجدة فانوس صغير على الطاولة. تقول: «سنستخدم هذا الليلة»."),
          EnglishA1StoryParagraph("Ella wants to know why. Grandma only smiles and puts on her warm coat.", "تريد إيلا معرفة السبب. لكن جدتها تبتسم فقط وترتدي معطفها الدافئ.")],
        ),
        EnglishA1StoryChapter(
          "A Walk After Sunset", "نزهة بعد الغروب",
          [EnglishA1StoryParagraph("They walk slowly along the path. The air is cool and the trees are quiet.", "تمشيان ببطء على الممر. الهواء بارد والأشجار ساكنة."),
          EnglishA1StoryParagraph("Ella hears a small sound behind a bench. It sounds like a tiny animal.", "تسمع إيلا صوتًا صغيرًا خلف مقعد. يبدو كصوت حيوان صغير."),
          EnglishA1StoryParagraph("Grandma lifts the lantern. A little puppy is sitting there alone.", "ترفع الجدة الفانوس. يوجد جرو صغير يجلس هناك وحده.")],
        ),
        EnglishA1StoryChapter(
          "A Missing Friend", "صديق مفقود",
          [EnglishA1StoryParagraph("The puppy has a red ribbon with a name: Sunny. Ella reads it aloud.", "يرتدي الجرو شريطًا أحمر يحمل اسم «ساني». تقرأ إيلا الاسم بصوت عالٍ."),
          EnglishA1StoryParagraph("They walk to the park gate, where a boy is looking for his dog.", "تذهبان إلى بوابة الحديقة حيث يبحث فتى عن كلبه."),
          EnglishA1StoryParagraph("“Sunny!” he calls. The puppy runs to the boy and jumps with happiness.", "ينادي: «ساني!» فيركض الجرو نحوه ويقفز فرحًا.")],
        ),
        EnglishA1StoryChapter(
          "Light for Someone Else", "نور لشخص آخر",
          [EnglishA1StoryParagraph("The boy thanks Ella and Grandma many times. He says Sunny is his best friend.", "يشكر الفتى إيلا وجدتها مرات عديدة. ويقول إن ساني أفضل أصدقائه."),
          EnglishA1StoryParagraph("Grandma says, “Sometimes a small light helps us do a big thing.”", "تقول الجدة: «أحيانًا يساعدنا ضوء صغير على فعل شيء كبير»."),
          EnglishA1StoryParagraph("Ella takes the lantern home and smiles. She will remember this evening for a long time.", "تحمل إيلا الفانوس إلى المنزل وتبتسم. ستتذكر هذا المساء طويلًا.")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "door_with_star", unit: 3,
      title: "The Door with a Star", titleArabic: "الباب ذو النجمة",
      scene: 4,
      chapters: [
        EnglishA1StoryChapter(
          "A Strange Map", "خريطة غريبة",
          [EnglishA1StoryParagraph("Omar gets a small map from his friend Eva. “This will help you find the music shop,” she says.", "يحصل عمر على خريطة صغيرة من صديقته إيفا. تقول: «ستساعدك على إيجاد متجر الموسيقى»."),
          EnglishA1StoryParagraph("Omar loves music, but he does not know this part of the city.", "يحب عمر الموسيقى، لكنه لا يعرف هذا الجزء من المدينة."),
          EnglishA1StoryParagraph("He reads the map carefully. It says, “Go straight, then turn left near the park.”", "يقرأ الخريطة بعناية. تقول: «امشِ مستقيمًا ثم انعطف يسارًا قرب الحديقة».")],
        ),
        EnglishA1StoryChapter(
          "The Red Door", "الباب الأحمر",
          [EnglishA1StoryParagraph("Omar walks past a café and sees a red door. He thinks it is the music shop.", "يمشي عمر بجانب مقهى ويرى بابًا أحمر. يظن أنه متجر الموسيقى."),
          EnglishA1StoryParagraph("He opens the door and smells fresh bread. It is a bakery, not a music shop.", "يفتح الباب وتصل إليه رائحة خبز طازج. إنه مخبز وليس متجر موسيقى."),
          EnglishA1StoryParagraph("A kind baker says, “The shop you want is next to the museum. Look for a gold star.”", "يقول الخباز الطيب: «المتجر الذي تريده بجانب المتحف. ابحث عن نجمة ذهبية».")],
        ),
        EnglishA1StoryChapter(
          "Music in the Street", "موسيقى في الشارع",
          [EnglishA1StoryParagraph("Omar crosses the street carefully and sees a large museum.", "يعبر عمر الشارع بحذر ويرى متحفًا كبيرًا."),
          EnglishA1StoryParagraph("There is a blue door next to it. A golden star shines above the door.", "بجانبه باب أزرق وفوقه نجمة ذهبية لامعة."),
          EnglishA1StoryParagraph("From inside, Omar hears a soft piano song. “This is the place!” he says.", "يسمع عمر لحن بيانو هادئًا من الداخل. يقول: «هذا هو المكان!»")],
        ),
        EnglishA1StoryChapter(
          "A New Song", "أغنية جديدة",
          [EnglishA1StoryParagraph("The shop owner lets Omar try a small keyboard. Omar plays three notes.", "يسمح صاحب المتجر لعمر بتجربة لوحة مفاتيح موسيقية صغيرة. يعزف عمر ثلاث نغمات."),
          EnglishA1StoryParagraph("“You have a good ear,” the owner says. Omar feels happy and thanks him.", "يقول صاحب المتجر: «لديك أذن موسيقية جيدة». يشعر عمر بالسعادة ويشكره."),
          EnglishA1StoryParagraph("On his way home, Omar writes a new song about a star and a blue door.", "في طريق العودة يكتب عمر أغنية جديدة عن نجمة وباب أزرق.")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "night_garden", unit: 3,
      title: "The Night Garden", titleArabic: "حديقة الليل",
      scene: 5,
      chapters: [
        EnglishA1StoryChapter(
          "The Old Garden", "الحديقة القديمة",
          [EnglishA1StoryParagraph("Nina visits Grandma in a town with small white houses and a quiet street.", "تزور نينا جدتها في بلدة ذات منازل بيضاء صغيرة وشارع هادئ."),
          EnglishA1StoryParagraph("Grandma says the garden looks different after sunset. Nina wants to see it.", "تقول الجدة إن الحديقة تبدو مختلفة بعد الغروب. تريد نينا رؤيتها."),
          EnglishA1StoryParagraph("They take a lantern and open the wooden gate. The night air smells of flowers.", "تحملان فانوسًا وتفتحان البوابة الخشبية. تفوح من هواء الليل رائحة الزهور.")],
        ),
        EnglishA1StoryChapter(
          "Tiny Golden Lights", "أضواء ذهبية صغيرة",
          [EnglishA1StoryParagraph("Nina sees tiny lights moving between the flowers. They look like little stars.", "ترى نينا أضواء صغيرة تتحرك بين الزهور. تبدو كنجوم صغيرة."),
          EnglishA1StoryParagraph("“Are these stars?” she asks. Grandma smiles. “No, they are fireflies.”", "تسأل: «هل هذه نجوم؟» فتبتسم الجدة: «لا، إنها يراعات»."),
          EnglishA1StoryParagraph("One firefly comes close and then flies away. Nina follows it with her eyes.", "تقترب يراعة ثم تطير بعيدًا. تتبعها نينا بعينيها.")],
        ),
        EnglishA1StoryChapter(
          "The Quiet Path", "الممر الهادئ",
          [EnglishA1StoryParagraph("Grandma and Nina walk slowly along a narrow path beside the trees.", "تسير الجدة ونينا ببطء على ممر ضيق بجانب الأشجار."),
          EnglishA1StoryParagraph("They hear water from a little fountain. The sound is soft and peaceful.", "تسمعان صوت الماء من نافورة صغيرة. الصوت هادئ ومريح."),
          EnglishA1StoryParagraph("Grandma asks Nina to sit and listen. Nina hears birds and the evening wind.", "تطلب الجدة من نينا الجلوس والاستماع. تسمع نينا الطيور ونسيم المساء.")],
        ),
        EnglishA1StoryChapter(
          "A Promise to Return", "وعد بالعودة",
          [EnglishA1StoryParagraph("Nina draws the garden in her notebook: flowers, a lantern, and many small lights.", "ترسم نينا الحديقة في دفترها: زهورًا وفانوسًا وأضواء صغيرة كثيرة."),
          EnglishA1StoryParagraph("She writes, “My favorite place is Grandma's garden at night.”", "تكتب: «مكاني المفضل هو حديقة جدتي ليلًا»."),
          EnglishA1StoryParagraph("Before bed, she says, “Can we come back tomorrow?” Grandma answers, “Of course!”", "قبل النوم تسأل: «هل يمكننا العودة غدًا؟» فتجيب الجدة: «بالطبع!»")],
        ),
      ],
    ),
    EnglishA1LongStory(
      id: "market_mystery", unit: 3,
      title: "The Market Mystery", titleArabic: "لغز السوق",
      scene: 8,
      chapters: [
        EnglishA1StoryChapter(
          "A Missing Basket", "السلة المفقودة",
          [EnglishA1StoryParagraph("Mila visits the town market with her father. They want to buy fruit and flowers.", "تزور ميلا سوق البلدة مع والدها. يريدان شراء الفاكهة والزهور."),
          EnglishA1StoryParagraph("Mila sees a beautiful little basket beside the flower shop. It has a green ribbon.", "ترى ميلا سلة صغيرة جميلة بجانب متجر الزهور، وعليها شريط أخضر."),
          EnglishA1StoryParagraph("A woman is worried. “I cannot find my basket,” she says. Mila decides to help.", "تبدو امرأة قلقة وتقول: «لا أجد سلتي». تقرر ميلا المساعدة.")],
        ),
        EnglishA1StoryChapter(
          "Three Friendly Shops", "ثلاثة متاجر ودية",
          [EnglishA1StoryParagraph("First, Mila asks the baker. “Is this basket yours?” He says, “No, sorry.”", "أولًا تسأل الخباز: «هل هذه سلتك؟» فيقول: «لا، آسف»."),
          EnglishA1StoryParagraph("Then she asks a man at the fruit stand. He knows the green ribbon.", "ثم تسأل رجلًا في متجر الفاكهة. يعرف الرجل الشريط الأخضر."),
          EnglishA1StoryParagraph("“I saw it near the old fountain,” he says. Mila and her father thank him.", "يقول: «رأيته قرب النافورة القديمة». تشكره ميلا ووالدها.")],
        ),
        EnglishA1StoryChapter(
          "The Fountain Clue", "دليل النافورة",
          [EnglishA1StoryParagraph("Near the fountain, Mila finds a card with a picture of a sunflower.", "قرب النافورة تعثر ميلا على بطاقة عليها صورة زهرة عباد الشمس."),
          EnglishA1StoryParagraph("She remembers a flower shop on the other side of the market.", "تتذكر متجر زهور في الجانب الآخر من السوق."),
          EnglishA1StoryParagraph("The shop owner smiles when she sees the card. “That belongs to my sister!”", "تبتسم صاحبة المتجر عند رؤية البطاقة وتقول: «هذه تخص أختي!»")],
        ),
        EnglishA1StoryChapter(
          "A Colorful Thank You", "شكر بالألوان",
          [EnglishA1StoryParagraph("The owner's sister arrives and finds her basket. She is very happy.", "تصل أخت صاحبة المتجر وتجد سلتها، فتشعر بسعادة كبيرة."),
          EnglishA1StoryParagraph("She gives Mila a single sunflower. “Thank you for helping me,” she says.", "تعطي ميلا زهرة عباد شمس واحدة وتقول: «شكرًا لمساعدتك»."),
          EnglishA1StoryParagraph("Mila and her father walk home with fruit, flowers, and a new story to tell.", "تعود ميلا ووالدها إلى البيت ومعهما فاكهة وزهور وقصة جديدة يرويانها.")],
        ),
      ],
    ),
  ];

  static EnglishA1LongStory storyFor(int unit, int lessonNumber) {
    if (unit < 1 || unit > 3 || lessonNumber < 1 || lessonNumber > 12) {
      throw RangeError('Unknown English A1 unit or lesson');
    }
    return stories[(unit - 1) * 3 + (lessonNumber - 1) ~/ 4];
  }

  static EnglishA1StoryChapter chapterFor(int unit, int lessonNumber) =>
      storyFor(unit, lessonNumber).chapters[(lessonNumber - 1) % 4];
}
