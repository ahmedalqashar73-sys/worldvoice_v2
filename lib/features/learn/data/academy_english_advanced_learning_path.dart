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
    'B2': <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "framework|إطار;assumption|افتراض;credibility|مصداقية;perspective|منظور;implication|دلالة;incentive|حافز;evidence|دليل;interpretation|تفسير;regulation|تنظيم;controversy|جدل;hypothesis|فرضية;constraint|قيد;stakeholder|صاحب مصلحة;inequality|تفاوت;transparency|شفافية;sustainability|استدامة;innovation|ابتكار;accountability|مساءلة;consensus|إجماع;uncertainty|عدم يقين",
      AdvancedWordKind.verb: "scrutinize|يفحص بدقة;substantiate|يثبت بالدليل;assess|يقيّم;emphasize|يؤكد;illustrate|يوضح بمثال;challenge|يطعن في;question|يتساءل عن;advocate|يدافع عن;mitigate|يخفف;regulate|ينظم;quantify|يحدد كميا;anticipate|يتوقع;prioritize|يعطي الأولوية;integrate|يدمج;reform|يصلح;negotiate|يتفاوض;contextualize|يضع في سياقه;disclose|يفصح عن;distinguish|يميز;reconsider|يعيد النظر",
      AdvancedWordKind.adjective: "credible|موثوق;nuanced|دقيق التفاصيل;equitable|منصف;ethical|أخلاقي;sustainable|مستدام;contentious|مثير للجدل;plausible|معقول;rigorous|صارم منهجيا;transparent|شفاف;empirical|تجريبي;systematic|منهجي;impartial|محايد;significant|ذو دلالة;measurable|قابل للقياس;widespread|واسع الانتشار;sophisticated|متطور;controversial|خلافي;preliminary|أولي;decisive|حاسم;substantial|جوهري",
      AdvancedWordKind.adverb: "critically|بنظرة نقدية;ethically|بشكل أخلاقي;systematically|بمنهجية;empirically|تجريبيا;broadly|على نطاق واسع;narrowly|في نطاق ضيق;considerably|بدرجة كبيرة;comparatively|بالمقارنة;implicitly|ضمنيا;explicitly|صراحة;disproportionately|بشكل غير متناسب;independently|بشكل مستقل;objectively|بموضوعية;plausibly|بشكل معقول;arguably|يمكن القول;theoretically|نظريا;cautiously|بحذر;consequently|وبناء على ذلك;nevertheless|مع ذلك;ultimately|في نهاية المطاف",
    },
    'C1': <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "inference|استدلال;provenance|مصدر المنشأ;corroboration|تأييد مستقل;methodology|منهجية;discrepancy|تباين;deliberation|مداولة;legitimacy|مشروعية;ambiguity|غموض;premise|مقدمة حجاجية;repercussion|تبعة;nuance|دقة المعنى;contingency|احتمال مشروط;attribution|إسناد;accountability|مساءلة;consensus|توافق;counterargument|حجة مضادة;plausibility|معقولية;testimony|شهادة;concession|تنازل حجاجي;qualification|تحفظ علمي",
      AdvancedWordKind.verb: "scrutinize|يفحص بدقة;corroborate|يؤيد بأدلة;contextualize|يضع في سياقه;substantiate|يثبت بالأدلة;reconcile|يوفق بين;elucidate|يوضح بدقة;interrogate|يفحص نقديا;reassess|يعيد التقييم;distinguish|يميز;acknowledge|يقر;document|يوثق;reconstruct|يعيد بناء;challenge|يطعن في;articulate|يصوغ بدقة;qualify|يقيد الحكم;mediate|يتوسط;disclose|يفصح عن;reconsider|يعيد النظر;differentiate|يفرق بين;justify|يبرر",
      AdvancedWordKind.adjective: "provisional|مؤقت قابل للتعديل;contentious|مثير للجدل;credible|موثوق;methodological|منهجي;ambiguous|ملتبس;defensible|يمكن الدفاع عنه;inconclusive|غير حاسم;systemic|بنيوي;nuanced|دقيق المعنى;compelling|مقنع بقوة;disproportionate|غير متناسب;transparent|شفاف;tentative|مبدئي;irreconcilable|متعذر التوفيق;unsubstantiated|غير مؤيد بالأدلة;contextual|سياقي;rigorous|صارم منهجيا;multifaceted|متعدد الجوانب;contested|موضع خلاف;consequential|ذو تبعات مهمة",
      AdvancedWordKind.adverb: "tentatively|على نحو مبدئي;conclusively|بشكل قاطع;explicitly|بوضوح وصراحة;implicitly|ضمنيا;critically|بشكل نقدي;systematically|بمنهجية;independently|باستقلالية;arguably|يمكن القول;ostensibly|ظاهريا;disproportionately|بشكل غير متناسب;subsequently|لاحقا;nonetheless|مع ذلك;accordingly|تبعا لذلك;presumably|على الأرجح;provisionally|بصورة مؤقتة;substantially|بدرجة كبيرة;conversely|على العكس;empirically|استنادا إلى التجربة;unequivocally|بلا التباس;prudently|بتعقل",
    },
    'C2': <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "epistemology|نظرية المعرفة;hermeneutics|علم التأويل;indeterminacy|عدم التعيّن;presupposition|افتراض مسبق;anachronism|مفارقة زمنية;paradox|مفارقة;counterfactual|افتراض مضاد للواقع;ontology|علم الوجود;discourse|خطاب;metanarrative|سردية كبرى;intertextuality|التناص;dissonance|تنافر;hegemony|هيمنة;contingency|احتمال غير حتمي;dialectic|جدلية;paradigm|نموذج فكري;axiom|مسلمة;fallibility|قابلية الخطأ;subjectivity|ذاتية;exegesis|تفسير نقدي للنص",
      AdvancedWordKind.verb: "problematize|يجعل موضع إشكال;deconstruct|يفكك نقديا;synthesize|يركب بين الأفكار;interrogate|يفحص نقديا;foreground|يبرز;qualify|يقيّد الحكم;delineate|يحدد المعالم;destabilize|يزعزع;juxtapose|يضع جنبا إلى جنب;extrapolate|يستقرئ;reconcile|يوفق;substantiate|يدعم بالأدلة;explicate|يفسر بالتفصيل;elucidate|يجلي;contest|ينازع;disentangle|يفصل المتشابك;conceptualize|يصوغ مفهوما;reframe|يعيد التأطير;scrutinize|يمحّص;contextualize|يضع في سياقه",
      AdvancedWordKind.adjective: "epistemic|معرفي;hermeneutic|تأويلي;axiomatic|قائم على المسلمات;dialectical|جدلي;ontological|أنطولوجي;equivocal|ملتبس المعنى;incommensurable|متعذر القياس بمعيار مشترك;discursive|خطابي;contingent|غير حتمي;paradoxical|مفارقي;apodictic|قطعي البرهان;intersubjective|بين ذاتي;interpretive|تفسيري;teleological|غائي;normative|معياري;reductive|اختزالي;multivalent|متعدد الدلالات;self-referential|ذاتي الإحالة;anachronistic|مفارِق للعصر;irreducible|متعذر الاختزال",
      AdvancedWordKind.adverb: "epistemically|من الوجهة المعرفية;hermeneutically|تأويليا;dialectically|جدليا;ostensibly|ظاهريا;tacitly|ضمنا;unequivocally|بلا لبس;categorically|بصورة قاطعة;tentatively|مبدئيا;cogently|بحجة متماسكة;incisively|بنقد نافذ;obliquely|بشكل غير مباشر;normatively|من الوجهة المعيارية;discursively|خطابيا;intrinsically|جوهريا;contingently|بصورة غير حتمية;reflexively|بمراجعة ذاتية;comparatively|بالمقارنة;meticulously|بدقة متناهية;provisionally|على نحو مؤقت;paradoxically|بصورة مفارقة",
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
    'B2': <int, Map<AdvancedWordKind, String>>{
      1: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "headline|عنوان صحفي;bias|تحيز;dataset|مجموعة بيانات;sample|عينة;statistic|إحصائية;opinion column|عمود رأي;publication|منشور;medium|وسيلة إعلام;correlation|ارتباط;rebuttal|تفنيد",
      AdvancedWordKind.verb: "verify|يتحقق;misrepresent|يشوه العرض;publish|ينشر;circulate|يتداول;rebut|يدحض;justify|يبرر;distort|يشوه;debate|يناقش;correct|يصحح;investigate|يتقصى",
      AdvancedWordKind.adjective: "misleading|مضلل;sensational|مثير مبالغ فيه;statistical|إحصائي;editorial|تحريري;biased|متحيز;representative|ممثل للعينة;contradictory|متناقض;persuasive|مقنع;flawed|معيب;verifiable|قابل للتحقق",
      AdvancedWordKind.adverb: "selectively|بشكل انتقائي;statistically|إحصائيا;inaccurately|على نحو غير دقيق;prominently|بشكل بارز;publicly|علنا;editorially|تحريريا;superficially|بسطحية;honestly|بأمانة;collectively|جماعيا;deliberately|عمدا",
      },
      2: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "algorithm|خوارزمية;platform|منصة;automation|أتمتة;infrastructure|بنية تحتية;surveillance|مراقبة;emissions|انبعاثات;subsidy|دعم حكومي;legislation|تشريع;audit|تدقيق;accessibility|إتاحة الوصول",
      AdvancedWordKind.verb: "automate|يؤتمت;encrypt|يشفّر;monitor|يراقب;optimize|يحسّن;deploy|ينشر تقنيا;simulate|يحاكي;incentivize|يحفز;enforce|ينفذ;validate|يتحقق من الصلاحية;calibrate|يعاير",
      AdvancedWordKind.adjective: "digital|رقمي;algorithmic|خوارزمي;renewable|متجدد;accessible|متاح للجميع;invasive|منتهك للخصوصية;scalable|قابل للتوسع;regulated|خاضع للتنظيم;predictive|تنبؤي;affordable|ميسور التكلفة;decentralized|لامركزي",
      AdvancedWordKind.adverb: "digitally|رقميا;remotely|عن بعد;securely|بأمان;automatically|آليا;experimentally|تجريبيا;prospectively|استشرافيا;transparently|بشفافية;reliably|بموثوقية;globally|عالميا;technically|تقنيا",
      },
      3: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "workforce|قوة عاملة;housing|سكن;conservation|حفاظ على الطبيعة;curriculum|منهج دراسي;expenditure|إنفاق;productivity|إنتاجية;tourism|سياحة;heritage|تراث;inclusion|إدماج;democracy|ديمقراطية",
      AdvancedWordKind.verb: "revise|يراجع;redistribute|يعيد توزيع;conserve|يحافظ على;protect|يحمي;allocate|يخصص;fund|يمول;reconstruct|يعيد بناء;interpret|يفسر;balance|يوازن;legislate|يشرّع",
      AdvancedWordKind.adjective: "interdisciplinary|متعدد التخصصات;disproportionate|غير متناسب;long-term|طويل الأجل;complex|معقد;structural|بنيوي;vulnerable|عرضة للخطر;representative|تمثيلي;democratic|ديمقراطي;beneficial|نافع;unintended|غير مقصود",
      AdvancedWordKind.adverb: "structurally|بنيويا;politically|سياسيا;economically|اقتصاديا;socially|اجتماعيا;environmentally|بيئيا;institutionally|مؤسسيا;historically|تاريخيا;pragmatically|عمليا;sustainably|بشكل مستدام;inclusively|بشكل شامل",
      },
    },
    'C1': <int, Map<AdvancedWordKind, String>>{
      1: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "manuscript|مخطوطة;artifact|قطعة أثرية;archive|أرشيف;repository|مستودع بحثي;protocol|بروتوكول;dataset|مجموعة بيانات;hypothesis|فرضية;peer review|مراجعة الأقران;chronology|تسلسل زمني;consent|موافقة مستنيرة",
      AdvancedWordKind.verb: "authenticate|يثبت الأصالة;transcribe|ينسخ نصيا;replicate|يكرر التجربة;triangulate|يفحص بمصادر متعددة;validate|يتحقق من صحة;annotate|يعلق توضيحيا;interpret|يفسر;calibrate|يعاير;extrapolate|يستقرئ;verify|يتحقق من",
      AdvancedWordKind.adjective: "archival|أرشيفي;peer-reviewed|محكم علميا;replicable|قابل للتكرار;unverified|غير متحقق منه;longitudinal|طولي عبر الزمن;historical|تاريخي;anomalous|شاذ عن المعتاد;predictive|تنبؤي;interdisciplinary|متعدد التخصصات;authenticated|موثق الأصالة",
      AdvancedWordKind.adverb: "historically|تاريخيا;statistically|إحصائيا;scientifically|علميا;retrospectively|بأثر رجعي;chronologically|حسب التسلسل الزمني;analytically|تحليليا;experimentally|تجريبيا;precisely|بدقة;comparatively|بالمقارنة;reproducibly|بصورة قابلة للتكرار",
      },
      2: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "restitution|رد المقتنيات;whistleblower|كاشف مخالفات;oversight|رقابة;grievance|تظلم;stewardship|رعاية مسؤولة;mandate|تفويض;governance|حوكمة;consultation|مشاورة;redress|إنصاف;stakeholder|صاحب مصلحة",
      AdvancedWordKind.verb: "legislate|يسن التشريعات;remediate|يعالج الأضرار;advocate|يناصر;regulate|ينظم;consult|يستشير;negotiate|يتفاوض;represent|يمثل;safeguard|يصون;adjudicate|يفصل في النزاع;implement|ينفذ",
      AdvancedWordKind.adjective: "institutional|مؤسسي;equitable|منصف;participatory|تشاركي;legally binding|ملزم قانونيا;representative|تمثيلي;deliberative|تداولي;inclusive|شامل;unlawful|غير قانوني;reciprocal|متبادل;procedural|إجرائي",
      AdvancedWordKind.adverb: "legally|قانونيا;institutionally|مؤسسيا;collectively|جماعيا;democratically|ديمقراطيا;equitably|بعدالة;formally|رسميا;publicly|علنا;transnationally|عبر الحدود;collaboratively|بالتعاون;ethically|أخلاقيا",
      },
      3: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "resilience|مرونة التكيف;ecosystem|نظام بيئي;procurement|مشتريات مؤسسية;confounder|متغير مربك;probability|احتمالية;emissions|انبعاثات;distribution|توزيع;mitigation|تخفيف الضرر;adaptation|تكيف;trade-off|مفاضلة",
      AdvancedWordKind.verb: "model|ينمذج;forecast|يتنبأ;quantify|يحدد كميا;mitigate|يخفف;diversify|ينوع;allocate|يخصص;simulate|يحاكي;monitor|يراقب;evaluate|يقيّم;prioritize|يعطي الأولوية",
      AdvancedWordKind.adjective: "ecological|بيئي;probabilistic|احتمالي;climatic|مناخي;resilient|مرن قادر على التكيف;sustainable|مستدام;data-driven|قائم على البيانات;counterfactual|مضاد للواقع;measurable|قابل للقياس;uncertain|غير يقيني;adaptive|تكيفي",
      AdvancedWordKind.adverb: "environmentally|بيئيا;probabilistically|احتماليا;regionally|إقليميا;globally|عالميا;quantitatively|كميا;ecologically|إيكولوجيا;economically|اقتصاديا;incrementally|تدريجيا;strategically|استراتيجيا;predictably|بصورة متوقعة",
      },
    },
    'C2': <int, Map<AdvancedWordKind, String>>{
      1: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "textual criticism|النقد النصي;textual variant|تنويع نصي;marginalia|تعليقات هامشية;paleography|علم الخطوط القديمة;palimpsest|مخطوطة ممحوّة ومعاد استخدامها;attribution|إسناد;chronology|تسلسل زمني;eyewitness account|شهادة شاهد عيان;provenance|مصدر المنشأ;historiography|علم كتابة التاريخ",
      AdvancedWordKind.verb: "collate|يقارن النسخ;authenticate|يثبت الأصالة;annotate|يعلق على النص;transcribe|ينسخ نصيا;emend|يصوّب النص;decipher|يفك رموزه;reconstruct|يعيد بناء;historicize|يحلل تاريخيا;translate|يترجم;date|يحدد زمن",
      AdvancedWordKind.adjective: "archival|أرشيفي;fragmentary|مجتزأ;contested|متنازع عليه;apocryphal|منحول;authentic|أصيل;inconclusive|غير حاسم;archaic|قديم الأسلوب;diachronic|تعاقبي تاريخيا;philological|متعلق بفقه اللغة;polyphonic|متعدد الأصوات",
      AdvancedWordKind.adverb: "historically|تاريخيا;anachronistically|خارج السياق الزمني;chronologically|زمنيا;philologically|وفق فقه اللغة;retrospectively|بأثر رجعي;sequentially|بالتتابع;intertextually|تناصيا;textually|من حيث النص;archivally|من حيث الأرشيف;faithfully|بأمانة",
      },
      2: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "ethical agency|الفاعلية الأخلاقية;moral culpability|المسؤولية عن الذنب;distributive justice|العدالة التوزيعية;public reason|التعليل العمومي;euphemism|تعبير ملطف;enthymeme|قياس مضمر;rhetorical framing|تأطير بلاغي;legitimation|إضفاء الشرعية;moral luck|الحظ الأخلاقي;reciprocity|المعاملة بالمثل",
      AdvancedWordKind.verb: "attribute|ينسب;legitimize|يضفي الشرعية;rationalize|يبرر بدوافع عقلية;euphemize|يصوغ تعبيرا ملطفا;implicate|يورط أو يقتضي;vindicate|يثبت صحة;presuppose|يفترض سلفا;universalize|يعمم;adjudicate|يفصل في نزاع;instrumentalize|يستخدم كوسيلة",
      AdvancedWordKind.adjective: "ethical|أخلاقي;justificatory|تبريري;rhetorical|بلاغي;coercive|قَسري;deliberative|تداولي;distributive|توزيعي;consequentialist|نتائجي أخلاقيا;deontological|واجباتي أخلاقيا;paternalistic|أبوي متسلط;dialogical|حواري",
      AdvancedWordKind.adverb: "ethically|أخلاقيا;rhetorically|بلاغيا;deliberatively|بالمداولة;pragmatically|براغماتيا;coercively|بالإكراه;equitably|بإنصاف;morally|من الناحية الأخلاقية;procedurally|إجرائيا;strategically|استراتيجيا;persuasively|بإقناع",
      },
      3: <AdvancedWordKind, String>{
      AdvancedWordKind.noun: "causal attribution|إسناد السببية;explanatory gap|فجوة تفسيرية;disciplinary boundary|حد تخصصي;scholarly consensus|إجماع علمي;burden of proof|عبء الإثبات;formal inference|استدلال صوري;counterexample|مثال ناقض;evidentiary threshold|حد كفاية الدليل;methodological pluralism|تعدد المناهج;logical entailment|اقتضاء منطقي",
      AdvancedWordKind.verb: "disambiguate|يزيل الالتباس;operationalize|يحوّل إلى متغير قابل للقياس;formalize|يصوغ رسميا;falsify|يدحض اختباريا;instantiate|يجسد في حالة;triangulate|يتحقق بعدة مصادر;generalize|يعمم;calibrate|يعاير;corroborate|يدعم بدليل مستقل;reinterpret|يعيد التأويل",
      AdvancedWordKind.adjective: "interdisciplinary|متعدد التخصصات;inferential|استدلالي;causally robust|متين من حيث السببية;falsifiable|قابل للدحض;generalizable|قابل للتعميم;explanatory|تفسيري;conceptual|مفاهيمي;probabilistic|احتمالي;analytical|تحليلي;methodologically sound|سليم منهجيا",
      AdvancedWordKind.adverb: "analytically|تحليليا;probabilistically|احتماليا;methodologically|منهجيا;theoretically|نظريا;empirically|تجريبيا;causally|سببيا;inferentially|استدلاليا;cautiously|بحذر;rigorously|بصرامة منهجية;systematically|بمنهجية",
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

  /// Two additional academic reading paragraphs extend the original story.
  /// Each contains topic vocabulary, an explicit counterargument and a
  /// defensible qualified conclusion rather than a beginner dialogue.
  static List<String> _upperReading(
      EnglishAdvancedLesson lesson,
      List<AdvancedCourseWord> nouns,
      List<AdvancedCourseWord> verbs,
      List<AdvancedCourseWord> adjectives,
      List<AdvancedCourseWord> adverbs) {
    final first =
        'The enquiry at the centre of "${lesson.storyTitle}" entered a more '
        'demanding phase when the panel revisited the ${nouns[0].term}. '
        'What had initially seemed straightforward became a question about '
        'the ${nouns[1].term} and the assumptions beneath an apparently '
        'authoritative explanation. The investigators decided to '
        '${verbs[0].term} the available evidence ${adverbs[0].term} and '
        'to ${verbs[1].term} the competing interpretation ${adverbs[1].term}. '
        'One participant called the emerging account ${adjectives[0].term}; '
        'another judged it ${adjectives[1].term}, pointing to important '
        'information that had been omitted. Neither position could be '
        'adopted merely because its spokesperson sounded confident. '
        'The group had to say what counted as evidence, what remained '
        'unresolved, and why a particular inference deserved provisional trust.';
    final second =
        'In the closing session, the discussion turned to the '
        '${nouns[2].term} and its connection with the ${nouns[3].term}. '
        'The chair asked each contributor to ${verbs[2].term} '
        'the central claim ${adverbs[2].term}, and to '
        '${verbs[3].term} the supporting material ${adverbs[3].term}. '
        'The resulting memorandum acknowledged a ${adjectives[2].term} '
        'difficulty without presenting every interpretation as equally '
        'plausible. Its authors also explained why the '
        '${nouns[4].term} could not be dismissed as a technical detail. '
        'To some readers, this measured response seemed frustratingly '
        'incomplete; to others, it was precisely the restraint that '
        'responsible scholarship required. The decision therefore remained '
        'open to further scrutiny, with clearly identified conditions '
        'under which it would need to be revised.';
    return <String>[...lesson.paragraphs, first, second];
  }

  /// Preserve the full original reading, with one newly scaffolded scene
  /// reusing lesson nouns, action verbs, descriptors and manner adverbs.
  static List<String> readingFor(EnglishAdvancedLesson lesson) {
    if (!supports(lesson)) return lesson.paragraphs;
    final nouns = category(lesson, AdvancedWordKind.noun);
    final verbs = category(lesson, AdvancedWordKind.verb);
    final adjectives = category(lesson, AdvancedWordKind.adjective);
    final adverbs = category(lesson, AdvancedWordKind.adverb);
    if (lesson.level == 'C1' || lesson.level == 'C2') {
      return _upperReading(lesson, nouns, verbs, adjectives, adverbs);
    }
    final context = lesson.level == 'A2'
        ? 'At the end of the day, the friends talked about their '
          '${nouns[0].term} and ${nouns[1].term}. They described the situation as '
          '${adjectives[0].term} and wanted to ${verbs[0].term} '
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
    if (lesson.level == 'C1' || lesson.level == 'C2') {
      return <String>[
        ...original,
        'Editor: What does the ${nouns[0].term} reveal about the '
            'main argument in ${lesson.storyTitle}?',
        'Researcher: The ${nouns[1].term} appears ${adjectives[0].term}, '
            'but another account makes it ${adjectives[1].term}.',
        'Editor: How could you ${verbs[0].term} that claim ${adverbs[0].term} '
            'without overlooking rival interpretations?',
        'Researcher: I would ${verbs[1].term} the ${nouns[2].term} '
            '${adverbs[1].term}, and then ${verbs[2].term} '
            'the ${nouns[3].term}.',
        'Editor: Offer a qualified judgement that states both its '
            'evidential grounds and the limits of your conclusion.',
      ];
    }
    return <String>[
      ...original,
      'Tutor: What can you tell me about ${nouns[0].term} and ${nouns[1].term}?',
      'Learner: I think the situation is ${adjectives[0].term}.',
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
    final upper = lesson.level == 'C1' || lesson.level == 'C2';
    final criticalListening = upper
      ? 'Consider this question: which interpretation is grounded in '
        'evidence and which rests on an assumption? '
        'Pause to identify a credible counterargument and explain '
        'whether it changes the original conclusion. '
        'Do not simply repeat the speaker’s confidence; examine the '
        'scope of each claim. The most persuasive response '
        'may be a qualified conclusion that distinguishes observation '
        'from inference. '
      : '';
    return '${lesson.listening} Welcome to the WorldVoice '
      '${lesson.level} vocabulary podcast. $criticalListening'
      'This episode revisits the same words used in your story and conversation. '
      '$groups Listen a second time. Pause after every word, repeat it, '
      'and write one sentence that uses the grammar rule from this lesson.';
  }
}
