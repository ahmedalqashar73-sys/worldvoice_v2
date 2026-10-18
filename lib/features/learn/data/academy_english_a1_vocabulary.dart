/// Vocabulary banks for full English A1 lessons.
///
/// Every one of the 36 lessons has 20 specifically authored English/Arabic
/// terms. Words are introduced by theme, played aloud using en-US TTS, and
/// revisited in dialogue, grammar, listening and story passages.
///
/// Do not use morphological text-to-speech guesses as written phonetics.
class EnglishA1Term {
  const EnglishA1Term(this.english, this.arabic);
  final String english;
  final String arabic;
}

abstract final class EnglishA1Vocabulary {
  static const _rows = <List<String>>[
    [
      'hello=مرحبًا|hi=أهلًا|goodbye=وداعًا|welcome=أهلًا وسهلًا|morning=صباح|evening=مساء|night=ليل|please=من فضلك|thanks=شكرًا|sorry=آسف|yes=نعم|no=لا|friend=صديق|name=اسم|teacher=معلم|student=طالب|school=مدرسة|class=صف|question=سؤال|answer=إجابة',
      'first=أول|last=أخير|family=عائلة|mother=أم|father=أب|sister=أخت|brother=أخ|parent=والد|child=طفل|baby=رضيع|grandmother=جدة|grandfather=جد|daughter=ابنة|son=ابن|cousin=ابن العم|aunt=عمة أو خالة|uncle=عم أو خال|relative=قريب|home=منزل|together=معًا',
      'one=واحد|two=اثنان|three=ثلاثة|four=أربعة|five=خمسة|six=ستة|seven=سبعة|eight=ثمانية|nine=تسعة|ten=عشرة|eleven=أحد عشر|twelve=اثنا عشر|number=رقم|count=يعد|more=أكثر|less=أقل|many=كثير|few=قليل|all=كل|some=بعض',
      'blue=أزرق|green=أخضر|red=أحمر|yellow=أصفر|black=أسود|white=أبيض|brown=بني|pink=وردي|purple=بنفسجي|orange=برتقالي|color=لون|light=فاتح|dark=داكن|bright=مشرق|paint=يرسم|picture=صورة|circle=دائرة|square=مربع|line=خط|shape=شكل',
      'book=كتاب|notebook=دفتر|pen=قلم حبر|pencil=قلم رصاص|paper=ورق|page=صفحة|letter=حرف أو رسالة|word=كلمة|sentence=جملة|story=قصة|title=عنوان|cover=غلاف|desk=مكتب|chair=كرسي|table=طاولة|bag=حقيبة|window=نافذة|door=باب|key=مفتاح|shelf=رف',
      'happy=سعيد|sad=حزين|angry=غاضب|worried=قلق|afraid=خائف|excited=متحمس|calm=هادئ|kind=لطيف|helpful=متعاون|friendly=ودود|tired=متعب|ready=مستعد|surprised=متفاجئ|brave=شجاع|quiet=هادئ|loud=صاخب|smile=يبتسم|laugh=يضحك|cry=يبكي|feel=يشعر',
      'small=صغير|big=كبير|short=قصير|tall=طويل القامة|long=طويل|new=جديد|old=قديم|young=صغير السن|clean=نظيف|dirty=متسخ|easy=سهل|hard=صعب|fast=سريع|slow=بطيء|beautiful=جميل|nice=لطيف|good=جيد|bad=سيئ|right=صحيح|wrong=خاطئ',
      'meet=يقابل|greet=يرحب|say=يقول|speak=يتحدث|talk=يتكلم|listen=يستمع|hear=يسمع|read=يقرأ|write=يكتب|spell=يتهجى|ask=يسأل|reply=يرد|learn=يتعلم|teach=يعلّم|remember=يتذكر|forget=ينسى|know=يعرف|think=يفكر|understand=يفهم|repeat=يكرر',
      'this=هذا|that=ذاك|these=هؤلاء أو هذه|those=أولئك|here=هنا|there=هناك|near=قريب|far=بعيد|inside=داخل|outside=خارج|above=فوق|below=تحت|between=بين|behind=خلف|beside=بجانب|front=أمام|back=خلف|left=يسار|right=يمين|middle=وسط',
      'library=مكتبة|bookshop=مكتبة كتب|park=حديقة عامة|garden=حديقة|museum=متحف|cafe=مقهى|shop=متجر|market=سوق|hospital=مستشفى|station=محطة|street=شارع|road=طريق|city=مدينة|town=بلدة|village=قرية|country=دولة|place=مكان|building=مبنى|office=مكتب عمل|room=غرفة',
      'star=نجمة|tree=شجرة|flower=زهرة|leaf=ورقة شجر|sun=شمس|moon=قمر|sky=سماء|cloud=سحابة|rain=مطر|wind=رياح|river=نهر|lake=بحيرة|mountain=جبل|sea=بحر|sand=رمل|stone=حجر|grass=عشب|bird=طائر|cat=قطة|dog=كلب',
      'find=يجد|lose=يفقد|look=ينظر|search=يبحث|open=يفتح|close=يغلق|bring=يحضر|give=يعطي|take=يأخذ|keep=يحتفظ|share=يشارك|show=يعرض|choose=يختار|try=يحاول|start=يبدأ|finish=ينهي|check=يتحقق|follow=يتبع|return=يعود|discover=يكتشف',
    ],
    [
      'wake=يستيقظ|sleep=ينام|dream=يحلم|get up=ينهض|wash=يغسل|brush=يفرش|shower=يستحم|dress=يرتدي|wear=يلبس|eat=يأكل|drink=يشرب|cook=يطبخ|prepare=يجهز|leave=يغادر|arrive=يصل|rest=يستريح|relax=يسترخي|study=يدرس|work=يعمل|practice=يتدرب',
      'breakfast=فطور|lunch=غداء|dinner=عشاء|snack=وجبة خفيفة|bread=خبز|egg=بيضة|milk=حليب|cheese=جبن|butter=زبدة|jam=مربى|honey=عسل|apple=تفاحة|banana=موز|orange=برتقالة|water=ماء|juice=عصير|tea=شاي|coffee=قهوة|rice=أرز|soup=حساء',
      'minute=دقيقة|hour=ساعة|day=يوم|week=أسبوع|month=شهر|year=سنة|today=اليوم|tomorrow=غدًا|yesterday=أمس|early=مبكر|late=متأخر|now=الآن|later=لاحقًا|always=دائمًا|often=غالبًا|sometimes=أحيانًا|never=أبدًا|usually=عادة|before=قبل|after=بعد',
      'monday=الاثنين|tuesday=الثلاثاء|wednesday=الأربعاء|thursday=الخميس|friday=الجمعة|saturday=السبت|sunday=الأحد|weekday=يوم عمل|weekend=عطلة نهاية الأسبوع|calendar=تقويم|date=تاريخ|schedule=جدول|appointment=موعد|holiday=عطلة|birthday=عيد ميلاد|season=فصل|spring=ربيع|summer=صيف|autumn=خريف|winter=شتاء',
      'kitchen=مطبخ|bedroom=غرفة نوم|bathroom=حمام|living room=غرفة معيشة|hallway=ممر|balcony=شرفة|floor=أرضية|ceiling=سقف|wall=جدار|roof=سطح|bed=سرير|pillow=وسادة|blanket=بطانية|sofa=أريكة|lamp=مصباح|mirror=مرآة|cupboard=خزانة|fridge=ثلاجة|oven=فرن|sink=حوض',
      'bus=حافلة|train=قطار|car=سيارة|taxi=سيارة أجرة|bicycle=دراجة|motorcycle=دراجة نارية|plane=طائرة|boat=قارب|ticket=تذكرة|driver=سائق|passenger=راكب|seat=مقعد|stop=محطة توقف|route=مسار|travel=يسافر|ride=يركب|drive=يقود|walk=يمشي|run=يجري|wait=ينتظر',
      'pet=حيوان أليف|puppy=جرو|kitten=قطة صغيرة|rabbit=أرنب|fish=سمكة|horse=حصان|cow=بقرة|sheep=خروف|chicken=دجاجة|duck=بطة|mouse=فأر|tail=ذيل|paw=قدم حيوان|fur=فرو|feed=يطعم|play=يلعب|jump=يقفز|sit=يجلس|stand=يقف|hide=يختبئ',
      'job=وظيفة|career=مهنة|manager=مدير|doctor=طبيب|nurse=ممرض|engineer=مهندس|artist=فنان|writer=كاتب|chef=طاه|farmer=مزارع|pilot=طيار|mechanic=ميكانيكي|clerk=موظف|cashier=أمين صندوق|police=شرطة|firefighter=إطفائي|colleague=زميل|team=فريق|meeting=اجتماع|project=مشروع',
      'math=رياضيات|science=علوم|history=تاريخ|geography=جغرافيا|language=لغة|English=الإنجليزية|Arabic=العربية|lesson=درس|homework=واجب|exam=امتحان|grade=درجة|note=ملاحظة|dictionary=قاموس|computer=حاسوب|screen=شاشة|keyboard=لوحة مفاتيح|notepad=دفتر ملاحظات|eraser=ممحاة|ruler=مسطرة|backpack=حقيبة ظهر',
      'umbrella=مظلة|jacket=سترة|coat=معطف|shirt=قميص|trousers=بنطال|skirt=تنورة|dress=فستان|shoes=حذاء|socks=جوارب|hat=قبعة|scarf=وشاح|gloves=قفازات|pocket=جيب|button=زر|zipper=سحاب|boots=حذاء طويل|sweater=سترة صوف|uniform=زي موحد|fabric=قماش|laundry=غسيل',
      'sunny=مشمس|rainy=ممطر|cloudy=غائم|windy=عاصف|snowy=مثلج|stormy=عاصف بشدة|hot=حار|cold=بارد|warm=دافئ|cool=معتدل البرودة|wet=مبلل|dry=جاف|forecast=توقع الطقس|temperature=درجة حرارة|degree=درجة|snow=ثلج|storm=عاصفة|thunder=رعد|lightning=برق|weather=الطقس',
      'habit=عادة|routine=روتين|plan=خطة|goal=هدف|task=مهمة|busy=مشغول|free=متفرغ|healthy=صحي|active=نشيط|quietly=بهدوء|quickly=بسرعة|carefully=بحذر|slowly=ببطء|regularly=بانتظام|daily=يوميًا|weekly=أسبوعيًا|timetable=جدول مواعيد|activity=نشاط|break=استراحة|energy=طاقة',
    ],
    [
      'map=خريطة|direction=اتجاه|north=شمال|south=جنوب|east=شرق|west=غرب|straight=مستقيم|turn=ينعطف|corner=زاوية شارع|cross=يعبر|crosswalk=ممر مشاة|traffic=مرور|signal=إشارة|bridge=جسر|tunnel=نفق|entrance=مدخل|exit=مخرج|distance=مسافة|location=موقع|address=عنوان',
      'bakery=مخبز|pharmacy=صيدلية|restaurant=مطعم|supermarket=سوبرماركت|bank=بنك|post office=مكتب بريد|cinema=سينما|theatre=مسرح|hotel=فندق|airport=مطار|zoo=حديقة حيوان|stadium=ملعب|gym=صالة رياضة|gallery=معرض|music shop=متجر موسيقى|gift shop=متجر هدايا|bookstore=متجر كتب|clinic=عيادة|factory=مصنع|playground=ملعب أطفال',
      'price=سعر|cost=تكلفة|cheap=رخيص|expensive=غالي|discount=خصم|sale=تخفيضات|cash=نقد|card=بطاقة|coin=عملة معدنية|change=باقي النقود|receipt=إيصال|basket=سلة|cart=عربة تسوق|customer=زبون|seller=بائع|buy=يشتري|sell=يبيع|pay=يدفع|spend=ينفق|save=يدخر',
      'fruit=فاكهة|vegetable=خضار|tomato=طماطم|potato=بطاطس|carrot=جزر|onion=بصل|cucumber=خيار|lettuce=خس|pepper=فلفل|grape=عنب|lemon=ليمون|strawberry=فراولة|melon=شمام|peach=خوخ|pear=كمثرى|mango=مانجو|pineapple=أناناس|watermelon=بطيخ|coconut=جوز هند|avocado=أفوكادو',
      'menu=قائمة طعام|order=طلب|waiter=نادل|dish=طبق|plate=صحن|bowl=وعاء|cup=كوب|glass=كأس|fork=شوكة|spoon=ملعقة|knife=سكين|napkin=منديل|salt=ملح|sugar=سكر|spicy=حار بالتوابل|sweet=حلو|sour=حامض|delicious=لذيذ|hungry=جائع|thirsty=عطشان',
      'garden path=ممر حديقة|fountain=نافورة|bench=مقعد حديقة|pond=بركة|butterfly=فراشة|bee=نحلة|firefly=يراعة|insect=حشرة|nest=عش|branch=غصن|root=جذر|seed=بذرة|plant=نبتة|bloom=يزهر|petal=بتلة|rose=وردة|tulip=زهرة توليب|lavender=لافندر|bush=شجيرة|forest=غابة',
      'music=موسيقى|song=أغنية|sing=يغني|dance=يرقص|guitar=غيتار|piano=بيانو|violin=كمان|drum=طبل|flute=ناي|band=فرقة موسيقية|singer=مغنٍ|concert=حفلة موسيقية|sound=صوت|melody=لحن|rhythm=إيقاع|instrument=آلة موسيقية|practice playing=يتمرن على العزف|hear again=يسمع مجددًا|clap=يصفق|perform=يؤدي',
      'trip=رحلة|journey=سفر|suitcase=حقيبة سفر|passport=جواز سفر|guide=دليل|tourist=سائح|visit=يزور|explore=يستكشف|photograph=صورة فوتوغرافية|camera=كاميرا|souvenir=تذكار|view=منظر|landmark=معلم بارز|beach=شاطئ|island=جزيرة|waterfall=شلال|path=مسار|adventure=مغامرة|lost=ضائع|safe=آمن',
      'hobby=هواية|drawing=رسم|painting=تلوين|reading=قراءة|swimming=سباحة|cycling=ركوب الدراجة|football=كرة قدم|basketball=كرة سلة|tennis=تنس|running=جري|hiking=تنزه|camping=تخييم|fishing=صيد|gardening=بستنة|photography=تصوير|chess=شطرنج|puzzle=لغز|game=لعبة|collection=مجموعة|craft=حرفة يدوية',
      'polite=مهذب|rude=وقح|excuse=اعذرني|pardon=المعذرة|may=هل يمكن|can=يستطيع|could=هل تستطيع|would=هل تود|request=طلب|offer=عرض|accept=يقبل|refuse=يرفض|invite=يدعو|thank=يشكر|apologize=يعتذر|respect=احترام|welcome again=مرحبًا مجددًا|of course=بالطبع|certainly=بالتأكيد|permission=إذن',
      'healthy food=طعام صحي|medicine=دواء|pain=ألم|headache=صداع|fever=حمى|cough=سعال|a cold=زكام|rest=راحة|exercise=تمرين رياضي|health=صحة|body=جسم|head=رأس|hand=يد|foot=قدم|eye=عين|ear=أذن|nose=أنف|mouth=فم|tooth=سن|heart=قلب',
      'celebrate=يحتفل|party=حفلة|festival=مهرجان|present=هدية|surprise=مفاجأة|balloon=بالون|cake=كعكة|candle=شمعة|wish=أمنية|special=مميز|wonderful=رائع|amazing=مدهش|memory=ذكرى|photo=صورة|decorate=يزين|wrap=يغلف|event=حدث|cheer=يهتف|enjoy=يستمتع|treat=مكافأة',
    ],
  ];

  static List<EnglishA1Term> forLesson(int unitNumber, int lessonNumber) {
    if (unitNumber < 1 || unitNumber > _rows.length ||
        lessonNumber < 1 || lessonNumber > 12) {
      throw RangeError('Unknown English A1 unit/lesson');
    }
    return _rows[unitNumber - 1][lessonNumber - 1]
        .split('|').map((entry) {
      final split = entry.indexOf('=');
      if (split < 1 || split == entry.length - 1) {
        throw FormatException('Malformed English A1 term: $entry');
      }
      return EnglishA1Term(entry.substring(0, split),
        entry.substring(split + 1));
    }).toList(growable: false);
  }

  static int get wordSlots => _rows.fold(0,
      (sum, unit) => sum + unit.fold(0,
        (n, row) => n + row.split('|').length));
}
