/// Curated beginner-course content shared by every WorldVoice learning language.
///
/// Each row: target text | pronunciation/romanization | Arabic meaning |
/// English meaning. Keep pronunciations attached to the *target* language,
/// never to the device language or the translated meaning.
class CourseWord {
  const CourseWord(this.text, this.pronunciation, this.arabic, this.english);

  final String text;
  final String pronunciation;
  final String arabic;
  final String english;
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.words,
  });

  final String id;
  final String titleArabic;
  final String titleEnglish;
  final List<CourseWord> words;
}

class CourseLanguage {
  const CourseLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.speechLocale,
    required this.lessons,
  });

  final String code;
  final String name;
  final String flag;
  final String speechLocale;
  final List<CourseLesson> lessons;

  int get wordCount => lessons.fold(0, (total, lesson) => total + lesson.words.length);
  bool get rightToLeft => const {'ar', 'fa', 'ur'}.contains(code);
}

abstract final class CourseCatalog {
  static List<CourseWord> _words(String raw) => raw.trim().split('\n').map((line) {
    final fields = line.trim().split('|');
    if (fields.length != 4 || fields.any((field) => field.trim().isEmpty)) {
      throw FormatException('Invalid WorldVoice vocabulary row: ' + line);
    }
    return CourseWord(fields[0].trim(), fields[1].trim(),
        fields[2].trim(), fields[3].trim());
  }).toList(growable: false);

  static CourseLanguage _course(
    String code, String name, String flag, String speechLocale,
    String greetings, String everyday,
  ) => CourseLanguage(
    code: code, name: name, flag: flag, speechLocale: speechLocale,
    lessons: [
      CourseLesson(
        id: 'greetings',
        titleArabic: 'التحيات والتعارف',
        titleEnglish: 'Greetings & introductions',
        words: _words(greetings),
      ),
      CourseLesson(
        id: 'conversation',
        titleArabic: 'محادثات يومية',
        titleEnglish: 'Everyday conversation',
        words: _words(everyday),
      ),
    ],
  );

