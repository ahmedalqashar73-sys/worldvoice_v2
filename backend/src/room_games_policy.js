// Room language game content is reviewed, static and independent of LLM costs.
// Five prompts per session, 30 seconds each, 5 free sessions per mode/day/host.
export const GAME_MODES = Object.freeze(["vocabulary", "guess"]);
export const GAME_LEVELS = Object.freeze(["beginner", "intermediate", "advanced"]);
export const GAME_LANGUAGE_CODES = Object.freeze(["ar", "en", "es", "zh", "ko", "fr"]);
export const GAME_QUESTIONS_PER_SESSION = 5;
export const GAME_SECONDS_PER_QUESTION = 30;
export const GAME_SESSIONS_PER_DAY = 5;
export const GAME_POINTS_PER_CORRECT = 10;

const banks = {
  en: {
    beginner: [
      ["apple", "A round fruit that is often red or green."],
      ["school", "A place where children go to learn."],
      ["window", "An opening in a wall that lets in light."],
      ["garden", "An outdoor place where flowers or vegetables grow."],
      ["pencil", "A tool used to write or draw that can be erased."],
      ["bridge", "A structure built to cross a river or road."],
      ["market", "A place where people buy and sell things."],
    ],
    intermediate: [
      ["library", "A place where people can borrow books."],
      ["journey", "An act of traveling from one place to another."],
      ["solution", "A way of solving a difficult problem."],
      ["tradition", "A custom passed down between generations."],
      ["research", "Careful study to discover facts about a subject."],
      ["resource", "A useful supply or source of support."],
      ["evidence", "Information used to show that something is true."],
    ],
    advanced: [
      ["resilience", "The ability to recover after difficulty or change."],
      ["ambiguity", "The quality of having more than one possible meaning."],
      ["consensus", "General agreement reached by a group."],
      ["paradox", "A statement that appears contradictory yet may be true."],
      ["integrity", "The quality of acting honestly and consistently."],
      ["coherence", "The quality of being clear, logical and connected."],
      ["nuance", "A small but meaningful difference in interpretation."],
    ],
  },
  ar: {
    beginner: [
      ["تفاحة", "فاكهة مستديرة قد تكون حمراء أو خضراء."],
      ["مدرسة", "مكان يذهب إليه الأطفال للتعلم."],
      ["نافذة", "فتحة في الجدار تسمح بدخول الضوء والهواء."],
      ["حديقة", "مكان تنمو فيه الأشجار والزهور ويقصده الناس للتنزه."],
      ["قلم", "أداة نستخدمها للكتابة والرسم."],
      ["جسر", "بناء يُستخدم لعبور نهر أو طريق."],
      ["سوق", "مكان تُباع فيه السلع وتُشترى."],
    ],
    intermediate: [
      ["مكتبة", "مكان يمكن فيه قراءة الكتب أو استعارتها."],
      ["رحلة", "انتقال من مكان إلى آخر بهدف الزيارة أو الاستكشاف."],
      ["حلول", "طرق مختلفة لمعالجة المشكلات والتغلب عليها."],
      ["تقاليد", "عادات تنتقل من جيل إلى جيل."],
      ["بحث", "دراسة منظمة تهدف إلى اكتشاف معلومات جديدة."],
      ["موارد", "إمكانات وأشياء متاحة للاستفادة منها."],
      ["دليل", "معلومة أو برهان يساعد على إثبات صحة أمر."],
    ],
    advanced: [
      ["مرونة", "القدرة على التكيف والتعافي بعد التحديات."],
      ["التباس", "عدم وضوح المعنى بسبب احتمال أكثر من تفسير."],
      ["إجماع", "اتفاق مجموعة على رأي أو قرار."],
      ["مفارقة", "حالة تبدو متناقضة لكنها تحمل معنى يمكن فهمه."],
      ["نزاهة", "الالتزام بالأمانة والابتعاد عن الفساد."],
      ["اتساق", "ترابط الأفكار والأفعال دون تناقض."],
      ["دقة", "الاهتمام بالتفاصيل وتجنب الخطأ في التعبير أو العمل."],
    ],
  },
  fr: {
    beginner: [
      ["pomme", "Un fruit rond souvent rouge ou vert."],
      ["école", "Un lieu où les enfants vont apprendre."],
      ["fenêtre", "Une ouverture dans un mur qui laisse entrer la lumière."],
      ["jardin", "Un espace extérieur où poussent des fleurs ou des légumes."],
      ["crayon", "Un objet utilisé pour écrire ou dessiner."],
      ["pont", "Une construction qui permet de traverser une rivière."],
      ["marché", "Un lieu où l'on achète et vend des produits."],
    ],
    intermediate: [
      ["bibliothèque", "Un lieu où l'on peut emprunter des livres."],
      ["voyage", "Le fait de se déplacer d'un lieu à un autre."],
      ["solution", "Une manière de résoudre un problème."],
      ["tradition", "Une coutume transmise entre générations."],
      ["recherche", "Une étude attentive pour découvrir des faits."],
      ["ressource", "Un moyen ou une réserve dont on peut se servir."],
      ["preuve", "Un élément qui montre qu'une affirmation est vraie."],
    ],
    advanced: [
      ["résilience", "La capacité à se remettre d'une difficulté."],
      ["ambiguïté", "Le fait de pouvoir être compris de plusieurs façons."],
      ["consensus", "Un accord général au sein d'un groupe."],
      ["paradoxe", "Une idée qui semble contradictoire mais peut être vraie."],
      ["intégrité", "La qualité d'une personne honnête et fidèle à ses principes."],
      ["cohérence", "Le caractère logique et lié des idées."],
      ["nuance", "Une différence légère mais importante dans le sens."],
    ],
  },
};

