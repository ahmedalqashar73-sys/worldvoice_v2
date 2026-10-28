/// Contextual learner vocabulary; pronunciation hints are approximations.
/// The TTS audio in the integrated lesson is the primary sound reference.
enum EnglishA1WordKind { noun, verb, adjective, adverb }

class EnglishA1Word {
  const EnglishA1Word(this.term, this.arabic, this.pronunciation,
      {this.kind = EnglishA1WordKind.noun});
  final String term;
  final String arabic;
  final String pronunciation;
  final EnglishA1WordKind kind;
}

abstract final class EnglishA1Vocabulary {
  static const _rawBanks = <int, String>{
    1: r'''hello|مرحبًا|هَلّو
hi|أهلًا|هاي
good morning|صباح الخير|غود مورنينغ
good evening|مساء الخير|غود إيفنينغ
goodbye|وداعًا|غودباي
please|من فضلك|پليز
thank you|شكرًا|ثانك يو
sorry|آسف|سوري
yes|نعم|يَس
no|لا|نو
friend|صديق|فرِند
name|اسم|نَيْم
my|خاصتي|ماي
your|خاصتك|يور
you|أنت|يو
I|أنا|آي
we|نحن|وي
they|هم|ذَيْ
he|هو|هي
she|هي|شي
student|طالب|ستيودَنت
teacher|معلم|تيتشر
school|مدرسة|سكول
book|كتاب|بُك
notebook|دفتر|نوتبُك
page|صفحة|پَيْج
pencil|قلم رصاص|پِنْسِل
pen|قلم|پِن
bag|حقيبة|باغ
chair|كرسي|تشير
table|طاولة|تيبِل
library|مكتبة|لايبرَري
door|باب|دور
window|نافذة|ويندو
tree|شجرة|تري
star|نجمة|ستار
blue|أزرق|بلو
green|أخضر|غرين
red|أحمر|رِد
yellow|أصفر|يَلّو
white|أبيض|وايت
black|أسود|بلاك
big|كبير|بِغ
small|صغير|سمول
new|جديد|نيو
old|قديم|أولد
happy|سعيد|هاپي
sad|حزين|ساد
lost|مفقود|لوست
found|وُجد|فاوند
look|ينظر|لوك
find|يجد|فايند
open|يفتح|أوبِن
close|يغلق|كلوز
read|يقرأ|ريد
write|يكتب|رايت
listen|يستمع|لِسِن
say|يقول|سَيْ
speak|يتحدث|سبيك
smile|يبتسم|سمايل
laugh|يضحك|لاف
help|يساعد|هِلپ
meet|يقابل|ميت
together|معًا|تُغيذَر
here|هنا|هير
there|هناك|ذير
this|هذا|ذِس
that|ذاك|ذات
today|اليوم|تودَيْ
tomorrow|غدًا|تومورو
first|أول|فِرست
last|أخير|لاست
picture|صورة|پِكتشَر
secret|سر|سيكريت
message|رسالة|مِسِج''',
    2: r'''morning|الصباح|مورنينغ
evening|المساء|إيفنينغ
night|ليل|نايت
afternoon|بعد الظهر|آفترنون
day|يوم|دَيْ
week|أسبوع|ويك
Monday|الاثنين|مَندَيْ
Tuesday|الثلاثاء|تيوزدَيْ
Wednesday|الأربعاء|وينزدَيْ
Thursday|الخميس|ثيرزدَيْ
Friday|الجمعة|فرايدَيْ
Saturday|السبت|ساتردَيْ
Sunday|الأحد|سَندَيْ
clock|ساعة|كلوك
seven|سبعة|سِڤِن
eight|ثمانية|إيت
nine|تسعة|ناين
ten|عشرة|تِن
early|مبكر|إيرلي
late|متأخر|لَيْت
wake up|يستيقظ|وَيْك أپ
get up|ينهض|غِت أپ
sleep|ينام|سليب
breakfast|فطور|برِكفَست
lunch|غداء|لَنتش
dinner|عشاء|دِنَر
bread|خبز|برِد
milk|حليب|مِلك
apple|تفاحة|أَپِل
water|ماء|ووتَر
kitchen|مطبخ|كِتشِن
bedroom|غرفة نوم|بِدروم
home|منزل|هوم
house|بيت|هاوس
family|عائلة|فاميلي
mother|أم|ماذَر
father|أب|فاذَر
brother|أخ|براذَر
sister|أخت|سِستَر
grandmother|جدة|غراند ماذَر
cat|قطة|كات
dog|كلب|دوغ
pet|حيوان أليف|پِت
bus|حافلة|بَس
driver|سائق|درايفَر
road|طريق|رود
rain|مطر|رَيْن
umbrella|مظلة|أمبريلا
yellow|أصفر|يَلّو
seat|مقعد|سيت
free|فارغ أو حر|فري
study|يدرس|ستَدي
work|يعمل|وِرك
walk|يمشي|ووك
run|يجري|رَن
go|يذهب|غو
come|يأتي|كَم
eat|يأكل|إيت
drink|يشرب|درِنك
cook|يطبخ|كوك
wait|ينتظر|وَيْت
start|يبدأ|ستارت
finish|ينهي|فِنِش
always|دائمًا|أولويز
often|غالبًا|أوفِن
sometimes|أحيانًا|سَمتايمز
never|أبدًا|نِڤَر
before|قبل|بِفور
after|بعد|آفتر
next|التالي|نِكست
under|تحت|أندَر
above|فوق|أبَڤ
near|قريب|نير
tired|متعب|تايرد
hungry|جائع|هَنغري
weather|الطقس|ويذَر
school|مدرسة|سكول''',
    3: r'''city|مدينة|سِتي
town|بلدة|تاون
street|شارع|ستريت
road|طريق|رود
map|خريطة|ماپ
shop|متجر|شوپ
market|سوق|ماركِت
café|مقهى|كافَيْ
restaurant|مطعم|رِستورَنت
library|مكتبة|لايبرَري
school|مدرسة|سكول
park|حديقة عامة|پارك
garden|حديقة|غاردِن
station|محطة|ستَيْشِن
museum|متحف|ميوزيَم
hospital|مستشفى|هوسپِتَل
bakery|مخبز|بَيْكَري
door|باب|دور
window|نافذة|ويندو
left|يسار|لِفت
right|يمين|رايت
straight|مستقيم|ستريت
turn|انعطف|تِرن
stop|توقف|ستوپ
near|قريب|نير
far|بعيد|فار
next to|بجانب|نِكست تو
between|بين|بِتوين
behind|خلف|بِهايند
in front of|أمام|إن فرَنت أڤ
where|أين|وير
how much|كم السعر|هاو مَتش
price|سعر|پرايس
money|مال|مَني
coin|عملة|كوين
cash|نقد|كاش
buy|يشتري|باي
sell|يبيع|سِل
want|يريد|وونت
need|يحتاج|نيد
like|يحب|لايك
love|يعشق|لَڤ
water|ماء|ووتَر
juice|عصير|جوس
bread|خبز|برِد
apple|تفاحة|أپِل
flower|زهرة|فلاوَر
tree|شجرة|تري
lantern|فانوس|لانتَرن
light|ضوء|لايت
night|ليل|نايت
star|نجمة|ستار
gold|ذهبي|غولد
silver|فضي|سِلڤَر
blue|أزرق|بلو
red|أحمر|رِد
green|أخضر|غرين
yellow|أصفر|يَلّو
beautiful|جميل|بيوتِفُل
quiet|هادئ|كوايَت
loud|مرتفع الصوت|لاود
music|موسيقى|ميوزِك
song|أغنية|سونغ
smile|ابتسامة|سمايل
friend|صديق|فرِند
family|عائلة|فاميلي
grandma|الجدة|غرانْدما
surprise|مفاجأة|سربرايز
search|يبحث|سيرتش
discover|يكتشف|دِسكَڤَر
walk|يمشي|ووك
follow|يتبع|فولّو
look|ينظر|لوك
listen|يستمع|لِسِن
excuse me|عذرًا|إكسكيوز مي
thank you|شكرًا|ثانك يو''',
  };

