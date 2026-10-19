/// Reviewed, offline, user-interface-language explanations for Emma's
/// first three English A1 teaching sessions.
///
/// The English teaching sentences and pronunciation remain in English.
/// All other content is selected by the *app interface locale*, never by the
/// target language of the course. No network translation or API cost.
class AcademyTutorLanguagePack {
  const AcademyTutorLanguagePack(this.sections, this.labels);
  /// Each lesson: welcome, goal, grammar, common mistake, practice tip, IPA tip.
  final List<List<String>> sections;
  final List<String> labels;
}

abstract final class AcademyTutorTranslations {
  static const String fallbackLocale = 'en';
  static const supported = <String>[
    'ar', 'en', 'es', 'fr', 'zh', 'ko', 'ja', 'ru', 'tr',
    'ur', 'de', 'pt', 'fa', 'id', 'th', 'hi', 'it',
  ];
  static const _packs = <String, AcademyTutorLanguagePack>{
    "ar": AcademyTutorLanguagePack([
      ["مرحبًا! أنا إيما، معلمتك في WorldVoice. اليوم سنتعلم كيف تعرّف بنفسك.","ستستطيع قول اسمك واستخدام I am وYou are بشكل صحيح.","في الإنجليزية نستخدم am مع I وare مع you ولا نحذف فعل be مثل I am a student.","مع I نستخدم am لا are، ومع you نستخدم are.","قل I am [اسمك] ثم You are my friend وردد بصوت واضح.","استمع للصوت الإنجليزي وراقب /æ/ في am و/ɑːr/ في are.",],
      ["مرحبًا مجددًا! اليوم سنتعلم أسماء الأشخاص والملكية.","اسأل What is your name? وأجب My name is...","نستخدم my وyour قبل الاسم، مثل my book وyour name، وhis وher للملكية.","you تعني أنت، أما your فتعني خاصتك.","اسأل عن الاسم ثم أجب باستخدام اسمك الحقيقي.","قارن بين you /juː/ وyour /jʊr/ وانتبه إلى /eɪ/ في name.",],
      ["اليوم سنتعلم الإشارة إلى الأشياء القريبة والبعيدة.","ستستخدم This is وThat is وIs this your بشكل صحيح.","this للقريب وthat للأبعد، ويأتي is بعد كليهما.","لا تحذف is: الصحيح This is my book.","أمسك قلمًا وقل This is my pen ثم أشر إلى شيء بعيد.","تدرب على /ð/ في this /ðɪs/ وthat /ðæt/ عبر الصوت الإنجليزي.",],
    ], ["الأستاذة إيما · شرح تفاعلي","القواعد · حوالي 5 دقائق","هدفنا اليوم","قاعدة سهلة تتذكرها","نتدرب على خمس جمل","استمع للمثال","خطأ شائع","اختبر فهمك","أجب عن ثلاثة أسئلة لتكمل","أحسنت! تابع إلى المفردات","السؤال","نصيحة الأستاذة","اختر إجابتك","الإجابة صحيحة!","حاول مرة أخرى","تابع",]),
    "en": AcademyTutorLanguagePack([
      ["Welcome back! I am Emma, your English tutor. We will practise introducing ourselves and making natural sentences.","You will be able to say your name and choose I am or You are correctly.","Use am with I, and are with you. English needs the verb be in sentences such as I am a student.","I takes am, not are. You takes are, not am.","Say I am [your name], then You are my friend. Practise aloud before moving on.","Use the English audio and IPA. Listen carefully to /æ/ in am and /ɑːr/ in are.",],
      ["Today we will learn how to talk about things that belong to people.","Ask What is your name? and answer My name is ... .","Use my and your before a noun: my book, your name. Use his for a male person's possession and her for a female person's.","You means the person; your shows possession. Say Your name is Sara.","Practise asking What is your name? and answering My name is ... .","Compare you /juː/ with your /jʊr/. Hear /eɪ/ in name.",],
      ["Today you will learn to point to objects near and far.","Use This is..., That is..., and Is this your...?","Use this for one nearby object and that for one farther away. Both use is.","Do not leave out is: This is my book, not This my book.","Hold a pen and say This is my pen. Point away and say That is my bag.","Practise /ð/ in this /ðɪs/ and that /ðæt/. Use the English audio.",],
    ], ["Tutor Emma · Guided lesson","Grammar · about 5 minutes","Today's goal","Remember the pattern","Let's practise five examples","Hear example","Common mistake","Quick understanding check","Answer three questions to continue","Great! Continue to vocabulary","Question","Tutor's tip","Choose your answer","Correct!","Try again","Continue",]),
    "es": AcademyTutorLanguagePack([
      ["¡Hola! Soy Emma, tu profesora de inglés. Hoy aprenderemos a presentarnos con frases naturales.","Al terminar podrás decir tu nombre y usar I am y You are correctamente.","En inglés usamos am con I y are con you. No se omite el verbo be: I am a student.","Con I se usa am, nunca are. Con you se usa are.","Di I am [tu nombre] y después You are my friend. Repítelo en voz alta.","Escucha el audio en inglés y mira el AFI: /æ/ en am es diferente de /ɑːr/ en are.",],
      ["¡Bienvenido de nuevo! Hoy hablaremos de nombres y pertenencias.","Aprenderás a preguntar What is your name? y responder My name is...","My y your van antes del sustantivo: my book, your name. His y her expresan posesión de otras personas.","You significa «tú»; your indica posesión. Di Your name is Sara.","Practica la pregunta What is your name? y responde con tu nombre.","Compara you /juː/ y your /jʊr/; name lleva el sonido /eɪ/.",],
      ["Ahora vamos a señalar objetos cercanos y lejanos.","Aprenderás This is..., That is... e Is this your...?","This señala algo cercano y that algo más lejano. Ambos llevan is.","No olvides is: This is my book, no This my book.","Sujeta un bolígrafo y di This is my pen; señala algo lejano y di That is my bag.","Practica /ð/ en this /ðɪs/ y that /ðæt/, con el audio en inglés.",],
    ], ["Emma · Clase guiada","Gramática · unos 5 minutos","Objetivo de hoy","Recuerda la estructura","Practiquemos cinco ejemplos","Escuchar ejemplo","Error frecuente","Comprueba lo aprendido","Responde tres preguntas para continuar","¡Bien! Continúa con vocabulario","Pregunta","Consejo de la profesora","Elige una respuesta","¡Correcto!","Inténtalo otra vez","Continuar",]),
    "fr": AcademyTutorLanguagePack([
      ["Bonjour ! Je suis Emma, votre professeure d’anglais. Aujourd’hui, nous allons apprendre à nous présenter.","Vous saurez dire votre nom et choisir correctement I am ou You are.","En anglais, on utilise am avec I et are avec you. Le verbe be est nécessaire : I am a student.","Avec I, on dit am et non are. Avec you, on dit are.","Dites I am [votre prénom], puis You are my friend. Répétez à voix haute.","Écoutez l’anglais et suivez l’API : /æ/ dans am diffère de /ɑːr/ dans are.",],
      ["Aujourd’hui, parlons des noms et de ce qui nous appartient.","Vous apprendrez à demander What is your name? et à répondre My name is...","My et your précèdent le nom : my book, your name. His et her indiquent aussi la possession.","You désigne la personne ; your exprime la possession. Dites Your name is Sara.","Demandez What is your name? et répondez avec votre prénom.","Comparez you /juː/ et your /jʊr/ ; name contient /eɪ/.",],
      ["Apprenons maintenant à désigner les objets proches ou éloignés.","Vous utiliserez This is..., That is... et Is this your...?","This désigne un objet proche et that un objet plus éloigné. Les deux prennent is.","N’oubliez pas is : This is my book, et non This my book.","Prenez un stylo : This is my pen. Montrez un objet plus loin : That is my bag.","Entraînez-vous au son /ð/ de this /ðɪs/ et that /ðæt/.",],
    ], ["Emma · Leçon guidée","Grammaire · environ 5 minutes","Objectif du jour","Retenez la structure","Pratiquons cinq exemples","Écouter l’exemple","Erreur fréquente","Vérifions votre compréhension","Répondez à trois questions","Bravo ! Passez au vocabulaire","Question","Conseil de la professeure","Choisissez une réponse","Bonne réponse !","Réessayez","Continuer",]),
    "zh": AcademyTutorLanguagePack([
      ["你好！我是你的英语老师 Emma。今天我们一起练习自我介绍和自然的英语句子。","学完后，你能介绍自己的名字，并正确使用 I am 和 You are。","英语里，I 后面用 am，you 后面用 are。句子里不能省略 be 动词，例如 I am a student。","I 搭配 am，不搭配 are；you 搭配 are。","先说 I am [你的名字]，再说 You are my friend。跟着音频多读几遍。","听英语原音，观察国际音标：am 中的 /æ/ 与 are 中的 /ɑːr/ 不同。",],
      ["今天我们来学习怎样表达名字和所属关系。","学会问 What is your name?，并回答 My name is...","my、your 放在名词前面，例如 my book、your name。his 和 her 也表示所属关系。","you 是“你”，your 是“你的”。要说 Your name is Sara。","问 What is your name?，再用自己的名字回答。","比较 you /juː/ 和 your /jʊr/；name 含有 /eɪ/ 音。",],
      ["今天学习指向近处和远处的物品。","会使用 This is...、That is... 和 Is this your...?","this 指近处的一个物品，that 指远处的一个物品，两者后面都用 is。","不要漏掉 is：This is my book，而不是 This my book。","拿起一支笔说 This is my pen，再指向远处说 That is my bag。","跟读 this /ðɪs/ 和 that /ðæt/ 中的 /ð/ 音。",],
    ], ["艾玛老师 · 引导课程","语法 · 约5分钟","今天的目标","记住句型","练习五个例句","听例句","常见错误","检查理解程度","回答三个问题后继续","做得好！继续学习词汇","问题","老师的小提示","选择答案","回答正确！","再试一次","继续",]),
    "ko": AcademyTutorLanguagePack([
      ["안녕하세요! 영어 선생님 Emma예요. 오늘은 자기소개와 자연스러운 영어 문장을 함께 배워요.","이름을 소개하고 I am과 You are를 정확히 사용할 수 있어요.","영어에서는 I 뒤에 am, you 뒤에 are를 써요. I am a student처럼 be동사를 생략하지 않아요.","I에는 am을, you에는 are를 써야 해요.","I am [이름]이라고 말한 뒤 You are my friend를 따라 말해 보세요.","영어 음성을 듣고 IPA를 보세요. am의 /æ/와 are의 /ɑːr/는 달라요.",],
      ["이번에는 이름과 소유를 표현하는 방법을 배워요.","What is your name?이라고 묻고 My name is...라고 답해 보세요.","my와 your는 명사 앞에 와요: my book, your name. his와 her도 소유를 나타내요.","you는 ‘너’, your는 ‘너의’를 뜻해요. Your name is Sara라고 말해요.","What is your name?을 묻고 자기 이름으로 답해 보세요.","you /juː/와 your /jʊr/를 비교하고 name의 /eɪ/ 소리를 들어 보세요.",],
      ["오늘은 가까운 물건과 먼 물건을 가리키는 법을 배워요.","This is..., That is..., Is this your...?를 쓸 수 있어요.","this는 가까운 한 물건, that은 조금 떨어진 한 물건을 가리켜요. 둘 다 is와 써요.","is를 빼면 안 돼요: This is my book이 맞아요.","펜을 들고 This is my pen, 멀리 있는 가방을 가리키며 That is my bag이라고 말해 보세요.","this /ðɪs/, that /ðæt/의 /ð/ 소리를 영어 음성으로 익혀 보세요.",],
    ], ["엠마 선생님 · 단계별 수업","문법 · 약 5분","오늘의 목표","문장 패턴 기억하기","예문 다섯 개 연습","예문 듣기","자주 하는 실수","이해도 확인","세 문제를 풀고 계속하세요","잘했어요! 어휘로 넘어가요","문제","선생님의 팁","답을 고르세요","정답이에요!","다시 해 보세요","계속",]),
    "ja": AcademyTutorLanguagePack([
      ["こんにちは！英語の先生のエマです。今日は自己紹介と自然な英文を一緒に練習しましょう。","自分の名前を言い、I am と You are を正しく使えるようになります。","英語では I の後に am、you の後に are を使います。I am a student のように be 動詞を省略しません。","I には am、you には are を使います。","I am [あなたの名前]、次に You are my friend と声に出して言いましょう。","英語の音声と IPA を確認しましょう。am の /æ/ と are の /ɑːr/ は異なります。",],
      ["今日は名前と持ち主の表し方を学びます。","What is your name? と質問し、My name is... と答えましょう。","my と your は名詞の前に置きます：my book、your name。his と her も所有を表します。","you は「あなた」、your は「あなたの」です。Your name is Sara と言います。","What is your name? と聞いて、自分の名前で答えましょう。","you /juː/ と your /jʊr/、name の /eɪ/ を聞き比べましょう。",],
      ["近くと遠くの物を指し示す表現を学びます。","This is...、That is...、Is this your...? を使いましょう。","this は近くの一つの物、that は遠くの一つの物です。どちらも is と使います。","is を省略しません：This is my book が正しい形です。","ペンを持って This is my pen、遠くを指して That is my bag と言ってみましょう。","this /ðɪs/ と that /ðæt/ の /ð/ を英語音声で練習しましょう。",],
    ], ["エマ先生 · ガイド付きレッスン","文法 · 約5分","今日の目標","文の形を覚えましょう","例文を5つ練習","例文を聞く","よくある間違い","理解度チェック","3問に答えて次へ","よくできました！単語へ進みましょう","問題","先生のヒント","答えを選択","正解！","もう一度","続ける",]),
    "ru": AcademyTutorLanguagePack([
      ["Привет! Я Эмма, твой преподаватель английского. Сегодня научимся знакомиться и строить простые предложения.","Ты сможешь представиться и правильно использовать I am и You are.","В английском после I ставится am, а после you — are. Глагол be нельзя пропускать: I am a student.","После I нужно am, а после you — are.","Скажи I am [своё имя], затем You are my friend. Повтори вслух.","Слушай английскую речь и смотри транскрипцию IPA: /æ/ в am и /ɑːr/ в are звучат по-разному.",],
      ["Сегодня научимся говорить об именах и принадлежности.","Научись спрашивать What is your name? и отвечать My name is...","my и your стоят перед существительным: my book, your name. his и her тоже обозначают принадлежность.","you означает «ты», а your — «твой». Говори Your name is Sara.","Спроси What is your name? и ответь, назвав своё имя.","Сравни you /juː/ и your /jʊr/; в name есть звук /eɪ/.",],
      ["Теперь научимся указывать на близкие и далёкие предметы.","Используй This is..., That is... и Is this your...?","this указывает на близкий предмет, that — на более далёкий. После обоих ставится is.","Не пропускай is: правильно This is my book.","Возьми ручку и скажи This is my pen. Укажи вдаль: That is my bag.","Отработай /ð/ в this /ðɪs/ и that /ðæt/ по аудио.",],
    ], ["Преподаватель Эмма · Урок","Грамматика · около 5 минут","Цель урока","Запомни структуру","Пять примеров","Прослушать пример","Частая ошибка","Проверка понимания","Ответь на три вопроса","Отлично! Переходи к словам","Вопрос","Совет преподавателя","Выбери ответ","Верно!","Попробуй ещё раз","Продолжить",]),
    "tr": AcademyTutorLanguagePack([
      ["Merhaba! Ben İngilizce öğretmenin Emma. Bugün kendimizi tanıtmayı ve doğru cümleler kurmayı öğreneceğiz.","Adını söyleyebilecek ve I am ile You are kalıplarını doğru kullanabileceksin.","İngilizcede I ile am, you ile are kullanılır. I am a student cümlesindeki be fiili atlanamaz.","I ile am, you ile are kullanmalısın.","I am [adın] de, ardından You are my friend cümlesini sesli tekrarla.","İngilizce sesi dinle ve IPA işaretlerine bak: am içindeki /æ/ ve are içindeki /ɑːr/ farklıdır.",],
      ["Bugün isimleri ve sahipliği anlatmayı öğreneceğiz.","What is your name? diye sorup My name is... diye cevap vereceksin.","my ve your isimden önce gelir: my book, your name. his ve her de sahiplik belirtir.","you “sen”, your ise “senin” demektir. Your name is Sara de.","What is your name? sorusunu sor ve kendi adınla cevap ver.","you /juː/ ve your /jʊr/ seslerini karşılaştır; name sözcüğündeki /eɪ/ sesini dinle.",],
      ["Bugün yakın ve uzaktaki nesneleri göstereceğiz.","This is..., That is... ve Is this your...? kalıplarını kullanacaksın.","this yakındaki, that daha uzaktaki tek bir nesneyi gösterir. İkisinden sonra da is gelir.","is sözcüğünü atlama: This is my book doğru biçimdir.","Bir kalem tutup This is my pen de; uzağı gösterip That is my bag de.","this /ðɪs/ ve that /ðæt/ içindeki /ð/ sesini çalış.",],
    ], ["Öğretmen Emma · Rehberli ders","Dil bilgisi · yaklaşık 5 dakika","Bugünkü hedef","Kalıbı hatırla","Beş örnekle alıştırma","Örneği dinle","Yaygın hata","Anladığını kontrol et","Devam etmek için üç soruyu cevapla","Harika! Kelimelere geç","Soru","Öğretmenin ipucu","Cevabı seç","Doğru!","Tekrar dene","Devam",]),
    "ur": AcademyTutorLanguagePack([
      ["السلام علیکم! میں ایما ہوں، آپ کی انگریزی استانی۔ آج ہم اپنا تعارف کروانا اور آسان جملے بنانا سیکھیں گے۔","آپ اپنا نام بتا سکیں گے اور I am اور You are درست استعمال کریں گے۔","انگریزی میں I کے ساتھ am اور you کے ساتھ are آتا ہے۔ I am a student میں فعل be حذف نہیں ہوتا۔","I کے ساتھ am اور you کے ساتھ are استعمال کریں۔","I am [اپنا نام] کہیں، پھر You are my friend بلند آواز سے دہرائیں۔","انگریزی آواز سنیں اور IPA دیکھیں: am کا /æ/ اور are کا /ɑːr/ مختلف ہیں۔",],
      ["آج ہم نام اور ملکیت ظاہر کرنا سیکھیں گے۔","آپ What is your name? پوچھ سکیں گے اور My name is... جواب دیں گے۔","my اور your اسم سے پہلے آتے ہیں: my book، your name۔ his اور her بھی ملکیت ظاہر کرتے ہیں۔","you کا مطلب آپ، جبکہ your کا مطلب آپ کا ہے۔ Your name is Sara کہیں۔","What is your name? پوچھیں اور اپنے نام سے جواب دیں۔","you /juː/ اور your /jʊr/ میں فرق سنیں؛ name میں /eɪ/ کی آواز ہے۔",],
      ["آج قریب اور دور کی چیزوں کی طرف اشارہ کرنا سیکھیں گے۔","آپ This is...، That is... اور Is this your...? استعمال کریں گے۔","this قریب کی چیز اور that دور کی چیز کے لیے ہے۔ دونوں کے ساتھ is استعمال ہوتا ہے۔","is مت چھوڑیں: درست جملہ This is my book ہے۔","قلم اٹھا کر This is my pen کہیں، پھر دور اشارہ کر کے That is my bag کہیں۔","this /ðɪs/ اور that /ðæt/ میں /ð/ کی آواز کی مشق کریں۔",],
    ], ["استاد ایما · رہنمائی والا سبق","گرامر · تقریباً 5 منٹ","آج کا مقصد","جملے کا نمونہ یاد رکھیں","پانچ مثالوں کی مشق","مثال سنیں","عام غلطی","اپنی سمجھ جانچیں","آگے بڑھنے کے لیے تین سوال حل کریں","بہت خوب! الفاظ پر جائیں","سوال","استاد کی نصیحت","جواب منتخب کریں","درست!","دوبارہ کوشش کریں","جاری رکھیں",]),
    "de": AcademyTutorLanguagePack([
      ["Hallo! Ich bin Emma, deine Englischlehrerin. Heute üben wir, uns vorzustellen und richtige englische Sätze zu bilden.","Du kannst anschließend deinen Namen nennen und I am sowie You are richtig verwenden.","Nach I steht am, nach you steht are. Das Verb be darf nicht fehlen: I am a student.","Mit I verwendet man am, mit you verwendet man are.","Sag I am [dein Name] und anschließend You are my friend. Wiederhole beides laut.","Höre die englische Aussprache und lies die IPA-Zeichen: /æ/ in am unterscheidet sich von /ɑːr/ in are.",],
      ["Heute geht es um Namen und Zugehörigkeit.","Frage What is your name? und antworte My name is...","my und your stehen vor Nomen: my book, your name. his und her zeigen ebenfalls Besitz an.","you bedeutet „du“, your bedeutet „dein“. Sage Your name is Sara.","Übe die Frage What is your name? und antworte mit deinem Namen.","Vergleiche you /juː/ mit your /jʊr/ und höre /eɪ/ in name.",],
      ["Heute zeigen wir auf nahe und entfernte Gegenstände.","Verwende This is..., That is... und Is this your...?","this bezeichnet etwas Nahes, that etwas Entfernteres. Beide brauchen is.","Lass is nicht weg: This is my book, nicht This my book.","Halte einen Stift hoch und sage This is my pen. Zeige in die Ferne: That is my bag.","Übe /ð/ in this /ðɪs/ und that /ðæt/ mit der englischen Tonspur.",],
    ], ["Lehrerin Emma · Geführte Lektion","Grammatik · etwa 5 Minuten","Heutiges Ziel","Merke dir das Muster","Fünf Beispiele üben","Beispiel anhören","Häufiger Fehler","Verständnis prüfen","Beantworte drei Fragen","Super! Weiter zum Wortschatz","Frage","Tipp der Lehrerin","Wähle eine Antwort","Richtig!","Versuche es erneut","Weiter",]),
    "pt": AcademyTutorLanguagePack([
      ["Olá! Sou Emma, sua professora de inglês. Hoje vamos praticar apresentações e frases naturais.","Você aprenderá a dizer seu nome e a usar I am e You are corretamente.","Em inglês, usamos am com I e are com you. Não podemos omitir o verbo be: I am a student.","Com I usamos am, não are. Com you usamos are.","Diga I am [seu nome] e depois You are my friend. Repita em voz alta.","Ouça o áudio em inglês e observe o IPA: /æ/ em am é diferente de /ɑːr/ em are.",],
      ["Hoje vamos aprender a falar de nomes e de posse.","Pergunte What is your name? e responda My name is...","my e your aparecem antes do substantivo: my book, your name. his e her também indicam posse.","you significa “você”; your indica algo que é seu. Diga Your name is Sara.","Pratique What is your name? e responda usando seu nome.","Compare you /juː/ e your /jʊr/; name tem o som /eɪ/.",],
      ["Hoje vamos apontar objetos próximos e distantes.","Use This is..., That is... e Is this your...?","this indica algo próximo e that algo mais distante. Ambos usam is.","Não esqueça is: This is my book, não This my book.","Segure uma caneta e diga This is my pen. Aponte para longe: That is my bag.","Pratique o som /ð/ em this /ðɪs/ e that /ðæt/.",],
    ], ["Professora Emma · Aula guiada","Gramática · cerca de 5 minutos","Objetivo de hoje","Lembre-se do padrão","Vamos praticar cinco exemplos","Ouvir exemplo","Erro comum","Verifique o que aprendeu","Responda a três perguntas","Muito bem! Continue com vocabulário","Pergunta","Dica da professora","Escolha uma resposta","Correto!","Tente novamente","Continuar",]),
    "fa": AcademyTutorLanguagePack([
      ["سلام! من اِما هستم، معلم زبان انگلیسی شما. امروز معرفی خود و ساختن جمله‌های ساده را تمرین می‌کنیم.","می‌توانید نام خود را بگویید و I am و You are را درست به کار ببرید.","در انگلیسی بعد از I از am و بعد از you از are استفاده می‌کنیم. فعل be را نمی‌توان حذف کرد: I am a student.","با I باید am و با you باید are بیاورید.","بگویید I am [نام شما] و سپس You are my friend را با صدای بلند تکرار کنید.","به صدای انگلیسی و IPA دقت کنید: /æ/ در am با /ɑːr/ در are فرق دارد.",],
      ["امروز درباره نام‌ها و مالکیت یاد می‌گیریم.","یاد می‌گیرید What is your name? بپرسید و My name is... پاسخ دهید.","my و your قبل از اسم می‌آیند: my book و your name. his و her نیز مالکیت را نشان می‌دهند.","you یعنی «تو»، ولی your یعنی «مال تو». بگویید Your name is Sara.","What is your name? را بپرسید و با نام خود پاسخ دهید.","you /juː/ و your /jʊr/ را مقایسه کنید؛ name صدای /eɪ/ دارد.",],
      ["امروز اشاره به اشیای نزدیک و دور را تمرین می‌کنیم.","از This is... و That is... و Is this your...? استفاده می‌کنید.","this برای یک چیز نزدیک و that برای یک چیز دورتر است. هر دو به is نیاز دارند.","is را حذف نکنید: This is my book درست است.","یک خودکار بردارید و بگویید This is my pen؛ به دورتر اشاره کنید و بگویید That is my bag.","صدای /ð/ را در this /ðɪs/ و that /ðæt/ تمرین کنید.",],
    ], ["معلم اِما · درس گام‌به‌گام","دستور زبان · حدود ۵ دقیقه","هدف امروز","الگو را به خاطر بسپار","تمرین پنج مثال","شنیدن مثال","اشتباه رایج","بررسی یادگیری","به سه سؤال پاسخ دهید","عالی! به واژگان بروید","سؤال","نکته معلم","پاسخ را انتخاب کنید","درست است!","دوباره تلاش کنید","ادامه",]),
    "id": AcademyTutorLanguagePack([
      ["Halo! Saya Emma, guru bahasa Inggris kamu. Hari ini kita belajar memperkenalkan diri dan membuat kalimat sederhana.","Kamu bisa menyebutkan nama dan memakai I am serta You are dengan benar.","Dalam bahasa Inggris, gunakan am setelah I dan are setelah you. Kata kerja be tidak boleh dihilangkan: I am a student.","I memakai am, bukan are. You memakai are.","Ucapkan I am [namamu], lalu You are my friend. Ulangi dengan suara keras.","Dengarkan audio bahasa Inggris dan perhatikan IPA: /æ/ pada am berbeda dengan /ɑːr/ pada are.",],
      ["Hari ini kita belajar menyebutkan nama dan kepemilikan.","Kamu akan bisa bertanya What is your name? dan menjawab My name is...","my dan your diletakkan sebelum kata benda: my book, your name. his dan her juga menunjukkan kepemilikan.","you berarti kamu; your berarti milikmu. Ucapkan Your name is Sara.","Tanyakan What is your name? lalu jawab dengan namamu.","Bandingkan you /juː/ dengan your /jʊr/; name memiliki bunyi /eɪ/.",],
      ["Sekarang kita belajar menunjukkan benda dekat dan jauh.","Gunakan This is..., That is..., dan Is this your...?","this menunjuk satu benda dekat, that satu benda lebih jauh. Keduanya memakai is.","Jangan hilangkan is: This is my book adalah bentuk yang benar.","Pegang pena dan katakan This is my pen. Tunjuk ke jauh: That is my bag.","Latih bunyi /ð/ dalam this /ðɪs/ dan that /ðæt/.",],
    ], ["Guru Emma · Pelajaran terpandu","Tata bahasa · sekitar 5 menit","Tujuan hari ini","Ingat polanya","Latih lima contoh","Dengarkan contoh","Kesalahan umum","Periksa pemahaman","Jawab tiga pertanyaan","Bagus! Lanjut ke kosakata","Pertanyaan","Tips guru","Pilih jawaban","Benar!","Coba lagi","Lanjut",]),
    "th": AcademyTutorLanguagePack([
      ["สวัสดี! ฉันชื่อเอ็มมา เป็นครูภาษาอังกฤษของคุณ วันนี้เราจะฝึกแนะนำตัวและสร้างประโยคง่าย ๆ กัน","คุณจะบอกชื่อตัวเองและใช้ I am กับ You are ได้อย่างถูกต้อง","ภาษาอังกฤษใช้ am กับ I และใช้ are กับ you ห้ามละกริยา be เช่น I am a student","ใช้ am หลัง I และ are หลัง you อย่าสลับกัน","พูด I am [ชื่อของคุณ] แล้วพูด You are my friend ตามเสียง","ฟังเสียงภาษาอังกฤษและดู IPA: เสียง /æ/ ใน am ต่างจาก /ɑːr/ ใน are",],
      ["วันนี้เราจะเรียนวิธีบอกชื่อและแสดงความเป็นเจ้าของ","คุณจะถาม What is your name? และตอบ My name is... ได้","my และ your อยู่หน้าคำนาม เช่น my book, your name ส่วน his และ her ก็ใช้แสดงความเป็นเจ้าของ","you แปลว่า คุณ แต่ your แปลว่า ของคุณ เช่น Your name is Sara","ฝึกถาม What is your name? แล้วตอบด้วยชื่อของตนเอง","เปรียบเทียบ you /juː/ กับ your /jʊr/ และฟังเสียง /eɪ/ ใน name",],
      ["วันนี้เราจะเรียนการชี้สิ่งของใกล้และไกล","คุณจะใช้ This is..., That is... และ Is this your...? ได้","this ใช้กับสิ่งของหนึ่งชิ้นที่อยู่ใกล้ ส่วน that ใช้กับสิ่งที่ไกลกว่า ทั้งคู่ใช้ is","อย่าลืม is: ต้องพูด This is my book","ถือปากกาแล้วพูด This is my pen จากนั้นชี้ไกล ๆ แล้วพูด That is my bag","ฝึกเสียง /ð/ ใน this /ðɪs/ และ that /ðæt/ จากเสียงภาษาอังกฤษ",],
    ], ["ครูเอ็มมา · บทเรียนแนะนำ","ไวยากรณ์ · ประมาณ 5 นาที","เป้าหมายวันนี้","จำรูปแบบประโยค","ฝึกห้าตัวอย่าง","ฟังตัวอย่าง","ข้อผิดพลาดที่พบบ่อย","ตรวจสอบความเข้าใจ","ตอบสามคำถามเพื่อไปต่อ","ยอดเยี่ยม! เรียนคำศัพท์ต่อ","คำถาม","คำแนะนำจากครู","เลือกคำตอบ","ถูกต้อง!","ลองอีกครั้ง","ต่อไป",]),
    "hi": AcademyTutorLanguagePack([
      ["नमस्ते! मैं एमा हूँ, आपकी अंग्रेज़ी शिक्षिका। आज हम अपना परिचय देना और सरल वाक्य बनाना सीखेंगे।","आप अपना नाम बता सकेंगे और I am तथा You are का सही प्रयोग करेंगे।","अंग्रेज़ी में I के साथ am और you के साथ are आता है। I am a student जैसे वाक्य में be क्रिया नहीं हटाते।","I के साथ am और you के साथ are का प्रयोग करें।","I am [आपका नाम] कहें, फिर You are my friend ज़ोर से दोहराएँ।","अंग्रेज़ी ऑडियो और IPA सुनें: am का /æ/ और are का /ɑːr/ अलग हैं।",],
      ["आज हम नाम और अधिकार बताना सीखेंगे।","आप What is your name? पूछेंगे और My name is... उत्तर देंगे।","my और your संज्ञा से पहले आते हैं: my book, your name। his और her भी स्वामित्व बताते हैं।","you का अर्थ ‘तुम’, जबकि your का अर्थ ‘तुम्हारा’ है। Your name is Sara कहें।","What is your name? पूछें और अपने नाम से उत्तर दें।","you /juː/ और your /jʊr/ की तुलना करें; name में /eɪ/ ध्वनि है।",],
      ["आज हम पास और दूर की चीज़ों की ओर संकेत करना सीखेंगे।","आप This is..., That is... और Is this your...? प्रयोग करेंगे।","this पास की एक चीज़ और that दूर की एक चीज़ के लिए है। दोनों के साथ is आता है।","is न हटाएँ: सही वाक्य This is my book है।","पेन उठाकर This is my pen कहें और दूर इशारा करके That is my bag कहें।","this /ðɪs/ और that /ðæt/ में /ð/ ध्वनि का अभ्यास करें।",],
    ], ["शिक्षिका एमा · निर्देशित पाठ","व्याकरण · लगभग 5 मिनट","आज का लक्ष्य","वाक्य का ढाँचा याद रखें","पाँच उदाहरणों का अभ्यास","उदाहरण सुनें","सामान्य गलती","समझ की जाँच","आगे बढ़ने के लिए तीन प्रश्न हल करें","बहुत अच्छा! शब्दावली पर जाएँ","प्रश्न","शिक्षिका की सलाह","उत्तर चुनें","सही!","फिर प्रयास करें","आगे",]),
    "it": AcademyTutorLanguagePack([
      ["Ciao! Sono Emma, la tua insegnante d’inglese. Oggi impareremo a presentarci e costruire frasi corrette.","Sarai in grado di dire il tuo nome e usare I am e You are correttamente.","In inglese si usa am con I e are con you. Il verbo be non si omette: I am a student.","Con I si usa am, non are. Con you si usa are.","Di’ I am [il tuo nome], poi You are my friend. Ripeti ad alta voce.","Ascolta l’audio inglese e osserva l’IPA: /æ/ in am è diverso da /ɑːr/ in are.",],
      ["Oggi impariamo a parlare di nomi e possesso.","Imparerai a chiedere What is your name? e rispondere My name is...","my e your precedono il nome: my book, your name. Anche his e her indicano possesso.","you significa «tu»; your significa «tuo». Di’ Your name is Sara.","Chiedi What is your name? e rispondi con il tuo nome.","Confronta you /juː/ e your /jʊr/; name contiene il suono /eɪ/.",],
      ["Impariamo a indicare oggetti vicini e lontani.","Userai This is..., That is... e Is this your...?","this indica una cosa vicina, that una più lontana. Entrambi richiedono is.","Non omettere is: si dice This is my book.","Prendi una penna e di’ This is my pen; indica un oggetto lontano e di’ That is my bag.","Esercitati con /ð/ in this /ðɪs/ e that /ðæt/.",],
    ], ["Insegnante Emma · Lezione guidata","Grammatica · circa 5 minuti","Obiettivo di oggi","Ricorda lo schema","Pratichiamo cinque esempi","Ascolta l’esempio","Errore comune","Verifica la comprensione","Rispondi a tre domande","Ottimo! Continua con il vocabolario","Domanda","Consiglio dell’insegnante","Scegli la risposta","Corretto!","Riprova","Continua",]),
  };

