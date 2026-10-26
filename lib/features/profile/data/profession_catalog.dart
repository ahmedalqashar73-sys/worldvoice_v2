class ProfessionOption {
  const ProfessionOption(this.key, this.en, this.ar);
  final String key;
  final String en;
  final String ar;

  String label(String localeCode) => localeCode == 'ar' ? ar : en;
}

class ProfessionCatalog {
  const ProfessionCatalog._();

  static const options = <ProfessionOption>[
    ProfessionOption('student','Student','طالب / طالبة'),
    ProfessionOption('teacher','Teacher','معلم / معلمة'),
    ProfessionOption('professor','Professor / Lecturer','أستاذ جامعي / محاضر'),
    ProfessionOption('doctor','Doctor','طبيب / طبيبة'),
    ProfessionOption('nurse','Nurse','ممرض / ممرضة'),
    ProfessionOption('pharmacist','Pharmacist','صيدلي / صيدلانية'),
    ProfessionOption('dentist','Dentist','طبيب أسنان'),
    ProfessionOption('engineer','Engineer','مهندس / مهندسة'),
    ProfessionOption('software_engineer','Software engineer','مهندس برمجيات'),
    ProfessionOption('developer','Developer / Programmer','مطور / مبرمج'),
    ProfessionOption('designer','Designer','مصمم / مصممة'),
    ProfessionOption('architect','Architect','مهندس معماري'),
    ProfessionOption('accountant','Accountant','محاسب / محاسبة'),
    ProfessionOption('banker','Banking / Finance','بنوك / مالية'),
    ProfessionOption('business_owner','Business owner','صاحب عمل / رائد أعمال'),
    ProfessionOption('manager','Manager','مدير / مديرة'),
    ProfessionOption('sales','Sales','مبيعات'),
    ProfessionOption('marketing','Marketing','تسويق'),
    ProfessionOption('hr','Human resources','موارد بشرية'),
    ProfessionOption('lawyer','Lawyer','محامٍ / محامية'),
    ProfessionOption('journalist','Journalist','صحفي / صحفية'),
    ProfessionOption('writer','Writer','كاتب / كاتبة'),
    ProfessionOption('translator','Translator / Interpreter','مترجم / مترجمة'),
    ProfessionOption('photographer','Photographer','مصور / مصورة'),
    ProfessionOption('artist','Artist','فنان / فنانة'),
    ProfessionOption('musician','Musician','موسيقي / موسيقية'),
    ProfessionOption('content_creator','Content creator','صانع محتوى'),
    ProfessionOption('chef','Chef','طاهٍ / طاهية'),
    ProfessionOption('pilot','Pilot','طيار / طيارة'),
    ProfessionOption('flight_attendant','Flight attendant','مضيف / مضيفة طيران'),
    ProfessionOption('police','Police officer','شرطي / شرطية'),
    ProfessionOption('military','Military','عسكري'),
    ProfessionOption('mechanic','Mechanic','ميكانيكي'),
    ProfessionOption('electrician','Electrician','كهربائي'),
    ProfessionOption('construction','Construction','إنشاءات / بناء'),
    ProfessionOption('farmer','Farmer','مزارع'),
    ProfessionOption('driver','Driver','سائق'),
    ProfessionOption('athlete','Athlete','رياضي / رياضية'),
    ProfessionOption('coach','Coach / Trainer','مدرب / مدربة'),
    ProfessionOption('researcher','Researcher','باحث / باحثة'),
    ProfessionOption('scientist','Scientist','عالم / باحث علمي'),
    ProfessionOption('government','Government employee','موظف حكومي'),
    ProfessionOption('customer_service','Customer service','خدمة عملاء'),
    ProfessionOption('hospitality','Hospitality / Hotel','ضيافة / فنادق'),
    ProfessionOption('retail','Retail','تجارة تجزئة'),
    ProfessionOption('freelancer','Freelancer','عمل حر'),
    ProfessionOption('unemployed','Not currently working','لا أعمل حاليًا'),
    ProfessionOption('retired','Retired','متقاعد / متقاعدة'),
    ProfessionOption('other','Other','أخرى'),
  ];

  static ProfessionOption? byKey(String? key) {
    if (key == null) return null;
    for (final item in options) {
      if (item.key == key) return item;
    }
    return null;
  }
}