  static final Map<int, List<EnglishA1Word>> _banks =
      _rawBanks.map((unit, raw) => MapEntry(
        unit,
        raw.trim().split('\n').map((line) {
          final parts = line.split('|');
          if (parts.length != 3 || parts.any((p) => p.trim().isEmpty)) {
            throw FormatException('Invalid English A1 vocabulary: $line');
          }
          return EnglishA1Word(parts[0].trim(), parts[1].trim(),
              parts[2].trim());
        }).toList(growable: false),
      ));

  /// Stable, topic-graded A1 word pools. Each lesson contains exactly
  /// ten nouns, ten verbs, ten adjectives and ten adverbs. The pools rotate
  /// for spaced review without repeating terms within a single lesson.
  static const _typedBanks = <int, Map<EnglishA1WordKind, List<String>>>{
    1: {
      EnglishA1WordKind.noun: <String>["notebook|دفتر", "teacher|معلم", "student|طالب", "school|مدرسة", "classroom|فصل دراسي", "library|مكتبة", "book|كتاب", "desk|مكتب", "chair|كرسي", "table|طاولة", "window|نافذة", "door|باب", "bag|حقيبة", "paper|ورق", "picture|صورة", "friend|صديق", "lesson|درس", "sentence|جملة", "question|سؤال", "answer|إجابة", "word|كلمة", "page|صفحة", "story|قصة", "color|لون", "ruler|مسطرة", "map|خريطة", "computer|حاسوب", "letter|رسالة", "name|اسم", "pencil|قلم رصاص"],
      EnglishA1WordKind.verb: <String>["read|يقرأ", "write|يكتب", "open|يفتح", "close|يغلق", "listen|يستمع", "look|ينظر", "speak|يتحدث", "say|يقول", "ask|يسأل", "answer|يجيب", "learn|يتعلم", "study|يدرس", "draw|يرسم", "count|يعد", "find|يجد", "help|يساعد", "carry|يحمل", "show|يعرض", "give|يعطي", "take|يأخذ", "put|يضع", "sit|يجلس", "stand|يقف", "smile|يبتسم", "play|يلعب", "share|يشارك", "walk|يمشي", "point|يشير", "meet|يقابل", "check|يتحقق"],
      EnglishA1WordKind.adjective: <String>["new|جديد", "old|قديم", "big|كبير", "small|صغير", "happy|سعيد", "sad|حزين", "good|جيد", "bad|سيئ", "nice|لطيف", "kind|طيب", "quiet|هادئ", "loud|مرتفع الصوت", "red|أحمر", "blue|أزرق", "green|أخضر", "yellow|أصفر", "white|أبيض", "black|أسود", "clean|نظيف", "dirty|متسخ", "easy|سهل", "hard|صعب", "short|قصير", "long|طويل", "bright|مشرق", "dark|داكن", "young|صغير السن", "friendly|ودود", "ready|مستعد", "beautiful|جميل"],
      EnglishA1WordKind.adverb: <String>["slowly|ببطء", "quickly|بسرعة", "carefully|بعناية", "quietly|بهدوء", "loudly|بصوت عال", "clearly|بوضوح", "happily|بسعادة", "sadly|بحزن", "gently|برفق", "easily|بسهولة", "together|معًا", "always|دائمًا", "often|غالبًا", "sometimes|أحيانًا", "usually|عادة", "never|أبدًا", "today|اليوم", "tomorrow|غدًا", "now|الآن", "here|هنا", "there|هناك", "outside|في الخارج", "inside|في الداخل", "early|مبكرًا", "late|متأخرًا", "first|أولًا", "next|بعد ذلك", "again|مرة أخرى", "well|جيدًا", "politely|بأدب"],
    },
    2: {
      EnglishA1WordKind.noun: <String>["morning|صباح", "evening|مساء", "breakfast|فطور", "lunch|غداء", "dinner|عشاء", "family|عائلة", "mother|أم", "father|أب", "sister|أخت", "brother|أخ", "home|منزل", "bedroom|غرفة نوم", "kitchen|مطبخ", "bathroom|حمام", "garden|حديقة", "bus|حافلة", "clock|ساعة", "week|أسبوع", "day|يوم", "hour|ساعة زمنية", "shirt|قميص", "jacket|سترة", "shoes|حذاء", "phone|هاتف", "milk|حليب", "bread|خبز", "egg|بيضة", "rice|أرز", "water|ماء", "umbrella|مظلة"],
      EnglishA1WordKind.verb: <String>["wake|يستيقظ", "sleep|ينام", "eat|يأكل", "drink|يشرب", "cook|يطبخ", "wash|يغسل", "clean|ينظف", "dress|يرتدي", "leave|يغادر", "arrive|يصل", "go|يذهب", "come|يأتي", "work|يعمل", "study|يدرس", "play|يلعب", "rest|يستريح", "wait|ينتظر", "start|يبدأ", "finish|ينهي", "make|يصنع", "buy|يشتري", "prepare|يحضر", "wear|يرتدي", "visit|يزور", "call|يتصل", "watch|يشاهد", "walk|يمشي", "travel|يسافر", "help|يساعد", "share|يشارك"],
      EnglishA1WordKind.adjective: <String>["awake|مستيقظ", "active|نشيط", "hungry|جائع", "thirsty|عطشان", "tired|متعب", "busy|مشغول", "free|متفرغ", "warm|دافئ", "cold|بارد", "hot|حار", "fresh|طازج", "healthy|صحي", "sick|مريض", "sleepy|نعسان", "bright|مشرق", "tidy|مرتب", "messy|فوضوي", "comfortable|مريح", "quiet|هادئ", "noisy|صاخب", "sunny|مشمس", "rainy|ممطر", "cloudy|غائم", "windy|عاصف", "ready|مستعد", "favorite|مفضل", "delicious|لذيذ", "simple|بسيط", "safe|آمن", "important|مهم"],
      EnglishA1WordKind.adverb: <String>["early|مبكرًا", "late|متأخرًا", "today|اليوم", "tomorrow|غدًا", "yesterday|أمس", "usually|عادة", "always|دائمًا", "often|غالبًا", "sometimes|أحيانًا", "never|أبدًا", "daily|يوميًا", "slowly|ببطء", "quickly|بسرعة", "quietly|بهدوء", "carefully|بعناية", "happily|بسعادة", "well|جيدًا", "outside|في الخارج", "inside|في الداخل", "upstairs|في الطابق العلوي", "downstairs|في الطابق السفلي", "nearby|في الجوار", "here|هنا", "there|هناك", "now|الآن", "soon|قريبًا", "first|أولًا", "then|ثم", "again|مرة أخرى", "together|معًا"],
    },
    3: {
      EnglishA1WordKind.noun: <String>["street|شارع", "market|سوق", "shop|متجر", "bank|بنك", "park|منتزه", "museum|متحف", "hospital|مستشفى", "bakery|مخبز", "pharmacy|صيدلية", "cafe|مقهى", "restaurant|مطعم", "library|مكتبة", "station|محطة", "ticket|تذكرة", "bus|حافلة", "bicycle|دراجة", "beach|شاطئ", "garden|حديقة", "flower|زهرة", "tree|شجرة", "gift|هدية", "party|حفلة", "cake|كعكة", "menu|قائمة طعام", "juice|عصير", "money|مال", "price|سعر", "map|خريطة", "bridge|جسر", "river|نهر"],
      EnglishA1WordKind.verb: <String>["walk|يمشي", "turn|ينعطف", "stop|يتوقف", "cross|يعبر", "visit|يزور", "buy|يشتري", "sell|يبيع", "pay|يدفع", "choose|يختار", "order|يطلب", "ask|يسأل", "show|يري", "follow|يتبع", "find|يجد", "search|يبحث", "travel|يسافر", "ride|يركب", "drive|يقود", "carry|يحمل", "bring|يحضر", "meet|يلتقي", "enjoy|يستمتع", "share|يشارك", "give|يعطي", "receive|يستلم", "play|يلعب", "dance|يرقص", "sing|يغني", "watch|يشاهد", "discover|يكتشف"],
      EnglishA1WordKind.adjective: <String>["near|قريب", "far|بعيد", "open|مفتوح", "closed|مغلق", "busy|مزدحم", "quiet|هادئ", "crowded|مكتظ", "empty|فارغ", "cheap|رخيص", "expensive|غالي", "beautiful|جميل", "pretty|جميل", "bright|مشرق", "dark|مظلم", "safe|آمن", "clean|نظيف", "dirty|متسخ", "fresh|طازج", "tasty|لذيذ", "sweet|حلو", "hot|ساخن", "cold|بارد", "small|صغير", "large|كبير", "old|قديم", "modern|حديث", "friendly|ودود", "helpful|مفيد", "special|مميز", "interesting|مثير للاهتمام"],
      EnglishA1WordKind.adverb: <String>["straight|مباشرة", "left|يسارًا", "right|يمينًا", "nearby|بالقرب", "faraway|بعيدًا", "outside|في الخارج", "inside|في الداخل", "here|هنا", "there|هناك", "today|اليوم", "tomorrow|غدًا", "now|الآن", "soon|قريبًا", "slowly|ببطء", "quickly|بسرعة", "carefully|بحذر", "safely|بأمان", "politely|بأدب", "kindly|بلطف", "happily|بسعادة", "quietly|بهدوء", "loudly|بصوت عال", "together|معًا", "alone|وحده", "usually|عادة", "sometimes|أحيانًا", "always|دائمًا", "first|أولًا", "then|ثم", "again|مرة أخرى"],
    },
  };