// Reviewed definitions for Spanish, Mandarin Chinese and Korean, all levels.
Object.assign(banks, {
  "es": {
    "beginner": [
      [
        "manzana",
        "Una fruta redonda que puede ser roja o verde."
      ],
      [
        "escuela",
        "Lugar donde los niños asisten para aprender."
      ],
      [
        "ventana",
        "Abertura de un edificio que deja pasar luz y aire."
      ],
      [
        "jardín",
        "Espacio donde se cultivan plantas y flores."
      ],
      [
        "lápiz",
        "Instrumento para escribir o dibujar que se puede borrar."
      ],
      [
        "puente",
        "Construcción que permite cruzar un río o una carretera."
      ],
      [
        "mercado",
        "Lugar donde se compran y venden productos."
      ],
      [
        "mesa",
        "Mueble con una superficie plana y varias patas."
      ],
      [
        "silla",
        "Mueble que sirve para sentarse una persona."
      ],
      [
        "libro",
        "Conjunto de páginas escritas o impresas."
      ],
      [
        "zapato",
        "Prenda que protege los pies al caminar."
      ],
      [
        "camino",
        "Vía por la que se puede caminar o viajar."
      ],
      [
        "lluvia",
        "Agua que cae de las nubes."
      ],
      [
        "verano",
        "Estación del año que suele ser la más calurosa."
      ],
      [
        "invierno",
        "Estación del año que suele ser la más fría."
      ],
      [
        "desayuno",
        "Primera comida que se toma por la mañana."
      ],
      [
        "cocina",
        "Habitación donde se preparan alimentos."
      ],
      [
        "familia",
        "Grupo de personas unidas por parentesco."
      ],
      [
        "música",
        "Arte que combina sonidos y ritmos."
      ],
      [
        "montaña",
        "Elevación natural grande del terreno."
      ],
      [
        "ciudad",
        "Población grande con edificios y calles."
      ],
      [
        "hospital",
        "Lugar donde los médicos atienden a pacientes."
      ],
      [
        "reloj",
        "Objeto que indica la hora."
      ],
      [
        "estrella",
        "Cuerpo celeste que emite luz propia."
      ],
      [
        "playa",
        "Zona de arena situada junto al mar."
      ]
    ],
    "intermediate": [
      [
        "biblioteca",
        "Lugar donde se pueden consultar o pedir prestados libros."
      ],
      [
        "viaje",
        "Desplazamiento de un lugar a otro."
      ],
      [
        "solución",
        "Respuesta que permite resolver un problema."
      ],
      [
        "tradición",
        "Costumbre que pasa de una generación a otra."
      ],
      [
        "investigación",
        "Estudio cuidadoso para descubrir hechos."
      ],
      [
        "recurso",
        "Medio disponible que puede ser útil para un propósito."
      ],
      [
        "evidencia",
        "Información que ayuda a demostrar que algo es cierto."
      ],
      [
        "amistad",
        "Relación de afecto y confianza entre personas."
      ],
      [
        "desafío",
        "Situación difícil que requiere esfuerzo para superarla."
      ],
      [
        "propuesta",
        "Idea presentada para que otros la consideren."
      ],
      [
        "comunidad",
        "Grupo de personas que comparten un entorno o intereses."
      ],
      [
        "oportunidad",
        "Circunstancia favorable para conseguir algo."
      ],
      [
        "experiencia",
        "Conocimiento adquirido al vivir o hacer algo."
      ],
      [
        "consecuencia",
        "Resultado producido por una acción."
      ],
      [
        "equilibrio",
        "Estado en el que varias fuerzas se compensan."
      ],
      [
        "progreso",
        "Avance hacia una meta o una mejora."
      ],
      [
        "responsabilidad",
        "Obligación de responder por las propias acciones."
      ],
      [
        "decisión",
        "Elección que se hace entre varias posibilidades."
      ],
      [
        "beneficio",
        "Ventaja o mejora que se obtiene."
      ],
      [
        "desarrollo",
        "Proceso de crecimiento o cambio gradual."
      ],
      [
        "creatividad",
        "Capacidad para producir ideas originales."
      ],
      [
        "comparación",
        "Acción de observar semejanzas y diferencias."
      ],
      [
        "objetivo",
        "Resultado que una persona intenta alcanzar."
      ],
      [
        "ambiente",
        "Condiciones que rodean a un ser vivo o lugar."
      ],
      [
        "comunicación",
        "Intercambio de información entre personas."
      ]
    ],
    "advanced": [
      [
        "resiliencia",
        "Capacidad de recuperarse después de una dificultad."
      ],
      [
        "ambigüedad",
        "Cualidad de admitir más de una interpretación."
      ],
      [
        "consenso",
        "Acuerdo general entre miembros de un grupo."
      ],
      [
        "paradoja",
        "Idea que parece contradictoria pero puede tener sentido."
      ],
      [
        "integridad",
        "Cualidad de actuar con honestidad y rectitud."
      ],
      [
        "coherencia",
        "Relación lógica y consistente entre ideas."
      ],
      [
        "matiz",
        "Diferencia pequeña pero importante en el significado."
      ],
      [
        "sostenibilidad",
        "Capacidad de mantenerse sin agotar los recursos."
      ],
      [
        "perspectiva",
        "Punto de vista desde el que se interpreta algo."
      ],
      [
        "discernimiento",
        "Capacidad para distinguir y juzgar con cuidado."
      ],
      [
        "inherente",
        "Que pertenece a algo por su propia naturaleza."
      ],
      [
        "transparencia",
        "Cualidad de comunicar información de forma clara y abierta."
      ],
      [
        "reciprocidad",
        "Correspondencia mutua entre acciones o sentimientos."
      ],
      [
        "heterogeneidad",
        "Presencia de elementos de naturaleza diferente."
      ],
      [
        "convergencia",
        "Proceso por el que varias cosas se acercan a un mismo punto."
      ],
      [
        "divergencia",
        "Separación o diferencia entre ideas y caminos."
      ],
      [
        "legitimidad",
        "Cualidad de ser conforme a normas o principios aceptados."
      ],
      [
        "trascendencia",
        "Importancia que supera lo inmediato o habitual."
      ],
      [
        "causalidad",
        "Relación entre una causa y su efecto."
      ],
      [
        "verosimilitud",
        "Cualidad de algo que parece verdadero o creíble."
      ],
      [
        "interdependencia",
        "Situación en que varios elementos dependen unos de otros."
      ],
      [
        "subjetividad",
        "Influencia de opiniones personales en un juicio."
      ],
      [
        "objetividad",
        "Consideración de hechos sin favoritismo personal."
      ],
      [
        "metodología",
        "Conjunto organizado de métodos usados en una investigación."
      ],
      [
        "innovación",
        "Introducción de ideas o métodos nuevos y útiles."
      ]
    ]
  },
  "zh": {
    "beginner": [
      [
        "苹果",
        "一种常见的圆形水果，可能是红色或绿色。"
      ],
      [
        "学校",
        "学生上课和学习知识的地方。"
      ],
      [
        "窗户",
        "墙上可以透光和通风的开口。"
      ],
      [
        "花园",
        "种植花草和其他植物的地方。"
      ],
      [
        "铅笔",
        "一种可以用橡皮擦去字迹的书写工具。"
      ],
      [
        "桥梁",
        "帮助人们跨过河流或道路的建筑。"
      ],
      [
        "市场",
        "人们买卖商品的地方。"
      ],
      [
        "桌子",
        "上面有平面，可以放东西的家具。"
      ],
      [
        "椅子",
        "供一个人坐下的家具。"
      ],
      [
        "书本",
        "由许多写着文字的纸页组成的物品。"
      ],
      [
        "鞋子",
        "穿在脚上保护双脚的东西。"
      ],
      [
        "道路",
        "供人或车辆通行的路线。"
      ],
      [
        "下雨",
        "天空中的水滴落到地面的天气现象。"
      ],
      [
        "夏天",
        "一年中通常最热的季节。"
      ],
      [
        "冬天",
        "一年中通常最冷的季节。"
      ],
      [
        "早餐",
        "每天早上吃的第一顿饭。"
      ],
      [
        "厨房",
        "家里准备和烹饪食物的房间。"
      ],
      [
        "家庭",
        "由亲属关系联系在一起的人们。"
      ],
      [
        "音乐",
        "通过旋律和节奏组织声音的艺术。"
      ],
      [
        "高山",
        "地面上高而大的自然隆起。"
      ],
      [
        "城市",
        "人口较多并有许多建筑和街道的地方。"
      ],
      [
        "医院",
        "医生和护士为病人提供治疗的地方。"
      ],
      [
        "时钟",
        "用来显示时间的装置。"
      ],
      [
        "星星",
        "夜空中看起来像发光小点的天体。"
      ],
      [
        "海滩",
        "海边由沙子或小石子覆盖的地带。"
      ]
    ],
    "intermediate": [
      [
        "图书馆",
        "可以阅读或借阅各种书籍的公共场所。"
      ],
      [
        "旅行",
        "从一个地方前往另一个地方的活动。"
      ],
      [
        "解决方案",
        "用于处理困难或问题的具体办法。"
      ],
      [
        "传统",
        "在不同世代之间流传的习俗。"
      ],
      [
        "研究",
        "为了发现事实而进行的系统性调查。"
      ],
      [
        "资源",
        "能够被利用来完成目标的条件或材料。"
      ],
      [
        "证据",
        "用来支持或证明某种说法的材料。"
      ],
      [
        "友谊",
        "朋友之间建立的信任和感情。"
      ],
      [
        "挑战",
        "需要努力和能力才能克服的困难。"
      ],
      [
        "建议",
        "为解决问题而提出的意见。"
      ],
      [
        "社区",
        "居住在同一区域或具有共同联系的人群。"
      ],
      [
        "机会",
        "有利于实现某个目标的时机。"
      ],
      [
        "经验",
        "通过亲身经历或实践获得的知识。"
      ],
      [
        "后果",
        "某种行为或事件产生的结果。"
      ],
      [
        "平衡",
        "不同力量或需求处于相对稳定的状态。"
      ],
      [
        "进步",
        "朝着更好状态或目标向前发展。"
      ],
      [
        "责任",
        "需要对自己的行为和任务承担的义务。"
      ],
      [
        "决定",
        "在几个可能选项中作出选择。"
      ],
      [
        "利益",
        "某种行动带来的好处或价值。"
      ],
      [
        "发展",
        "事物逐渐成长和变化的过程。"
      ],
      [
        "创造力",
        "提出新颖想法或方法的能力。"
      ],
      [
        "比较",
        "找出两个或多个事物之间的异同。"
      ],
      [
        "目标",
        "努力希望达到的结果。"
      ],
      [
        "环境",
        "人或生物周围的自然和社会条件。"
      ],
      [
        "沟通",
        "人与人之间交换想法和信息的过程。"
      ]
    ],
    "advanced": [
      [
        "韧性",
        "面对困难后重新恢复并适应的能力。"
      ],
      [
        "歧义",
        "一句话或一个表达可以有多种解释的情况。"
      ],
      [
        "共识",
        "一个群体成员之间形成的普遍一致意见。"
      ],
      [
        "悖论",
        "表面上相互矛盾却可能包含道理的说法。"
      ],
      [
        "诚信",
        "遵守承诺并坚持诚实正直的品质。"
      ],
      [
        "连贯性",
        "思想和表达在逻辑上保持一致的特征。"
      ],
      [
        "细微差别",
        "意义相近的事物之间不明显但重要的区别。"
      ],
      [
        "可持续性",
        "在不耗尽未来资源的前提下长期保持的能力。"
      ],
      [
        "视角",
        "观察和理解某件事情所采取的立场。"
      ],
      [
        "洞察力",
        "通过表面现象发现深层意义的能力。"
      ],
      [
        "内在性",
        "某种性质属于事物自身而非外部附加的状态。"
      ],
      [
        "透明度",
        "信息和过程向相关人员公开清晰的程度。"
      ],
      [
        "互惠",
        "双方在付出和接受之间相互给予好处。"
      ],
      [
        "异质性",
        "一个整体由性质各不相同的部分组成的特征。"
      ],
      [
        "趋同",
        "不同事物逐渐变得相似或接近的过程。"
      ],
      [
        "分歧",
        "观点或立场之间存在的不一致。"
      ],
      [
        "正当性",
        "行为或制度符合合理原则而被认可的性质。"
      ],
      [
        "超越性",
        "突破当前范围或限制而达到更高层次的特征。"
      ],
      [
        "因果关系",
        "原因与其所产生结果之间的联系。"
      ],
      [
        "可信度",
        "信息或论述值得相信的程度。"
      ],
      [
        "相互依存",
        "多个对象彼此依赖才能正常运作的状态。"
      ],
      [
        "主观性",
        "判断受到个人经历和感受影响的特征。"
      ],
      [
        "客观性",
        "基于事实而尽量不受个人偏好影响的品质。"
      ],
      [
        "方法论",
        "研究某个问题时采用的系统方法与原则。"
      ],
      [
        "创新",
        "引入有价值的新思路或新做法的行为。"
      ]
    ]
  },
  "ko": {
    "beginner": [
      [
        "사과",
        "둥글고 빨갛거나 초록색인 과일입니다."
      ],
      [
        "학교",
        "학생들이 가서 공부하는 장소입니다."
      ],
      [
        "창문",
        "빛과 바람이 들어오도록 벽에 낸 구멍입니다."
      ],
      [
        "정원",
        "꽃과 나무를 심어 가꾸는 공간입니다."
      ],
      [
        "연필",
        "글을 쓰거나 그림을 그린 뒤 지울 수 있는 도구입니다."
      ],
      [
        "다리",
        "강이나 도로를 건너갈 수 있게 만든 시설입니다."
      ],
      [
        "시장",
        "물건을 사고파는 사람들이 모이는 장소입니다."
      ],
      [
        "책상",
        "공부하거나 물건을 올려놓는 평평한 가구입니다."
      ],
      [
        "의자",
        "한 사람이 앉을 때 사용하는 가구입니다."
      ],
      [
        "책",
        "글이나 그림을 여러 장의 종이에 담아 묶은 물건입니다."
      ],
      [
        "신발",
        "걸을 때 발을 보호하기 위해 신는 물건입니다."
      ],
      [
        "길",
        "사람이나 차가 다니는 통로입니다."
      ],
      [
        "비",
        "구름에서 물방울이 땅으로 떨어지는 현상입니다."
      ],
      [
        "여름",
        "일 년 중 보통 가장 더운 계절입니다."
      ],
      [
        "겨울",
        "일 년 중 보통 가장 추운 계절입니다."
      ],
      [
        "아침식사",
        "하루를 시작할 때 아침에 먹는 음식입니다."
      ],
      [
        "부엌",
        "집에서 음식을 만들고 요리하는 공간입니다."
      ],
      [
        "가족",
        "혈연이나 혼인 등으로 연결된 사람들의 모임입니다."
      ],
      [
        "음악",
        "소리와 리듬을 조화롭게 구성하는 예술입니다."
      ],
      [
        "산",
        "주변 땅보다 높게 솟아 있는 자연 지형입니다."
      ],
      [
        "도시",
        "사람과 건물이 많이 모여 있는 큰 생활 지역입니다."
      ],
      [
        "병원",
        "아픈 사람들이 진료와 치료를 받는 장소입니다."
      ],
      [
        "시계",
        "현재 시간을 알려 주는 물건입니다."
      ],
      [
        "별",
        "밤하늘에서 작게 빛나는 것처럼 보이는 천체입니다."
      ],
      [
        "해변",
        "바다와 맞닿아 있는 모래나 자갈이 있는 곳입니다."
      ]
    ],
    "intermediate": [
      [
        "도서관",
        "사람들이 책을 읽거나 빌릴 수 있는 곳입니다."
      ],
      [
        "여행",
        "평소 있던 곳을 떠나 다른 장소를 방문하는 일입니다."
      ],
      [
        "해결책",
        "문제나 어려움을 처리할 수 있는 방법입니다."
      ],
      [
        "전통",
        "오랜 시간에 걸쳐 다음 세대로 전해지는 풍습입니다."
      ],
      [
        "연구",
        "새로운 사실을 알아내기 위해 체계적으로 조사하는 일입니다."
      ],
      [
        "자원",
        "목표를 이루는 데 활용할 수 있는 재료나 수단입니다."
      ],
      [
        "증거",
        "어떤 주장이 사실임을 뒷받침하는 자료입니다."
      ],
      [
        "우정",
        "친구 사이에 형성되는 믿음과 애정입니다."
      ],
      [
        "도전",
        "노력과 용기를 필요로 하는 어려운 과제입니다."
      ],
      [
        "제안",
        "다른 사람에게 검토해 보라고 내놓는 생각입니다."
      ],
      [
        "공동체",
        "생활이나 관심사를 함께 나누는 사람들의 집단입니다."
      ],
      [
        "기회",
        "원하는 목표를 이루기에 좋은 상황이나 때입니다."
      ],
      [
        "경험",
        "직접 겪거나 실천하면서 얻은 지식입니다."
      ],
      [
        "결과",
        "어떤 행동이나 사건 뒤에 생겨나는 일입니다."
      ],
      [
        "균형",
        "서로 다른 힘이나 요구가 고르게 맞춰진 상태입니다."
      ],
      [
        "발전",
        "이전보다 더 나은 상태로 성장하거나 변하는 과정입니다."
      ],
      [
        "책임",
        "자신의 행동과 맡은 일을 감당해야 하는 의무입니다."
      ],
      [
        "결정",
        "여러 선택지 중에서 하나를 고르는 일입니다."
      ],
      [
        "이익",
        "어떤 활동으로 얻게 되는 도움이나 혜택입니다."
      ],
      [
        "창의력",
        "새롭고 독창적인 생각을 만들어 내는 능력입니다."
      ],
      [
        "비교",
        "둘 이상의 대상이 어떻게 같고 다른지 살펴보는 일입니다."
      ],
      [
        "목표",
        "노력하여 이루고자 하는 결과입니다."
      ],
      [
        "환경",
        "사람과 생물을 둘러싸고 영향을 주는 조건입니다."
      ],
      [
        "소통",
        "사람들이 생각이나 정보를 서로 주고받는 과정입니다."
      ],
      [
        "협력",
        "공통된 목적을 위해 함께 힘을 합치는 행동입니다."
      ]
    ],
    "advanced": [
      [
        "회복탄력성",
        "어려움을 겪은 뒤 다시 적응하고 회복하는 능력입니다."
      ],
      [
        "모호성",
        "하나의 표현을 여러 가지 뜻으로 해석할 수 있는 성질입니다."
      ],
      [
        "합의",
        "여러 사람이 논의를 통해 공통된 의견에 도달한 상태입니다."
      ],
      [
        "역설",
        "겉으로는 모순처럼 보이지만 의미를 담을 수 있는 주장입니다."
      ],
      [
        "진정성",
        "겉모습이 아니라 실제 마음과 행동이 일치하는 성질입니다."
      ],
      [
        "일관성",
        "생각과 행동이 서로 모순되지 않고 이어지는 성질입니다."
      ],
      [
        "미묘함",
        "쉽게 알아차리기 어렵지만 중요한 차이가 있는 특성입니다."
      ],
      [
        "지속가능성",
        "미래의 자원을 해치지 않고 오랫동안 유지될 수 있는 성질입니다."
      ],
      [
        "관점",
        "어떤 대상을 바라보고 해석할 때 취하는 입장입니다."
      ],
      [
        "통찰력",
        "겉으로 드러난 현상을 넘어 본질을 이해하는 능력입니다."
      ],
      [
        "내재성",
        "어떤 특징이 외부에서 온 것이 아니라 대상 자체에 속한 성질입니다."
      ],
      [
        "투명성",
        "정보나 과정이 이해관계자에게 명확하게 공개되는 정도입니다."
      ],
      [
        "호혜성",
        "서로 도움이나 혜택을 주고받는 관계의 특성입니다."
      ],
      [
        "이질성",
        "하나의 집단 안에 서로 다른 종류의 요소가 존재하는 성질입니다."
      ],
      [
        "수렴",
        "서로 다른 생각이나 현상이 점차 한 방향으로 모이는 과정입니다."
      ],
      [
        "발산",
        "하나의 시작점에서 여러 방향으로 퍼져 나가는 현상입니다."
      ],
      [
        "정당성",
        "행동이나 제도가 합당한 원칙에 맞아 인정받는 성질입니다."
      ],
      [
        "초월성",
        "기존의 경계나 한계를 넘어서는 성질입니다."
      ],
      [
        "인과관계",
        "어떤 원인과 그 때문에 나타나는 결과 사이의 연결입니다."
      ],
      [
        "신뢰성",
        "어떤 정보나 대상이 믿을 만한 정도입니다."
      ],
      [
        "상호의존성",
        "둘 이상의 대상이 서로에게 의지하는 관계의 특성입니다."
      ],
      [
        "주관성",
        "판단이 개인의 경험과 감정에 영향을 받는 성질입니다."
      ],
      [
        "객관성",
        "개인적인 선호를 배제하고 사실에 따라 판단하는 성질입니다."
      ],
      [
        "방법론",
        "연구를 수행할 때 사용하는 체계적인 절차와 원칙입니다."
      ],
      [
        "혁신",
        "기존 방식과 다른 새롭고 유용한 생각이나 방법을 도입하는 일입니다."
      ]
    ]
  }
});

