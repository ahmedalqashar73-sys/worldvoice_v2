import 'academy_english_advanced_models.dart';

/// A syllabus-linked word bank, retaining the author's original graded story.
/// Each lesson teaches 10 nouns, 10 verbs, 10 adjectives and 10 adverbs.
/// Graded revision intentionally recycles known terms between lessons.
enum AdvancedWordKind { noun, verb, adjective, adverb }

class AdvancedCourseWord {
  const AdvancedCourseWord(this.term, this.arabic, this.kind);
  final String term;
  final String arabic;
  final AdvancedWordKind kind;
}

abstract final class EnglishAdvancedLearningPath {
  static const _core = <String, Map<AdvancedWordKind, String>>{
    'A2': <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "person|شخص;neighbor|جار;visitor|زائر;friend|صديق;family|عائلة;journey|رحلة;message|رسالة;meeting|اجتماع;question|سؤال;answer|إجابة;problem|مشكلة;solution|حل;choice|خيار;idea|فكرة;reason|سبب;plan|خطة;place|مكان;event|فعالية;experience|تجربة;opinion|رأي",
      AdvancedWordKind.verb: "describe|يصف;explain|يشرح;discuss|يناقش;compare|يقارن;decide|يقرر;prepare|يجهز;remember|يتذكر;notice|يلاحظ;discover|يكتشف;improve|يحسن;organize|ينظم;arrange|يرتب;invite|يدعو;recommend|يوصي;expect|يتوقع;choose|يختار;continue|يواصل;practise|يتدرب;mention|يذكر;support|يدعم",
      AdvancedWordKind.adjective: "helpful|مفيد;simple|بسيط;difficult|صعب;comfortable|مريح;unusual|غير مألوف;interesting|مثير للاهتمام;important|مهم;possible|ممكن;useful|نافع;polite|مهذب;friendly|ودود;careful|حذر;ready|مستعد;available|متاح;similar|مشابه;different|مختلف;successful|ناجح;surprised|متفاجئ;worried|قلق;excited|متحمس",
      AdvancedWordKind.adverb: "carefully|بعناية;usually|عادة;often|غالبا;sometimes|أحيانا;always|دائما;rarely|نادرا;quickly|بسرعة;slowly|ببطء;quietly|بهدوء;clearly|بوضوح;politely|بأدب;happily|بسعادة;recently|مؤخرا;already|بالفعل;finally|أخيرا;probably|على الأرجح;really|حقا;especially|خصوصا;nearly|تقريبا;gradually|تدريجيا",
    },
    'B1': <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "initiative|مبادرة;responsibility|مسؤولية;colleague|زميل;manager|مدير;resident|ساكن;participant|مشارك;volunteer|متطوع;resource|مورد;deadline|موعد نهائي;feedback|تغذية راجعة;consequence|نتيجة مترتبة;improvement|تحسين;agreement|اتفاق;dispute|خلاف;proposal|مقترح;survey|استبيان;evidence|دليل;outcome|حصيلة;attitude|موقف;relationship|علاقة",
      AdvancedWordKind.verb: "coordinate|ينسق;evaluate|يقيّم;investigate|يحقق;negotiate|يتفاوض;contribute|يساهم;collaborate|يتعاون;adapt|يتكيف;motivate|يحفز;resolve|يحل;persuade|يقنع;prioritize|يعطي الأولوية;respond|يستجيب;justify|يبرر;recommend|يوصي;manage|يدير;participate|يشارك;demonstrate|يوضح;challenge|يتحدى;estimate|يقدر;reflect|يتأمل",
      AdvancedWordKind.adjective: "reliable|موثوق;relevant|ذو صلة;practical|عملي;ambitious|طموح;efficient|كفؤ;flexible|مرن;independent|مستقل;supportive|داعم;constructive|بنّاء;confident|واثق;reasonable|معقول;transparent|شفاف;responsible|مسؤول;appropriate|مناسب;effective|فعال;accessible|يسهل الوصول إليه;optimistic|متفائل;sensitive|حساس;productive|منتج;challenging|صعب",
      AdvancedWordKind.adverb: "effectively|بفعالية;responsibly|بمسؤولية;confidently|بثقة;independently|باستقلالية;patiently|بصبر;constructively|بشكل بناء;increasingly|بشكل متزايد;eventually|في نهاية المطاف;consistently|باستمرار;surprisingly|بشكل مفاجئ;clearly|بوضوح;accurately|بدقة;approximately|تقريبا;efficiently|بكفاءة;particularly|على وجه الخصوص;primarily|في المقام الأول;apparently|على ما يبدو;widely|على نطاق واسع;relatively|نسبيا;genuinely|بصدق",
    },
  };
  static const _unit = <String, Map<int, Map<AdvancedWordKind, String>>>{
    'A2': <int, Map<AdvancedWordKind, String>>{
      1: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "station|محطة;platform|رصيف;ticket|تذكرة;passport|جواز سفر;suitcase|حقيبة سفر;reservation|حجز;departure|مغادرة;arrival|وصول;destination|وجهة;passenger|راكب",
      AdvancedWordKind.verb: "travel|يسافر;depart|يغادر;arrive|يصل;book|يحجز;cancel|يلغي;board|يصعد;return|يعود;pack|يحزم;explore|يستكشف;navigate|يتنقل",
      AdvancedWordKind.adjective: "delayed|متأخر;crowded|مزدحم;local|محلي;foreign|أجنبي;direct|مباشر;expensive|مكلف;cheap|رخيص;safe|آمن;busy|مشغول;convenient|ملائم",
      AdvancedWordKind.adverb: "abroad|في الخارج;away|بعيدا;nearby|بالقرب;outside|في الخارج;inside|في الداخل;early|مبكرا;late|متأخرا;together|معا;directly|مباشرة;immediately|فورا",
      },
      2: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "apartment|شقة;recipe|وصفة;medicine|دواء;appointment|موعد;hobby|هواية;bicycle|دراجة;garden|حديقة;ingredient|مكون;pet|حيوان أليف;exercise|تمرين",
      AdvancedWordKind.verb: "repair|يصلح;rest|يرتاح;adopt|يتبنى;cook|يطبخ;exercise|يتمرن;recover|يتعافى;decorate|يزين;clean|ينظف;borrow|يستعير;relax|يسترخي",
      AdvancedWordKind.adjective: "healthy|صحي;homemade|محضر منزليا;fresh|طازج;sore|مؤلم;active|نشيط;gentle|لطيف;tidy|مرتب;noisy|صاخب;spacious|واسع;delicious|لذيذ",
      AdvancedWordKind.adverb: "daily|يوميا;weekly|أسبوعيا;regularly|بانتظام;safely|بأمان;gently|بلطف;indoors|داخل المنزل;outdoors|خارج المنزل;properly|بشكل صحيح;normally|عادة;overnight|طوال الليل",
      },
      3: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "hotel|فندق;airport|مطار;museum|متحف;interview|مقابلة;excursion|رحلة قصيرة;complaint|شكوى;receipt|إيصال;flight|رحلة جوية;service|خدمة;customer|زبون",
      AdvancedWordKind.verb: "check|يتحقق;request|يطلب;confirm|يؤكد;complain|يشتكي;apologize|يعتذر;apply|يتقدم بطلب;greet|يرحب;replace|يستبدل;reserve|يحجز;postpone|يؤجل",
      AdvancedWordKind.adjective: "professional|مهني;official|رسمي;missing|مفقود;broken|مكسور;reliable|موثوق;excellent|ممتاز;unexpected|غير متوقع;formal|رسمي الطابع;reasonable|معقول;necessary|ضروري",
      AdvancedWordKind.adverb: "online|عبر الإنترنت;personally|شخصيا;formally|بشكل رسمي;unexpectedly|بشكل مفاجئ;promptly|على الفور;correctly|بشكل صحيح;patiently|بصبر;briefly|باختصار;successfully|بنجاح;instead|بدلا من ذلك",
      },
    },
    'B1': <int, Map<AdvancedWordKind, String>>{
      1: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "festival|مهرجان;internship|تدريب عملي;donation|تبرع;campaign|حملة;committee|لجنة;fundraiser|جمع تبرعات;petition|عريضة;entrepreneur|رائد أعمال;sponsor|جهة راعية;workplace|مكان عمل",
      AdvancedWordKind.verb: "advocate|يدافع عن;assist|يساعد;mentor|يوجه;endorse|يؤيد;launch|يطلق;recruit|يوظف;fund|يمول;appeal|يناشد;organize|ينظم;expand|يوسع",
      AdvancedWordKind.adjective: "charitable|خيري;local|محلي;urgent|عاجل;worthwhile|جدير بالاهتمام;communal|مجتمعي;inclusive|شامل;innovative|مبتكر;financial|مالي;enthusiastic|متحمس;dedicated|متفان",
      AdvancedWordKind.adverb: "publicly|علنا;voluntarily|طوعا;collectively|جماعيا;successfully|بنجاح;financially|ماليا;socially|اجتماعيا;locally|محليا;steadily|بثبات;creatively|بإبداع;jointly|بشكل مشترك",
      },
      2: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "misunderstanding|سوء فهم;attachment|مرفق;interviewer|محاور;candidate|مرشح;culture|ثقافة;setback|انتكاسة;election|انتخابات;presentation|عرض تقديمي;customer|عميل;itinerary|برنامج رحلة",
      AdvancedWordKind.verb: "clarify|يوضح;apologize|يعتذر;summarize|يلخص;interview|يجري مقابلة;hesitate|يتردد;reinterpret|يعيد تفسير;reschedule|يعيد الجدولة;express|يعبر;reassure|يطمئن;submit|يقدم",
      AdvancedWordKind.adjective: "cross-cultural|عابر للثقافات;confusing|مربك;disappointing|مخيب للأمل;informal|غير رسمي;professional|مهني;unfamiliar|غير مألوف;stressful|مجهد;persuasive|مقنع;memorable|لا ينسى;hesitant|متردد",
      AdvancedWordKind.adverb: "tactfully|بلباقة;thoughtfully|بتفكير متأن;respectfully|باحترام;unexpectedly|بشكل غير متوقع;openly|بصراحة;deliberately|عن قصد;diplomatically|بدبلوماسية;verbally|شفهيا;privately|بشكل خاص;positively|بإيجابية",
      },
      3: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "playground|ملعب;exhibition|معرض;installation|تركيب;policy|سياسة;assignment|مهمة دراسية;exchange|تبادل;emergency|حالة طوارئ;transport|نقل;neighborhood|حي;workshop|ورشة",
      AdvancedWordKind.verb: "repair|يصلح;restore|يعيد ترميم;conserve|يحافظ على;rebuild|يعيد بناء;enact|يسن;consult|يستشير;redesign|يعيد تصميم;evacuate|يخلي;accommodate|يستوعب;mediate|يتوسط",
      AdvancedWordKind.adjective: "sustainable|مستدام;damaged|متضرر;equitable|منصف;risky|محفوف بالمخاطر;creative|إبداعي;diverse|متنوع;viable|قابل للتطبيق;unresolved|غير محسوم;substantial|كبير;temporary|مؤقت",
      AdvancedWordKind.adverb: "strategically|استراتيجيا;collaboratively|بالتعاون;sustainably|بشكل مستدام;urgently|بشكل عاجل;fairly|بعدالة;alternatively|كبديل;temporarily|بشكل مؤقت;pragmatically|بصورة عملية;safely|بأمان;systematically|بمنهجية",
      },
    },
  };

  static bool supports(EnglishAdvancedLesson lesson) =>
      _core.containsKey(lesson.level) &&
      _unit[lesson.level]!.containsKey(lesson.unitNumber);

  static List<AdvancedCourseWord> _parse(String source, AdvancedWordKind kind) =>
      source.split(';').map((entry) {
        final split = entry.split('|');
        if (split.length != 2) throw FormatException('Word pair: $entry');
        return AdvancedCourseWord(split[0].trim(), split[1].trim(), kind);
      }).toList(growable: false);

  static List<AdvancedCourseWord> wordsFor(EnglishAdvancedLesson lesson) {
    if (!supports(lesson)) return const <AdvancedCourseWord>[];
    final lessonWords = <AdvancedCourseWord>[];
    for (final kind in AdvancedWordKind.values) {
      final common = _parse(_core[lesson.level]![kind]!, kind);
      final focused = _parse(_unit[lesson.level]![lesson.unitNumber]![kind]!, kind);
      for (var index = 0; index < 5; index++) {
        lessonWords.add(common[((lesson.number - 1) * 3 + index) % common.length]);
        lessonWords.add(focused[((lesson.number - 1) * 3 + index) % focused.length]);
      }
    }
    return List<AdvancedCourseWord>.unmodifiable(lessonWords);
  }

  static List<AdvancedCourseWord> category(
      EnglishAdvancedLesson lesson, AdvancedWordKind kind) =>
      wordsFor(lesson).where((word) => word.kind == kind)
          .toList(growable: false);

  /// Preserve the full original reading, with one newly scaffolded scene
  /// reusing lesson nouns, action verbs, descriptors and manner adverbs.
  static List<String> readingFor(EnglishAdvancedLesson lesson) {
    if (!supports(lesson)) return lesson.paragraphs;
    final nouns = category(lesson, AdvancedWordKind.noun);
    final verbs = category(lesson, AdvancedWordKind.verb);
    final adjectives = category(lesson, AdvancedWordKind.adjective);
    final adverbs = category(lesson, AdvancedWordKind.adverb);
    final context = lesson.level == 'A2'
        ? 'At the end of the day, the friends talked about their '
          '${nouns[0].term} and ${nouns[1].term}. They shared an '
          '${adjectives[0].term} idea and wanted to ${verbs[0].term} '
          '${adverbs[0].term}. One person offered to ${verbs[1].term} '
          '${adverbs[1].term}. Although the situation was '
          '${adjectives[1].term}, everyone listened and learned together.'
        : 'Following the events, the group discussed the '
          '${nouns[0].term} and ${nouns[1].term}. Their '
          '${adjectives[0].term} proposal encouraged them to '
          '${verbs[0].term} ${adverbs[0].term}; however, they still '
          'needed to ${verbs[1].term} ${adverbs[1].term}. '
          'This ${adjectives[1].term} discussion helped them '
          'reconsider their assumptions.';
    return <String>[...lesson.paragraphs, context];
  }

  static List<String> conversationFor(EnglishAdvancedLesson lesson) {
    final original = EnglishAdvancedDialogues.forLesson(lesson).lines;
    if (!supports(lesson)) return original;
    final nouns = category(lesson, AdvancedWordKind.noun);
    final verbs = category(lesson, AdvancedWordKind.verb);
    final adjectives = category(lesson, AdvancedWordKind.adjective);
    final adverbs = category(lesson, AdvancedWordKind.adverb);
    return <String>[
      ...original,
      'Tutor: What can you tell me about ${nouns[0].term} and ${nouns[1].term}?',
      'Learner: I have an ${adjectives[0].term} idea about this topic.',
      'Tutor: Could you use two new verbs in complete sentences?',
      'Learner: I would like to ${verbs[0].term} ${adverbs[0].term} '
          'and ${verbs[1].term} ${adverbs[1].term}.',
      'Tutor: Good. Now describe one ${adjectives[1].term} aspect of the story.',
    ];
  }

  static String podcastFor(EnglishAdvancedLesson lesson) {
    if (!supports(lesson)) return lesson.listening;
    final names = <AdvancedWordKind, String>{
      AdvancedWordKind.noun: 'nouns',
      AdvancedWordKind.verb: 'verbs',
      AdvancedWordKind.adjective: 'adjectives',
      AdvancedWordKind.adverb: 'adverbs',
    };
    final groups = AdvancedWordKind.values.map((kind) {
      final terms = category(lesson, kind).map((w) => w.term).join(', ');
      return 'Now listen to these ten ${names[kind]}: $terms.';
    }).join(' ');
    return '${lesson.listening} Welcome to the WorldVoice '
      '${lesson.level} vocabulary podcast. '
      'This episode revisits the same words used in your story and conversation. '
      '$groups Listen a second time. Pause after every word, repeat it, '
      'and write one sentence that uses the grammar rule from this lesson.';
  }
}
