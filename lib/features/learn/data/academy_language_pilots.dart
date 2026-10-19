/// Four independently authored starter lessons in target languages.
/// This catalog is the FIRST lesson pilot for each course, not a claim that
/// 30 complete lessons or higher CEFR content exist in these languages.
class AcademyLanguageWord {
  const AcademyLanguageWord(this.term, this.arabic, this.pronunciation);
  final String term, arabic, pronunciation;
}

class AcademyLanguagePilot {
  const AcademyLanguagePilot({
    required this.code, required this.name, required this.voiceLocale,
    required this.title, required this.titleArabic,
    required this.grammar, required this.grammarArabic,
    required this.dialogue, required this.dialogueArabic,
    required this.listening, required this.story, required this.storyArabic,
    required this.comprehension, required this.options,
    required this.correctIndex, required this.words,
  });
  final String code, name, voiceLocale, title, titleArabic;
  final String grammar, grammarArabic, dialogue, dialogueArabic, listening;
  final List<String> story, storyArabic;
  final String comprehension;
  final List<String> options;
  final int correctIndex;
  final List<AcademyLanguageWord> words;
}

abstract final class AcademyLanguagePilots {
  static const courses = <AcademyLanguagePilot>[
    AcademyLanguagePilot(
      code: "es", name: "Español",
      voiceLocale: "es-ES", title: "Saludos y presentaciones",
      titleArabic: "التحيات والتعارف", grammar: "En español, puedes saludar con «Hola» y presentarte con «Me llamo ...». Pregunta «¿Cómo te llamas?» para saber el nombre de la otra persona.",
      grammarArabic: "قل Hola للتحية، وMe llamo مع اسمك للتعارف. اسأل ¿Cómo te llamas? لمعرفة اسم الشخص الآخر. هذه جمل تستخدم في الحديث اليومي.",
      dialogue: "Ana: ¡Hola! Me llamo Ana. ¿Cómo te llamas?\nLuis: Me llamo Luis. ¡Mucho gusto!\nAna: ¡Mucho gusto, Luis!", dialogueArabic: "تصل آنا إلى المدرسة بدفترها الأزرق، وترى طفلًا عند الباب فتقول مبتسمة: مرحبًا، اسمي آنا.",
      listening: "Hola, soy Ana. Tengo un cuaderno azul. Luis es mi amigo. Estamos en la escuela.",
      story: ["Ana llega a la escuela con su cuaderno azul. Ve a un niño en la puerta. «¡Hola! Me llamo Ana», dice con una sonrisa.","El niño se llama Luis. Los dos entran en clase. Ana busca su cuaderno en su mochila, pero no está allí. «¿Dónde está mi cuaderno?», pregunta.","Luis encuentra el cuaderno cerca de la ventana. «¿Es tuyo?», dice. Ana responde: «¡Sí, gracias!». Ahora Ana y Luis son amigos."],
      storyArabic: ["تصل آنا إلى المدرسة بدفترها الأزرق، وترى طفلًا عند الباب فتقول مبتسمة: مرحبًا، اسمي آنا.","اسمه لويس. يدخلان الصف وتبحث آنا عن دفترها في الحقيبة لكنها لا تجده، فتسأل عن مكانه.","يعثر لويس على الدفتر قرب النافذة ويعيده لها. تشكره آنا ويصبحان صديقين."],
      comprehension: "¿Cómo se llama la niña?", options: ["Ana","Luis","María"],
      correctIndex: 0,
      words: [
        AcademyLanguageWord("hola", "مرحبًا", "/ˈola/"),
        AcademyLanguageWord("adiós", "وداعًا", "/aˈdjos/"),
        AcademyLanguageWord("gracias", "شكرًا", "/ˈɡɾa.sjas/"),
        AcademyLanguageWord("por favor", "من فضلك", "/poɾ faˈβoɾ/"),
        AcademyLanguageWord("sí", "نعم", "/si/"),
        AcademyLanguageWord("no", "لا", "/no/"),
        AcademyLanguageWord("nombre", "اسم", "/ˈnom.bɾe/"),
        AcademyLanguageWord("me llamo", "اسمي", "/me ˈʝa.mo/"),
        AcademyLanguageWord("soy", "أنا", "/soj/"),
        AcademyLanguageWord("amigo", "صديق", "/aˈmi.ɣo/"),
        AcademyLanguageWord("amiga", "صديقة", "/aˈmi.ɣa/"),
        AcademyLanguageWord("escuela", "مدرسة", "/esˈkwe.la/"),
        AcademyLanguageWord("maestro", "معلم", "/maˈes.tɾo/"),
        AcademyLanguageWord("estudiante", "طالب", "/es.tuˈðjan.te/"),
        AcademyLanguageWord("libro", "كتاب", "/ˈli.βɾo/"),
        AcademyLanguageWord("cuaderno", "دفتر", "/kwaˈðeɾ.no/"),
        AcademyLanguageWord("mochila", "حقيبة", "/moˈtʃi.la/"),
        AcademyLanguageWord("azul", "أزرق", "/aˈsul/"),
        AcademyLanguageWord("ventana", "نافذة", "/benˈta.na/"),
        AcademyLanguageWord("mucho gusto", "تشرفت بلقائك", "/ˈmu.tʃo ˈɡus.to/"),
      ],
    ),
    AcademyLanguagePilot(
      code: "fr", name: "Français",
      voiceLocale: "fr-FR", title: "Bonjour et présentations",
      titleArabic: "التحيات والتعارف", grammar: "En français, dis «Bonjour» pour saluer. Présente-toi avec «Je m’appelle ...». Demande «Comment tu t’appelles ?» et réponds «Enchanté(e)» pour dire que tu es ravi de rencontrer la personne.",
      grammarArabic: "قل Bonjour للتحية، ثم Je m’appelle متبوعة باسمك. اسأل Comment tu t’appelles ? لمعرفة اسم الشخص. Enchanté(e) عبارة مهذبة عند التعارف.",
      dialogue: "Léa : Bonjour ! Je m’appelle Léa.\nHugo : Salut ! Je m’appelle Hugo.\nLéa : Enchantée, Hugo !", dialogueArabic: "تصل ليا إلى المدرسة بدفتر أزرق، وتقابل هوغو عند الباب. تحييه وتعرف بنفسها فيبتسم.",
      listening: "Bonjour ! Je m’appelle Léa. Hugo est mon ami. Nous sommes à l’école. Enchantée !",
      story: ["Léa arrive à l’école avec un carnet bleu. Devant la porte, elle rencontre Hugo. Elle dit : « Bonjour ! Je m’appelle Léa. » Hugo lui sourit.","Dans la classe, Léa ne trouve plus son carnet. Elle regarde dans son sac et sous la table. « Où est mon carnet bleu ? », demande-t-elle.","Hugo trouve le carnet près de la fenêtre. « C’est ton carnet ? » demande-t-il. « Oui, merci ! » répond Léa. Ils deviennent amis."],
      storyArabic: ["تصل ليا إلى المدرسة بدفتر أزرق، وتقابل هوغو عند الباب. تحييه وتعرف بنفسها فيبتسم.","في الصف تبحث ليا عن دفترها في الحقيبة وتحت الطاولة دون أن تجده، وتسأل عنه.","يجد هوغو الدفتر قرب النافذة. تشكره ليا ويصبحان صديقين."],
      comprehension: "Comment s’appelle la fille ?", options: ["Léa","Hugo","Julie"],
      correctIndex: 0,
      words: [
        AcademyLanguageWord("bonjour", "مرحبًا", "/bɔ̃.ʒuʁ/"),
        AcademyLanguageWord("salut", "أهلًا", "/sa.ly/"),
        AcademyLanguageWord("au revoir", "إلى اللقاء", "/o ʁə.vwaʁ/"),
        AcademyLanguageWord("merci", "شكرًا", "/mɛʁ.si/"),
        AcademyLanguageWord("s’il vous plaît", "من فضلك", "/sil vu plɛ/"),
        AcademyLanguageWord("oui", "نعم", "/wi/"),
        AcademyLanguageWord("non", "لا", "/nɔ̃/"),
        AcademyLanguageWord("nom", "اسم", "/nɔ̃/"),
        AcademyLanguageWord("je m’appelle", "اسمي", "/ʒə ma.pɛl/"),
        AcademyLanguageWord("je suis", "أنا", "/ʒə sɥi/"),
        AcademyLanguageWord("ami", "صديق", "/a.mi/"),
        AcademyLanguageWord("amie", "صديقة", "/a.mi/"),
        AcademyLanguageWord("école", "مدرسة", "/e.kɔl/"),
        AcademyLanguageWord("professeur", "معلم", "/pʁɔ.fɛ.sœʁ/"),
        AcademyLanguageWord("élève", "طالب", "/e.lɛv/"),
        AcademyLanguageWord("livre", "كتاب", "/livʁ/"),
        AcademyLanguageWord("carnet", "دفتر", "/kaʁ.nɛ/"),
        AcademyLanguageWord("sac", "حقيبة", "/sak/"),
        AcademyLanguageWord("bleu", "أزرق", "/blø/"),
        AcademyLanguageWord("enchanté", "تشرفت بلقائك", "/ɑ̃.ʃɑ̃.te/"),
      ],
    ),
    AcademyLanguagePilot(
      code: "zh", name: "中文",
      voiceLocale: "zh-CN", title: "问候与自我介绍",
      titleArabic: "التحية والتعارف", grammar: "“你好” (nǐ hǎo) means hello. Say “我叫…” (wǒ jiào) and your name to introduce yourself. To ask a name, say “你叫什么名字？” (nǐ jiào shénme míngzi). Mandarin has lexical tones; listen carefully and repeat.",
      grammarArabic: "你好 (nǐ hǎo) تعني مرحبًا. قل 我叫 (wǒ jiào) مع اسمك. اسأل 你叫什么名字？ لمعرفة الاسم. انتبه إلى نغمات الصينية واستمع جيدًا قبل التكرار.",
      dialogue: "小丽：你好！我叫小丽。\n小明：你好！我叫小明。\n小丽：很高兴认识你！", dialogueArabic: "لدى شياو لي دفتر أزرق. تذهب إلى المدرسة وتلتقي طالبًا جديدًا عند الباب وتعرّف بنفسها.",
      listening: "你好！我叫小丽。我在学校。小明是我的朋友。很高兴认识你！",
      story: ["小丽有一个蓝色的本子。今天她去学校，在门口看见一个新同学。她说：“你好！我叫小丽。” 新同学笑了。","上课的时候，小丽找不到她的本子。她看看书包，又看看桌子下面。她问：“我的本子在哪儿？”","小明在窗户旁边找到了本子。他说：“这是你的本子吗？” 小丽很高兴：“是的，谢谢你！” 他们成为了朋友。"],
      storyArabic: ["لدى شياو لي دفتر أزرق. تذهب إلى المدرسة وتلتقي طالبًا جديدًا عند الباب وتعرّف بنفسها.","في الصف لا تجد دفترها وتبحث داخل الحقيبة وتحت الطاولة وتسأل أين هو.","يجد شياو مينغ الدفتر قرب النافذة. تشكره شياو لي ويصبحان صديقين."],
      comprehension: "女孩叫什么名字？", options: ["小丽","小明","小红"],
      correctIndex: 0,
      words: [
        AcademyLanguageWord("你好", "مرحبًا", "nǐ hǎo"),
        AcademyLanguageWord("再见", "إلى اللقاء", "zàijiàn"),
        AcademyLanguageWord("谢谢", "شكرًا", "xièxie"),
        AcademyLanguageWord("请", "من فضلك", "qǐng"),
        AcademyLanguageWord("是", "يكون / نعم", "shì"),
        AcademyLanguageWord("不是", "ليس", "bú shì"),
        AcademyLanguageWord("名字", "اسم", "míngzi"),
        AcademyLanguageWord("我叫", "اسمي", "wǒ jiào"),
        AcademyLanguageWord("我", "أنا", "wǒ"),
        AcademyLanguageWord("你", "أنت", "nǐ"),
        AcademyLanguageWord("朋友", "صديق", "péngyou"),
        AcademyLanguageWord("老师", "معلم", "lǎoshī"),
        AcademyLanguageWord("学生", "طالب", "xuésheng"),
        AcademyLanguageWord("学校", "مدرسة", "xuéxiào"),
        AcademyLanguageWord("书", "كتاب", "shū"),
        AcademyLanguageWord("本子", "دفتر", "běnzi"),
        AcademyLanguageWord("书包", "حقيبة مدرسية", "shūbāo"),
        AcademyLanguageWord("蓝色", "أزرق", "lánsè"),
        AcademyLanguageWord("窗户", "نافذة", "chuānghu"),
        AcademyLanguageWord("很高兴认识你", "تشرفت بلقائك", "hěn gāoxìng rènshi nǐ"),
      ],
    ),
    AcademyLanguagePilot(
      code: "ko", name: "한국어",
      voiceLocale: "ko-KR", title: "인사와 자기소개",
      titleArabic: "التحيات والتعارف", grammar: "“안녕하세요” (annyeonghaseyo) is a polite hello. Introduce yourself using “저는…” (jeoneun) plus your name and the polite ending 이에요/예요. Ask “이름이 뭐예요?” to learn someone's name. Politeness is essential in Korean.",
      grammarArabic: "안녕하세요 (annyeonghaseyo) تحية مهذبة. للتعريف بالنفس قل 저는 مع اسمك ثم 이에요 أو 예요. اسأل 이름이 뭐예요? لمعرفة الاسم. درجة الاحترام مهمة في الكورية.",
      dialogue: "지민: 안녕하세요! 저는 지민이에요.\n민수: 안녕하세요! 저는 민수예요.\n지민: 반가워요!", dialogueArabic: "تذهب جيمين إلى المدرسة ومعها دفتر أزرق. تقابل مينسو عند الباب وتحييه وتعرّف بنفسها.",
      listening: "안녕하세요! 저는 지민이에요. 여기는 학교예요. 민수는 제 친구예요. 반가워요!",
      story: ["지민은 파란 공책을 가지고 학교에 갑니다. 학교 문 앞에서 새로운 친구 민수를 만납니다. 지민은 “안녕하세요! 저는 지민이에요.”라고 말합니다.","교실에서 지민은 공책을 찾을 수 없습니다. 가방 안을 보고 책상 아래도 봅니다. “제 공책이 어디 있어요?”라고 물어봅니다.","민수는 창문 옆에서 공책을 찾습니다. “이거 지민 씨 공책이에요?” 지민은 웃으며 말합니다. “네, 고마워요!” 두 사람은 친구가 됩니다."],
      storyArabic: ["تذهب جيمين إلى المدرسة ومعها دفتر أزرق. تقابل مينسو عند الباب وتحييه وتعرّف بنفسها.","في الصف لا تجد دفترها، فتبحث في الحقيبة وتحت الطاولة وتسأل أين هو.","يعثر مينسو على الدفتر قرب النافذة ويعيده لها. تشكره جيمين ويصبحان صديقين."],
      comprehension: "여자 이름이 뭐예요?", options: ["지민","민수","수진"],
      correctIndex: 0,
      words: [
        AcademyLanguageWord("안녕하세요", "مرحبًا", "annyeonghaseyo"),
        AcademyLanguageWord("안녕히 가세요", "وداعًا لمن يغادر", "annyeonghi gaseyo"),
        AcademyLanguageWord("감사합니다", "شكرًا", "gamsahamnida"),
        AcademyLanguageWord("주세요", "من فضلك أعطني", "juseyo"),
        AcademyLanguageWord("네", "نعم", "ne"),
        AcademyLanguageWord("아니요", "لا", "aniyo"),
        AcademyLanguageWord("이름", "اسم", "ireum"),
        AcademyLanguageWord("저는", "أنا (مهذب)", "jeoneun"),
        AcademyLanguageWord("저", "أنا (مهذب)", "jeo"),
        AcademyLanguageWord("당신", "أنت", "dangsin"),
        AcademyLanguageWord("친구", "صديق", "chingu"),
        AcademyLanguageWord("선생님", "معلم", "seonsaengnim"),
        AcademyLanguageWord("학생", "طالب", "haksaeng"),
        AcademyLanguageWord("학교", "مدرسة", "hakgyo"),
        AcademyLanguageWord("책", "كتاب", "chaek"),
        AcademyLanguageWord("공책", "دفتر", "gongchaek"),
        AcademyLanguageWord("가방", "حقيبة", "gabang"),
        AcademyLanguageWord("파란색", "أزرق", "paransaek"),
        AcademyLanguageWord("창문", "نافذة", "changmun"),
        AcademyLanguageWord("반가워요", "تشرفت بلقائك", "bangawoyo"),
      ],
    ),
  ];

  static AcademyLanguagePilot? forCode(String code) {
    for (final course in courses) {
      if (course.code == code) return course;
    }
    return null;
  }
}