// Expanded original word lists: 25 locally defined words at each difficulty.
banks.en.beginner.push(...[
  [
    "table",
    "A piece of furniture with a flat top and legs."
  ],
  [
    "chair",
    "A piece of furniture made for one person to sit on."
  ],
  [
    "book",
    "A set of written or printed pages bound together."
  ],
  [
    "shoe",
    "Something worn to protect a foot when walking."
  ],
  [
    "road",
    "A route used by people, bicycles and vehicles."
  ],
  [
    "rain",
    "Drops of water that fall from clouds."
  ],
  [
    "summer",
    "The warmest season of the year in many places."
  ],
  [
    "winter",
    "The coldest season of the year in many places."
  ],
  [
    "breakfast",
    "The first meal eaten in the morning."
  ],
  [
    "kitchen",
    "The room where food is prepared and cooked."
  ],
  [
    "family",
    "People related to each other through birth or marriage."
  ],
  [
    "music",
    "An art made by arranging sounds and rhythms."
  ],
  [
    "mountain",
    "A large natural rise of land above its surroundings."
  ],
  [
    "city",
    "A large populated area with streets and buildings."
  ],
  [
    "hospital",
    "A place where sick people receive medical treatment."
  ],
  [
    "clock",
    "An object that shows the time."
  ],
  [
    "star",
    "A luminous object visible in the night sky."
  ],
  [
    "beach",
    "An area of sand or small stones beside the sea."
  ]
]);
banks.en.intermediate.push(...[
  [
    "friendship",
    "A caring and trusting relationship between people."
  ],
  [
    "challenge",
    "A difficult task that requires effort to overcome."
  ],
  [
    "proposal",
    "An idea put forward for other people to consider."
  ],
  [
    "community",
    "A group of people sharing a location or interests."
  ],
  [
    "opportunity",
    "A favorable situation that makes an achievement possible."
  ],
  [
    "experience",
    "Knowledge gained from doing or living through something."
  ],
  [
    "consequence",
    "A result brought about by an action or event."
  ],
  [
    "balance",
    "A state in which different forces are in proportion."
  ],
  [
    "progress",
    "Movement toward a goal or an improved condition."
  ],
  [
    "responsibility",
    "A duty to answer for one's actions or obligations."
  ],
  [
    "decision",
    "A choice made after considering possibilities."
  ],
  [
    "benefit",
    "An advantage or helpful result of an action."
  ],
  [
    "development",
    "A process of gradual growth or change."
  ],
  [
    "creativity",
    "The ability to produce original ideas."
  ],
  [
    "comparison",
    "The act of identifying similarities and differences."
  ],
  [
    "objective",
    "A result that a person is trying to achieve."
  ],
  [
    "environment",
    "The conditions surrounding people or living things."
  ],
  [
    "communication",
    "The exchange of ideas or information."
  ]
]);
banks.en.advanced.push(...[
  [
    "sustainability",
    "The capacity to continue without depleting future resources."
  ],
  [
    "perspective",
    "A particular standpoint used to interpret a situation."
  ],
  [
    "discernment",
    "The ability to judge differences with care."
  ],
  [
    "inherent",
    "Belonging to something as an essential quality."
  ],
  [
    "transparency",
    "The quality of making information and processes open and clear."
  ],
  [
    "reciprocity",
    "The mutual exchange of actions or benefits."
  ],
  [
    "heterogeneity",
    "The presence of different kinds of elements within a group."
  ],
  [
    "convergence",
    "The process of moving toward a common point or outcome."
  ],
  [
    "divergence",
    "A movement or difference away from a shared direction."
  ],
  [
    "legitimacy",
    "Acceptance as being consistent with valid principles or rules."
  ],
  [
    "transcendence",
    "Importance or existence beyond ordinary limits."
  ],
  [
    "causality",
    "The relationship between an event and what produces it."
  ],
  [
    "plausibility",
    "The quality of seeming reasonable or likely to be true."
  ],
  [
    "interdependence",
    "A condition in which multiple parties rely on each other."
  ],
  [
    "subjectivity",
    "The influence of personal perceptions on judgment."
  ],
  [
    "objectivity",
    "The practice of considering facts without personal preference."
  ],
  [
    "methodology",
    "A systematic set of methods for inquiry or research."
  ],
  [
    "innovation",
    "The introduction of a useful new idea or approach."
  ]
]);
banks.ar.beginner.push(...[
  [
    "طاولة",
    "قطعة أثاث ذات سطح مستو توضع عليها الأشياء."
  ],
  [
    "كرسي",
    "قطعة أثاث يجلس عليها شخص واحد."
  ],
  [
    "كتاب",
    "مجموعة صفحات مكتوبة أو مطبوعة ومجلدة."
  ],
  [
    "حذاء",
    "شيء نلبسه في القدم لحمايتها أثناء المشي."
  ],
  [
    "طريق",
    "مسار مخصص لمرور الناس أو المركبات."
  ],
  [
    "مطر",
    "قطرات ماء تسقط من الغيوم إلى الأرض."
  ],
  [
    "صيف",
    "الفصل الذي يكون عادة أشد فصول السنة حرارة."
  ],
  [
    "شتاء",
    "الفصل الذي يكون عادة أبرد فصول السنة."
  ],
  [
    "فطور",
    "الوجبة الأولى التي نتناولها في الصباح."
  ],
  [
    "مطبخ",
    "غرفة يُحضّر فيها الطعام ويُطبخ."
  ],
  [
    "أسرة",
    "مجموعة أشخاص تربط بينهم صلة قرابة."
  ],
  [
    "موسيقى",
    "فن يجمع الأصوات والإيقاعات بطريقة منظمة."
  ],
  [
    "جبل",
    "ارتفاع طبيعي كبير في سطح الأرض."
  ],
  [
    "مدينة",
    "تجمع سكاني كبير فيه مبان وشوارع."
  ],
  [
    "مستشفى",
    "مكان يتلقى فيه المرضى الرعاية والعلاج."
  ],
  [
    "ساعة",
    "أداة تساعد على معرفة الوقت."
  ],
  [
    "نجمة",
    "جسم سماوي مضيء نراه في السماء ليلًا."
  ],
  [
    "شاطئ",
    "منطقة رملية أو صخرية بمحاذاة البحر."
  ]
]);
banks.ar.intermediate.push(...[
  [
    "صداقة",
    "علاقة تقوم على المودة والثقة بين الأشخاص."
  ],
  [
    "تحدي",
    "موقف صعب يتطلب جهدًا للتغلب عليه."
  ],
  [
    "اقتراح",
    "فكرة يقدمها شخص ليدرسها الآخرون."
  ],
  [
    "مجتمع",
    "مجموعة أفراد يشتركون في بيئة أو مصالح."
  ],
  [
    "فرصة",
    "ظرف مناسب يساعد على تحقيق هدف."
  ],
  [
    "خبرة",
    "معرفة يكتسبها الإنسان من الممارسة والتجربة."
  ],
  [
    "نتيجة",
    "ما يحدث بسبب فعل أو حدث سابق."
  ],
  [
    "توازن",
    "حالة تتعادل فيها القوى أو الاحتياجات المختلفة."
  ],
  [
    "تقدم",
    "انتقال تدريجي نحو هدف أو حالة أفضل."
  ],
  [
    "مسؤولية",
    "واجب تحمل تبعات الأفعال والقرارات."
  ],
  [
    "قرار",
    "اختيار أحد البدائل بعد التفكير فيها."
  ],
  [
    "فائدة",
    "أمر نافع نحصل عليه من عمل أو تجربة."
  ],
  [
    "تطور",
    "عملية نمو أو تغير تحدث بالتدريج."
  ],
  [
    "إبداع",
    "القدرة على إنتاج أفكار جديدة ومميزة."
  ],
  [
    "مقارنة",
    "معرفة أوجه الشبه والاختلاف بين أشياء."
  ],
  [
    "هدف",
    "أمر يسعى الإنسان إلى تحقيقه."
  ],
  [
    "بيئة",
    "الظروف الطبيعية والاجتماعية المحيطة بالكائنات."
  ],
  [
    "تواصل",
    "تبادل الأفكار والمعلومات بين الأشخاص."
  ]
]);
banks.ar.advanced.push(...[
  [
    "استدامة",
    "القدرة على الاستمرار مع الحفاظ على موارد المستقبل."
  ],
  [
    "منظور",
    "زاوية ينظر منها الإنسان إلى قضية أو موقف."
  ],
  [
    "تمييز",
    "القدرة على إدراك الفروق والحكم بدقة."
  ],
  [
    "جوهري",
    "وصف لما يعد جزءًا أساسيًا من طبيعة الشيء."
  ],
  [
    "شفافية",
    "وضوح المعلومات والإجراءات وإتاحتها للمعنيين."
  ],
  [
    "تبادلية",
    "علاقة تقوم على المنفعة أو المعاملة المتبادلة."
  ],
  [
    "تغاير",
    "وجود عناصر مختلفة الطبيعة داخل مجموعة واحدة."
  ],
  [
    "تقارب",
    "انتقال اتجاهات مختلفة نحو نقطة مشتركة."
  ],
  [
    "تباعد",
    "اختلاف مسارات أو مواقف كانت متقاربة."
  ],
  [
    "مشروعية",
    "اتفاق التصرف مع قواعد ومبادئ معترف بها."
  ],
  [
    "تجاوز",
    "تخطي الحدود أو العقبات المعتادة."
  ],
  [
    "سببية",
    "العلاقة التي تربط السبب بما ينتج عنه."
  ],
  [
    "معقولية",
    "صفة ما يبدو منطقيًا وقابلًا للتصديق."
  ],
  [
    "ترابط",
    "اعتماد أجزاء متعددة بعضها على بعض."
  ],
  [
    "ذاتية",
    "تأثر الحكم بالأفكار والمشاعر الشخصية."
  ],
  [
    "موضوعية",
    "الاعتماد على الوقائع دون تحيز شخصي."
  ],
  [
    "منهجية",
    "مجموعة طرق منظمة تُستخدم في البحث أو العمل."
  ],
  [
    "ابتكار",
    "إدخال فكرة أو أسلوب جديد ذي منفعة."
  ]
]);
banks.fr.beginner.push(...[
  [
    "table",
    "Un meuble avec une surface plate et des pieds."
  ],
  [
    "chaise",
    "Un meuble destiné à accueillir une personne assise."
  ],
  [
    "livre",
    "Un ensemble de pages écrites ou imprimées et reliées."
  ],
  [
    "chaussure",
    "Un objet que l'on porte pour protéger le pied."
  ],
  [
    "route",
    "Une voie destinée à la circulation des personnes et des véhicules."
  ],
  [
    "pluie",
    "De l'eau qui tombe des nuages sous forme de gouttes."
  ],
  [
    "été",
    "La saison généralement la plus chaude de l'année."
  ],
  [
    "hiver",
    "La saison généralement la plus froide de l'année."
  ],
  [
    "petit-déjeuner",
    "Le premier repas pris le matin."
  ],
  [
    "cuisine",
    "La pièce où l'on prépare et fait cuire les aliments."
  ],
  [
    "famille",
    "Un groupe de personnes unies par des liens de parenté."
  ],
  [
    "musique",
    "Un art qui organise les sons et les rythmes."
  ],
  [
    "montagne",
    "Un relief naturel qui s'élève fortement au-dessus du sol."
  ],
  [
    "ville",
    "Une grande agglomération avec des rues et des bâtiments."
  ],
  [
    "hôpital",
    "Un établissement où des personnes malades sont soignées."
  ],
  [
    "horloge",
    "Un objet qui permet de connaître l'heure."
  ],
  [
    "étoile",
    "Un astre qui produit sa propre lumière."
  ],
  [
    "plage",
    "Une zone de sable ou de galets au bord de la mer."
  ]
]);
banks.fr.intermediate.push(...[
  [
    "amitié",
    "Un lien d'affection et de confiance entre personnes."
  ],
  [
    "défi",
    "Une difficulté qu'il faut surmonter avec effort."
  ],
  [
    "proposition",
    "Une idée soumise à l'examen d'autres personnes."
  ],
  [
    "communauté",
    "Un groupe de personnes ayant un lieu ou des intérêts communs."
  ],
  [
    "occasion",
    "Une situation favorable pour réaliser quelque chose."
  ],
  [
    "expérience",
    "Une connaissance acquise par la pratique ou le vécu."
  ],
  [
    "conséquence",
    "Le résultat d'un acte ou d'un événement."
  ],
  [
    "équilibre",
    "Un état où plusieurs forces se compensent."
  ],
  [
    "progrès",
    "Une avancée vers un objectif ou une amélioration."
  ],
  [
    "responsabilité",
    "L'obligation d'assumer ses actes et ses devoirs."
  ],
  [
    "décision",
    "Un choix fait parmi plusieurs possibilités."
  ],
  [
    "avantage",
    "Un résultat utile ou favorable."
  ],
  [
    "développement",
    "Un processus de croissance ou de transformation."
  ],
  [
    "créativité",
    "La capacité à concevoir des idées originales."
  ],
  [
    "comparaison",
    "L'action de rechercher les ressemblances et les différences."
  ],
  [
    "objectif",
    "Un résultat que l'on souhaite atteindre."
  ],
  [
    "environnement",
    "Les conditions qui entourent les êtres vivants."
  ],
  [
    "communication",
    "L'échange de pensées ou d'informations."
  ]
]);
banks.fr.advanced.push(...[
  [
    "durabilité",
    "La capacité à se maintenir sans épuiser les ressources futures."
  ],
  [
    "perspective",
    "Un point de vue particulier sur une situation."
  ],
  [
    "discernement",
    "La capacité à distinguer et à juger avec finesse."
  ],
  [
    "inhérent",
    "Qui appartient à la nature même d'une chose."
  ],
  [
    "transparence",
    "La qualité de rendre les informations accessibles et claires."
  ],
  [
    "réciprocité",
    "Le caractère mutuel d'un échange d'actions ou d'avantages."
  ],
  [
    "hétérogénéité",
    "La présence d'éléments de natures différentes dans un ensemble."
  ],
  [
    "convergence",
    "Le fait que plusieurs directions se rapprochent."
  ],
  [
    "divergence",
    "Une séparation entre des opinions ou des orientations."
  ],
  [
    "légitimité",
    "La qualité de ce qui est reconnu comme conforme à des principes."
  ],
  [
    "transcendance",
    "Le fait de dépasser les limites habituelles."
  ],
  [
    "causalité",
    "Le lien qui unit une cause et son effet."
  ],
  [
    "vraisemblance",
    "Le caractère de ce qui semble crédible ou probable."
  ],
  [
    "interdépendance",
    "Une relation où plusieurs éléments dépendent les uns des autres."
  ],
  [
    "subjectivité",
    "L'influence de jugements personnels sur une appréciation."
  ],
  [
    "objectivité",
    "La recherche de faits sans préférence personnelle."
  ],
  [
    "méthodologie",
    "Un ensemble structuré de méthodes utilisées dans une étude."
  ],
  [
    "innovation",
    "L'introduction d'une idée ou d'une méthode nouvelle et utile."
  ]
]);