  static bool supports(String languageCode) =>
      _packs.containsKey(languageCode);
  static String normalized(String languageCode) =>
      _packs.containsKey(languageCode) ? languageCode : fallbackLocale;
  static bool isRtl(String code) =>
      const {'ar', 'fa', 'ur'}.contains(code);

  /// lesson 1..3, field 0..5.
  static String explain(String code, int lesson, int field) {
    if (lesson < 1 || lesson > 3 || field < 0 || field > 5) {
      throw RangeError('Unknown tutor explanation field');
    }
    return _packs[normalized(code)]!.sections[lesson - 1][field];
  }

  /// UI labels are independent of the lesson.
  static String label(String code, int index) {
    final values = _packs[normalized(code)]!.labels;
    if (index < 0 || index >= values.length) {
      throw RangeError('Unknown tutor label');
    }
    return values[index];
  }
  /// Translations of the five demonstration sentences per tutor lesson.
  static const _exampleMeanings = <String, List<List<String>>>{
    "ar": [
      ["أنا سارة.", "أنا طالب.", "أنت صديقي.", "هل أنت طالب؟", "نعم، أنا كذلك. / لا، لست كذلك."],
      ["اسمي مايا.", "ما اسمك؟", "هذا كتابي.", "اسمه ليو.", "اسمها نينا."],
      ["هذا قلمي.", "تلك حقيبتك.", "هل هذا كتابك؟", "نعم، هو كذلك.", "لا، ذلك ليس دفتري."],
    ],
    "en": [
      ["I am Sara.", "I am a student.", "You are my friend.", "Are you a student?", "Yes, I am. / No, I am not."],
      ["My name is Maya.", "What is your name?", "This is my book.", "His name is Leo.", "Her name is Nina."],
      ["This is my pen.", "That is your bag.", "Is this your book?", "Yes, it is.", "No, that is not my notebook."],
    ],
    "es": [
      ["Soy Sara.", "Soy estudiante.", "Eres mi amigo.", "¿Eres estudiante?", "Sí, lo soy. / No, no lo soy."],
      ["Me llamo Maya.", "¿Cómo te llamas?", "Este es mi libro.", "Se llama Leo.", "Se llama Nina."],
      ["Este es mi bolígrafo.", "Esa es tu mochila.", "¿Es este tu libro?", "Sí, lo es.", "No, ese no es mi cuaderno."],
    ],
    "fr": [
      ["Je suis Sara.", "Je suis étudiant(e).", "Tu es mon ami(e).", "Es-tu étudiant(e) ?", "Oui. / Non, je ne le suis pas."],
      ["Je m’appelle Maya.", "Comment tu t’appelles ?", "Voici mon livre.", "Il s’appelle Léo.", "Elle s’appelle Nina."],
      ["Voici mon stylo.", "C’est ton sac là-bas.", "Est-ce ton livre ?", "Oui, c’est ça.", "Non, ce n’est pas mon cahier."],
    ],
    "zh": [
      ["我是萨拉。", "我是学生。", "你是我的朋友。", "你是学生吗？", "是的。/ 不，我不是。"],
      ["我叫玛雅。", "你叫什么名字？", "这是我的书。", "他叫里奥。", "她叫妮娜。"],
      ["这是我的钢笔。", "那是你的包。", "这是你的书吗？", "是的。", "不，那不是我的笔记本。"],
    ],
    "ko": [
      ["저는 사라예요.", "저는 학생이에요.", "당신은 제 친구예요.", "학생이에요?", "네, 맞아요. / 아니요."],
      ["제 이름은 마야예요.", "이름이 뭐예요?", "이것은 제 책이에요.", "그의 이름은 레오예요.", "그녀의 이름은 니나예요."],
      ["이것은 제 펜이에요.", "저것은 당신의 가방이에요.", "이것은 당신의 책이에요?", "네, 맞아요.", "아니요, 저것은 제 공책이 아니에요."],
    ],
    "ja": [
      ["私はサラです。", "私は学生です。", "あなたは私の友達です。", "あなたは学生ですか？", "はい、そうです。／いいえ、違います。"],
      ["私の名前はマヤです。", "お名前は何ですか？", "これは私の本です。", "彼の名前はレオです。", "彼女の名前はニナです。"],
      ["これは私のペンです。", "あれはあなたのかばんです。", "これはあなたの本ですか？", "はい、そうです。", "いいえ、あれは私のノートではありません。"],
    ],
    "de": [
      ["Ich bin Sara.", "Ich bin Schüler(in).", "Du bist mein Freund.", "Bist du Schüler(in)?", "Ja. / Nein, bin ich nicht."],
      ["Ich heiße Maya.", "Wie heißt du?", "Das ist mein Buch.", "Er heißt Leo.", "Sie heißt Nina."],
      ["Das ist mein Stift.", "Das dort ist deine Tasche.", "Ist das dein Buch?", "Ja, das ist es.", "Nein, das ist nicht mein Notizbuch."],
    ],
    "pt": [
      ["Eu sou Sara.", "Sou estudante.", "Você é meu amigo.", "Você é estudante?", "Sim, sou. / Não, não sou."],
      ["Meu nome é Maya.", "Qual é o seu nome?", "Este é meu livro.", "O nome dele é Leo.", "O nome dela é Nina."],
      ["Esta é minha caneta.", "Aquela é sua bolsa.", "Este é seu livro?", "Sim, é.", "Não, aquele não é meu caderno."],
    ],
    "ru": [
      ["Я Сара.", "Я студент(ка).", "Ты мой друг.", "Ты студент(ка)?", "Да. / Нет."],
      ["Меня зовут Майя.", "Как тебя зовут?", "Это моя книга.", "Его зовут Лео.", "Её зовут Нина."],
      ["Это моя ручка.", "Вон там твоя сумка.", "Это твоя книга?", "Да.", "Нет, это не моя тетрадь."],
    ],
    "tr": [
      ["Ben Sara'yım.", "Ben öğrenciyim.", "Sen benim arkadaşımsın.", "Öğrenci misin?", "Evet. / Hayır."],
      ["Benim adım Maya.", "Adın ne?", "Bu benim kitabım.", "Onun adı Leo.", "Onun adı Nina."],
      ["Bu benim kalemim.", "Şu senin çantan.", "Bu senin kitabın mı?", "Evet.", "Hayır, şu benim defterim değil."],
    ],
    "ur": [
      ["میں سارہ ہوں۔", "میں طالب علم ہوں۔", "آپ میرے دوست ہیں۔", "کیا آپ طالب علم ہیں؟", "جی ہاں۔ / نہیں۔"],
      ["میرا نام مایا ہے۔", "آپ کا نام کیا ہے؟", "یہ میری کتاب ہے۔", "اس کا نام لیو ہے۔", "اس کا نام نینا ہے۔"],
      ["یہ میرا قلم ہے۔", "وہ آپ کا بیگ ہے۔", "کیا یہ آپ کی کتاب ہے؟", "جی ہاں۔", "نہیں، وہ میری نوٹ بک نہیں ہے۔"],
    ],
    "fa": [
      ["من سارا هستم.", "من دانش‌آموز هستم.", "تو دوست من هستی.", "آیا دانش‌آموز هستی؟", "بله. / نه."],
      ["نام من مایا است.", "نام تو چیست؟", "این کتاب من است.", "نام او لئو است.", "نام او نینا است."],
      ["این خودکار من است.", "آن کیف تو است.", "آیا این کتاب تو است؟", "بله.", "نه، آن دفتر من نیست."],
    ],
    "id": [
      ["Saya Sara.", "Saya seorang pelajar.", "Kamu teman saya.", "Apakah kamu pelajar?", "Ya. / Tidak."],
      ["Nama saya Maya.", "Siapa namamu?", "Ini buku saya.", "Namanya Leo.", "Namanya Nina."],
      ["Ini pena saya.", "Itu tasmu.", "Apakah ini bukumu?", "Ya.", "Tidak, itu bukan buku catatan saya."],
    ],
    "th": [
      ["ฉันชื่อซารา", "ฉันเป็นนักเรียน", "คุณเป็นเพื่อนของฉัน", "คุณเป็นนักเรียนหรือเปล่า?", "ใช่ / ไม่ใช่"],
      ["ฉันชื่อมายา", "คุณชื่ออะไร?", "นี่คือหนังสือของฉัน", "เขาชื่อเลโอ", "เธอชื่อนีนา"],
      ["นี่คือปากกาของฉัน", "นั่นคือกระเป๋าของคุณ", "นี่คือหนังสือของคุณไหม?", "ใช่", "ไม่ นั่นไม่ใช่สมุดของฉัน"],
    ],
    "hi": [
      ["मैं सारा हूँ।", "मैं विद्यार्थी हूँ।", "तुम मेरे दोस्त हो।", "क्या तुम विद्यार्थी हो?", "हाँ। / नहीं।"],
      ["मेरा नाम माया है।", "तुम्हारा नाम क्या है?", "यह मेरी किताब है।", "उसका नाम लियो है।", "उसका नाम नीना है।"],
      ["यह मेरा पेन है।", "वह तुम्हारा बैग है।", "क्या यह तुम्हारी किताब है?", "हाँ।", "नहीं, वह मेरी कॉपी नहीं है।"],
    ],
    "it": [
      ["Sono Sara.", "Sono uno studente / una studentessa.", "Sei mio amico.", "Sei uno studente?", "Sì. / No."],
      ["Mi chiamo Maya.", "Come ti chiami?", "Questo è il mio libro.", "Si chiama Leo.", "Si chiama Nina."],
      ["Questa è la mia penna.", "Quella è la tua borsa.", "Questo è il tuo libro?", "Sì.", "No, quello non è il mio quaderno."],
    ],
  };
  static const _exampleNotes = <String, String>{
    "ar": "انتبه إلى تركيب الجملة الإنجليزية واستمع للنطق، ثم حاول تكوين مثال جديد.",
    "en": "Notice the English sentence pattern, listen to the pronunciation, and make your own example.",
    "es": "Observa la estructura inglesa, escucha la pronunciación y crea tu propio ejemplo.",
    "fr": "Observez la structure anglaise, écoutez la prononciation et créez votre propre exemple.",
    "zh": "注意英语句型，听发音，再尝试自己造一个句子。",
    "ko": "영어 문장 구조를 살펴보고 발음을 들은 뒤 직접 문장을 만들어 보세요.",
    "ja": "英語の文の形を確認し、発音を聞いて、自分でも文を作りましょう。",
    "de": "Achte auf den englischen Satzbau, höre die Aussprache und bilde ein eigenes Beispiel.",
    "pt": "Observe a estrutura em inglês, ouça a pronúncia e crie um exemplo próprio.",
    "ru": "Обрати внимание на английскую структуру, послушай произношение и составь свой пример.",
    "tr": "İngilizce cümle yapısını incele, telaffuzu dinle ve kendi örneğini oluştur.",
    "ur": "انگریزی جملے کی ساخت دیکھیں، تلفظ سنیں اور اپنی مثال بنائیں۔",
    "fa": "ساخت جمله انگلیسی را ببینید، تلفظ را بشنوید و مثال خودتان را بسازید.",
    "id": "Perhatikan pola kalimat Inggris, dengarkan pengucapannya, lalu buat contoh sendiri.",
    "th": "สังเกตโครงสร้างประโยคอังกฤษ ฟังการออกเสียง แล้วลองแต่งประโยคด้วยตนเอง",
    "hi": "अंग्रेज़ी वाक्य की रचना देखें, उच्चारण सुनें और अपना उदाहरण बनाएँ।",
    "it": "Osserva la struttura inglese, ascolta la pronuncia e crea un tuo esempio.",
  };
  static String exampleMeaning(String code, int lesson, int index) {
    if (lesson < 1 || lesson > 3 || index < 0 || index > 4) {
      throw RangeError('Unknown tutor example');
    }
    return _exampleMeanings[normalized(code)]![lesson - 1][index];
  }
  static String exampleNote(String code) =>
      _exampleNotes[normalized(code)]!;

}
