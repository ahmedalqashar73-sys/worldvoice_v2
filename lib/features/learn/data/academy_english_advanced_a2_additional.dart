part of 'academy_english_advanced_models.dart';

/// Fully authored third and fourth lessons for English A2 Unit 1.
/// No placeholder lessons are unlocked without their own content and checks.
abstract final class EnglishAdvancedA2Additional {
  static const lessons = <EnglishAdvancedLesson>[
    EnglishAdvancedLesson(
      level: 'A2', number: 3, title: "Finding an Apartment",
      titleArabic: "البحث عن شقة", storyTitle: "Finding an Apartment",
      storyTitleArabic: "البحث عن شقة",
      paragraphs: <String>["Amira wanted to move closer to her new school, so she booked a viewing of an apartment in a quiet street. The furnished living room was bright, and a small balcony looked over a park. The estate agent explained that the rent was paid at the beginning of each month.","Amira asked the landlord about the lease and the deposit. She also wanted to know whether utility bills were included. The landlord showed her the kitchen and said she could complete an application online after the inspection. Amira took notes because she did not want to forget any details.","That evening, Amira compared two homes. The first apartment was cheaper, but the second was nearer the school and had more space. She decided that a comfortable home was worth a slightly longer search, and she asked for another viewing on Saturday."],
      storyWords: <EnglishAdvancedWord>[EnglishAdvancedWord("apartment", "شقة"),EnglishAdvancedWord("viewing", "معاينة عقار"),EnglishAdvancedWord("furnished", "مفروش"),EnglishAdvancedWord("balcony", "شرفة"),EnglishAdvancedWord("rent", "إيجار"),EnglishAdvancedWord("landlord", "مالك العقار"),EnglishAdvancedWord("lease", "عقد إيجار"),EnglishAdvancedWord("deposit", "مبلغ تأمين"),EnglishAdvancedWord("utility bills", "فواتير الخدمات"),EnglishAdvancedWord("application", "طلب تقديم")],
      extraWords: <EnglishAdvancedWord>[EnglishAdvancedWord("tenant", "مستأجر"),EnglishAdvancedWord("electricity bill", "فاتورة كهرباء"),EnglishAdvancedWord("property manager", "مدير العقار"),EnglishAdvancedWord("rental agreement", "اتفاقية إيجار"),EnglishAdvancedWord("monthly payment", "دفعة شهرية"),EnglishAdvancedWord("maintenance fee", "رسوم صيانة"),EnglishAdvancedWord("entrance hall", "بهو المدخل"),EnglishAdvancedWord("security deposit", "تأمين مسترد"),EnglishAdvancedWord("moving boxes", "صناديق الانتقال"),EnglishAdvancedWord("washing machine", "غسالة"),EnglishAdvancedWord("shared kitchen", "مطبخ مشترك"),EnglishAdvancedWord("heating system", "نظام تدفئة"),EnglishAdvancedWord("building entrance", "مدخل المبنى"),EnglishAdvancedWord("key collection", "استلام المفاتيح")],
      grammarTitle: "Comparatives and making choices", grammarArabic: "للمقارنة بين شيئين نستخدم الصفة المقارنة ثم than: cheaper than وnearer than. لبعض الصفات الأطول نستخدم more مثل more comfortable than. استخدم جملة تربط السعر بالموقع لاتخاذ قرار.",
      grammarExamples: <String>["This apartment is cheaper than that one.","The second home is nearer to school.","A brighter room may be more comfortable."],
      listening: "Hello, Amira. I am calling from the apartment office about your Saturday viewing. The visit will start at eleven thirty, not eleven. Please bring your identification and arrive five minutes early. The monthly rent is six hundred pounds, and water is included, but electricity is not. If you want the apartment, you can send your application through our website. The landlord will contact you after the weekend.", listeningQuestion: "Which bill is not included in the apartment rent?",
      listeningOptions: <String>["Water","Electricity","Heating"],
      listeningAnswer: 1, readingQuestion: "Why was Amira unsure about choosing the first home?",
      readingOptions: <String>["It was too close to the school","The balcony was closed","She wanted to compare price, space and location"],
      readingAnswer: 2, writingCue: "Amira asked the landlord how much the ____ would cost each month.",
      writingAnswer: "rent",
    ),
    EnglishAdvancedLesson(
      level: 'A2', number: 4, title: "At the Pharmacy",
      titleArabic: "في الصيدلية", storyTitle: "At the Pharmacy",
      storyTitleArabic: "في الصيدلية",
      paragraphs: <String>["After two rainy days, Omar woke up with a sore throat and a headache. He went to the pharmacy near his home and described his symptoms to the pharmacist. He explained that he had no serious allergies, but he wanted to feel better before an important school trip.","The pharmacist asked whether Omar had taken any tablets that morning. She checked the dosage on a box and carefully read the label. She explained that some medicines could cause side effects and that Omar should follow the instructions rather than take more than the recommended amount.","Omar bought the medicine and returned home to rest. He drank water and decided to call a doctor if the pain became worse or did not improve. The next day, his throat felt better, and he was glad that he had asked for clear advice instead of guessing about the medicine."],
      storyWords: <EnglishAdvancedWord>[EnglishAdvancedWord("sore throat", "ألم الحلق"),EnglishAdvancedWord("headache", "صداع"),EnglishAdvancedWord("pharmacy", "صيدلية"),EnglishAdvancedWord("symptoms", "أعراض"),EnglishAdvancedWord("pharmacist", "صيدلي"),EnglishAdvancedWord("allergies", "حساسية"),EnglishAdvancedWord("tablets", "أقراص"),EnglishAdvancedWord("dosage", "جرعة"),EnglishAdvancedWord("label", "ملصق التعليمات"),EnglishAdvancedWord("side effects", "آثار جانبية")],
      extraWords: <EnglishAdvancedWord>[EnglishAdvancedWord("medication", "دواء"),EnglishAdvancedWord("cough syrup", "شراب السعال"),EnglishAdvancedWord("pain relief", "تخفيف الألم"),EnglishAdvancedWord("thermometer", "مقياس حرارة"),EnglishAdvancedWord("waiting area", "منطقة انتظار"),EnglishAdvancedWord("medicine cabinet", "خزانة الأدوية"),EnglishAdvancedWord("health insurance", "تأمين صحي"),EnglishAdvancedWord("recovery", "تعافٍ"),EnglishAdvancedWord("rest period", "فترة راحة"),EnglishAdvancedWord("pharmacy counter", "منضدة الصيدلية"),EnglishAdvancedWord("liquid medicine", "دواء سائل"),EnglishAdvancedWord("emergency contact", "رقم تواصل طارئ"),EnglishAdvancedWord("treatment plan", "خطة علاج"),EnglishAdvancedWord("appointment card", "بطاقة موعد")],
      grammarTitle: "Advice with should, shouldn't and if", grammarArabic: "نستخدم should للنصيحة: You should rest. ونستخدم shouldn't عند النهي: You shouldn't take extra tablets. عندما نتحدث عن وضع صحي محتمل نستخدم if مع المضارع: If symptoms get worse, ask a doctor.",
      grammarExamples: <String>["You should drink enough water.","You shouldn't take extra tablets.","If symptoms get worse, contact a doctor."],
      listening: "Good afternoon. Before using this medicine, please read the instructions on the label. Take the amount recommended by your pharmacist, and do not take extra tablets to make the treatment work faster. Some medicines may make people feel tired. If you have questions about allergies or side effects, speak to a qualified pharmacist or doctor. Keep all medicines safely away from young children.", listeningQuestion: "What should a customer do before taking the medicine?",
      listeningOptions: <String>["Read the label and follow professional advice","Double the recommended dose","Give the tablets to a friend"],
      listeningAnswer: 0, readingQuestion: "What would Omar do if his pain got worse or did not improve?",
      readingOptions: <String>["Take many extra tablets","Call a doctor","Stop drinking water"],
      readingAnswer: 1, writingCue: "The ____ explained how to use the tablets safely.",
      writingAnswer: "pharmacist",
    ),
  ];
}
