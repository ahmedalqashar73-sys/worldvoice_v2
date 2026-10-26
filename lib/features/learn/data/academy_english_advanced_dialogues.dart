part of 'academy_english_advanced_models.dart';

/// Original two-speaker guided dialogue and real IPA cues for every
/// currently published advanced English lesson. Audio plays English text.
class EnglishAdvancedDialogue {
  const EnglishAdvancedDialogue({
    required this.lines, required this.tip,
    required this.tipArabic, required this.pronunciation,
  });
  final List<String> lines;
  final String tip;
  final String tipArabic;
  final List<String> pronunciation;
}

abstract final class EnglishAdvancedDialogues {
  static const _dialogues = <String, EnglishAdvancedDialogue>{
    "b1.2.1": EnglishAdvancedDialogue(
      lines: <String>["Sami: You said the draft was due tomorrow, right?", "Supervisor: Yes. The full report is due next Friday.", "Sami: I thought you wanted everything today.", "Supervisor: I am sorry the email was unclear.", "Sami: I will check the date before replying next time."],
      tip: "Practise the stressed syllables in attachment, recipient, clarify. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["attachment /əˈtætʃmənt/", "recipient /rɪˈsɪpiənt/", "clarify /ˈklærəfaɪ/"],
    ),
    "b1.2.2": EnglishAdvancedDialogue(
      lines: <String>["Noura: Although I am enjoying the visit, some routines are new to me.", "Host: Please ask whenever you are unsure.", "Noura: Despite the different meal time, I felt welcome yesterday.", "Host: We enjoyed hearing about your family too.", "Noura: Next time, I would love to share a dish from home."],
      tip: "Practise the stressed syllables in custom, culture, curiosity. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["custom /ˈkʌstəm/", "culture /ˈkʌltʃər/", "curiosity /ˌkjʊriˈɑːsəti/"],
    ),
    "b1.2.3": EnglishAdvancedDialogue(
      lines: <String>["Officer: Have you ever handled a difficult customer request?", "Karim: Yes. Last winter, I solved a delivery problem.", "Officer: What did you do personally?", "Karim: I contacted the customer and worked with the delivery team.", "Officer: That example explains your contribution clearly."],
      tip: "Practise the stressed syllables in recruitment, contribution, qualified. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["recruitment /rɪˈkruːtmənt/", "contribution /ˌkɑːntrɪˈbjuːʃən/", "qualified /ˈkwɑːlɪfaɪd/"],
    ),
    "b1.2.4": EnglishAdvancedDialogue(
      lines: <String>["Tutor: What had happened before you noticed the problem?", "Leila: The submission window had closed.", "Tutor: Had you checked the file-size limit?", "Leila: No. Next time I will test the upload early.", "Tutor: That is a useful change you can control."],
      tip: "Practise the stressed syllables in portrait, submission, persistence. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["portrait /ˈpɔːrtrət/", "submission /səbˈmɪʃən/", "persistence /pərˈsɪstəns/"],
    ),
    "b1.2.5": EnglishAdvancedDialogue(
      lines: <String>["Hadi: If we took turns, the work would feel fairer.", "Sister: I agree, but some tasks take longer than others.", "Father: What would you change first?", "Hadi: I would compare the time each job takes.", "Sister: Then we could try a rota and review it."],
      tip: "Practise the stressed syllables in chore, compromise, responsibility. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["chore /tʃɔːr/", "compromise /ˈkɑːmprəmaɪz/", "responsibility /rɪˌspɑːnsəˈbɪləti/"],
    ),
    "b1.2.6": EnglishAdvancedDialogue(
      lines: <String>["Manager: Why do we need a welcome guide?", "Mariam: To help new staff find answers quickly.", "Colleague: Who will update it?", "Mariam: I suggest a named editor so that the information stays accurate.", "Manager: Let us test it in one department first."],
      tip: "Practise the stressed syllables in proposal, presentation, editor. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["proposal /prəˈpoʊzəl/", "presentation /ˌprezənˈteɪʃən/", "editor /ˈedɪtər/"],
    ),
    "b1.2.7": EnglishAdvancedDialogue(
      lines: <String>["Friend: Will you promise longer opening hours?", "Rami: If we find enough supervision, we will test them.", "Friend: What if you do not win?", "Rami: I will still help unless the new council rejects the idea.", "Friend: That sounds more useful than a promise you cannot keep."],
      tip: "Practise the stressed syllables in candidate, ballot, supervision. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["candidate /ˈkændɪdət/", "ballot /ˈbælət/", "supervision /ˌsuːpərˈvɪʒən/"],
    ),
    "b1.2.8": EnglishAdvancedDialogue(
      lines: <String>["Dina: Could you tell me where the printer was delivered?", "Agent: I can check the photograph and address record.", "Dina: Do you know when a replacement will arrive?", "Agent: Thursday between ten and two.", "Dina: Thank you. Could you send that in writing?"],
      tip: "Practise the stressed syllables in courier, resolution, parcel. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["courier /ˈkʊriər/", "resolution /ˌrezəˈluːʃən/", "parcel /ˈpɑːrsəl/"],
    ),
    "b1.2.9": EnglishAdvancedDialogue(
      lines: <String>["Amal: I was checking our itinerary when the cancellation arrived.", "Guide: The next boat is uncertain too.", "Amal: Can we do something locally while we wait?", "Guide: A walking tour is available this afternoon.", "Amal: Good. I will contact the guesthouse about our delayed arrival."],
      tip: "Practise the stressed syllables in itinerary, ferry, disruption. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["itinerary /aɪˈtɪnəreri/", "ferry /ˈferi/", "disruption /dɪsˈrʌpʃən/"],
    ),
    "b1.2.10": EnglishAdvancedDialogue(
      lines: <String>["Adam: I need to report damage to the lens cover.", "Secretary: Thank you for telling me. Where was it stored?", "Adam: I used the cupboard. I should have used the locker.", "Secretary: We must check the repair estimate first.", "Adam: I will help arrange the repair and follow the instructions next time."],
      tip: "Practise the stressed syllables in responsible, protective, equipment. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["responsible /rɪˈspɑːnsəbəl/", "protective /prəˈtektɪv/", "equipment /ɪˈkwɪpmənt/"],
    ),
    "b1.3.1": EnglishAdvancedDialogue(
      lines: <String>["Salim: Has the swing been repaired yet?", "Worker: Yes, but the final inspection is tomorrow.", "Salim: Can volunteers help today?", "Worker: The path can be cleaned, but the equipment must stay closed.", "Salim: I will explain the difference to the group."],
      tip: "Practise the stressed syllables in playground, inspection, maintenance. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["playground /ˈpleɪɡraʊnd/", "inspection /ɪnˈspekʃən/", "maintenance /ˈmeɪntənəns/"],
    ),
    "b1.3.2": EnglishAdvancedDialogue(
      lines: <String>["Assistant: Had anyone moved the sculpture yesterday?", "Worker: The team had placed it in storage after the stand broke.", "Assistant: Why was the movement sheet empty?", "Worker: We had forgotten to update it.", "Assistant: Let us record every move, even a short one."],
      tip: "Practise the stressed syllables in sculpture, inventory, temporary. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["sculpture /ˈskʌlptʃər/", "inventory /ˈɪnvəntɔːri/", "temporary /ˈtempəreri/"],
    ),
    "b1.3.3": EnglishAdvancedDialogue(
      lines: <String>["Organizer: If we use the smaller room, will everyone fit?", "Volunteer: Not together, but we can offer two sessions.", "Organizer: What if a guest cannot attend the new time?", "Volunteer: We will refund the ticket if they contact us before Friday.", "Organizer: Then let us explain both options clearly."],
      tip: "Practise the stressed syllables in venue, contingency, performance. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["venue /ˈvenjuː/", "contingency /kənˈtɪndʒənsi/", "performance /pərˈfɔːrməns/"],
    ),
    "b1.3.4": EnglishAdvancedDialogue(
      lines: <String>["Student: Must everyone hand in a phone?", "Teacher: There is an agreed exception process for medical needs.", "Student: Do families have to wait until school ends to contact us?", "Teacher: No. Urgent messages can come through the office.", "Student: Please explain that clearly in the parent letter."],
      tip: "Practise the stressed syllables in policy, exception, procedure. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["policy /ˈpɑːləsi/", "exception /ɪkˈsepʃən/", "procedure /prəˈsiːdʒər/"],
    ),
    "b1.3.5": EnglishAdvancedDialogue(
      lines: <String>["Amina: I suggest sharing our drafts before Friday.", "Student: I am struggling with the survey results.", "Amina: Would you like someone to explain the chart?", "Student: Yes. I want to finish my own section.", "Amina: Let us agree to check progress together tomorrow."],
      tip: "Practise the stressed syllables in assignment, contribution, collaborative. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["assignment /əˈsaɪnmənt/", "contribution /ˌkɑːntrɪˈbjuːʃən/", "collaborative /kəˈlæbəreɪtɪv/"],
    ),
    "b1.3.6": EnglishAdvancedDialogue(
      lines: <String>["Hassan: Which photographs should we use?", "Partner: The ones that show how people share the square.", "Hassan: What about the man who spoke to us?", "Partner: We should ask his permission before using his photo.", "Hassan: Agreed. Let us check our captions together too."],
      tip: "Practise the stressed syllables in exchange, bilingual, permission. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["exchange /ɪksˈtʃeɪndʒ/", "bilingual /baɪˈlɪŋɡwəl/", "permission /pərˈmɪʃən/"],
    ),
    "b1.3.7": EnglishAdvancedDialogue(
      lines: <String>["Zain: If the junction were safer, more people would cycle.", "Driver: I agree, but this barrier would block our stop.", "Zain: Where would you put it instead?", "Driver: Farther along, where passengers have room.", "Zain: Let us test that option and collect feedback."],
      tip: "Practise the stressed syllables in cycling, junction, visibility. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["cycling /ˈsaɪklɪŋ/", "junction /ˈdʒʌŋkʃən/", "visibility /ˌvɪzəˈbɪləti/"],
    ),
    "b1.3.8": EnglishAdvancedDialogue(
      lines: <String>["Supervisor: What were you doing when the alarm sounded?", "Layla: I was helping visitors near the entrance.", "Supervisor: Is anyone missing from your group?", "Layla: One visitor left earlier; reception is checking the record.", "Supervisor: Thank you. We will stay here until we receive instructions."],
      tip: "Practise the stressed syllables in evacuation, assembly, supervisor. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["evacuation /ɪˌvækjuˈeɪʃən/", "assembly /əˈsembli/", "supervisor /ˈsuːpərvaɪzər/"],
    ),
    "b1.3.9": EnglishAdvancedDialogue(
      lines: <String>["Mona: You said the repairs would begin this week.", "Representative: That is correct. The team is scheduled for Monday.", "Mona: Residents told me they needed a written update.", "Representative: I will send the dates and responsible contact.", "Mona: Thank you. We can review progress next month."],
      tip: "Practise the stressed syllables in tenant, representative, commitment. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["tenant /ˈtenənt/", "representative /ˌreprɪˈzentətɪv/", "commitment /kəˈmɪtmənt/"],
    ),
    "b1.3.10": EnglishAdvancedDialogue(
      lines: <String>["Counselor: Have you tried any activities in the new field?", "Yasmin: Yes. I completed a short placement last month.", "Counselor: What have you learned about your interests?", "Yasmin: I have found that I enjoy practical projects.", "Counselor: Then let us compare courses that build on that experience."],
      tip: "Practise the stressed syllables in portfolio, counselor, retraining. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["portfolio /pɔːrtˈfoʊlioʊ/", "counselor /ˈkaʊnsələr/", "retraining /ˌriːˈtreɪnɪŋ/"],
    ),
    "b2.1.5": EnglishAdvancedDialogue(
      lines: <String>["Lara: The trial may suggest improvement, but it was small.", "Researcher: Then the headline should not promise the same result for everyone.", "Lara: Could a visible sponsorship label help?", "Researcher: Yes, alongside a realistic claim and clear limits.", "Lara: I will separate the testimonial from the independent evidence."],
      tip: "Practise the stressed syllables in endorsement, persuasion, testimonial. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["endorsement /ɪnˈdɔːrsmənt/", "persuasion /pərˈsweɪʒən/", "testimonial /ˌtestɪˈmoʊniəl/"],
    ),
    "b2.1.6": EnglishAdvancedDialogue(
      lines: <String>["Faris: Are member details shared publicly by default?", "Volunteer: They were, but we have changed that setting.", "Faris: Will deletion requests be handled clearly?", "Volunteer: Yes. The process is described in the member notice.", "Faris: Then people can choose without losing access to public events."],
      tip: "Practise the stressed syllables in privacy, retention, permission. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["privacy /ˈpraɪvəsi/", "retention /rɪˈtenʃən/", "permission /pərˈmɪʃən/"],
    ),
    "b2.1.7": EnglishAdvancedDialogue(
      lines: <String>["Salma: Although attendance helps, some absences have good reasons.", "Opponent: Then how can a compulsory rule be fair?", "Salma: Despite that difficulty, a flexible exception could address the concern.", "Opponent: Would students know the process?", "Salma: They should; an unclear exception would weaken my proposal."],
      tip: "Practise the stressed syllables in rebuttal, assumption, argument. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["rebuttal /rɪˈbʌtəl/", "assumption /əˈsʌmpʃən/", "argument /ˈɑːrɡjəmənt/"],
    ),
    "b2.1.8": EnglishAdvancedDialogue(
      lines: <String>["Resident: Does this forecast guarantee enough power every year?", "Engineer: No. Wind varies, so actual output could differ.", "Resident: Might the wildlife study change the site?", "Engineer: Yes. It may identify a better location.", "Resident: Then the decision should wait for that evidence."],
      tip: "Practise the stressed syllables in turbine, renewable, feasibility. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["turbine /ˈtɜːrbaɪn/", "renewable /rɪˈnuːəbəl/", "feasibility /ˌfiːzəˈbɪləti/"],
    ),
    "b2.1.9": EnglishAdvancedDialogue(
      lines: <String>["Artisan: Visitors who join our workshop should see real work.", "Resident: And groups that block our doors should use the square.", "Planner: Can scheduled visits meet both needs?", "Artisan: Yes, if we help choose the times.", "Resident: Then include residents who do not benefit financially too."],
      tip: "Practise the stressed syllables in artisan, heritage, residential. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["artisan /ˈɑːrtɪzən/", "heritage /ˈherɪtɪdʒ/", "residential /ˌrezɪˈdenʃəl/"],
    ),
    "b2.1.10": EnglishAdvancedDialogue(
      lines: <String>["Participant: We asked whether the grant was confirmed.", "Organizer: It is still under review.", "Participant: Then why call the proposal ready?", "Organizer: We should call it conditionally approved instead.", "Participant: Please publish the funding condition with the result."],
      tip: "Practise the stressed syllables in deliberation, conditional, implementation. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["deliberation /dɪˌlɪbəˈreɪʃən/", "conditional /kənˈdɪʃənəl/", "implementation /ˌɪmpləmenˈteɪʃən/"],
    ),
    "b2.2.1": EnglishAdvancedDialogue(
      lines: <String>["Librarian: Although many residents own phones, forms still cause problems.", "Officer: Would faster internet solve everything?", "Librarian: Not necessarily. Some people need language or skills support.", "Officer: Then we should retain the telephone option.", "Librarian: Yes, while we test whether the online changes improve completion."],
      tip: "Practise the stressed syllables in accessibility, inclusion, literacy. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["accessibility /əkˌsesəˈbɪləti/", "inclusion /ɪnˈkluːʒən/", "literacy /ˈlɪtərəsi/"],
    ),
    "b2.2.2": EnglishAdvancedDialogue(
      lines: <String>["Teacher: Must students accept the assistant's outline?", "Colleague: No. They should explain which suggestions they used.", "Teacher: What about a reference they cannot find?", "Colleague: They must verify it or remove the unsupported claim.", "Teacher: Then our assessment should value that judgment."],
      tip: "Practise the stressed syllables in automated, fabricated, assessment. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["automated /ˈɔːtəmeɪtɪd/", "fabricated /ˈfæbrɪkeɪtɪd/", "assessment /əˈsesmənt/"],
    ),
    "b2.2.3": EnglishAdvancedDialogue(
      lines: <String>["Student: Were all supplier emissions included?", "Analyst: No. The missing categories are stated in the report.", "Student: Could the total fall simply because the boundary changed?", "Analyst: Yes, which is why methods must be compared.", "Student: Then offsets should also be reported separately."],
      tip: "Practise the stressed syllables in emissions, boundary, compensation. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["emissions /ɪˈmɪʃənz/", "boundary /ˈbaʊndəri/", "compensation /ˌkɑːmpenˈseɪʃən/"],
    ),
    "b2.2.4": EnglishAdvancedDialogue(
      lines: <String>["Manager: If the overall score were accurate, would that settle fairness?", "Analyst: No. Errors could still affect groups differently.", "Manager: What would help us detect that?", "Analyst: Group-level checks and a practical human appeal.", "Manager: Then automatic rejection should remain suspended."],
      tip: "Practise the stressed syllables in algorithm, variable, threshold. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["algorithm /ˈælɡərɪðəm/", "variable /ˈveriəbəl/", "threshold /ˈθreʃhoʊld/"],
    ),
    "b2.2.5": EnglishAdvancedDialogue(
      lines: <String>["Passenger: Why are you introducing feeder buses?", "Planner: To connect smaller areas with the frequent route.", "Passenger: What if the final connection leaves before my shift ends?", "Planner: We need that feedback so that the timetable can be revised.", "Passenger: Then please measure missed connections as well as speed."],
      tip: "Practise the stressed syllables in integration, reliability, affordability. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["integration /ˌɪntɪˈɡreɪʃən/", "reliability /rɪˌlaɪəˈbɪləti/", "affordability /əˌfɔːrdəˈbɪləti/"],
    ),
    "b2.2.6": EnglishAdvancedDialogue(
      lines: <String>["Journalist: Does the study prove that the habit improves marks?", "Researcher: No. Motivation may explain part of the association.", "Journalist: Might a broader sample help?", "Researcher: Yes, together with better baseline information.", "Journalist: I will preserve that distinction in the headline."],
      tip: "Practise the stressed syllables in association, causal, confounding. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["association /əˌsoʊsiˈeɪʃən/", "causal /ˈkɔːzəl/", "confounding /kənˈfaʊndɪŋ/"],
    ),
    "b2.2.7": EnglishAdvancedDialogue(
      lines: <String>["Manager: Were all qualifications in the advert necessary?", "Supervisor: Some were not directly related to the tasks.", "Manager: How can practical ability be assessed?", "Supervisor: Through a supervised demonstration and clear criteria.", "Manager: Then training access should be reviewed alongside applicant skills."],
      tip: "Practise the stressed syllables in competency, qualification, apprenticeship. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["competency /ˈkɑːmpɪtənsi/", "qualification /ˌkwɑːlɪfɪˈkeɪʃən/", "apprenticeship /əˈprentɪʃɪp/"],
    ),
    "b2.2.8": EnglishAdvancedDialogue(
      lines: <String>["Officer: Residents asked whether occasional hosting was covered.", "Analyst: The draft needs a clearer scope definition.", "Officer: Landlords also asked how registration would work.", "Analyst: Then practical guidance belongs in the next version.", "Officer: We should distinguish a proposal from an existing rule."],
      tip: "Practise the stressed syllables in regulation, enforcement, transition. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["regulation /ˌreɡjəˈleɪʃən/", "enforcement /ɪnˈfɔːrsmənt/", "transition /trænˈzɪʃən/"],
    ),
    "b2.2.9": EnglishAdvancedDialogue(
      lines: <String>["Reporter: The first article said the service would close.", "Editor: What did the document actually say?", "Reporter: It said the opening hours were under review.", "Editor: Then explain that difference in a visible correction.", "Reporter: I will separate confirmed facts from unresolved questions."],
      tip: "Practise the stressed syllables in anonymous, skepticism, verification. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["anonymous /əˈnɑːnɪməs/", "skepticism /ˈskeptɪsɪzəm/", "verification /ˌverɪfɪˈkeɪʃən/"],
    ),
    "b2.2.10": EnglishAdvancedDialogue(
      lines: <String>["Student: Although the fee is low, the total cost may be higher.", "Rider: Waiting between orders affects our day too.", "Student: Would combined deliveries help?", "Rider: They might, but demand and pay arrangements matter.", "Student: Then our report should explain the trade-offs rather than assume one answer."],
      tip: "Practise the stressed syllables in convenience, consolidated, subscription. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["convenience /kənˈviːniəns/", "consolidated /kənˈsɑːlɪdeɪtɪd/", "subscription /səbˈskrɪpʃən/"],
    ),
    "b2.3.1": EnglishAdvancedDialogue(
      lines: <String>["Manager: If we shortened the week, would productivity automatically rise?", "Evaluator: Not if unchanged tasks created hidden overtime.", "Manager: What would make the trial meaningful?", "Evaluator: Realistic workloads and recorded hours, including days off.", "Manager: Then the calendar change must be matched by work redesign."],
      tip: "Practise the stressed syllables in productivity, compressed, evaluation. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["productivity /ˌproʊdʌkˈtɪvəti/", "compressed /kəmˈprest/", "evaluation /ɪˌvæljuˈeɪʃən/"],
    ),
    "b2.3.2": EnglishAdvancedDialogue(
      lines: <String>["Student: Although the label says recycled, we know little about the factory.", "Tutor: Exactly. What else affects the jacket's impact?", "Student: Durability, working conditions, and how much is produced.", "Tutor: Then qualify the conclusion rather than dismiss the material improvement.", "Student: Our guide can show both the evidence and the gaps."],
      tip: "Practise the stressed syllables in sustainable, durability, garment. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["sustainable /səˈsteɪnəbəl/", "durability /ˌdʊrəˈbɪləti/", "garment /ˈɡɑːrmənt/"],
    ),
    "b2.3.3": EnglishAdvancedDialogue(
      lines: <String>["Chair: The artist said the forms represented shared journeys.", "Resident: I still dislike the design, and the path is too narrow.", "Chair: Those are different concerns. We can review access directly.", "Resident: Will the commissioning budget be explained too?", "Chair: Yes. Transparency does not require everyone to share the same taste."],
      tip: "Practise the stressed syllables in aesthetic, abstract, commission. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["aesthetic /esˈθetɪk/", "abstract /ˈæbstrækt/", "commission /kəˈmɪʃən/"],
    ),
    "b2.3.4": EnglishAdvancedDialogue(
      lines: <String>["Writer: This relative increase may sound larger than it is.", "Reviewer: Have you included the baseline risk?", "Writer: Not yet. I will add context and the source date.", "Reviewer: The translation should preserve the uncertainty too.", "Writer: Then we should test both versions with readers."],
      tip: "Practise the stressed syllables in relative, absolute, uncertainty. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["relative /ˈrelətɪv/", "absolute /ˈæbsəluːt/", "uncertainty /ʌnˈsɜːrtənti/"],
    ),
    "b2.3.5": EnglishAdvancedDialogue(
      lines: <String>["Farmer: If grazing is restricted, how will households adapt?", "Conservationist: That is why the livelihood review is part of the plan.", "Farmer: Will access remain possible outside the nesting areas?", "Conservationist: Yes, if the agreed paths are maintained.", "Farmer: Then responsibilities and funding must be clear before approval."],
      tip: "Practise the stressed syllables in wetland, conservation, livelihood. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["wetland /ˈwetlənd/", "conservation /ˌkɑːnsərˈveɪʃən/", "livelihood /ˈlaɪvlihʊd/"],
    ),
    "b2.3.6": EnglishAdvancedDialogue(
      lines: <String>["Planner: If we chose cheaper land farther out, what would change?", "Resident: Journeys would be longer and more infrastructure would be needed.", "Planner: Could phased development address that?", "Resident: Only if later phases depend on actual service capacity.", "Planner: Then those conditions must be explicit."],
      tip: "Practise the stressed syllables in infrastructure, projection, displacement. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["infrastructure /ˈɪnfrəstrʌktʃər/", "projection /prəˈdʒekʃən/", "displacement /dɪsˈpleɪsmənt/"],
    ),
    "b2.3.7": EnglishAdvancedDialogue(
      lines: <String>["Teacher: Although our marking is consistent, are we measuring every intended skill?", "Colleague: Not with one timed essay.", "Teacher: Could an oral explanation add useful evidence?", "Colleague: Yes, but its criteria and workload need attention.", "Teacher: Then we should assess both reliability and validity."],
      tip: "Practise the stressed syllables in reliability, validity, moderation. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["reliability /rɪˌlaɪəˈbɪləti/", "validity /vəˈlɪdəti/", "moderation /ˌmɑːdəˈreɪʃən/"],
    ),
    "b2.3.8": EnglishAdvancedDialogue(
      lines: <String>["Analyst: Were telephone complaints included from the beginning?", "Officer: No. That limitation is now documented.", "Analyst: Then the neighborhood ranking could mislead readers.", "Officer: The dashboard has been revised to explain that.", "Analyst: Good. Open access also requires understandable context."],
      tip: "Practise the stressed syllables in dataset, provenance, revision. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["dataset /ˈdeɪtəset/", "provenance /ˈprɑːvənəns/", "revision /rɪˈvɪʒən/"],
    ),
    "b2.3.9": EnglishAdvancedDialogue(
      lines: <String>["Participant: If customer demand fell, what would happen to the job estimate?", "Economist: It would probably fall too.", "Participant: Would phased investment remove that risk?", "Economist: It could limit exposure, but not eliminate uncertainty.", "Participant: Then the conditions and risk bearers should be explicit."],
      tip: "Practise the stressed syllables in logistics, sensitivity, viability. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["logistics /ləˈdʒɪstɪks/", "sensitivity /ˌsensəˈtɪvəti/", "viability /ˌvaɪəˈbɪləti/"],
    ),
    "b2.3.10": EnglishAdvancedDialogue(
      lines: <String>["Evaluator: What if we had counted only total visits?", "Officer: We would have missed the uneven access across neighborhoods.", "Evaluator: Might earlier outreach have helped?", "Officer: It might have, but we cannot establish that with certainty.", "Evaluator: Then we should state that limit while recommending a better next phase."],
      tip: "Practise the stressed syllables in evaluation, counterfactual, outreach. Then read both roles, pausing at meaningful clause boundaries.",
      tipArabic: "تدرّب على مواضع النبر في كلمات النطق الثلاث، ثم اقرأ دوري المحادثة مع التوقف عند حدود المعنى.",
      pronunciation: <String>["evaluation /ɪˌvæljuˈeɪʃən/", "counterfactual /ˌkaʊntərˈfæktʃuəl/", "outreach /ˈaʊtriːtʃ/"],
    ),
    'a2.3.1': EnglishAdvancedDialogue(
      lines: <String>["Salma: Could you check my booking, please?", "Receptionist: Certainly. What seems to be wrong?", "Salma: We booked a twin room, but this room has one bed.", "Receptionist: I am sorry. I can give you the correct room now.", "Salma: Thank you. Could we have two key cards?"],
      tip: "Say Could you as a smooth phrase, then stress the main request: check my booking.",
      tipArabic: "اربط Could you بسلاسة، وشدّد على الفعل الأساسي في الطلب.",
      pronunciation: <String>["reception /rɪˈsepʃən/", "porter /ˈpɔːrtər/", "elevator /ˈeləveɪtər/"],
    ),
    'a2.3.2': EnglishAdvancedDialogue(
      lines: <String>["Omar: I would like to move my arrival to Saturday.", "Agent: Certainly. Would you like to keep the same number of nights?", "Omar: Yes, two nights, please. Is there a change fee?", "Agent: No, your flexible rate includes this change.", "Omar: Great. I would like written confirmation, please."],
      tip: "Practise I would like to as one phrase; stress the new day to make the change clear.",
      tipArabic: "تدرّب على I would like to كعبارة واحدة، وأبرز اسم اليوم الجديد.",
      pronunciation: <String>["calendar /ˈkælɪndər/", "available /əˈveɪləbəl/", "cancel /ˈkænsəl/"],
    ),
    'a2.3.3': EnglishAdvancedDialogue(
      lines: <String>["Maya: Can I take a photo of this pot?", "Guide: Yes, but you must not use a flash.", "Maya: Do I have to leave my small bag outside?", "Guide: No, small bags are allowed. You must leave large bags in the cloakroom.", "Maya: Thank you. I will keep my ticket with me."],
      tip: "Make the negative clear in must not; do not let a rule sound like permission.",
      tipArabic: "انطق not بوضوح حتى لا تبدو قاعدة المنع وكأنها إذن.",
      pronunciation: <String>["museum /mjuˈziːəm/", "ancient /ˈeɪnʃənt/", "exhibition /ˌeksɪˈbɪʃən/"],
    ),
    'a2.3.4': EnglishAdvancedDialogue(
      lines: <String>["Nabil: I am flying to Muscat this afternoon. Is this the right gate?", "Employee: No, your flight is now leaving from gate eighteen.", "Nabil: Are passengers boarding yet?", "Employee: Yes. Follow the blue signs and keep your boarding pass ready.", "Nabil: Thank you. My cousin is meeting me at the airport tonight."],
      tip: "Keep the ending in flying and meeting audible; stress the gate number when asking directions.",
      tipArabic: "أظهر نهاية ing في flying وmeeting، وانطق رقم البوابة بوضوح.",
      pronunciation: <String>["airport /ˈerpɔːrt/", "luggage /ˈlʌɡɪdʒ/", "boarding /ˈbɔːrdɪŋ/"],
    ),
    'a2.3.5': EnglishAdvancedDialogue(
      lines: <String>["Mr Ali: Shall I help you carry that parcel?", "Hana: Yes, please. It is too heavy for me.", "Mr Ali: I will bring my toolbox as well.", "Hana: Thank you. Shall I water your plants when you go away?", "Mr Ali: That would be very helpful. I will show you on Wednesday."],
      tip: "Use a friendly rising tone for Shall I questions; practise the contraction I will → I'll.",
      tipArabic: "استخدم نبرة سؤال لطيفة مع Shall I، وتدرّب على اختصار I will إلى I’ll.",
      pronunciation: <String>["neighbor /ˈneɪbər/", "parcel /ˈpɑːrsəl/", "screwdriver /ˈskruːdraɪvər/"],
    ),
    'a2.3.6': EnglishAdvancedDialogue(
      lines: <String>["Interviewer: Where did you work last summer?", "Rania: I worked in a small clothes shop.", "Interviewer: Did you help customers choose clothes?", "Rania: Yes, I did. I also kept the shelves tidy.", "Interviewer: Thank you. Which days can you work here?"],
      tip: "Practise the final /t/ in worked and the final /d/ in smiled without adding an extra syllable.",
      tipArabic: "تدرّب على نهاية worked بصوت /t/ ونهاية smiled بصوت /d/ دون إضافة مقطع.",
      pronunciation: <String>["interview /ˈɪntərvjuː/", "strength /streŋθ/", "punctual /ˈpʌŋktʃuəl/"],
    ),
    'a2.3.7': EnglishAdvancedDialogue(
      lines: <String>["Instructor: How often do you exercise?", "Yusuf: I rarely exercise, but I want to start.", "Instructor: Our beginner group meets twice a week.", "Yusuf: That works for me. Is the class usually busy?", "Instructor: It is sometimes busy, so please arrive a little early."],
      tip: "Stress the frequency words to distinguish usually, sometimes and rarely.",
      tipArabic: "شدّد على كلمات التكرار لتوضيح الفرق بين usually وsometimes وrarely.",
      pronunciation: <String>["exercise /ˈeksərsaɪz/", "usually /ˈjuːʒuəli/", "energetic /ˌenərˈdʒetɪk/"],
    ),
    'a2.3.8': EnglishAdvancedDialogue(
      lines: <String>["Teacher: What will we do if the rain continues?", "Farmer: If it stays wet, we will visit the barn.", "Teacher: Can the children see the animals there?", "Farmer: Yes. If the path dries later, we will take a short walk too.", "Teacher: Good. I will tell the group about the new plan."],
      tip: "Pause lightly after the if clause and stress the activity that will change.",
      tipArabic: "توقف قليلًا بعد جملة if، وأبرز النشاط الذي سيتغير في جملة النتيجة.",
      pronunciation: <String>["excursion /ɪkˈskɜːrʒən/", "waterproof /ˈwɔːtərpruːf/", "muddy /ˈmʌdi/"],
    ),
    'a2.3.9': EnglishAdvancedDialogue(
      lines: <String>["Dalia: Excuse me. I think this is the wrong order.", "Server: I am sorry. What did you order?", "Dalia: A grilled sandwich, please. We have enough time to wait.", "Server: I will ask the kitchen to prepare it now.", "Dalia: Thank you. The new sandwich is warm enough."],
      tip: "Use a calm tone for Excuse me and stress wrong order without shouting.",
      tipArabic: "استخدم نبرة هادئة في Excuse me، وأبرز wrong order دون صراخ.",
      pronunciation: <String>["omelet /ˈɑːmlət/", "enough /ɪˈnʌf/", "complaint /kəmˈpleɪnt/"],
    ),
    'a2.3.10': EnglishAdvancedDialogue(
      lines: <String>["Leen: We are going to visit a mountain village next summer.", "Brother: Are we going to stay near the painting school?", "Leen: Yes, if we can find a room at a good price.", "Brother: If the first guesthouse is expensive, we will try another one.", "Leen: Good idea. Let us check the costs before we book."],
      tip: "Practise are going to and is going to clearly, then contrast the plan with the if alternative.",
      tipArabic: "تدرّب على are going to وis going to، ثم ميّز الخطة عن البديل الذي يبدأ بـ if.",
      pronunciation: <String>["brochure /broʊˈʃʊr/", "village /ˈvɪlɪdʒ/", "summer /ˈsʌmər/"],
    ),
    'a2.2.8': EnglishAdvancedDialogue(
      lines: <String>[
        'Lina: I lost the phone that I used on the bus.',
        'Friend: Did you ask the driver who was on duty?',
        'Lina: Not yet. Can we visit the lost property office?',
        'Friend: Yes, we can describe the screen and ringtone.',
        'Lina: Thank you. I hope someone has found it.',
      ],
      tip: 'Link who and that to the words they describe, with natural stress.',
      tipArabic: 'اربط who وthat بالأسماء التي تصفها دون وقفة طويلة.',
      pronunciation: <String>[
        'notification /ˌnoʊtɪfɪˈkeɪʃən/', 'ringtone /ˈrɪŋtoʊn/', 'contact /ˈkɑːntækt/',
      ],
    ),
    'a2.2.9': EnglishAdvancedDialogue(
      lines: <String>[
        'Tariq: I am going to buy a gift for my sister.',
        'Seller: Would you like her initials on the mug?',
        'Tariq: That sounds great. How long will it take?',
        'Seller: About twenty minutes. I will wrap it for you.',
        'Tariq: Perfect! I am going to give it to her tonight.',
      ],
      tip: 'Contrast an existing plan with a spontaneous offer using will.',
      tipArabic: 'فرق بين خطة going to والعرض اللحظي باستخدام will.',
      pronunciation: <String>[
        'engraved /ɪnˈɡreɪvd/', 'ceramic /səˈræmɪk/', 'initials /ɪˈnɪʃəlz/',
      ],
    ),
    'a2.2.10': EnglishAdvancedDialogue(
      lines: <String>[
        'Amal: Did you use to visit the beach as a child?',
        'Cousin: Yes, we used to build sandcastles every summer.',
        'Amal: I did not use to enjoy swimming in cold water.',
        'Cousin: Let us walk to the lighthouse instead.',
        'Amal: Good idea. We can watch the tide from there.',
      ],
      tip: 'Practise the smooth sound of used to in affirmative sentences.',
      tipArabic: 'تدرّب على used to في الإثبات وuse to بعد did.',
      pronunciation: <String>[
        'lighthouse /ˈlaɪthaʊs/', 'seashell /ˈsiːʃel/', 'coastline /ˈkoʊstlaɪn/',
      ],
    ),

    'a2.2.4': EnglishAdvancedDialogue(
      lines: <String>[
        'Yusuf: Can you check my bicycle? The front tire is flat.',
        'Mechanic: I have just found a hole near the valve.',
        'Yusuf: Have you checked the chain yet?',
        'Mechanic: Yes, I have already tightened it.',
        'Yusuf: Great! I will test the brakes before riding.',
      ],
      tip: 'Stress just and already when explaining what has been repaired.',
      tipArabic: 'شدّد على just وalready لتوضيح زمن إكمال التصليح.',
      pronunciation: <String>[
        'mechanic /məˈkænɪk/', 'bicycle /ˈbaɪsɪkəl/', 'valve /vælv/',
      ],
    ),
    'a2.2.5': EnglishAdvancedDialogue(
      lines: <String>[
        'Layla: Do I have to complete this adoption form today?',
        'Worker: Yes, but you do not have to take the kitten home today.',
        'Layla: Must I buy special food?',
        'Worker: Please ask the vet about the best choice.',
        'Layla: Thank you. I will prepare a quiet place first.',
      ],
      tip: 'Contrast have to with do not have to using clear pauses.',
      tipArabic: 'لاحظ الفرق بين الإلزام وعدم الضرورة في have to وdon’t have to.',
      pronunciation: <String>[
        'adoption /əˈdɑːpʃən/', 'kitten /ˈkɪtən/', 'veterinary /ˈvɛtərɪnɛri/',
      ],
    ),
    'a2.2.6': EnglishAdvancedDialogue(
      lines: <String>[
        'Host: Would you like some tea?',
        'Hana: Yes, please. That would be lovely.',
        'Host: Would you like to try the homemade biscuits?',
        'Hana: I would love to. Shall I help with the cups?',
        'Host: Thank you, but please relax and enjoy the visit.',
      ],
      tip: 'Keep invitations and polite offers soft and friendly.',
      tipArabic: 'استخدم نبرة هادئة ومهذبة عند تقديم الدعوات والعروض.',
      pronunciation: <String>[
        'hospitality /ˌhɑːspɪˈtæləti/', 'pastries /ˈpeɪstriz/', 'invitation /ˌɪnvɪˈteɪʃən/',
      ],
    ),
    'a2.2.7': EnglishAdvancedDialogue(
      lines: <String>[
        'Ken: How long have you practised speaking English?',
        'Fatima: I have studied for about two years.',
        'Ken: Have you worked with a partner since January?',
        'Fatima: Yes. We have met every Wednesday.',
        'Ken: Great! Let us practise a short role-play today.',
      ],
      tip: 'Give for and since clear stress to mark duration and starting point.',
      tipArabic: 'ميّز بين مدة التعلم ونقطة البداية باستخدام for وsince.',
      pronunciation: <String>[
        'exchange /ɪksˈtʃeɪndʒ/', 'fluently /ˈfluːəntli/', 'feedback /ˈfiːdbæk/',
      ],
    ),

    'a2.2.1': EnglishAdvancedDialogue(
      lines: <String>[
        'Salma: Do you think this desk is too large for the bedroom?',
        'Nadia: No, it is small enough to fit beside the window.',
        'Salma: Is the blue rug more expensive than the green one?',
        'Nadia: Yes, but the green rug is softer and easier to clean.',
        'Salma: Great! Then I have enough money for a reading lamp.',
      ],
      tip: 'Use a clear stress on brighter, enough, and more expensive.',
      tipArabic: 'تدرّب على نبر المقارنة والتشديد على brighter وenough.',
      pronunciation: <String>[
        'wardrobe /ˈwɔːr.droʊb/', 'mirror /ˈmɪr.ər/', 'comfortable /ˈkʌmf.tə.bəl/',
      ],
    ),
    'a2.2.2': EnglishAdvancedDialogue(
      lines: <String>[
        'Omar: I feel dizzy. Should I go to work today?',
        'Nurse: You should rest and drink enough water.',
        'Omar: Do I have to take the medicine after food?',
        'Nurse: Please follow the instructions on the label.',
        'Omar: Thank you. I will call again if I feel worse.',
      ],
      tip: 'Practise polite requests with should and have to.',
      tipArabic: 'لاحظ النبرة المهذبة عند طلب النصيحة باستخدام should.',
      pronunciation: <String>[
        'clinic /ˈklɪn.ɪk/', 'infection /ɪnˈfek.ʃən/', 'medicine /ˈmed.ɪ.sən/',
      ],
    ),
    'a2.2.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Mira: Can you help me make the family dish?',
        'Sam: Sure! What should I do first?',
        'Mira: First, wash the vegetables. Then, chop the onions.',
        'Sam: Should I add the broth now?',
        'Mira: Yes. Finally, taste it before adding any salt.',
      ],
      tip: 'Mark each step with first, then, and finally.',
      tipArabic: 'اجعل صوتك واضحًا عند ترتيب الخطوات: first، then، finally.',
      pronunciation: <String>[
        'broth /brɔːθ/', 'vegetables /ˈvedʒ.tə.bəlz/', 'onions /ˈʌn.jənz/',
      ],
    ),

    'b2.1.4': EnglishAdvancedDialogue(
      lines: <String>[
        'Amira: Could we donate every lunch that students do not eat?',
        'Manager: Not all of them. Food must meet storage and temperature requirements.',
        'Amira: Should we give everyone a smaller serving?',
        'Manager: Offer a choice. Some pupils need a larger meal.',
        'Amira: Then we should measure the results before expanding the scheme.',
      ],
      tip: 'Use strong stress on must for safety rules and softer intonation with should for advice.',
      tipArabic: 'استخدم تشديدًا واضحًا على must للتعليمات الملزمة، ونبرة ألطف مع should للنصيحة.',
      pronunciation: <String>[
        'edible /ˈɛdəbəl/',
        'surplus /ˈsɝːpləs/',
        'hygiene /ˈhaɪdʒiːn/',
      ],
    ),

    'b2.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Tenant: Will the solar project actually reduce our bills?',
        'Engineer: It could, although the savings will vary by season.',
        'Tenant: Who pays for battery storage and future repairs?',
        'Engineer: The proposal includes a maintenance reserve and clear billing rules.',
        'Tenant: Then we should test a smaller installation before expanding.',
      ],
      tip: 'Contrast realistic forecasts with guarantees and stress although, could and provided that.',
      tipArabic: 'استخدم نبرة تحفظ مع could وalthough عند الحديث عن التوقعات، ولا تحول الاحتمال إلى ضمان.',
      pronunciation: <String>[
        'photovoltaic /ˌfoʊtoʊvɑːlˈteɪɪk/',
        'warranty /ˈwɔːrənti/',
        'efficiency /ɪˈfɪʃənsi/',
      ],
    ),
    'c1.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Official: Does the evidence prove that the factory polluted the river?',
        'Chemist: No. Similar particles were also found upstream.',
        'Official: Could the rainfall explain the increase in concentration?',
        'Chemist: It may contribute, but correlation is not proof of causation.',
        'Official: What should we do while the source remains uncertain?',
      ],
      tip: 'Practise precise scientific hedging: may, suggest, and cannot establish.',
      tipArabic: 'تدرّب على لغة البحث الدقيقة والتمييز بين suggest وprove، مع التأكيد على حدود النتائج.',
      pronunciation: <String>[
        'microplastic /ˌmaɪkroʊˈplæstɪk/',
        'polymer /ˈpɑːlɪmər/',
        'contamination /kənˌtæməˈneɪʃən/',
      ],
    ),
    'c2.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Counsel: Are you suggesting that the diplomat deliberately misled us?',
        'Expert: Not necessarily. Memory can absorb details learned afterward.',
        'Counsel: But surely a precise recollection ought to be trusted?',
        'Expert: Coherence does not, by itself, establish historical accuracy.',
        'Judge: Then we must weigh the testimony against contemporaneous records.',
      ],
      tip: 'Distinguish rhetorical certainty from evidential caution and practise complex stress patterns.',
      tipArabic: 'لاحظ الفرق في النبرة بين الاعتراض القاطع والتحفظ المبني على الأدلة، خصوصًا not necessarily.',
      pronunciation: <String>[
        'retrospective /ˌrɛtrəˈspɛktɪv/',
        'testimony /ˈtɛstəmoʊni/',
        'corroborate /kəˈrɑːbəreɪt/',
      ],
    ),

    'a2.1.6': EnglishAdvancedDialogue(
      lines: <String>["Mina: Excuse me, has the last bus left?","Waiter: I'm afraid it has. Would you like me to call a licensed taxi?","Mina: Yes, please. I am going to check the timetable next time.","Waiter: You can wait inside while the driver is on the way.","Mina: Thank you. I will send my sister the meeting point."],
      tip: "Practise going to for plans and will for an immediate decision.", tipArabic: "فرّق في النطق بين going to للخطة وwill للقرار اللحظي.",
      pronunciation: <String>["reminder /rɪˈmaɪndər/","licensed /ˈlaɪsənst/","timetable /ˈtaɪmˌteɪbəl/"],
    ),
    'a2.1.7': EnglishAdvancedDialogue(
      lines: <String>["Leo: Have you ever joined an art club?","Hana: No, I've never been to one before.","Leo: Our club makes posters and works on creative projects.","Hana: That sounds interesting. Can beginners join?","Leo: Of course! I'll show you the room after class."],
      tip: "Listen for contractions I've and I'll in friendly conversation.", tipArabic: "انتبه إلى نطق I've وI'll كاختصارات إنجليزية طبيعية.",
      pronunciation: <String>["sketching /ˈskɛtʃɪŋ/","corridor /ˈkɔːrɪdɔːr/","classmate /ˈklæsˌmeɪt/"],
    ),
    'a2.1.8': EnglishAdvancedDialogue(
      lines: <String>["Daniel: Excuse me, could I return this lamp?","Assistant: Certainly. What seems to be wrong with it?","Daniel: The switch doesn't work. Would a replacement be possible?","Assistant: Yes, I'll check the fault and bring another one.","Daniel: Thank you for your help. I appreciate it."],
      tip: "Maintain a calm, polite tone for could and would questions.", tipArabic: "درّب نبرة الطلب المهذب مع could وwould في المتجر.",
      pronunciation: <String>["replacement /rɪˈpleɪsmənt/","warranty /ˈwɔːrənti/","inconvenience /ˌɪnkənˈviːniəns/"],
    ),
    'a2.1.9': EnglishAdvancedDialogue(
      lines: <String>["Emma: Should we take this shortcut?","Cousin: No, let's follow the marked forest trail.","Emma: Good idea. We will stop when we reach the viewpoint.","Ranger: Please stay on the path and keep your rubbish with you.","Emma: We will. Thank you for the safety advice."],
      tip: "Practise natural stress in sequencing: before, after and when.", tipArabic: "درّب النبرة الصحيحة على before وafter وwhen عند ترتيب الأحداث.",
      pronunciation: <String>["shortcut /ˈʃɔːrtkʌt/","viewpoint /ˈvjuːˌpɔɪnt/","forecast /ˈfɔːrkæst/"],
    ),
    'a2.1.10': EnglishAdvancedDialogue(
      lines: <String>["Sara: Which team is the fastest today?","Coach: The blue team, but the relay isn't over yet.","Sara: That was the most exciting final lap!","Coach: The runners showed great sportsmanship when the baton fell.","Sara: I agree. Helping others matters more than winning."],
      tip: "Stress comparisons: faster than, the fastest and the most exciting.", tipArabic: "أكّد صوتيًا على صيغ المقارنة والتفضيل بدل حفظها دون فهم.",
      pronunciation: <String>["relay /ˈriːleɪ/","baton /bəˈtɑːn/","sportsmanship /ˈspɔːrtsmənʃɪp/"],
    ),
    'a2.1.5': EnglishAdvancedDialogue(
      lines: <String>[
        'Salma: Do we have any rice for dinner?',
        'Mother: No, but we have some vegetables.',
        'Salma: How many carrots should I buy?',
        'Mother: Three carrots and two tomatoes, please.',
        'Salma: Great! I will write them on my shopping list.',
      ],
      tip: 'Practise how much for uncountable food and how many for countable items.',
      tipArabic: 'تدرب على السؤال عن كميات الطعام بتمييز how much عن how many مع نبرة سؤال طبيعية.',
      pronunciation: <String>[
        'vegetable /ˈvɛdʒtəbəl/',
        'carrot /ˈkærət/',
        'quantity /ˈkwɑːntəti/',
      ],
    ),
    'b1.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Yusuf: The model bridge is bending under pressure.',
        'Hana: We should strengthen the supports before testing again.',
        'Yusuf: Could we use another material instead?',
        'Hana: We have to check the budget first.',
        'Yusuf: Agreed. We must record the failed test in our report.',
      ],
      tip: 'Use must, have to, should and could to express different degrees of obligation.',
      tipArabic: 'جرّب الاختلاف في النبرة بين الاقتراح could والنصيحة should والضرورة must.',
      pronunciation: <String>[
        'structural /ˈstrʌktʃərəl/',
        'pressure /ˈprɛʃər/',
        'durability /ˌdʊrəˈbɪləti/',
      ],
    ),

    'a2.1.3': EnglishAdvancedDialogue(
      lines: <String>[
        'Amira: Is this apartment still available to rent?',
        'Agent: Yes. Would you like to see the living room first?',
        'Amira: Please. Is the apartment furnished?',
        'Agent: Yes, and the balcony faces the park.',
        'Amira: Are the utility bills included in the rent?',
      ],
      tip: 'Practise polite comparisons with cheaper than, nearer than, and more comfortable than.',
      tipArabic: 'تدرّب على المقارنة الطبيعية بين خيارين باستخدام cheaper than وnearer than، مع نبرة سؤال مهذبة.',
      pronunciation: <String>[
        'apartment /əˈpɑːrtmənt/',
        'landlord /ˈlændlɔːrd/',
        'deposit /dɪˈpɑːzɪt/',
      ],
    ),
    'a2.1.4': EnglishAdvancedDialogue(
      lines: <String>[
        'Omar: Hello. I have a sore throat. Could you help me?',
        'Pharmacist: Of course. Do you have any allergies?',
        'Omar: No serious allergies, but I have a headache too.',
        'Pharmacist: Please read the label and follow the dosage instructions.',
        'Omar: Thank you. I will ask a doctor if the symptoms get worse.',
      ],
      tip: 'Use should for advice and pronounce warnings clearly in connected English speech.',
      tipArabic: 'تعلّم طلب النصيحة بوضوح وتدرب على نطق should بسلاسة قبل الفعل الأساسي.',
      pronunciation: <String>[
        'pharmacy /ˈfɑːrməsi/',
        'symptoms /ˈsɪmptəmz/',
        'dosage /ˈdoʊsɪdʒ/',
      ],
    ),
    'a2.1.1': EnglishAdvancedDialogue(
      lines: <String>["Lina: Excuse me, which platform is the train leaving from?", "Clerk: It leaves from platform four in ten minutes.", "Lina: I cannot find my ticket. Can you check my booking?", "Clerk: Of course. Please show me the receipt.", "Lina: Thank you! I found it in my suitcase."],
      tip: "Practise polite questions with 'Excuse me' and 'Can you ...?'.", tipArabic: "تدرّب على السؤال المهذب باستخدام Excuse me وCan you، مع تقليد نبرة السؤال.",
      pronunciation: <String>["platform /ˈplætfɔːrm/", "receipt /rɪˈsiːt/", "ticket /ˈtɪkɪt/"],
    ),
    'a2.1.2': EnglishAdvancedDialogue(
      lines: <String>["Customer: Good morning. Do you have fresh bread?", "Nora: Yes. Would you like one loaf or two?", "Customer: One loaf, please. How much is it?", "Nora: Three pounds. Would you also like a sweet roll?", "Customer: Yes, thank you. Here is the money."],
      tip: "Use 'How much' for prices and 'How many' for countable items.", tipArabic: "استخدم How much للسعر وHow many للعدد، واستمع إلى الكلمات التي تربط الجمل.",
      pronunciation: <String>["flour /ˈflaʊər/", "dough /doʊ/", "bakery /ˈbeɪkəri/"],
    ),
    'b1.1.1': EnglishAdvancedDialogue(
      lines: <String>["Nadia: If we organize a concert, will people support the library?", "Volunteer: I think they will, especially if we invite local schools.", "Nadia: We should prepare a realistic budget first.", "Volunteer: Agreed. I can contact a sponsor this afternoon.", "Nadia: Great. Let's review the plan before the deadline."],
      tip: "Stress the result in first-conditionals: 'If we organize..., people WILL support...'.", tipArabic: "لاحظ نبرة تأكيد النتيجة في الشرط الأول واستمع إلى إيقاع الجملة الشرطية.",
      pronunciation: <String>["volunteer /ˌvɑːlənˈtɪr/", "proposal /prəˈpoʊzəl/", "budget /ˈbʌdʒɪt/"],
    ),
    'b1.1.2': EnglishAdvancedDialogue(
      lines: <String>["Tessa: The microphone has stopped working. What should we do?", "Engineer: I have checked the cables, but we need a replacement.", "Tessa: Could we arrange a short acoustic performance?", "Musician: I can perform without electronic equipment.", "Tessa: Excellent. Please tell the audience about the change."],
      tip: "Listen for weak forms in connected speech, especially 'could we' and 'should we'.", tipArabic: "تدرّب على النطق المتصل في could we وshould we وتجنب فصل كل كلمة بوقف طويل.",
      pronunciation: <String>["rehearsal /rɪˈhɝːsəl/", "audience /ˈɔːdiəns/", "festival /ˈfɛstəvəl/"],
    ),
    'b2.1.1': EnglishAdvancedDialogue(
      lines: <String>["Editor: The article implies that results collapsed nationwide.", "Journalist: Yet the sample includes different age groups in different years.", "Editor: Are you suggesting that our interpretation is misleading?", "Journalist: Potentially. We need an independent analysis before publishing a conclusion.", "Editor: Then prepare a transparent correction with the relevant context."],
      tip: "Distinguish emphasis on 'implies', 'potentially', and 'misleading' while making a qualified claim.", tipArabic: "ركّز على مواضع التشديد في الكلمات التي تعبّر عن احتمال أو تحفظ بدل الجزم.",
      pronunciation: <String>["misleading /ˌmɪsˈliːdɪŋ/", "credibility /ˌkrɛdəˈbɪləti/", "verification /ˌvɛrəfɪˈkeɪʃən/"],
    ),
    'b2.1.2': EnglishAdvancedDialogue(
      lines: <String>["Manager: Staff surveys suggest that flexible schedules improve morale.", "Researcher: That's true for experienced employees, but not necessarily for new recruits.", "Manager: Would mandatory office days address that problem?", "Researcher: They might, provided that mentoring is structured and equitable.", "Manager: Let's pilot the change before making the policy permanent."],
      tip: "Practise contrastive stress on 'experienced' versus 'new' and cautious 'might'.", tipArabic: "عند عرض رأيين مختلفين أظهر التباين في التشديد بين experienced وnew.",
      pronunciation: <String>["autonomy /ɔːˈtɑːnəmi/", "mentoring /ˈmɛntɔːrɪŋ/", "productivity /ˌproʊdʌkˈtɪvəti/"],
    ),
    'c1.1.1': EnglishAdvancedDialogue(
      lines: <String>["Curator: Immediate exhibition would make the manuscript accessible to the public.", "Conservator: But accessibility must be balanced against irreversible deterioration.", "Curator: Could digital copies meet the public interest temporarily?", "Conservator: They might, provided we disclose the limits of our interpretation.", "Curator: Then the provisional catalogue should explicitly acknowledge uncertainty."],
      tip: "Practise thought-grouping in complex sentences, pausing at 'provided' and 'against'.", tipArabic: "قسّم الجمل المعقدة إلى مجموعات معنوية قصيرة، واحفظ الوقف عند الروابط دون قطع الفكرة.",
      pronunciation: <String>["provenance /ˈprɑːvənəns/", "authenticity /ˌɔːθɛnˈtɪsəti/", "provisional /prəˈvɪʒənəl/"],
    ),
    'c1.1.2': EnglishAdvancedDialogue(
      lines: <String>["Oceanographer: Some coral colonies survived the recent heatwave.", "Ecologist: Nevertheless, that alone doesn't establish ecosystem recovery.", "Oceanographer: The evidence may indicate localized resilience.", "Ecologist: But the monitoring period is too short for a definitive claim.", "Oceanographer: Then we should present the findings as provisional."],
      tip: "Practise the rhythmic contrast between 'Nevertheless' and the claim that follows.", tipArabic: "تدرّب على نبرة Nevertheless بوصفها انتقالًا حجاجيًا مع المحافظة على الإيقاع الطبيعي.",
      pronunciation: <String>["biodiversity /ˌbaɪoʊdaɪˈvɝːsəti/", "resilience /rɪˈzɪliəns/", "ecosystem /ˈiːkoʊsɪstəm/"],
    ),
    'c2.1.1': EnglishAdvancedDialogue(
      lines: <String>["Historian: The charts present conflicting accounts of the harbor's alteration.", "Commissioner: Surely the sediment record can settle the matter conclusively?", "Historian: Not without conflating geological evidence with human intention.", "Commissioner: So the documentation establishes prior awareness, not deliberate sabotage?", "Historian: Precisely. Any broader verdict would exceed the evidentiary threshold."],
      tip: "Shape intonation to distinguish a rhetorical challenge from qualified agreement.", tipArabic: "استخدم النبرة لتمييز الاستفهام الاعتراضي عن الموافقة المقيدة، وراقب قوة التشديد في evidentiary.",
      pronunciation: <String>["corroboration /kəˌrɑːbəˈreɪʃən/", "chronology /krəˈnɑːlədʒi/", "ambiguity /ˌæmbɪˈɡjuːəti/"],
    ),
    'c2.1.2': EnglishAdvancedDialogue(
      lines: <String>["Editor: Your rendering preserves the idiom's ambiguity but may unsettle readers.", "Translator: That discomfort is arguably integral to the narrator's voice.", "Editor: Couldn't a more transparent paraphrase convey the same intention?", "Translator: It might clarify the plot while inadvertently foreclosing competing readings.", "Editor: Then perhaps a restrained annotation offers the least intrusive compromise."],
      tip: "Practise subtle pragmatic emphasis on 'arguably', 'might', and 'inadvertently'.", tipArabic: "تدرّب على النبرة التي تميز التحفظ الدقيق عن الرفض القطعي، خصوصًا arguably وmight.",
      pronunciation: <String>["polysemy /pəˈlɪsəmi/", "paraphrase /ˈpærəfreɪz/", "hermeneutics /ˌhɝːməˈnuːtɪks/"],
    ),
    'b1.1.4': EnglishAdvancedDialogue(
      lines: <String>["Producer: Have you ever worked at a radio station?", "Huda: No, I haven't, but I have practised reading announcements.", "Producer: You introduced the segment very clearly yesterday.", "Huda: Thank you. I was nervous when I started.", "Producer: Next time, pause before the important information."],
      tip: "Practise asking about experience with Have you ever and compare it with an event at a specific past time.", tipArabic: "اسأل عن الخبرة باستخدام Have you ever، ثم استخدم الماضي البسيط عند الحديث عن وقت محدد.",
      pronunciation: <String>["producer /prəˈduːsər/", "broadcast /ˈbrɔːdkæst/", "headset /ˈhɛdsɛt/"],
    ),
    'b1.1.5': EnglishAdvancedDialogue(
      lines: <String>["Parent: Is this the crossing that parents complained about?", "Leila: Yes. It is the crossing that needs brighter lighting.", "Parent: Who will inspect the street?", "Leila: An officer who works for the council will visit tomorrow.", "Parent: I will write a statement about what I saw."],
      tip: "Use who for identifying people and that for identifying things. Read the clauses without unnatural long pauses.", tipArabic: "استخدم who لتحديد الأشخاص وthat لتحديد الأشياء، واقرأ جملة الصلة دون فواصل صوتية غير طبيعية.",
      pronunciation: <String>["petition /pəˈtɪʃən/", "pedestrian /pəˈdɛstriən/", "crossing /ˈkrɔːsɪŋ/"],
    ),
    'b1.1.6': EnglishAdvancedDialogue(
      lines: <String>["Coordinator: What would you do if a puppy became frightened?", "Samira: I would give it space and speak softly.", "Coordinator: Would you try to pick it up immediately?", "Samira: No. I would ask a trained worker for guidance.", "Coordinator: Excellent. Safety and patience come first."],
      tip: "Practise hypothetical If ... were ... I would ... sentences, with natural linking and stress on would.", tipArabic: "تدرّب على الشرط الافتراضي If ... were ... I would مع ربط الكلمات وتشديد مناسب.",
      pronunciation: <String>["volunteer /ˌvɑːlənˈtɪr/", "shelter /ˈʃɛltər/", "veterinary /ˈvɛtərənɛri/"],
    ),
    'b1.1.7': EnglishAdvancedDialogue(
      lines:<String>["Mentor: What are you planning to sell?","Farah: I want to test a small breakfast menu.","Mentor: Have you considered speaking to customers?","Farah: Yes, and I enjoyed doing the survey.","Mentor: Plan to expand only after the trial works."],
      tip:"Practise decide to and enjoy -ing as natural chunks; stress the verb.",tipArabic:"تدرّب على decide to مع الفعل وenjoy مع ing، وكرر الجمل بإيقاع إنجليزي طبيعي.",
      pronunciation:<String>["entrepreneur /ˌɑːntrəprəˈnɝː/","supplier /səˈplaɪər/","profit /ˈprɑːfɪt/"],
    ),
    'b1.1.8': EnglishAdvancedDialogue(
      lines:<String>["Runner: Must I wear my number throughout the race?","Omar: Yes, it must stay visible.","Runner: Should I bring my own drinking water?","Omar: You should. There are also two water stations.","Runner: Where can I find the first-aid team?"],
      tip:"Give clear instructions with emphasis on must and should.",tipArabic:"استخدم نبرة واضحة للفرق بين must للإلزام وshould للنصيحة.",
      pronunciation:<String>["participant /pɑːrˈtɪsəpənt/","marshal /ˈmɑːrʃəl/","hydration /haɪˈdreɪʃən/"],
    ),
    'b1.1.9': EnglishAdvancedDialogue(
      lines:<String>["Neighbor: Is this the area that will become the vegetable garden?","Leila: Yes, and the section which faces west will have flowers.","Neighbor: Who will look after the raised beds?","Leila: Residents who sign up for the maintenance rota.","Neighbor: That sounds fair. I can help on Saturdays."],
      tip:"Link relative clauses smoothly and distinguish who and which.",tipArabic:"اربط جمل الصلة دون توقف غير طبيعي؛ who للأشخاص وwhich للأشياء.",
      pronunciation:<String>["rotation /roʊˈteɪʃən/","irrigation /ˌɪrəˈɡeɪʃən/","harvest /ˈhɑːrvɪst/"],
    ),
    'b1.1.10': EnglishAdvancedDialogue(
      lines:<String>["Adviser: Which university are you considering?","Yara: Although the first offers a scholarship, the second has more placements.","Adviser: Have you compared accommodation costs?","Yara: Yes. Despite the distance, the course suits my ambitions.","Adviser: Then choose the programme that supports your goals."],
      tip:"Stress the central contrasts in although, despite and however.",tipArabic:"شدّد على الكلمات التي توضّح المقارنة أثناء استعمال although وdespite وhowever.",
      pronunciation:<String>["scholarship /ˈskɑːlərʃɪp/","accommodation /əˌkɑːməˈdeɪʃən/","ambition /æmˈbɪʃən/"],
    ),
  };


  /// Newly authored upper-level units use a contextual guided discussion.
  /// Existing original C1/C2 dialogues remain unchanged.
  static EnglishAdvancedDialogue _upperLevelDialogue(EnglishAdvancedLesson lesson) {
    final subject = lesson.storyTitle;
    final disputedClaim = lesson.paragraphs[0].split('. ')[1];
    final nextStep = lesson.paragraphs[3].split('. ')[2];
    final conclusion = lesson.paragraphs[4].split('. ')[2];
    return EnglishAdvancedDialogue(
      lines: <String>[
        'Interviewer: What made the inquiry into $subject controversial?',
        'Researcher: $disputedClaim',
        'Interviewer: How did you evaluate evidence without overstating it?',
        'Researcher: $nextStep',
        'Interviewer: What should readers remember? $conclusion',
      ],
      tip: 'Present a claim, acknowledge a counterargument and qualify your inference. Read the contrasting clauses aloud with natural prominence.',
      tipArabic: 'اعرض الحجة والرأي المعارض ثم استنتج بحذر. تدرب على إبراز كلمات الدليل والاعتراض والاستنتاج في النطق.',
      pronunciation: lesson.level == 'C2'
          ? <String>['hermeneutics /ˌhɜːrməˈnuːtɪks/', 'presupposition /ˌpriːsʌpəˈzɪʃən/', 'nuance /ˈnuːɑːns/']
          : <String>['inference /ˈɪnfərəns/', 'ambiguity /ˌæmbɪˈɡjuːɪti/', 'accountability /əˌkaʊntəˈbɪləti/'],
    );
  }

  static EnglishAdvancedDialogue forLesson(EnglishAdvancedLesson lesson) {
    final key = '${lesson.level.toLowerCase()}.${lesson.unitNumber}.${lesson.number}';
    final dialogue = _dialogues[key];
    if (dialogue == null) {
      if ((lesson.level == 'C1' || lesson.level == 'C2') &&
          lesson.unitNumber >= 1 && lesson.unitNumber <= 3) {
        return _upperLevelDialogue(lesson);
      }
      throw StateError('No authored dialogue for $key');
    }
    return dialogue;
  }
}

