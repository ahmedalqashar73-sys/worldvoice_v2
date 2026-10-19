/// Localized tutor guidance for all WorldVoice user-interface languages.
///
/// Learners study English examples in English, while the instructor's
/// explanation and example meanings use the user's app language.
/// The audio remains target-language English. Unknown locales use English,
/// never an unrelated Arabic fallback.
class AcademyTutorLocaleText {
  const AcademyTutorLocaleText(this.intro, this.rule, this.mistake,
      this.practice, this.exampleMeanings);
  final String intro;
  final String rule;
  final String mistake;
  final String practice;
  final List<String> exampleMeanings;
}

abstract final class AcademyTutorLocales {
  static const supported = <String>{
    "ar", "en", "es", "fr", "zh", "ko", "ja", "ru", "tr", "ur", "de", "pt", "fa", "id", "th", "hi", "it"
  };

  static const _ui = <String, List<String>>{
    "ar": ["الأستاذة إيما", "هدف الدرس", "شرح القاعدة", "أمثلة", "خطأ شائع", "فهمت القاعدة؟", "تحقق من الإجابة", "إجابة صحيحة!", "حاول مجددًا", "السؤال التالي", "النطق الإنجليزي · IPA", "استمع إلى المثال", "تابع إلى المفردات"],
    "en": ["Tutor Emma", "Today's goal", "Grammar explained", "Examples", "Common mistake", "Check your understanding", "Check answer", "Correct!", "Try again", "Next question", "English pronunciation · IPA", "Hear example", "Continue to vocabulary"],
    "es": ["Profesora Emma", "Objetivo de hoy", "Explicación de gramática", "Ejemplos", "Error frecuente", "Comprueba lo aprendido", "Comprobar respuesta", "¡Correcto!", "Inténtalo de nuevo", "Siguiente pregunta", "Pronunciación inglesa · AFI", "Escuchar ejemplo", "Continuar al vocabulario"],
    "fr": ["Professeure Emma", "Objectif du jour", "Explication de grammaire", "Exemples", "Erreur fréquente", "Vérifie tes acquis", "Vérifier la réponse", "Bonne réponse !", "Réessaie", "Question suivante", "Prononciation anglaise · API", "Écouter l'exemple", "Passer au vocabulaire"],
    "zh": ["艾玛老师", "本课目标", "语法讲解", "例句", "常见错误", "检查理解", "检查答案", "答对了！", "再试一次", "下一题", "英语发音 · IPA", "听例句", "继续学习词汇"],
    "ko": ["엠마 선생님", "오늘의 학습 목표", "문법 설명", "예문", "자주 하는 실수", "이해도 확인", "정답 확인", "정답이에요!", "다시 시도하세요", "다음 문제", "영어 발음 · IPA", "예문 듣기", "어휘 학습으로 이동"],
    "ja": ["エマ先生", "今日の目標", "文法の説明", "例文", "よくある間違い", "理解度チェック", "答えを確認", "正解です！", "もう一度", "次の問題", "英語の発音 · IPA", "例文を聞く", "単語に進む"],
    "ru": ["Преподаватель Эмма", "Цель урока", "Объяснение грамматики", "Примеры", "Типичная ошибка", "Проверьте понимание", "Проверить ответ", "Верно!", "Попробуйте ещё раз", "Следующий вопрос", "Английское произношение · IPA", "Прослушать пример", "К словам"],
    "tr": ["Öğretmen Emma", "Bugünkü hedef", "Dil bilgisi açıklaması", "Örnekler", "Sık yapılan hata", "Anladığını kontrol et", "Cevabı kontrol et", "Doğru!", "Tekrar dene", "Sonraki soru", "İngilizce telaffuz · IPA", "Örneği dinle", "Kelimelere geç"],
    "ur": ["استاد ایما", "آج کا مقصد", "گرامر کی وضاحت", "مثالیں", "عام غلطی", "فہم کی جانچ", "جواب چیک کریں", "درست!", "دوبارہ کوشش کریں", "اگلا سوال", "انگریزی تلفظ · IPA", "مثال سنیں", "الفاظ پر جائیں"],
    "de": ["Lehrerin Emma", "Lernziel", "Grammatikerklärung", "Beispiele", "Häufiger Fehler", "Verständnis prüfen", "Antwort prüfen", "Richtig!", "Versuch es erneut", "Nächste Frage", "Englische Aussprache · IPA", "Beispiel anhören", "Weiter zu den Wörtern"],
    "pt": ["Professora Emma", "Objetivo de hoje", "Explicação de gramática", "Exemplos", "Erro comum", "Verifique o que aprendeu", "Verificar resposta", "Correto!", "Tente novamente", "Próxima questão", "Pronúncia inglesa · IPA", "Ouvir exemplo", "Continuar para o vocabulário"],
    "fa": ["استاد اِما", "هدف امروز", "توضیح دستور زبان", "مثال‌ها", "اشتباه رایج", "بررسی یادگیری", "بررسی پاسخ", "درست است!", "دوباره تلاش کن", "سؤال بعدی", "تلفظ انگلیسی · IPA", "شنیدن مثال", "ادامه به واژگان"],
    "id": ["Guru Emma", "Tujuan hari ini", "Penjelasan tata bahasa", "Contoh", "Kesalahan umum", "Periksa pemahaman", "Periksa jawaban", "Benar!", "Coba lagi", "Pertanyaan berikutnya", "Pelafalan Inggris · IPA", "Dengarkan contoh", "Lanjut ke kosakata"],
    "th": ["ครูเอ็มมา", "เป้าหมายวันนี้", "คำอธิบายไวยากรณ์", "ตัวอย่าง", "ข้อผิดพลาดที่พบบ่อย", "ตรวจสอบความเข้าใจ", "ตรวจคำตอบ", "ถูกต้อง!", "ลองอีกครั้ง", "คำถามถัดไป", "การออกเสียงอังกฤษ · IPA", "ฟังตัวอย่าง", "ไปที่คำศัพท์"],
    "hi": ["शिक्षिका एम्मा", "आज का लक्ष्य", "व्याकरण की व्याख्या", "उदाहरण", "सामान्य गलती", "अपनी समझ जाँचें", "उत्तर जाँचें", "सही!", "फिर कोशिश करें", "अगला प्रश्न", "अंग्रेज़ी उच्चारण · IPA", "उदाहरण सुनें", "शब्दावली पर जाएँ"],
    "it": ["Insegnante Emma", "Obiettivo di oggi", "Spiegazione grammaticale", "Esempi", "Errore comune", "Verifica la comprensione", "Controlla la risposta", "Corretto!", "Riprova", "Domanda successiva", "Pronuncia inglese · IPA", "Ascolta l'esempio", "Passa al vocabolario"],
  };