export function gameDay(now) { return new Date(now).toISOString().slice(0, 10); }

export function roomGameLanguageCodes(roomData = {}) {
  const raw = roomData.languageCodes;
  const codes = Array.isArray(raw) && raw.length ? raw
    : [roomData.languageCode ?? "en"];
  return [...new Set(codes.map(code => String(code).toLowerCase().split("-")[0])
    .filter(code => GAME_LANGUAGE_CODES.includes(code)))];
}

export function normalGameAnswer(text) {
  if (typeof text !== "string") return "";
  return text.normalize("NFC").trim().toLocaleLowerCase()
    .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED]/g, "")
    .replace(/\s+/g, " ");
}

export function gameIndex(startedAtMs, now) {
  return Math.max(0, Math.min(GAME_QUESTIONS_PER_SESSION,
    Math.floor((now - startedAtMs) / (GAME_SECONDS_PER_QUESTION * 1000))));
}

export function gameTimeLeft(startedAtMs, now) {
  const index = gameIndex(startedAtMs, now);
  if (index >= GAME_QUESTIONS_PER_SESSION) return 0;
  return Math.max(0, Math.ceil((startedAtMs +
    (index + 1) * GAME_SECONDS_PER_QUESTION * 1000 - now) / 1000));
}

function scrambledWord(word, offset) {
  const letters = [...word];
  for (let i = letters.length - 1; i > 0; i--) {
    const j = (offset * 7 + i * 13 + 3) % (i + 1);
    [letters[i], letters[j]] = [letters[j], letters[i]];
  }
  const scrambled = letters.join("");
  return scrambled === word ? letters.reverse().join("") : scrambled;
}

export function gameQuestions({language, level, mode, seed}) {
  if (!GAME_LANGUAGE_CODES.includes(language) ||
      !GAME_LEVELS.includes(level) || !GAME_MODES.includes(mode)) {
    throw Object.assign(new Error("Unsupported room game selection."), {status: 400});
  }
  const bank = banks[language][level];
  const offset = Math.abs(seed) % bank.length;
  return Array.from({length: GAME_QUESTIONS_PER_SESSION}, (_, index) => {
    const [answer, definition] = bank[(offset + index) % bank.length];
    return {answer, definition,
      clue: mode === "guess" ? scrambledWord(answer, seed + index) : definition};
  });
}

export function canPlayGame(mode, {uid, hostId, role, seatIndex}) {
  if (mode === "vocabulary") return true;
  if (uid === hostId && role === "host") return true;
  return ["speaker", "coHost", "vipSeat"].includes(role) &&
    Number.isSafeInteger(seatIndex) && seatIndex >= 2 && seatIndex <= 8;
}
