part of 'academy_english_advanced_models.dart';

/// CEFR course architecture mirrors A1: 3 units, 10 numbered lesson slots
/// per unit. A slot is NOT published until a distinct full lesson exists.
/// No fabricated exercises, borrowed story texts or progress completion.
class EnglishAdvancedUnitOutline {
  const EnglishAdvancedUnitOutline({
    required this.level,
    required this.number,
    required this.title,
    required this.titleArabic,
    required this.plannedTopics,
  });

  final String level;
  final int number;
  final String title;
  final String titleArabic;
  final List<String> plannedTopics;

  List<EnglishAdvancedLesson> get publishedLessons =>
      EnglishAdvancedSyllabus.forUnit(level, number);

  EnglishAdvancedLesson? lessonAt(int number) =>
      EnglishAdvancedSyllabus.findLesson(level, this.number, number);
}

abstract final class EnglishAdvancedCurriculum {
  static const _levels = <String, List<EnglishAdvancedUnitOutline>>{
    'A2': [
      EnglishAdvancedUnitOutline(
        level: 'A2', number: 1,
        title: "Everyday Life and Travel", titleArabic: "الحياة اليومية والسفر",
        plannedTopics: <String>["The Train Ticket", "The Baker's Early Morning", "Finding an Apartment", "At the Pharmacy", "Planning a Family Dinner", "Missing the Last Bus", "A New Classmate", "Returning a Purchase", "The Weekend Hike", "The Community Sports Day"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'A2', number: 2,
        title: "Home, Health and Hobbies", titleArabic: "المنزل والصحة والهوايات",
        plannedTopics: <String>["A Room of Your Own", "The Doctor's Advice", "A Recipe from Home", "A Bicycle Repair", "The Pet Adoption", "An Invitation to Tea", "A Language Exchange", "The Lost Phone", "Buying a Birthday Gift", "A Weekend by the Sea"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'A2', number: 3,
        title: "Travel, Services and Plans", titleArabic: "الرحلات والخدمات والخطط",
        plannedTopics: <String>["A Hotel Mix-up", "Changing a Reservation", "The Museum Tour", "A Busy Airport", "A Helpful Neighbor", "Preparing for an Interview", "Starting a Fitness Habit", "A Rainy Excursion", "A Restaurant Complaint", "Plans for Next Summer"],
      ),
    ],
    'B1': [
      EnglishAdvancedUnitOutline(
        level: 'B1', number: 1,
        title: "Community, Work and Initiative", titleArabic: "المجتمع والعمل والمبادرة",
        plannedTopics: <String>["The Library That Almost Closed", "The Riverside Festival", "A Team Project", "An Unexpected Internship", "The Neighborhood Petition", "The Volunteer Interview", "A Small Business Idea", "Organizing a Charity Run", "The Community Garden", "Making a Difficult Choice"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'B1', number: 2,
        title: "Communication and Experience", titleArabic: "التواصل والخبرات الشخصية",
        plannedTopics: <String>["A Misunderstood Email", "A Visit to Another Culture", "A Job Interview Revisited", "Learning from a Setback", "A Family Debate", "Presenting a New Idea", "The Student Election", "A Customer Service Problem", "A Trip That Changed Plans", "A Lesson in Responsibility"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'B1', number: 3,
        title: "Problems and Solutions", titleArabic: "المشكلات والحلول",
        plannedTopics: <String>["Repairing the Playground", "The Missing Exhibition Piece", "Saving a Local Festival", "A New School Policy", "A Challenging Group Assignment", "A Cultural Exchange", "The Cycling Campaign", "An Emergency at Work", "The Housing Meeting", "A Chance to Start Again"],
      ),
    ],
    'B2': [
      EnglishAdvancedUnitOutline(
        level: 'B2', number: 1,
        title: "Society, Evidence and Debate", titleArabic: "المجتمع والأدلة والنقاش",
        plannedTopics: <String>["The Headline That Spread", "The Hybrid Work Question", "The Rooftop Energy Debate", "The Food Waste Challenge", "The Ethics of Advertising", "Online Privacy", "The University Debate", "A Renewable Energy Proposal", "Tourism and Local Culture", "An Election of Ideas"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'B2', number: 2,
        title: "Technology and Public Policy", titleArabic: "التقنية والسياسات العامة",
        plannedTopics: <String>["A Digital Divide", "Artificial Intelligence in Classrooms", "The Carbon Footprint", "When Algorithms Choose", "The Future of Public Transport", "A Contested Scientific Study", "The Workplace Skills Gap", "A New Housing Regulation", "Media Trust and Doubt", "The Cost of Convenience"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'B2', number: 3,
        title: "Perspectives and Analysis", titleArabic: "وجهات النظر والتحليل",
        plannedTopics: <String>["The Case for Four-Day Weeks", "The Hidden Cost of Fashion", "A Controversial Public Artwork", "Public Health Communication", "The Nature Reserve Proposal", "The Challenges of Urban Growth", "Rethinking the Exam System", "Citizens and Open Data", "Economic Opportunity and Risk", "A Balanced Policy Review"],
      ),
    ],
    'C1': [
      EnglishAdvancedUnitOutline(
        level: 'C1', number: 1,
        title: "Research and Interpretation", titleArabic: "البحث والتفسير",
        plannedTopics: <String>["The Archive's Dilemma", "Beneath the Changing Reef", "What the River Samples Revealed", "The Museum's Disputed Artifact", "Scientific Uncertainty", "Interpreting Historical Letters", "The Language of Policy", "The Ethics of a Clinical Trial", "Competing Environmental Models", "A Researcher's Responsibility"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'C1', number: 2,
        title: "Culture, Institutions and Ethics", titleArabic: "الثقافة والمؤسسات والأخلاقيات",
        plannedTopics: <String>["The Heritage Preservation Dispute", "The Whistleblower's Choice", "A Question of Cultural Ownership", "Designing a Fair Public Service", "The University Funding Debate", "When Experts Disagree", "The International Arts Symposium", "A Crisis in Public Trust", "Language and Identity", "Rethinking Institutional Accountability"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'C1', number: 3,
        title: "Global Issues and Critical Writing", titleArabic: "القضايا العالمية والكتابة النقدية",
        plannedTopics: <String>["Migration and Belonging", "The Future of Food Systems", "Public Narratives of Climate Change", "The Politics of Conservation", "Health Data and Consent", "Cross-Cultural Negotiation", "The Limits of Economic Forecasts", "A New Educational Framework", "Science and the Public Sphere", "Presenting a Qualified Conclusion"],
      ),
    ],
    'C2': [
      EnglishAdvancedUnitOutline(
        level: 'C2', number: 1,
        title: "Interpretation and Evidence", titleArabic: "التأويل والأدلة",
        plannedTopics: <String>["The Harbor of Unreliable Maps", "The Translator's Unfinished Sentence", "The Witness Who Remembered Tomorrow", "The Paradox of Perfect Evidence", "An Unreliable Narrator", "The Architecture of an Argument", "When Memory Contradicts Record", "The Ethics of Historical Judgment", "A Disputed Translation", "The Limits of Certainty"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'C2', number: 2,
        title: "Rhetoric, Society and Philosophy", titleArabic: "البلاغة والمجتمع والفلسفة",
        plannedTopics: <String>["The Language of Moral Responsibility", "The Art of Deliberate Ambiguity", "A Philosophical Dialogue on Justice", "The Problem of Expert Authority", "The Rhetoric of Risk", "Interpretation Across Cultures", "An Anatomy of Persuasion", "The Hidden Assumptions of Models", "The Boundaries of Public Reason", "A Critique of Easy Solutions"],
      ),
      EnglishAdvancedUnitOutline(
        level: 'C2', number: 3,
        title: "Mastery, Nuance and Synthesis", titleArabic: "الإتقان والدقة والتركيب",
        plannedTopics: <String>["A World of Competing Narratives", "The Limits of Translation Theory", "Reading Between Historical Lines", "The Disciplines of Doubt", "Art, Meaning and Attribution", "Reconstructing a Complex Debate", "When Causation Remains Unclear", "The Responsibilities of Scholarship", "The Politics of Interpretation", "Writing with Intellectual Precision"],
      ),
    ],
  };

  static List<EnglishAdvancedUnitOutline> unitsFor(String level) =>
      _levels[level] ?? <EnglishAdvancedUnitOutline>[];

  static int get plannedSlotCount =>
      _levels.values.fold<int>(0, (total, units) =>
          total + units.fold<int>(0, (sum, unit) =>
              sum + unit.plannedTopics.length));
}

