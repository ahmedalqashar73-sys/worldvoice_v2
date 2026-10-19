/// Carefully authored tutor teaching notes in all 17 app UI languages.
/// Target-language English sentences/IPA remain in English and are not translated.
class AcademyTutorTranslatedCopy {
  const AcademyTutorTranslatedCopy(this._fields);
  final List<String> _fields;
  String get welcome => _fields[0];
  String get goal => _fields[1];
  String get rule => _fields[2];
  String get mistake => _fields[3];
  String get tip => _fields[4];
  String get pronunciation => _fields[5];
}

abstract final class AcademyTutorLanguage {
  static const supported = ["ar","en","es","fr","zh","ko","ja","ru","tr","ur","de","pt","fa","id","th","hi","it"];
  static const _notes = <String, List<List<String>>>{
  'ar': [
    ["مرحبًا! أنا إيما. اليوم سنتعلم التعارف الصحيح مع I am وYou are.", "ستقدم اسمك وتحوّل العبارة إلى سؤال.", "نستخدم am مع I وare مع you. الفعل be لازم في هذه الجمل.", "I are غير صحيحة؛ نقول I am.", "تدرّب على تعريف نفسك بصوت مسموع.", "تعلم صوت /æ/ في am والفرق مع /ɑː/ في are."],
    ["مرحبًا بعودتك! سنتعلم التعبير عن الملكية.", "ستقول اسمي واسمك واسمه واسمها.", "تأتي my وyour وhis وher قبل الاسم: my book، your name.", "You name خطأ؛ الصحيح Your name.", "اسأل صديقك What is your name? وأجب My name is ...", "تدرّب على /maɪ/ و/jʊr/ والنطق الإنجليزي الفعلي."],
    ["اليوم سنشير إلى الأشياء القريبة والبعيدة.", "ستفرق بين this للقريب وthat للبعيد.", "نستخدم This is للقريب وThat is للبعيد، ونبدأ السؤال بـ Is this...?", "This my book خطأ؛ يلزم is: This is my book.", "أمسك قلمًا وقل This is my pen، وأشر لشيء بعيد وقل That is ...", "تدرّب على صوت /ð/ في this وthat."],
  ],
  'en': [
    ["Hello! I’m Emma. Today we’ll introduce ourselves using I am and You are.", "Introduce yourself, describe someone and ask a simple question.", "Use am with I and are with you. English sentences need the verb be here.", "I are is incorrect; say I am.", "Say I am [your name] three times, then You are my friend.", "Practise /æ/ in am and compare it with /ɑː/ in are."],
    ["Welcome back! Today we’ll learn how to show ownership.", "Say my name, your name, his name and her name.", "My, your, his and her go before a noun: my book, your name.", "You name is wrong; use Your name.", "Ask What is your name? and reply My name is ...", "Practise /maɪ/ and /jʊr/ with English audio."],
    ["Today we’ll point to things near us and farther away.", "Tell the difference between this and that.", "Use This is for something near, That is for something far. Ask Is this...?", "This my book is missing is: This is my book.", "Hold a pen: This is my pen. Point far away: That is ...", "Practise /ð/ in this and that."],
  ],
  'es': [
    ["¡Hola! Soy Emma. Hoy aprenderás a presentarte con I am y You are.", "Di tu nombre, describe a alguien y haz una pregunta sencilla.", "En inglés usamos am con I y are con you. Aquí no se puede omitir el verbo be.", "I are es incorrecto; di I am.", "Di I am [tu nombre] tres veces y luego You are my friend.", "Practica /æ/ en am y compáralo con /ɑː/ en are."],
    ["¡Bienvenido de nuevo! Hoy expresaremos posesión.", "Aprenderás a decir mi nombre, tu nombre, su nombre (de él o de ella).", "My, your, his y her van antes del sustantivo: my book, your name.", "You name es incorrecto; lo correcto es Your name.", "Pregunta What is your name? y responde My name is ...", "Practica /maɪ/ y /jʊr/ con el audio en inglés."],
    ["Hoy señalaremos objetos cercanos y lejanos.", "Distingue this para lo cercano y that para lo lejano.", "Usa This is para objetos cercanos y That is para lejanos. Pregunta Is this...?", "This my book necesita is: This is my book.", "Sostén un bolígrafo y di This is my pen; señala algo lejano y di That is ...", "Practica el sonido /ð/ de this y that."],
  ],
  'fr': [
    ["Bonjour ! Je suis Emma. Aujourd’hui, apprends à te présenter avec I am et You are.", "Donne ton nom, décris quelqu’un et pose une question simple.", "En anglais, on utilise am avec I et are avec you. Le verbe be est obligatoire ici.", "I are est incorrect ; dis I am.", "Dis I am [ton prénom] trois fois, puis You are my friend.", "Entraîne-toi au son /æ/ de am et compare-le à /ɑː/ de are."],
    ["Te revoilà ! Apprenons à exprimer la possession.", "Dis mon nom, ton nom, son nom (à lui ou à elle).", "My, your, his et her précèdent le nom : my book, your name.", "You name est incorrect ; il faut Your name.", "Demande What is your name? et réponds My name is ...", "Travaille /maɪ/ et /jʊr/ avec l’audio anglais."],
    ["Aujourd’hui, désignons les choses proches ou éloignées.", "Distingue this (près) de that (loin).", "On utilise This is pour ce qui est proche et That is pour ce qui est loin. Pour demander : Is this...?", "This my book est incomplet : This is my book.", "Tiens un stylo : This is my pen. Montre un objet éloigné : That is ...", "Entraîne-toi au son /ð/ dans this et that."],
  ],
  'zh': [
    ["你好！我是艾玛。今天一起学习用 I am 和 You are 介绍自己。", "学会说自己的名字、描述别人并提出简单问题。", "英语里 I 要搭配 am，you 要搭配 are。这里的 be 动词不能省略。", "I are 是错的，应该说 I am。", "大声说三遍 I am [你的名字]，再说 You are my friend。", "练习 am 中的 /æ/，并与 are 中的 /ɑː/ 对比。"],
    ["欢迎回来！今天学习如何表达所属关系。", "学会说“我的名字”“你的名字”“他的名字”“她的名字”。", "my、your、his、her 要放在名词前，例如 my book、your name。", "You name 不对，正确表达是 Your name。", "问 What is your name?，然后回答 My name is ...", "跟随英语原声练习 /maɪ/ 和 /jʊr/。"],
    ["今天我们学习指向近处和远处的东西。", "区分表示近处的 this 和表示远处的 that。", "近处说 This is，远处说 That is。提问时用 Is this...?", "This my book 少了 is，应说 This is my book。", "拿起笔说 This is my pen，再指远处说 That is ...", "练习 this 和 that 中的 /ð/ 音。"],
  ],
  'ko': [
    ["안녕하세요! 저는 엠마예요. 오늘은 I am과 You are로 자기소개를 배워요.", "이름을 말하고 다른 사람을 설명하며 간단한 질문을 해요.", "영어에서는 I 뒤에 am, you 뒤에 are를 써요. 여기서는 be동사를 생략할 수 없어요.", "I are는 틀리고 I am이 맞아요.", "I am [이름]을 세 번 소리 내어 말하고 You are my friend도 따라 해 보세요.", "am의 /æ/와 are의 /ɑː/ 소리를 비교해 보세요."],
    ["다시 만나서 반가워요! 오늘은 소유 표현을 배워요.", "내 이름, 네 이름, 그의 이름, 그녀의 이름을 영어로 말해요.", "my, your, his, her는 명사 앞에 와요. 예: my book, your name.", "You name은 잘못된 표현이에요. Your name이 맞아요.", "What is your name?으로 묻고 My name is ...로 답하세요.", "영어 음성을 들으며 /maɪ/와 /jʊr/를 연습하세요."],
    ["오늘은 가까운 물건과 먼 물건을 가리켜 볼게요.", "가까운 this와 먼 that을 구별해요.", "가까우면 This is, 멀면 That is를 써요. 질문은 Is this...?로 시작해요.", "This my book에는 is가 빠졌어요. This is my book이 맞아요.", "펜을 들고 This is my pen, 멀리 있는 물건을 가리키며 That is ...라고 말하세요.", "this와 that의 /ð/ 발음을 연습하세요."],
  ],
  'ja': [
    ["こんにちは、エマです。今日は I am と You are を使った自己紹介を学びます。", "名前を伝え、人を説明し、簡単な質問ができるようになります。", "英語では I に am、you に are を使います。この文では be 動詞を省略できません。", "I are は誤りで、I am が正しい形です。", "I am [名前] を3回声に出し、You are my friend も言ってみましょう。", "am の /æ/ と are の /ɑː/ を聞き比べましょう。"],
    ["おかえりなさい！今日は持ち主を表す語を学びます。", "「私の名前」「あなたの名前」「彼の名前」「彼女の名前」を言えるようになります。", "my、your、his、her は名詞の前に置きます。例：my book、your name。", "You name は誤りで、Your name が正しい形です。", "What is your name? と尋ね、My name is ... と答えましょう。", "英語音声に合わせて /maɪ/ と /jʊr/ を練習しましょう。"],
    ["今日は近くと遠くの物を指してみましょう。", "近くの this と遠くの that を区別します。", "近くは This is、遠くは That is。質問は Is this...? から始めます。", "This my book には is が必要です。This is my book。", "ペンを持ち This is my pen、遠くを指し That is ... と言いましょう。", "this と that の /ð/ の音を練習しましょう。"],
  ],
  'ru': [
    ["Привет! Я Эмма. Сегодня научимся представляться с I am и You are.", "Ты сможешь назвать своё имя, описать человека и задать простой вопрос.", "В английском после I нужен am, после you — are. Здесь глагол be нельзя пропускать.", "I are — ошибка; правильно I am.", "Три раза скажи вслух I am [имя], затем You are my friend.", "Сравни звук /æ/ в am со звуком /ɑː/ в are."],
    ["С возвращением! Сегодня изучим принадлежность.", "Научимся говорить «моё имя», «твоё имя», «его имя» и «её имя».", "My, your, his и her ставятся перед существительным: my book, your name.", "You name неверно; правильно Your name.", "Спроси What is your name? и ответь My name is ...", "Повторяй /maɪ/ и /jʊr/ за английским аудио."],
    ["Сегодня будем показывать на ближние и дальние предметы.", "Различай this для близкого и that для далёкого.", "Для близкого говори This is, для дальнего That is. Вопрос: Is this...?", "В This my book не хватает is: This is my book.", "Возьми ручку: This is my pen. Укажи вдаль: That is ...", "Тренируй звук /ð/ в this и that."],
  ],
  'tr': [
    ["Merhaba! Ben Emma. Bugün I am ve You are ile kendimizi tanıtacağız.", "Adını söylemeyi, birini tanımlamayı ve basit soru sormayı öğreneceksin.", "İngilizcede I ile am, you ile are kullanılır. Bu cümlelerde be fiili atlanamaz.", "I are yanlıştır; I am demelisin.", "I am [adın] cümlesini üç kez sesli söyle, ardından You are my friend de.", "am sözcüğündeki /æ/ ile are sözcüğündeki /ɑː/ seslerini karşılaştır."],
    ["Tekrar hoş geldin! Bugün iyelik ifadelerini öğreniyoruz.", "Benim adım, senin adın, onun adı ifadelerini kuracaksın.", "My, your, his, her isimden önce gelir: my book, your name.", "You name yanlıştır; Your name doğrudur.", "What is your name? diye sor ve My name is ... diye yanıtla.", "İngilizce sesleri dinleyerek /maɪ/ ve /jʊr/ alıştırması yap."],
    ["Bugün yakın ve uzak nesneleri göstereceğiz.", "Yakın için this, uzak için that kullanmayı öğren.", "Yakında This is, uzakta That is kullanılır. Soru: Is this...?", "This my book eksik bir cümledir: This is my book.", "Kalemini göster: This is my pen. Uzağı göster: That is ...", "this ve that içindeki /ð/ sesini çalış."],
  ],
  'ur': [
    ["سلام! میں ایما ہوں۔ آج ہم I am اور You are کے ذریعے اپنا تعارف سیکھیں گے۔", "آپ اپنا نام بتا سکیں گے، کسی کا تعارف کرائیں گے اور آسان سوال پوچھیں گے۔", "انگریزی میں I کے ساتھ am اور you کے ساتھ are آتا ہے۔ یہاں فعل be حذف نہیں ہوتا۔", "I are غلط ہے؛ درست I am ہے۔", "I am [اپنا نام] تین بار بلند آواز میں کہیں، پھر You are my friend کہیں۔", "am میں /æ/ اور are میں /ɑː/ کی آواز کا فرق سنیں۔"],
    ["واپس خوش آمدید! آج ملکیت کے الفاظ سیکھتے ہیں۔", "میرا نام، تمہارا نام، اس کا نام کہنا سیکھیں گے۔", "my، your، his، her اسم سے پہلے آتے ہیں: my book، your name۔", "You name غلط ہے؛ Your name درست ہے۔", "پوچھیں What is your name? اور جواب دیں My name is ...", "انگریزی آواز کے ساتھ /maɪ/ اور /jʊr/ کی مشق کریں۔"],
    ["آج قریب اور دور کی چیزوں کی طرف اشارہ کریں گے۔", "قریب کے لیے this اور دور کے لیے that کا فرق جانیں۔", "قریب کے لیے This is، دور کے لیے That is۔ سوال: Is this...?", "This my book میں is موجود نہیں؛ درست This is my book۔", "قلم اٹھائیں: This is my pen۔ دور اشارہ کریں: That is ...", "this اور that میں /ð/ کی آواز کی مشق کریں۔"],
  ],
  'de': [
    ["Hallo! Ich bin Emma. Heute stellen wir uns mit I am und You are vor.", "Du lernst, deinen Namen zu nennen, jemanden zu beschreiben und einfach zu fragen.", "Im Englischen steht am nach I und are nach you. Hier darf das Verb be nicht fehlen.", "I are ist falsch; richtig ist I am.", "Sag dreimal I am [dein Name] und danach You are my friend.", "Übe /æ/ in am und vergleiche es mit /ɑː/ in are."],
    ["Willkommen zurück! Heute geht es um Besitz.", "Du lernst mein Name, dein Name, sein Name und ihr Name auf Englisch.", "My, your, his und her stehen vor dem Nomen: my book, your name.", "You name ist falsch; es muss Your name heißen.", "Frage What is your name? und antworte My name is ...", "Übe /maɪ/ und /jʊr/ mit dem englischen Audio."],
    ["Heute zeigen wir auf nahe und entfernte Dinge.", "Unterscheide this für nah und that für fern.", "Für Nähe: This is. Für Entfernung: That is. Frage: Is this...?", "In This my book fehlt is: This is my book.", "Halte einen Stift hoch: This is my pen. Zeige in die Ferne: That is ...", "Übe den Laut /ð/ in this und that."],
  ],
  'pt': [
    ["Olá! Sou Emma. Hoje vamos nos apresentar usando I am e You are.", "Você aprenderá a dizer seu nome, descrever alguém e fazer perguntas simples.", "Em inglês, I usa am e you usa are. Não se omite o verbo be nessas frases.", "I are está errado; diga I am.", "Diga I am [seu nome] três vezes em voz alta e depois You are my friend.", "Pratique /æ/ em am e compare com /ɑː/ em are."],
    ["Bem-vindo de volta! Hoje veremos posse.", "Aprenda a dizer meu nome, seu nome, nome dele e nome dela.", "My, your, his e her vêm antes do substantivo: my book, your name.", "You name está errado; use Your name.", "Pergunte What is your name? e responda My name is ...", "Pratique /maɪ/ e /jʊr/ com áudio em inglês."],
    ["Hoje vamos apontar coisas próximas e distantes.", "Distinga this para perto e that para longe.", "Use This is para algo perto e That is para longe. Pergunte Is this...?", "This my book precisa de is: This is my book.", "Segure uma caneta e diga This is my pen; aponte longe e diga That is ...", "Pratique o som /ð/ em this e that."],
  ],
  'fa': [
    ["سلام! من اِما هستم. امروز معرفی خود را با I am و You are یاد می‌گیریم.", "می‌توانی نامت را بگویی، کسی را توصیف کنی و سؤال ساده بپرسی.", "در انگلیسی با I از am و با you از are استفاده می‌کنیم. فعل be در این جمله‌ها حذف نمی‌شود.", "I are اشتباه است؛ درست آن I am است.", "سه بار I am [نام خودت] را بلند بگو و سپس You are my friend.", "صدای /æ/ در am را با /ɑː/ در are مقایسه کن."],
    ["خوش برگشتی! امروز مالکیت را یاد می‌گیریم.", "عبارت‌های نام من، نام تو، نام او را خواهی آموخت.", "my و your و his و her قبل از اسم می‌آیند: my book، your name.", "You name اشتباه است؛ باید Your name باشد.", "بپرس What is your name? و جواب بده My name is ...", "با صدای انگلیسی /maɪ/ و /jʊr/ را تمرین کن."],
    ["امروز به چیزهای نزدیک و دور اشاره می‌کنیم.", "فرق this برای نزدیک و that برای دور را یاد بگیر.", "برای نزدیک This is و برای دور That is می‌گوییم. سؤال: Is this...?", "در This my book فعل is جا افتاده است: This is my book.", "قلمی را بردار و بگو This is my pen، سپس به دور اشاره کن و بگو That is ...", "صدای /ð/ را در this و that تمرین کن."],
  ],
  'id': [
    ["Halo! Saya Emma. Hari ini kita belajar memperkenalkan diri dengan I am dan You are.", "Kamu bisa menyebut nama, menjelaskan seseorang, dan bertanya sederhana.", "Dalam bahasa Inggris, gunakan am setelah I dan are setelah you. Kata kerja be tidak boleh dihilangkan di sini.", "I are salah; yang benar I am.", "Ucapkan I am [namamu] tiga kali, lalu You are my friend.", "Latih /æ/ dalam am dan bandingkan dengan /ɑː/ dalam are."],
    ["Selamat datang kembali! Hari ini kita belajar kepemilikan.", "Katakan namaku, namamu, namanya (laki-laki atau perempuan).", "My, your, his, dan her ada sebelum kata benda: my book, your name.", "You name salah; gunakan Your name.", "Tanyakan What is your name? dan jawab My name is ...", "Latih /maɪ/ dan /jʊr/ dengan audio Inggris."],
    ["Hari ini kita menunjuk benda dekat dan jauh.", "Bedakan this untuk yang dekat dan that untuk yang jauh.", "Gunakan This is untuk dekat dan That is untuk jauh. Pertanyaan: Is this...?", "This my book kurang is: This is my book.", "Pegang pena dan katakan This is my pen; tunjuk jauh dan katakan That is ...", "Latih suara /ð/ dalam this dan that."],
  ],
  'th': [
    ["สวัสดี! ฉันชื่อเอ็มมา วันนี้เราจะเรียนการแนะนำตัวด้วย I am และ You are", "คุณจะบอกชื่อ อธิบายบุคคล และถามคำถามง่าย ๆ ได้", "ภาษาอังกฤษใช้ am กับ I และ are กับ you ในประโยคนี้ห้ามละกริยา be", "I are ไม่ถูกต้อง ต้องใช้ I am", "พูด I am [ชื่อของคุณ] ดัง ๆ สามครั้ง แล้วพูด You are my friend", "ฝึกเสียง /æ/ ใน am และเปรียบเทียบกับ /ɑː/ ใน are"],
    ["ยินดีต้อนรับกลับมา! วันนี้เราเรียนคำแสดงความเป็นเจ้าของ", "ฝึกพูดชื่อของฉัน ชื่อของคุณ ชื่อของเขาและชื่อของเธอ", "my, your, his, her ต้องอยู่หน้าคำนาม เช่น my book, your name", "You name ไม่ถูกต้อง ต้องเป็น Your name", "ถาม What is your name? และตอบ My name is ...", "ฝึก /maɪ/ และ /jʊr/ ด้วยเสียงภาษาอังกฤษ"],
    ["วันนี้เราจะชี้สิ่งของที่อยู่ใกล้และไกล", "แยก this สำหรับใกล้ และ that สำหรับไกล", "ใช้ This is กับสิ่งใกล้ และ That is กับสิ่งไกล คำถามใช้ Is this...?", "This my book ขาด is ต้องเป็น This is my book", "ถือปากกาแล้วพูด This is my pen จากนั้นชี้ไปไกล ๆ พูด That is ...", "ฝึกเสียง /ð/ ใน this และ that"],
  ],
  'hi': [
    ["नमस्ते! मैं एम्मा हूँ। आज हम I am और You are से अपना परिचय देना सीखेंगे।", "आप अपना नाम बताएँगे, किसी का वर्णन करेंगे और सरल प्रश्न पूछेंगे।", "अंग्रेज़ी में I के साथ am और you के साथ are आता है। यहाँ be क्रिया छोड़ नहीं सकते।", "I are गलत है; सही I am है।", "I am [अपना नाम] तीन बार बोलें, फिर You are my friend कहें।", "am के /æ/ और are के /ɑː/ स्वरों का अंतर सुनें।"],
    ["वापस स्वागत है! आज स्वामित्व बताना सीखेंगे।", "मेरा नाम, तुम्हारा नाम, उसका नाम कहना सीखें।", "my, your, his, her संज्ञा से पहले आते हैं: my book, your name.", "You name गलत है; Your name सही है।", "पूछें What is your name? और जवाब दें My name is ...", "अंग्रेज़ी ऑडियो से /maɪ/ और /jʊr/ बोलने का अभ्यास करें।"],
    ["आज पास और दूर की चीज़ें दिखाना सीखेंगे।", "पास के this और दूर के that का अंतर समझें।", "पास के लिए This is, दूर के लिए That is। प्रश्न: Is this...?", "This my book में is नहीं है; सही है This is my book।", "कलम पकड़ें: This is my pen। दूर इशारा करें: That is ...", "this और that में /ð/ ध्वनि का अभ्यास करें।"],
  ],
  'it': [
    ["Ciao! Sono Emma. Oggi impariamo a presentarci con I am e You are.", "Saprai dire il tuo nome, descrivere qualcuno e fare domande semplici.", "In inglese si usa am con I e are con you. Il verbo be qui non si può omettere.", "I are è sbagliato; devi dire I am.", "Ripeti I am [il tuo nome] tre volte, poi You are my friend.", "Esercitati con /æ/ in am e confrontalo con /ɑː/ in are."],
    ["Bentornato! Oggi impariamo il possesso.", "Dirai il mio nome, il tuo nome, il suo nome (di lui o lei).", "My, your, his e her precedono il nome: my book, your name.", "You name è sbagliato; si dice Your name.", "Chiedi What is your name? e rispondi My name is ...", "Esercitati con /maɪ/ e /jʊr/ ascoltando l'inglese."],
    ["Oggi indichiamo oggetti vicini e lontani.", "Distingui this (vicino) e that (lontano).", "Per vicino: This is. Per lontano: That is. Domanda: Is this...?", "In This my book manca is: This is my book.", "Prendi una penna: This is my pen. Indica lontano: That is ...", "Esercitati con /ð/ in this e that."],
  ],
  };