  static final List<CourseLanguage> all = [
    _course('en', 'English', '🇬🇧', 'en-US', '''
Hello|هَلّو|مرحبًا|Hello
Good morning|غُد مورنينغ|صباح الخير|Good morning
Thank you|ثانك يو|شكرًا|Thank you
Please|پليز|من فضلك|Please
Goodbye|غُدباي|وداعًا|Goodbye
''', '''
How are you?|هاو آر يو|كيف حالك؟|How are you?
I'm fine|آيم فاين|أنا بخير|I'm fine
What's your name?|واتس يور نيم|ما اسمك؟|What's your name?
Nice to meet you|نايس تو ميت يو|سعيد بلقائك|Nice to meet you
See you later|سي يو لَيْتر|أراك لاحقًا|See you later
'''),
    _course('es', 'Español', '🇪🇸', 'es-ES', '''
Hola|أُولا|مرحبًا|Hello
Buenos días|بُوينوس دِياس|صباح الخير|Good morning
Gracias|غْراثياس|شكرًا|Thank you
Por favor|پور فابور|من فضلك|Please
Adiós|أديوس|وداعًا|Goodbye
''', '''
¿Cómo estás?|كومو إِستاس|كيف حالك؟|How are you?
Estoy bien|إستوي بِيِن|أنا بخير|I'm fine
¿Cómo te llamas?|كومو تي ياماس|ما اسمك؟|What's your name?
Mucho gusto|موتشو غوستو|تشرفت بلقائك|Nice to meet you
Hasta luego|أستا لويغو|أراك لاحقًا|See you later
'''),
    _course('fr', 'Français', '🇫🇷', 'fr-FR', '''
Bonjour|بونجور|مرحبًا|Hello
Bonsoir|بونسوار|مساء الخير|Good evening
Merci|ميرسي|شكرًا|Thank you
S'il vous plaît|سيل فو پليه|من فضلك|Please
Au revoir|أو رُفوار|إلى اللقاء|Goodbye
''', '''
Comment ça va ?|كومان سا ڤا|كيف الحال؟|How are you?
Ça va bien|سا ڤا بْيان|أنا بخير|I'm fine
Comment tu t'appelles ?|كومان تو تاپيل|ما اسمك؟|What's your name?
Enchanté|أونشانتي|تشرفت بلقائك|Nice to meet you
À bientôt|آ بيانْتو|أراك قريبًا|See you soon
'''),
    _course('zh', '中文', '🇨🇳', 'zh-CN', '''
你好|nǐ hǎo|مرحبًا|Hello
早上好|zǎoshang hǎo|صباح الخير|Good morning
谢谢|xièxie|شكرًا|Thank you
请|qǐng|من فضلك|Please
再见|zàijiàn|إلى اللقاء|Goodbye
''', '''
你好吗？|nǐ hǎo ma|كيف حالك؟|How are you?
我很好|wǒ hěn hǎo|أنا بخير|I'm fine
你叫什么名字？|nǐ jiào shénme míngzi|ما اسمك؟|What's your name?
很高兴认识你|hěn gāoxìng rènshi nǐ|سعيد بلقائك|Nice to meet you
回头见|huítóu jiàn|أراك لاحقًا|See you later
'''),
    _course('ko', '한국어', '🇰🇷', 'ko-KR', '''
안녕하세요|annyeonghaseyo|مرحبًا|Hello
좋은 아침이에요|joeun achimieyo|صباح الخير|Good morning
감사합니다|gamsahamnida|شكرًا|Thank you
부탁합니다|butakhamnida|أرجوك|Please
안녕히 가세요|annyeonghi gaseyo|إلى اللقاء لمن يغادر|Goodbye (to one leaving)
''', '''
잘 지내세요?|jal jinaeseyo|هل أنت بخير؟|Are you doing well?
네, 잘 지내요|ne, jal jinaeyo|نعم، أنا بخير|Yes, I'm well
이름이 뭐예요?|ireumi mwoyeyo|ما اسمك؟|What's your name?
만나서 반가워요|mannaseo bangawoyo|سعيد بلقائك|Nice to meet you
또 봐요|tto bwayo|أراك مجددًا|See you again
'''),
    _course('ja', '日本語', '🇯🇵', 'ja-JP', '''
こんにちは|konnichiwa|مرحبًا|Hello
おはようございます|ohayō gozaimasu|صباح الخير|Good morning
ありがとう|arigatō|شكرًا|Thank you
お願いします|onegai shimasu|من فضلك|Please
さようなら|sayōnara|وداعًا|Goodbye
''', '''
お元気ですか|ogenki desu ka|كيف حالك؟|How are you?
元気です|genki desu|أنا بخير|I'm fine
お名前は何ですか|onamae wa nan desu ka|ما اسمك؟|What's your name?
はじめまして|hajimemashite|تشرفت بمعرفتك|Nice to meet you
またね|mata ne|أراك لاحقًا|See you later
'''),
    _course('ar', 'العربية', '🇸🇦', 'ar-SA', '''
مرحبًا|marḥaban|مرحبًا|Hello
صباح الخير|ṣabāḥ al-khayr|صباح الخير|Good morning
شكرًا|shukran|شكرًا|Thank you
من فضلك|min faḍlik|من فضلك|Please
إلى اللقاء|ilā al-liqāʾ|إلى اللقاء|Goodbye
''', '''
كيف حالك؟|kayfa ḥāluka|كيف حالك؟|How are you?
أنا بخير|anā bikhayr|أنا بخير|I'm fine
ما اسمك؟|mā ismuka|ما اسمك؟|What's your name?
تشرفت بمعرفتك|tasharraftu bimaʿrifatika|تشرفت بمعرفتك|Nice to meet you
أراك لاحقًا|arāka lāḥiqan|أراك لاحقًا|See you later
'''),
    _course('de', 'Deutsch', '🇩🇪', 'de-DE', '''
Hallo|هالو|مرحبًا|Hello
Guten Morgen|غوتن مورغن|صباح الخير|Good morning
Danke|دانكه|شكرًا|Thank you
Bitte|بِتّه|من فضلك|Please
Auf Wiedersehen|أوف فيدرزين|إلى اللقاء|Goodbye
''', '''
Wie geht es dir?|ڤي غيت إس دير|كيف حالك؟|How are you?
Mir geht es gut|مير غيت إس غوت|أنا بخير|I'm fine
Wie heißt du?|ڤي هايسْت دو|ما اسمك؟|What's your name?
Freut mich|فرويت ميش|تشرفت بلقائك|Nice to meet you
Bis später|بِس شْبيتر|أراك لاحقًا|See you later
'''),
    _course('ru', 'Русский', '🇷🇺', 'ru-RU', '''
Привет|privet|مرحبًا|Hello
Доброе утро|dobroye utro|صباح الخير|Good morning
Спасибо|spasibo|شكرًا|Thank you
Пожалуйста|pozhaluysta|من فضلك|Please
До свидания|do svidaniya|إلى اللقاء|Goodbye
''', '''
Как дела?|kak dela|كيف الحال؟|How are you?
Всё хорошо|vsyo khorosho|كل شيء بخير|I'm fine
Как тебя зовут?|kak tebya zovut|ما اسمك؟|What's your name?
Приятно познакомиться|priyatno poznakomitsya|سعيد بلقائك|Nice to meet you
До встречи|do vstrechi|أراك لاحقًا|See you later
'''),
    _course('tr', 'Türkçe', '🇹🇷', 'tr-TR', '''
Merhaba|مَرْهَبا|مرحبًا|Hello
Günaydın|غونايدن|صباح الخير|Good morning
Teşekkürler|تَشَكّورلَر|شكرًا|Thank you
Lütfen|لوتفن|من فضلك|Please
Hoşça kal|هوشچا كال|وداعًا|Goodbye
''', '''
Nasılsın?|ناسلسن|كيف حالك؟|How are you?
İyiyim|إيييم|أنا بخير|I'm fine
Adın ne?|أدن نَه|ما اسمك؟|What's your name?
Memnun oldum|ممنون أُلدوم|تشرفت بلقائك|Nice to meet you
Görüşürüz|غوروشوروز|أراك لاحقًا|See you later
'''),
    _course('ur', 'اردو', '🇵🇰', 'ur-PK', '''
سلام|salām|مرحبًا|Hello
صبح بخیر|subah bakhair|صباح الخير|Good morning
شکریہ|shukriya|شكرًا|Thank you
براہ کرم|barāh-e karam|من فضلك|Please
خدا حافظ|khudā hāfiz|وداعًا|Goodbye
''', '''
آپ کیسے ہیں؟|āp kaise hain|كيف حالك؟|How are you?
میں ٹھیک ہوں|main ṭhīk hūn|أنا بخير|I'm fine
آپ کا نام کیا ہے؟|āp kā nām kyā hai|ما اسمك؟|What's your name?
آپ سے مل کر خوشی ہوئی|āp se mil kar khushī huī|سعيد بلقائك|Nice to meet you
پھر ملیں گے|phir milenge|أراك لاحقًا|See you later
'''),
    _course('pt', 'Português', '🇧🇷', 'pt-BR', '''
Olá|أُلا|مرحبًا|Hello
Bom dia|بون جيا|صباح الخير|Good morning
Obrigado|أُبريغادو|شكرًا (للمتحدث الرجل)|Thank you (male speaker)
Por favor|پور فافور|من فضلك|Please
Tchau|تشاو|وداعًا|Goodbye
''', '''
Tudo bem?|تودو بَيْن|كيف الحال؟|How are you?
Estou bem|إشتو بَيْن|أنا بخير|I'm fine
Como você se chama?|كومو ڤوسي سي شاما|ما اسمك؟|What's your name?
Prazer|پرازار|تشرفت بلقائك|Nice to meet you
Até logo|أتي لوغو|أراك لاحقًا|See you later
'''),
    _course('fa', 'فارسی', '🇮🇷', 'fa-IR', '''
سلام|salâm|مرحبًا|Hello
صبح بخیر|sobh bekheyr|صباح الخير|Good morning
ممنون|mamnun|شكرًا|Thank you
لطفاً|lotfan|من فضلك|Please
خداحافظ|khodâhâfez|وداعًا|Goodbye
''', '''
حالت چطوره؟|hâlet chetore|كيف حالك؟|How are you?
خوبم|khubam|أنا بخير|I'm fine
اسمت چیه؟|esmet chiye|ما اسمك؟|What's your name?
خوشبختم|khoshbakhtam|تشرفت بلقائك|Nice to meet you
بعداً می‌بینمت|ba'dan mibinamet|أراك لاحقًا|See you later
'''),
    _course('id', 'Bahasa Indonesia', '🇮🇩', 'id-ID', '''
Halo|هالو|مرحبًا|Hello
Selamat pagi|سلامات پاگي|صباح الخير|Good morning
Terima kasih|تريما كاسيه|شكرًا|Thank you
Tolong|تولونغ|من فضلك / ساعدني|Please / Help
Sampai jumpa|سامپاي جومپا|إلى اللقاء|Goodbye
''', '''
Apa kabar?|أپا كابار|كيف حالك؟|How are you?
Saya baik|سايا بايك|أنا بخير|I'm fine
Siapa namamu?|سياپا نامامو|ما اسمك؟|What's your name?
Senang bertemu denganmu|سننغ برتمو دنگنمو|سعيد بلقائك|Nice to meet you
Sampai nanti|سامپاي نانتي|أراك لاحقًا|See you later
'''),
    _course('th', 'ไทย', '🇹🇭', 'th-TH', '''
สวัสดี|sawatdi|مرحبًا|Hello
อรุณสวัสดิ์|arun sawat|صباح الخير|Good morning
ขอบคุณ|khop khun|شكرًا|Thank you
กรุณา|karuna|من فضلك (رسمي)|Please (formal)
ลาก่อน|la kon|وداعًا|Goodbye
''', '''
สบายดีไหม|sabai di mai|كيف حالك؟|How are you?
สบายดี|sabai di|أنا بخير|I'm fine
คุณชื่ออะไร|khun chue arai|ما اسمك؟|What's your name?
ยินดีที่ได้รู้จัก|yin di thi dai ruchak|سعيد بلقائك|Nice to meet you
แล้วเจอกัน|laeo choe kan|أراك لاحقًا|See you later
'''),
    _course('hi', 'हिन्दी', '🇮🇳', 'hi-IN', '''
नमस्ते|namaste|مرحبًا|Hello
सुप्रभात|suprabhāt|صباح الخير|Good morning
धन्यवाद|dhanyavād|شكرًا|Thank you
कृपया|kr̥payā|من فضلك|Please
अलविदा|alvidā|وداعًا|Goodbye
''', '''
आप कैसे हैं?|āp kaise hain|كيف حالك؟|How are you?
मैं ठीक हूँ|main ṭhīk hūn|أنا بخير|I'm fine
आपका नाम क्या है?|āpkā nām kyā hai|ما اسمك؟|What's your name?
आपसे मिलकर खुशी हुई|āpse milkar khushī huī|سعيد بلقائك|Nice to meet you
फिर मिलेंगे|phir milenge|أراك لاحقًا|See you later
'''),
    _course('it', 'Italiano', '🇮🇹', 'it-IT', '''
Ciao|تشاو|مرحبًا|Hello
Buongiorno|بونجورنو|صباح الخير|Good morning
Grazie|غراتسيه|شكرًا|Thank you
Per favore|پير فاڤوري|من فضلك|Please
Arrivederci|أرّيفيديرتشي|إلى اللقاء|Goodbye
''', '''
Come stai?|كومي ستاي|كيف حالك؟|How are you?
Sto bene|ستو بيني|أنا بخير|I'm fine
Come ti chiami?|كومي تي كيامي|ما اسمك؟|What's your name?
Piacere|پياتشيري|تشرفت بلقائك|Nice to meet you
A dopo|آ دوپو|أراك لاحقًا|See you later
'''),
  ];

  static CourseLanguage? byCode(String code) {
    for (final course in all) {
      if (course.code == code) return course;
    }
    return null;
  }
}