  static const _lessons = <String, List<List<String>>>{
    "en": [
      ["Welcome! Today we'll learn to introduce ourselves using I am and You are.", "Use am after I, and are after you. English needs the verb be: I am a student, not I a student.", "I are happy is incorrect. The correct sentence is I am happy.", "Say I am followed by your name. Then ask Are you a student?", "I'm Sara.", "I'm a student.", "You're my friend.", "Are you a student?", "Yes, I am. / No, I'm not."],
      ["Welcome back! Let's learn to talk about things that belong to us.", "Use my before a noun that belongs to you and your before a noun belonging to the other person. His and her refer to other people.", "You name is incorrect. Say Your name is Sara.", "Practise asking What is your name? and answering My name is ...", "My name is Maya.", "What is your name?", "This is my book.", "His name is Leo.", "Her name is Nina."],
      ["Now let's point to objects near and far.", "This is for one object near you. That is for one object farther away. Both use is.", "This my book misses the verb. Say This is my book.", "Hold a pen and say This is my pen. Point away and say That is your bag.", "This is my pen.", "That is your bag.", "Is this your book?", "Yes, it is.", "No, that is not my notebook."],
    ],
    "es": [
      ["¡Hola! Hoy aprenderás a presentarte en inglés con I am y You are.", "Con el pronombre I se usa am; con you se usa are. El inglés necesita el verbo be: I am a student, no I a student.", "I are happy es incorrecto. La forma correcta es I am happy.", "Di I am seguido de tu nombre. Después practica la pregunta Are you a student?", "Soy Sara.", "Soy estudiante.", "Eres mi amigo/a.", "¿Eres estudiante?", "Sí, lo soy. / No, no lo soy."],
      ["¡Bienvenido de nuevo! Hoy hablarás de lo que pertenece a cada persona.", "Pon my delante de algo tuyo y your delante de algo de la persona con la que hablas. His significa «su» de él; her, «su» de ella.", "You name es incorrecto: debe ser Your name is Sara.", "Pregunta What is your name? y responde My name is ...", "Me llamo Maya.", "¿Cómo te llamas?", "Este es mi libro.", "Él se llama Leo.", "Ella se llama Nina."],
      ["Hoy aprenderás a señalar objetos cercanos y lejanos.", "This señala un objeto cercano y that uno más lejano. Ambos se usan con is.", "This my book está incompleto; di This is my book.", "Sostén un bolígrafo y di This is my pen; señala una bolsa distante y di That is your bag.", "Este es mi bolígrafo.", "Esa es tu bolsa.", "¿Este es tu libro?", "Sí, lo es.", "No, ese no es mi cuaderno."],
    ],
    "fr": [
      ["Bonjour ! Aujourd'hui, apprends à te présenter en anglais avec I am et You are.", "Après I, on utilise am ; après you, on utilise are. L'anglais exige le verbe be : I am a student, pas I a student.", "I are happy est incorrect. Il faut dire I am happy.", "Prononce I am suivi de ton prénom, puis entraîne-toi à demander Are you a student?", "Je suis Sara.", "Je suis élève.", "Tu es mon ami(e).", "Es-tu élève ?", "Oui. / Non."],
      ["Bon retour ! Apprenons à parler des choses qui appartiennent à quelqu'un.", "My précède un nom qui désigne ce qui t'appartient ; your concerne ton interlocuteur. His signifie «son/sa» à lui et her «son/sa» à elle.", "You name est incorrect ; dis Your name is Sara.", "Demande What is your name? et réponds My name is ...", "Je m'appelle Maya.", "Comment t'appelles-tu ?", "C'est mon livre.", "Il s'appelle Leo.", "Elle s'appelle Nina."],
      ["Aujourd'hui, nous allons montrer des objets proches et éloignés.", "This désigne un objet proche ; that un objet éloigné. Les deux s'emploient avec is.", "This my book est incomplet : dis This is my book.", "Tiens un stylo et dis This is my pen ; montre un sac éloigné et dis That is your bag.", "C'est mon stylo.", "C'est ton sac, là-bas.", "Est-ce ton livre ?", "Oui, c'est ça.", "Non, ce n'est pas mon cahier."],
    ],
    "zh": [
      ["你好！今天艾玛老师带你用 I am 和 You are 做自我介绍。", "I 后面用 am，you 后面用 are。英语句子通常不能省略 be 动词：要说 I am a student，不能说 I a student。", "I are happy 是错误的，正确说法是 I am happy。", "说出 I am 加上你的名字，再练习询问 Are you a student?", "我是萨拉。", "我是一名学生。", "你是我的朋友。", "你是学生吗？", "是的。/ 不，我不是。"],
      ["欢迎回来！今天学习如何表达东西属于谁。", "my 放在属于自己的名词前，your 放在属于对方的名词前。his 表示他的，her 表示她的。", "You name 不正确，应该说 Your name is Sara。", "练习问 What is your name?，再回答 My name is ...", "我叫玛雅。", "你叫什么名字？", "这是我的书。", "他叫利奥。", "她叫妮娜。"],
      ["今天学习用英语指出近处和远处的物品。", "this 指近处的一个物品，that 指远处的一个物品。后面都要用 is。", "This my book 缺少动词，应该说 This is my book。", "拿起笔说 This is my pen，再指着远处的包说 That is your bag。", "这是我的笔。", "那是你的包。", "这是你的书吗？", "是的。", "不，那不是我的笔记本。"],
    ],
    "ko": [
      ["안녕하세요! 오늘은 I am과 You are로 영어 자기소개를 연습해요.", "I 뒤에는 am, you 뒤에는 are를 써요. 영어에서는 be동사를 생략하지 않아요. I am a student가 맞아요.", "I are happy는 틀린 문장이에요. I am happy라고 말해요.", "I am 뒤에 자신의 이름을 말한 다음 Are you a student?를 연습하세요.", "저는 사라예요.", "저는 학생이에요.", "당신은 제 친구예요.", "학생이세요?", "네, 맞아요. / 아니요."],
      ["다시 만나서 반가워요! 이제 소유를 나타내는 표현을 배워요.", "내 물건 앞에는 my, 상대방의 물건 앞에는 your를 붙여요. his는 그의, her는 그녀의 뜻이에요.", "You name은 틀려요. Your name is Sara가 맞아요.", "What is your name?이라고 묻고 My name is ...라고 답해 보세요.", "제 이름은 마야예요.", "이름이 뭐예요?", "이것은 제 책이에요.", "그의 이름은 레오예요.", "그녀의 이름은 니나예요."],
      ["오늘은 가까운 것과 먼 것을 가리키는 표현을 배워요.", "this는 가까운 물건 하나, that은 먼 물건 하나를 가리켜요. 둘 다 is와 함께 사용해요.", "This my book은 동사가 빠졌어요. This is my book이라고 해야 해요.", "펜을 들고 This is my pen, 멀리 있는 가방을 가리키며 That is your bag이라고 말해 보세요.", "이것은 제 펜이에요.", "저것은 당신의 가방이에요.", "이것이 당신의 책인가요?", "네, 맞아요.", "아니요, 저것은 제 공책이 아니에요."],
    ],
    "ja": [
      ["こんにちは！今日は I am と You are を使って自己紹介しましょう。", "I の後には am、you の後には are を使います。英語では be 動詞を省略できません。I am a student が正しい形です。", "I are happy は間違いです。I am happy と言いましょう。", "I am の後に自分の名前を続け、Are you a student? と質問してみましょう。", "私はサラです。", "私は学生です。", "あなたは私の友達です。", "あなたは学生ですか？", "はい。／いいえ。"],
      ["おかえりなさい！今日は持ち主を示す表現を学びましょう。", "自分の物には my、相手の物には your を名詞の前に置きます。his は彼の、her は彼女のです。", "You name は誤りです。Your name is Sara と言います。", "What is your name? と尋ね、My name is ... と答えましょう。", "私の名前はマヤです。", "お名前は何ですか？", "これは私の本です。", "彼の名前はレオです。", "彼女の名前はニナです。"],
      ["今日は近くの物と遠くの物を示す言い方です。", "this は近くの物、that は遠くの物を指します。どちらも is と組み合わせます。", "This my book には動詞が足りません。This is my book が正しいです。", "ペンを持って This is my pen、遠くのかばんを指して That is your bag と言いましょう。", "これは私のペンです。", "あれはあなたのかばんです。", "これはあなたの本ですか？", "はい、そうです。", "いいえ、あれは私のノートではありません。"],
    ],
    "ru": [
      ["Здравствуйте! Сегодня научимся представляться с I am и You are.", "После I используем am, после you — are. В английском нельзя пропускать глагол be: I am a student.", "I are happy — ошибка. Правильно: I am happy.", "Произнесите I am и своё имя. Затем спросите: Are you a student?", "Я Сара.", "Я студент.", "Ты мой друг.", "Ты студент?", "Да. / Нет."],
      ["С возвращением! Сегодня поговорим о принадлежности предметов.", "My ставится перед тем, что принадлежит вам, your — перед тем, что принадлежит собеседнику. His — его, her — её.", "You name — ошибка. Правильно: Your name is Sara.", "Спросите What is your name? и ответьте My name is ...", "Меня зовут Майя.", "Как тебя зовут?", "Это моя книга.", "Его зовут Лео.", "Её зовут Нина."],
      ["Сегодня научимся указывать на близкие и далёкие предметы.", "This — один предмет рядом; that — один предмет дальше. В обоих случаях используем is.", "This my book — неполное предложение. Правильно: This is my book.", "Возьмите ручку: This is my pen. Укажите на далёкую сумку: That is your bag.", "Это моя ручка.", "То твоя сумка.", "Это твоя книга?", "Да.", "Нет, то не моя тетрадь."],
    ],
    "tr": [
      ["Merhaba! Bugün I am ve You are ile kendimizi tanıtmayı öğreneceğiz.", "I ile am, you ile are kullanılır. İngilizcede be fiili atlanmaz: I am a student denir.", "I are happy yanlıştır. Doğrusu I am happy.", "I am ifadesinden sonra adını söyle, ardından Are you a student? diye sor.", "Ben Sara'yım.", "Ben öğrenciyim.", "Sen benim arkadaşımsın.", "Öğrenci misin?", "Evet. / Hayır."],
      ["Tekrar hoş geldin! Bugün sahiplik ifadelerini öğreneceğiz.", "Kendi eşyan için ismin önünde my, karşındakinin eşyası için your kullan. His onun (erkek), her onun (kadın) anlamındadır.", "You name yanlıştır. Your name is Sara demelisin.", "What is your name? diye sorup My name is ... diye cevap ver.", "Benim adım Maya.", "Adın ne?", "Bu benim kitabım.", "Onun adı Leo.", "Onun adı Nina."],
      ["Bugün yakındaki ve uzaktaki nesneleri göstereceğiz.", "This yakındaki, that uzaktaki tek bir nesneyi gösterir. Her ikisinden sonra is gelir.", "This my book eksiktir. Doğrusu This is my book.", "Bir kalem tutup This is my pen de; uzak bir çantayı gösterip That is your bag de.", "Bu benim kalemim.", "Şu senin çantan.", "Bu senin kitabın mı?", "Evet.", "Hayır, şu benim defterim değil."],
    ],
    "ur": [
      ["سلام! آج I am اور You are کے ساتھ انگریزی میں اپنا تعارف کرانا سیکھیں گے۔", "I کے بعد am اور you کے بعد are آتا ہے۔ انگریزی میں be فعل نہیں چھوڑتے: I am a student۔", "I are happy غلط ہے۔ درست صورت I am happy ہے۔", "I am کے بعد اپنا نام کہیں، پھر پوچھیں Are you a student?", "میں سارہ ہوں۔", "میں طالب علم ہوں۔", "تم میرے دوست ہو۔", "کیا تم طالب علم ہو؟", "ہاں۔ / نہیں۔"],
      ["واپس خوش آمدید! آج ملکیت ظاہر کرنا سیکھیں گے۔", "اپنی چیز کے اسم سے پہلے my اور دوسرے شخص کی چیز کے اسم سے پہلے your آتا ہے۔ his اس کا (مذکر)، her اس کا (مونث) ہے۔", "You name غلط ہے؛ Your name is Sara کہیں۔", "پوچھیں What is your name? اور جواب دیں My name is ...", "میرا نام مایا ہے۔", "تمہارا نام کیا ہے؟", "یہ میری کتاب ہے۔", "اس کا نام لیو ہے۔", "اس کا نام نینا ہے۔"],
      ["آج قریب اور دور کی چیزوں کی نشاندہی کرنا سیکھیں گے۔", "this قریب کی ایک چیز، اور that دور کی ایک چیز کے لیے ہے۔ دونوں کے ساتھ is لگتا ہے۔", "This my book نامکمل ہے۔ درست: This is my book۔", "قلم اٹھا کر This is my pen کہیں، دور بیگ کی طرف اشارہ کرکے That is your bag کہیں۔", "یہ میرا قلم ہے۔", "وہ تمہارا بیگ ہے۔", "کیا یہ تمہاری کتاب ہے؟", "جی ہاں۔", "نہیں، وہ میری کاپی نہیں۔"],
    ],
    "de": [
      ["Hallo! Heute lernen wir, uns mit I am und You are vorzustellen.", "Nach I steht am, nach you steht are. Im Englischen darf das Verb be nicht fehlen: I am a student.", "I are happy ist falsch. Richtig ist I am happy.", "Sage I am mit deinem Namen und frage dann Are you a student?", "Ich bin Sara.", "Ich bin Schüler/-in.", "Du bist mein Freund.", "Bist du Schüler/-in?", "Ja. / Nein."],
      ["Willkommen zurück! Heute sprechen wir über Besitz.", "My steht vor Dingen, die dir gehören, your vor Dingen deines Gegenübers. His bedeutet sein, her bedeutet ihr.", "You name ist falsch. Sage Your name is Sara.", "Frage What is your name? und antworte My name is ...", "Ich heiße Maya.", "Wie heißt du?", "Das ist mein Buch.", "Er heißt Leo.", "Sie heißt Nina."],
      ["Heute zeigen wir nahe und entfernte Dinge.", "This zeigt einen nahen, that einen weiter entfernten Gegenstand. Beide stehen mit is.", "This my book ist unvollständig. Richtig: This is my book.", "Halte einen Stift und sage This is my pen. Zeige auf eine Tasche: That is your bag.", "Das ist mein Stift.", "Das dort ist deine Tasche.", "Ist das dein Buch?", "Ja.", "Nein, das ist nicht mein Heft."],
    ],
    "pt": [
      ["Olá! Hoje vamos nos apresentar em inglês com I am e You are.", "Depois de I usamos am; depois de you usamos are. O inglês precisa do verbo be: I am a student.", "I are happy está errado. O correto é I am happy.", "Diga I am seguido do seu nome e pratique Are you a student?", "Eu sou Sara.", "Sou estudante.", "Você é meu amigo.", "Você é estudante?", "Sim. / Não."],
      ["Bem-vindo de volta! Hoje vamos falar de posse.", "Use my antes do que pertence a você e your antes do que pertence à outra pessoa. His é dele; her é dela.", "You name está errado. Diga Your name is Sara.", "Pergunte What is your name? e responda My name is ...", "Meu nome é Maya.", "Qual é seu nome?", "Este é meu livro.", "O nome dele é Leo.", "O nome dela é Nina."],
      ["Hoje aprenderemos a apontar objetos próximos e distantes.", "This indica um objeto perto; that indica um mais distante. Ambos são usados com is.", "This my book está incompleto. Diga This is my book.", "Segure uma caneta: This is my pen. Aponte para uma bolsa longe: That is your bag.", "Esta é minha caneta.", "Aquela é sua bolsa.", "Este é seu livro?", "Sim.", "Não, aquele não é meu caderno."],
    ],
    "fa": [
      ["سلام! امروز یاد می‌گیریم با I am و You are خودمان را به انگلیسی معرفی کنیم.", "بعد از I از am و بعد از you از are استفاده می‌کنیم. در انگلیسی فعل be حذف نمی‌شود: I am a student.", "I are happy اشتباه است. شکل درست I am happy است.", "بعد از I am نام خود را بگویید، سپس بپرسید Are you a student?", "من سارا هستم.", "من دانش‌آموز هستم.", "تو دوست من هستی.", "آیا دانش‌آموز هستی؟", "بله. / خیر."],
      ["خوش برگشتی! امروز مالکیت را یاد می‌گیریم.", "قبل از اسم چیزی که مال خودتان است my و برای چیز متعلق به مخاطب your می‌آوریم. his برای او (مذکر) و her برای او (مونث) است.", "You name نادرست است؛ بگویید Your name is Sara.", "بپرسید What is your name? و پاسخ دهید My name is ...", "نام من مایا است.", "نام تو چیست؟", "این کتاب من است.", "نام او لئو است.", "نام او نینا است."],
      ["امروز اشاره به چیزهای نزدیک و دور را یاد می‌گیریم.", "this برای یک چیز نزدیک و that برای یک چیز دور است. هر دو با is به کار می‌روند.", "This my book ناقص است. درست: This is my book.", "یک خودکار بردارید و بگویید This is my pen؛ سپس به کیفی دور اشاره کنید.", "این خودکار من است.", "آن کیف توست.", "آیا این کتاب توست؟", "بله.", "خیر، آن دفتر من نیست."],
    ],
    "id": [
      ["Halo! Hari ini kita belajar memperkenalkan diri dengan I am dan You are.", "Setelah I gunakan am; setelah you gunakan are. Dalam bahasa Inggris, kata kerja be tidak boleh dihilangkan: I am a student.", "I are happy salah. Bentuk yang benar ialah I am happy.", "Ucapkan I am diikuti namamu, lalu tanyakan Are you a student?", "Saya Sara.", "Saya seorang siswa.", "Kamu adalah teman saya.", "Apakah kamu seorang siswa?", "Ya. / Tidak."],
      ["Selamat datang kembali! Hari ini kita belajar menunjukkan kepemilikan.", "Gunakan my sebelum benda milikmu dan your sebelum benda milik lawan bicara. His berarti miliknya (pria), her miliknya (wanita).", "You name salah. Katakan Your name is Sara.", "Tanyakan What is your name? lalu jawab My name is ...", "Nama saya Maya.", "Siapa namamu?", "Ini buku saya.", "Namanya Leo.", "Namanya Nina."],
      ["Hari ini kita belajar menunjuk benda dekat dan jauh.", "This untuk satu benda dekat; that untuk benda yang lebih jauh. Keduanya memakai is.", "This my book tidak lengkap. Yang benar This is my book.", "Pegang pena dan katakan This is my pen; tunjuk tas di kejauhan: That is your bag.", "Ini pena saya.", "Itu tasmu.", "Apakah ini bukumu?", "Ya.", "Tidak, itu bukan buku catatan saya."],
    ],
    "th": [
      ["สวัสดี! วันนี้เราจะฝึกแนะนำตัวด้วย I am และ You are", "หลัง I ใช้ am ส่วนหลัง you ใช้ are ภาษาอังกฤษต้องมีคำกริยา be เช่น I am a student", "I are happy ไม่ถูกต้อง ต้องพูดว่า I am happy", "พูด I am ตามด้วยชื่อของคุณ แล้วลองถาม Are you a student?", "ฉันชื่อซารา", "ฉันเป็นนักเรียน", "คุณเป็นเพื่อนของฉัน", "คุณเป็นนักเรียนหรือไม่?", "ใช่ / ไม่ใช่"],
      ["ยินดีต้อนรับกลับ! วันนี้จะเรียนการแสดงความเป็นเจ้าของ", "ใช้ my หน้าคำนามที่เป็นของเรา และ your หน้าคำนามของคู่สนทนา his หมายถึงของเขา her หมายถึงของเธอ", "You name ไม่ถูกต้อง ต้องพูดว่า Your name is Sara", "ถาม What is your name? แล้วตอบ My name is ...", "ฉันชื่อมายา", "คุณชื่ออะไร?", "นี่คือหนังสือของฉัน", "เขาชื่อลีโอ", "เธอชื่อนีนา"],
      ["วันนี้จะเรียนการชี้สิ่งของที่อยู่ใกล้และไกล", "this ใช้กับสิ่งของหนึ่งชิ้นที่อยู่ใกล้ ส่วน that ใช้กับสิ่งที่ไกลกว่า ทั้งคู่ใช้ is", "This my book ยังขาดกริยา ต้องพูดว่า This is my book", "ถือปากกาแล้วพูด This is my pen ชี้ไปที่กระเป๋าไกล ๆ แล้วพูด That is your bag", "นี่คือปากกาของฉัน", "นั่นคือกระเป๋าของคุณ", "นี่คือหนังสือของคุณใช่ไหม?", "ใช่", "ไม่ นั่นไม่ใช่สมุดของฉัน"],
    ],
    "hi": [
      ["नमस्ते! आज हम I am और You are से अंग्रेज़ी में अपना परिचय देना सीखेंगे।", "I के साथ am और you के साथ are लगाते हैं। अंग्रेज़ी में be क्रिया नहीं छोड़ सकते: I am a student.", "I are happy गलत है। सही वाक्य I am happy है।", "I am के बाद अपना नाम बोलें, फिर पूछें Are you a student?", "मैं सारा हूँ।", "मैं छात्र हूँ।", "तुम मेरे दोस्त हो।", "क्या तुम छात्र हो?", "हाँ। / नहीं।"],
      ["फिर स्वागत है! आज हम स्वामित्व बताना सीखेंगे।", "अपनी चीज़ के नाम से पहले my और दूसरे की चीज़ से पहले your लगाएँ। his का अर्थ उसका (पुरुष), her का अर्थ उसका (महिला) है।", "You name गलत है। Your name is Sara कहें।", "पूछें What is your name? और उत्तर दें My name is ...", "मेरा नाम माया है।", "तुम्हारा नाम क्या है?", "यह मेरी किताब है।", "उसका नाम लियो है।", "उसका नाम नीना है।"],
      ["आज पास और दूर की चीज़ों की ओर संकेत करना सीखेंगे।", "this पास की एक वस्तु और that दूर की एक वस्तु के लिए है। दोनों के साथ is लगता है।", "This my book अधूरा है। सही: This is my book.", "कलम उठाकर This is my pen कहें; दूर बैग दिखाकर That is your bag कहें।", "यह मेरी कलम है।", "वह तुम्हारा बैग है।", "क्या यह तुम्हारी किताब है?", "हाँ।", "नहीं, वह मेरी कॉपी नहीं है।"],
    ],
    "it": [
      ["Ciao! Oggi imparerai a presentarti in inglese usando I am e You are.", "Dopo I si usa am, dopo you si usa are. In inglese il verbo be non si omette: I am a student.", "I are happy è sbagliato. La forma corretta è I am happy.", "Di' I am seguito dal tuo nome, poi chiedi Are you a student?", "Sono Sara.", "Sono uno studente.", "Sei mio amico.", "Sei uno studente?", "Sì. / No."],
      ["Bentornato! Oggi parliamo di possesso.", "Usa my prima di qualcosa che ti appartiene e your per qualcosa del tuo interlocutore. His significa di lui, her di lei.", "You name è errato. Di' Your name is Sara.", "Chiedi What is your name? e rispondi My name is ...", "Mi chiamo Maya.", "Come ti chiami?", "Questo è il mio libro.", "Lui si chiama Leo.", "Lei si chiama Nina."],
      ["Oggi impariamo a indicare oggetti vicini e lontani.", "This indica un oggetto vicino, that uno più lontano. Entrambi richiedono is.", "This my book è incompleto. Di' This is my book.", "Tieni una penna e di' This is my pen; indica una borsa lontana: That is your bag.", "Questa è la mia penna.", "Quella è la tua borsa.", "Questo è il tuo libro?", "Sì.", "No, quello non è il mio quaderno."],
    ],
  };

  static String label(String locale, int index) {
    if (index < 0 || index > 12) throw RangeError.index(index, _ui['en']!);
    return (_ui[locale] ?? _ui['en']!)[index];
  }

  static AcademyTutorLocaleText forLesson(String locale, int lesson) {
    if (lesson < 1 || lesson > 3) throw RangeError.range(lesson, 1, 3);
    final values = (_lessons[locale] ?? _lessons['en']!)[lesson - 1];
    return AcademyTutorLocaleText(values[0], values[1], values[2],
        values[3], values.sublist(4));
  }

  static String explanation(String locale, int lesson, int field) {
    final t = forLesson(locale, lesson);
    return switch (field) {
      0 => t.intro,
      1 => t.rule,
      2 => t.mistake,
      3 => t.practice,
      _ => throw RangeError.range(field, 0, 3),
    };
  }
}