  static List<EnglishA1Word> wordsByKind(
          int unit, int lessonNumber, EnglishA1WordKind kind) =>
      forLesson(unit, lessonNumber).where((word) => word.kind == kind)
          .toList(growable: false);

  static List<EnglishA1Word> forLesson(int unit, int lessonNumber) {
    if (lessonNumber < 1 || lessonNumber > 10) {
      throw RangeError.range(lessonNumber, 1, 10, 'lessonNumber');
    }
    final banks = _typedBanks[unit];
    if (banks == null) throw ArgumentError.value(unit, 'unit');
    final legacy = _banks[unit]!;
    final words = <EnglishA1Word>[];
    for (final kind in EnglishA1WordKind.values) {
      final bank = banks[kind]!;
      if (bank.length < 10) throw StateError('Insufficient A1 words for $kind');
      for (var i = 0; i < 10; i++) {
        final row = bank[((lessonNumber - 1) * 7 + i) % bank.length]
            .split('|');
        final old = legacy.where((word) =>
            word.term.toLowerCase() == row.first.toLowerCase());
        words.add(EnglishA1Word(row[0], row[1],
          old.isEmpty ? row[0] : old.first.pronunciation,
          kind: kind));
      }
    }
    return List<EnglishA1Word>.unmodifiable(words);
  }

  static int uniqueCount(int unit) => _typedBanks[unit]?.values
      .fold<int>(0, (n, words) => n + words.length) ?? 0;
}
