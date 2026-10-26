/// Original first guided A1 lessons for the four current non-English
/// Academy course languages. These are pilots, not 30 finished lessons each.
class AcademyStartWord {
  const AcademyStartWord(this.term, this.arabic, this.phonetic);
  final String term;
  final String arabic;
  /// IPA (Spanish/French), Pinyin (Chinese), or Romanization (Korean).
  final String phonetic;
}

class AcademyStartQuestion {
  const AcademyStartQuestion(this.question, this.options, this.answer);
  final String question;
  final List<String> options;
  final int answer;
}

class AcademyGuidedStart {
  const AcademyGuidedStart({
    required this.code, required this.name, required this.title,
    required this.titleArabic, required this.grammar,
    required this.grammarArabic, required this.grammarEnglish,
    required this.dialogue, required this.story,
    required this.storyArabic, required this.words, required this.checks,
  });
  final String code;
  final String name;
  final String title;
  final String titleArabic;
  final String grammar;
  final String grammarArabic;
  final String grammarEnglish;
  final String dialogue;
  final List<String> story;
  final List<String> storyArabic;
  final List<AcademyStartWord> words;
  final List<AcademyStartQuestion> checks;
}

abstract final class AcademyMultilingualStarters {
  static const lessons = <String, AcademyGuidedStart>{
    'es': AcademyGuidedStart(
      code: "es", name: "Español",
      title: "¡Hola! Me llamo Ana", titleArabic: "التحيات والتعارف بالإسبانية",
      grammar: "Me llamo Ana. Soy estudiante. ¿Cómo te llamas?", grammarArabic: "استخدم Me llamo لتقول اسمك، وSoy للتعريف بنفسك. عند السؤال عن الاسم قل ¿Cómo te llamas?",
      grammarEnglish: "Me llamo introduces your name. Soy says who you are. Ask a person's name with ¿Cómo te llamas?",
      dialogue: "Ana: ¡Hola! Me llamo Ana. ¿Cómo te llamas?\nLuis: ¡Hola! Me llamo Luis. Mucho gusto.\nAna: ¡Mucho gusto!",
      story: ["Ana llega a una biblioteca pequeña. Es su primer día en la ciudad. Ve un libro azul cerca de la ventana y sonríe. Allí conoce a Luis, un estudiante muy amable.","Luis dice: «¡Hola! ¿Cómo te llamas?». Ana responde: «Me llamo Ana». Los dos buscan libros de idiomas y deciden estudiar español juntos."], storyArabic: ["تصل آنا إلى مكتبة صغيرة في يومها الأول بالمدينة. ترى كتابًا أزرق قرب النافذة وتبتسم، وتلتقي لويس وهو طالب لطيف.","يسأل لويس: مرحبًا، ما اسمك؟ فتجيب آنا: اسمي آنا. يبحث الاثنان عن كتب اللغات ويقرران دراسة الإسبانية معًا."],
      words: [AcademyStartWord("hola", "مرحبًا", "/ˈola/"),
        AcademyStartWord("adiós", "وداعًا", "/aˈðjos/"),
        AcademyStartWord("gracias", "شكرًا", "/ˈɡɾasjas/"),
        AcademyStartWord("por favor", "من فضلك", "/poɾ faˈβoɾ/"),
        AcademyStartWord("nombre", "اسم", "/ˈnombɾe/"),
        AcademyStartWord("me llamo", "اسمي", "/me ˈʝamo/"),
        AcademyStartWord("soy", "أنا", "/soi/"),
        AcademyStartWord("estudiante", "طالب", "/estuˈðjante/"),
        AcademyStartWord("amigo", "صديق", "/aˈmiɡo/"),
        AcademyStartWord("amiga", "صديقة", "/aˈmiɡa/"),
        AcademyStartWord("mucho gusto", "تشرفت بمعرفتك", "/ˈmutʃo ˈɡusto/"),
        AcademyStartWord("buenos días", "صباح الخير", "/ˈbwenos ˈdias/"),
        AcademyStartWord("buenas noches", "مساء الخير", "/ˈbwenas ˈnotʃes/"),
        AcademyStartWord("sí", "نعم", "/si/"),
        AcademyStartWord("no", "لا", "/no/"),
        AcademyStartWord("libro", "كتاب", "/ˈliβɾo/"),
        AcademyStartWord("biblioteca", "مكتبة", "/biβljoˈteka/"),
        AcademyStartWord("ciudad", "مدينة", "/sjuˈðað/"),
        AcademyStartWord("idioma", "لغة", "/iˈðjoma/"),
        AcademyStartWord("juntos", "معًا", "/ˈxuntos/")],
      checks: [AcademyStartQuestion("¿Cómo te llamas?", ["Me llamo Ana.","Tengo dos libros.","Hasta mañana."], 0),
        AcademyStartQuestion("¿Qué significa «gracias»?", ["مرحبًا","شكرًا","وداعًا"], 1),
        AcademyStartQuestion("¿Dónde conoce Ana a Luis?", ["En la biblioteca.","En el aeropuerto.","En un restaurante."], 0)],
    ),
    'fr': AcademyGuidedStart(
      code: "fr", name: "Français",
      title: "Bonjour ! Je m'appelle Léa", titleArabic: "التحيات والتعارف بالفرنسية",
      grammar: "Je m'appelle Léa. Je suis étudiante. Comment tu t'appelles ?", grammarArabic: "قل Je m'appelle لتقديم اسمك، وJe suis للتعريف بنفسك. عند سؤال شخص عن اسمه استخدم Comment tu t'appelles ?",
      grammarEnglish: "Je m'appelle gives your name; je suis describes who you are. Ask a person's name with Comment tu t'appelles ?",
      dialogue: "Léa : Bonjour ! Je m'appelle Léa. Et toi ?\nPaul : Salut ! Je m'appelle Paul. Enchanté !\nLéa : Enchantée !",
      story: ["Léa entre dans une petite librairie après l'école. Elle cherche un livre facile en français. Sur une table, elle trouve un carnet bleu avec un joli dessin.","Paul travaille dans la librairie. Il sourit et dit : « Bonjour ! Je m'appelle Paul. » Léa répond : « Je m'appelle Léa. Enchantée ! » Ils parlent de livres et deviennent amis."], storyArabic: ["تدخل ليا مكتبة صغيرة بعد المدرسة للبحث عن كتاب فرنسي سهل. تجد دفترًا أزرق عليه رسمة جميلة.","يعمل بول في المكتبة، يبتسم ويعرّف نفسه. ترد ليا باسمها ويقولان تشرفنا باللقاء. يتحدثان عن الكتب ويصبحان صديقين."],
      words: [AcademyStartWord("bonjour", "مرحبًا أو صباح الخير", "/bɔ̃.ʒuʁ/"),
        AcademyStartWord("salut", "أهلًا", "/sa.ly/"),
        AcademyStartWord("au revoir", "إلى اللقاء", "/o ʁə.vwaʁ/"),
        AcademyStartWord("merci", "شكرًا", "/mɛʁ.si/"),
        AcademyStartWord("s'il vous plaît", "من فضلك", "/sil vu plɛ/"),
        AcademyStartWord("je", "أنا", "/ʒə/"),
        AcademyStartWord("tu", "أنت", "/ty/"),
        AcademyStartWord("nom", "اسم", "/nɔ̃/"),
        AcademyStartWord("je m'appelle", "اسمي", "/ʒə ma.pɛl/"),
        AcademyStartWord("ami", "صديق", "/a.mi/"),
        AcademyStartWord("amie", "صديقة", "/a.mi/"),
        AcademyStartWord("élève", "تلميذ", "/e.lɛv/"),
        AcademyStartWord("école", "مدرسة", "/e.kɔl/"),
        AcademyStartWord("livre", "كتاب", "/livʁ/"),
        AcademyStartWord("bleu", "أزرق", "/blø/"),
        AcademyStartWord("ville", "مدينة", "/vil/"),
        AcademyStartWord("oui", "نعم", "/wi/"),
        AcademyStartWord("non", "لا", "/nɔ̃/"),
        AcademyStartWord("enchanté", "تشرفت بمعرفتك", "/ɑ̃.ʃɑ̃.te/"),
        AcademyStartWord("ensemble", "معًا", "/ɑ̃.sɑ̃bl/")],
      checks: [AcademyStartQuestion("Comment tu t'appelles ?", ["Je m'appelle Léa.","Merci beaucoup.","Il est midi."], 0),
        AcademyStartQuestion("Que signifie «merci» ?", ["شكرًا","مرحبًا","كتاب"], 0),
        AcademyStartQuestion("Où Léa rencontre-t-elle Paul ?", ["À la librairie.","À la gare.","Au parc."], 0)],
    ),
    'zh': AcademyGuidedStart(
      code: "zh", name: "中文",
      title: "你好！我叫小美", titleArabic: "التحيات والتعارف بالصينية",
      grammar: "你好！我叫小美。你叫什么名字？", grammarArabic: "你好 (nǐ hǎo) للتحية، 我叫 (wǒ jiào) للتعريف باسمك، و你叫什么名字؟ للسؤال عن الاسم.",
      grammarEnglish: "你好 means hello. 我叫 introduces your name. 你叫什么名字？ asks a person's name.",
      dialogue: "小美：你好！我叫小美。你叫什么名字？\n小明：你好！我叫小明。很高兴认识你！\n小美：我也很高兴！",
      story: ["小美今天去图书馆。她想找一本中文书。图书馆很安静，桌子上有一本蓝色的书。她看见一个学生在看书。","学生说：“你好！我叫小明。”小美笑着说：“我叫小美。很高兴认识你！”他们一起学习中文。"], storyArabic: ["تذهب شياو مي اليوم إلى المكتبة للبحث عن كتاب صيني. المكتبة هادئة، وعلى الطاولة كتاب أزرق. ترى طالبًا يقرأ.","يقول الطالب: مرحبًا، اسمي شياو مينغ. تبتسم شياو مي وتعرّف بنفسها. يدرسان الصينية معًا."],
      words: [AcademyStartWord("你好", "مرحبًا", "nǐ hǎo"),
        AcademyStartWord("再见", "مع السلامة", "zàijiàn"),
        AcademyStartWord("谢谢", "شكرًا", "xièxie"),
        AcademyStartWord("请", "من فضلك", "qǐng"),
        AcademyStartWord("我", "أنا", "wǒ"),
        AcademyStartWord("你", "أنت", "nǐ"),
        AcademyStartWord("他", "هو", "tā"),
        AcademyStartWord("她", "هي", "tā"),
        AcademyStartWord("叫", "يسمى", "jiào"),
        AcademyStartWord("名字", "اسم", "míngzi"),
        AcademyStartWord("学生", "طالب", "xuésheng"),
        AcademyStartWord("老师", "معلم", "lǎoshī"),
        AcademyStartWord("朋友", "صديق", "péngyou"),
        AcademyStartWord("书", "كتاب", "shū"),
        AcademyStartWord("中文", "اللغة الصينية", "Zhōngwén"),
        AcademyStartWord("学校", "مدرسة", "xuéxiào"),
        AcademyStartWord("图书馆", "مكتبة", "túshūguǎn"),
        AcademyStartWord("一起", "معًا", "yìqǐ"),
        AcademyStartWord("很高兴", "سعيد جدًا", "hěn gāoxìng"),
        AcademyStartWord("认识", "يتعرف على", "rènshi")],
      checks: [AcademyStartQuestion("“我叫小美”是什么意思？", ["اسمي شياو مي","شكرًا","مع السلامة"], 0),
        AcademyStartQuestion("“谢谢”是什么意思？", ["مرحبًا","شكرًا","طالب"], 1),
        AcademyStartQuestion("小美在哪里认识小明？", ["在图书馆","在医院","在机场"], 0)],
    ),
    'ko': AcademyGuidedStart(
      code: "ko", name: "한국어",
      title: "안녕하세요! 저는 민지예요", titleArabic: "التحيات والتعارف بالكورية",
      grammar: "안녕하세요! 저는 민지예요. 이름이 뭐예요?", grammarArabic: "안녕하세요 (annyeonghaseyo) للتحية المهذبة، 저는 ...예요 للتعريف بنفسك، و이름이 뭐예요؟ للسؤال عن الاسم.",
      grammarEnglish: "안녕하세요 is a polite hello. 저는 ...예요 introduces your name. 이름이 뭐예요? asks a person's name.",
      dialogue: "민지: 안녕하세요! 저는 민지예요. 이름이 뭐예요?\n준호: 안녕하세요! 저는 준호예요. 만나서 반가워요!\n민지: 저도 반가워요!",
      story: ["민지는 오늘 작은 도서관에 가요. 한국어 책을 찾고 있어요. 창문 옆에 파란색 책이 있어요. 민지는 그 책을 보고 웃어요.","준호가 와서 인사해요. “안녕하세요! 저는 준호예요.” 민지가 대답해요. “저는 민지예요. 만나서 반가워요!” 두 사람은 같이 공부해요."], storyArabic: ["تذهب مينجي إلى مكتبة صغيرة للبحث عن كتاب كوري. قرب النافذة تجد كتابًا أزرق فتبتسم.","يأتي جونهو ويلقي التحية ويعرّف بنفسه. ترد مينجي باسمها ويقولان تشرفنا بالتعارف. ثم يدرسان معًا."],
      words: [AcademyStartWord("안녕하세요", "مرحبًا (مهذبة)", "annyeonghaseyo"),
        AcademyStartWord("안녕", "أهلًا", "annyeong"),
        AcademyStartWord("안녕히 가세요", "مع السلامة", "annyeonghi gaseyo"),
        AcademyStartWord("감사합니다", "شكرًا", "gamsahamnida"),
        AcademyStartWord("네", "نعم", "ne"),
        AcademyStartWord("아니요", "لا", "aniyo"),
        AcademyStartWord("저", "أنا (مهذبة)", "jeo"),
        AcademyStartWord("이름", "اسم", "ireum"),
        AcademyStartWord("저는", "أنا (كموضوع)", "jeoneun"),
        AcademyStartWord("친구", "صديق", "chingu"),
        AcademyStartWord("학생", "طالب", "haksaeng"),
        AcademyStartWord("선생님", "معلم", "seonsaengnim"),
        AcademyStartWord("책", "كتاب", "chaek"),
        AcademyStartWord("학교", "مدرسة", "hakgyo"),
        AcademyStartWord("도서관", "مكتبة", "doseogwan"),
        AcademyStartWord("한국어", "اللغة الكورية", "hangugeo"),
        AcademyStartWord("같이", "معًا", "gachi"),
        AcademyStartWord("만나서", "عند اللقاء", "mannaseo"),
        AcademyStartWord("반가워요", "سعيد بلقائك", "bangawoyo"),
        AcademyStartWord("뭐예요", "ما هو؟", "mwoyeyo")],
      checks: [AcademyStartQuestion("“저는 민지예요” 뜻은?", ["اسمي مينجي","شكرًا","هذا كتاب"], 0),
        AcademyStartQuestion("“감사합니다” 뜻은?", ["مرحبًا","شكرًا","مع السلامة"], 1),
        AcademyStartQuestion("민지는 어디에서 준호를 만나요?", ["도서관","학교 운동장","공항"], 0)],
    ),
  };

  static AcademyGuidedStart? forCode(String code) => lessons[code];
}
