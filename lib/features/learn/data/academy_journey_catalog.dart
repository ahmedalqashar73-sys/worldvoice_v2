/// Curriculum targets, not a claim that all units have been authored.
///
/// Existing A1 lessons are stored in academy_catalog.dart and remain the
/// authority for what the learner can actually open or complete.
class AcademyJourneyLevel {
  const AcademyJourneyLevel({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.goalArabic,
    required this.goalEnglish,
    required this.plannedUnits,
    required this.topicsArabic,
    required this.topicsEnglish,
  });

  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String goalArabic;
  final String goalEnglish;
  final int plannedUnits;
  final List<String> topicsArabic;
  final List<String> topicsEnglish;

  bool get isBeginner => id == 'A1';
}

abstract final class AcademyJourneyCatalog {
  static const levels = <AcademyJourneyLevel>[
    AcademyJourneyLevel(
      id: 'A1',
      titleArabic: 'المبتدئ',
      titleEnglish: 'Beginner',
      goalArabic: 'قدّم نفسك وتحدث عن يومك بجمل بسيطة.',
      goalEnglish: 'Introduce yourself and talk about daily life in simple sentences.',
      plannedUnits: 12,
      topicsArabic: ['التحيات والتعارف', 'الروتين اليومي', 'الأرقام والوقت', 'العائلة', 'الطعام', 'المنزل', 'الأماكن والاتجاهات', 'التسوق', 'الهوايات', 'الطقس', 'المواصلات', 'مراجعة المستوى'],
      topicsEnglish: ['Greetings', 'Daily routine', 'Numbers and time', 'Family', 'Food', 'Home', 'Places and directions', 'Shopping', 'Hobbies', 'Weather', 'Transport', 'Level review'],
    ),
    AcademyJourneyLevel(
      id: 'A2',
      titleArabic: 'المبتدئ المتقدم',
      titleEnglish: 'Elementary',
      goalArabic: 'تعامل مع السفر والمواقف اليومية والطلبات.',
      goalEnglish: 'Handle travel, everyday situations and requests.',
      plannedUnits: 12,
      topicsArabic: ['الرحلات', 'حجز الفندق', 'المطعم', 'طلب المساعدة', 'الصحة', 'الأصدقاء', 'الرسائل', 'الذكريات', 'التخطيط', 'المشتريات', 'الحياة الاجتماعية', 'مراجعة المستوى'],
      topicsEnglish: ['Trips', 'Hotels', 'Restaurants', 'Asking for help', 'Health', 'Friends', 'Messages', 'Memories', 'Plans', 'Purchases', 'Social life', 'Review'],
    ),
    AcademyJourneyLevel(
      id: 'B1',
      titleArabic: 'المتوسط',
      titleEnglish: 'Intermediate',
      goalArabic: 'احكِ قصة واشرح رأيك وأسبابه.',
      goalEnglish: 'Tell stories and explain opinions and reasons.',
      plannedUnits: 16,
      topicsArabic: ['التجارب', 'الطموح', 'ثقافات العالم', 'حل المشكلات', 'العمل', 'السفر', 'العلاقات', 'المواقف المفاجئة'],
      topicsEnglish: ['Experiences', 'Ambitions', 'Cultures', 'Problem solving', 'Work', 'Travel', 'Relationships', 'Unexpected events'],
    ),
    AcademyJourneyLevel(
      id: 'B2',
      titleArabic: 'فوق المتوسط',
      titleEnglish: 'Upper-intermediate',
      goalArabic: 'ناقش الأفكار المعقدة وعبّر عن الحجج بوضوح.',
      goalEnglish: 'Discuss complex ideas and support a viewpoint.',
      plannedUnits: 16,
      topicsArabic: ['المقابلات', 'التقنية', 'النقاش', 'الصحافة', 'التواصل المهني', 'التفكير النقدي'],
      topicsEnglish: ['Interviews', 'Technology', 'Debate', 'Media', 'Professional communication', 'Critical thinking'],
    ),
    AcademyJourneyLevel(
      id: 'C1',
      titleArabic: 'المتقدم',
      titleEnglish: 'Advanced',
      goalArabic: 'افهم النصوص الطويلة وتحدث بمرونة ودقة.',
      goalEnglish: 'Understand extended texts and communicate flexibly.',
      plannedUnits: 20,
      topicsArabic: ['الأسلوب', 'الإقناع', 'العروض', 'الأدب', 'التحليل', 'اللغة المهنية'],
      topicsEnglish: ['Style', 'Persuasion', 'Presentations', 'Literature', 'Analysis', 'Professional language'],
    ),
    AcademyJourneyLevel(
      id: 'C2',
      titleArabic: 'الإتقان',
      titleEnglish: 'Mastery',
      goalArabic: 'حلل المعاني الدقيقة وأعد صياغة النصوص المعقدة.',
      goalEnglish: 'Infer subtle meaning and synthesize complex texts.',
      plannedUnits: 20,
      topicsArabic: ['النصوص الأدبية', 'الدقة والأسلوب', 'الاستدلال', 'الحوار المتقدم', 'النقد', 'الملخصات المركّبة'],
      topicsEnglish: ['Literature', 'Precision and style', 'Inference', 'Advanced dialogue', 'Critique', 'Synthesis'],
    ),
  ];

  static int get plannedUnits =>
      levels.fold(0, (sum, level) => sum + level.plannedUnits);
}