  static AcademyTutorTranslatedCopy lesson(String locale, int number) {
    final notes = _notes[locale] ?? _notes['en']!;
    if (number < 1 || number > notes.length) {
      throw RangeError.range(number, 1, notes.length);
    }
    return AcademyTutorTranslatedCopy(notes[number - 1]);
  }

  static bool supports(String locale) => _notes.containsKey(locale);
}


/// Translations of the English practice examples for the 17 supported app
/// languages. The English source sentences remain visible for learning.
extension AcademyTutorExampleTranslations on AcademyTutorTranslatedCopy {}

abstract final class AcademyTutorExamples {
  static const Map<String, List<List<String>>> _translations = {
    'ar': [
      ["أنا سارة.","أنا طالب.","أنت صديقي.","هل أنت طالب؟","نعم، أنا كذلك. / لا، لست كذلك."],
      ["اسمي مايا.","ما اسمك؟","هذا كتابي.","اسمه ليو.","اسمها نينا."],
      ["هذا قلمي.","تلك حقيبتك.","هل هذا كتابك؟","نعم، هو كذلك.","لا، ذلك ليس دفتري."],
    ],
    'en': [
      ["I am Sara.","I am a student.","You are my friend.","Are you a student?","Yes, I am. / No, I am not."],
      ["My name is Maya.","What is your name?","This is my book.","His name is Leo.","Her name is Nina."],
      ["This is my pen.","That is your bag.","Is this your book?","Yes, it is.","No, that is not my notebook."],
    ],
    'es': [
      ["Soy Sara.","Soy estudiante.","Eres mi amigo.","¿Eres estudiante?","Sí, lo soy. / No, no lo soy."],
      ["Me llamo Maya.","¿Cómo te llamas?","Este es mi libro.","Se llama Leo.","Se llama Nina."],
      ["Este es mi bolígrafo.","Esa es tu mochila.","¿Este es tu libro?","Sí, lo es.","No, ese no es mi cuaderno."],
    ],
    'fr': [
      ["Je suis Sara.","Je suis étudiant(e).","Tu es mon ami(e).","Es-tu étudiant(e) ?","Oui. / Non."],
      ["Je m’appelle Maya.","Comment t’appelles-tu ?","C’est mon livre.","Il s’appelle Leo.","Elle s’appelle Nina."],
      ["C’est mon stylo.","C’est ton sac là-bas.","Est-ce ton livre ?","Oui, c’est ça.","Non, ce n’est pas mon cahier."],
    ],
    'zh': [
      ["我是萨拉。","我是一名学生。","你是我的朋友。","你是学生吗？","是的，我是。/ 不，我不是。"],
      ["我叫玛雅。","你叫什么名字？","这是我的书。","他的名字叫利奥。","她的名字叫妮娜。"],
      ["这是我的笔。","那是你的包。","这是你的书吗？","是的。","不，那不是我的笔记本。"],
    ],
    'ko': [
      ["저는 사라예요.","저는 학생이에요.","당신은 제 친구예요.","학생인가요?","네, 맞아요. / 아니요, 아니에요."],
      ["제 이름은 마야예요.","이름이 뭐예요?","이것은 제 책이에요.","그의 이름은 레오예요.","그녀의 이름은 니나예요."],
      ["이것은 제 펜이에요.","저것은 당신의 가방이에요.","이것은 당신의 책인가요?","네, 맞아요.","아니요, 저것은 제 공책이 아니에요."],
    ],
    'ja': [
      ["私はサラです。","私は学生です。","あなたは私の友達です。","学生ですか？","はい、そうです。／いいえ、違います。"],
      ["私の名前はマヤです。","お名前は何ですか？","これは私の本です。","彼の名前はレオです。","彼女の名前はニナです。"],
      ["これは私のペンです。","あれはあなたのかばんです。","これはあなたの本ですか？","はい、そうです。","いいえ、あれは私のノートではありません。"],
    ],
    'ru': [
      ["Я Сара.","Я студент(ка).","Ты мой друг.","Ты студент(ка)?","Да. / Нет."],
      ["Меня зовут Майя.","Как тебя зовут?","Это моя книга.","Его зовут Лео.","Её зовут Нина."],
      ["Это моя ручка.","Та сумка — твоя.","Это твоя книга?","Да.","Нет, та тетрадь не моя."],
    ],
    'tr': [
      ["Ben Sara'yım.","Ben öğrenciyim.","Sen benim arkadaşımsın.","Öğrenci misin?","Evet. / Hayır."],
      ["Benim adım Maya.","Adın ne?","Bu benim kitabım.","Onun adı Leo.","Onun adı Nina."],
      ["Bu benim kalemim.","Şu senin çantan.","Bu senin kitabın mı?","Evet.","Hayır, şu benim defterim değil."],
    ],
    'ur': [
      ["میں سارا ہوں۔","میں طالب علم ہوں۔","تم میرے دوست ہو۔","کیا تم طالب علم ہو؟","ہاں۔ / نہیں۔"],
      ["میرا نام مایا ہے۔","تمہارا نام کیا ہے؟","یہ میری کتاب ہے۔","اس کا نام لیو ہے۔","اس کا نام نینا ہے۔"],
      ["یہ میرا قلم ہے۔","وہ تمہارا بیگ ہے۔","کیا یہ تمہاری کتاب ہے؟","ہاں۔","نہیں، وہ میری کاپی نہیں ہے۔"],
    ],
    'de': [
      ["Ich bin Sara.","Ich bin Student(in).","Du bist mein Freund / meine Freundin.","Bist du Student(in)?","Ja. / Nein."],
      ["Ich heiße Maya.","Wie heißt du?","Das ist mein Buch.","Er heißt Leo.","Sie heißt Nina."],
      ["Das ist mein Stift.","Das dort ist deine Tasche.","Ist das dein Buch?","Ja.","Nein, das dort ist nicht mein Heft."],
    ],
    'pt': [
      ["Eu sou Sara.","Sou estudante.","Você é meu amigo.","Você é estudante?","Sim, sou. / Não, não sou."],
      ["Meu nome é Maya.","Qual é o seu nome?","Este é meu livro.","O nome dele é Leo.","O nome dela é Nina."],
      ["Esta é minha caneta.","Aquela é sua bolsa.","Este é seu livro?","Sim.","Não, aquele não é meu caderno."],
    ],
    'fa': [
      ["من سارا هستم.","من دانش‌آموز هستم.","تو دوست من هستی.","آیا دانش‌آموز هستی؟","بله، هستم. / نه، نیستم."],
      ["نام من مایا است.","نام تو چیست؟","این کتاب من است.","نام او لئو است.","نام او نینا است."],
      ["این خودکار من است.","آن کیف تو است.","آیا این کتاب تو است؟","بله.","نه، آن دفتر من نیست."],
    ],
    'id': [
      ["Saya Sara.","Saya seorang pelajar.","Kamu teman saya.","Apakah kamu pelajar?","Ya. / Tidak."],
      ["Nama saya Maya.","Siapa namamu?","Ini buku saya.","Namanya Leo.","Namanya Nina."],
      ["Ini pena saya.","Itu tasmu.","Apakah ini bukumu?","Ya.","Tidak, itu bukan buku catatan saya."],
    ],
    'th': [
      ["ฉันชื่อซารา","ฉันเป็นนักเรียน","คุณเป็นเพื่อนของฉัน","คุณเป็นนักเรียนไหม?","ใช่ / ไม่ใช่"],
      ["ฉันชื่อมายา","คุณชื่ออะไร?","นี่คือหนังสือของฉัน","เขาชื่อเลโอ","เธอชื่อนีนา"],
      ["นี่คือปากกาของฉัน","นั่นคือกระเป๋าของคุณ","นี่คือหนังสือของคุณใช่ไหม?","ใช่","ไม่ นั่นไม่ใช่สมุดของฉัน"],
    ],
    'hi': [
      ["मैं सारा हूँ।","मैं विद्यार्थी हूँ।","तुम मेरे दोस्त हो।","क्या तुम विद्यार्थी हो?","हाँ। / नहीं।"],
      ["मेरा नाम माया है।","तुम्हारा नाम क्या है?","यह मेरी किताब है।","उसका नाम लियो है।","उसका नाम नीना है।"],
      ["यह मेरी कलम है।","वह तुम्हारा बैग है।","क्या यह तुम्हारी किताब है?","हाँ।","नहीं, वह मेरी नोटबुक नहीं है।"],
    ],
    'it': [
      ["Sono Sara.","Sono uno studente / una studentessa.","Sei mio amico / mia amica.","Sei uno studente?","Sì. / No."],
      ["Mi chiamo Maya.","Come ti chiami?","Questo è il mio libro.","Si chiama Leo.","Si chiama Nina."],
      ["Questa è la mia penna.","Quella è la tua borsa.","Questo è il tuo libro?","Sì.","No, quello non è il mio quaderno."],
    ],
  };

  static String forExample(String locale, int lesson, int index) {
    if (lesson < 1 || lesson > 3 || index < 0 || index > 4) {
      throw RangeError('Tutor example outside supported lessons');
    }
    return (_translations[locale] ?? _translations['en']!)[lesson - 1][index];
  }
}
