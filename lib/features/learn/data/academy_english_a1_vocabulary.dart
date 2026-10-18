/// Contextual learner vocabulary; pronunciation hints are approximations.
/// The TTS audio in the integrated lesson is the primary sound reference.
class EnglishA1Word {
  const EnglishA1Word(this.term, this.arabic, this.pronunciation);
  final String term;
  final String arabic;
  final String pronunciation;
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

  /// Every lesson teaches/reinforces 20 different terms; consecutive lessons
  /// deliberately overlap for retrieval and spaced revision.
  static List<EnglishA1Word> forLesson(int unit, int lessonNumber) {
    if (lessonNumber < 1 || lessonNumber > 12) {
      throw RangeError.range(lessonNumber, 1, 12, 'lessonNumber');
    }
    final bank = _banks[unit];
    if (bank == null || bank.length < 20) {
      throw ArgumentError.value(unit, 'unit', 'Unknown A1 vocabulary bank');
    }
    return List.generate(20, (index) =>
        bank[((lessonNumber - 1) * 11 + index) % bank.length],
        growable: false);
  }

  static int uniqueCount(int unit) => _banks[unit]?.length ?? 0;
}
