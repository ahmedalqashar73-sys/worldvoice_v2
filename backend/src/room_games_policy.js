// Room language game content is reviewed, static and independent of LLM costs.
// Five prompts per session, 30 seconds each, 5 free sessions per mode/day/host.
export const GAME_MODES = Object.freeze(["vocabulary", "guess"]);
export const GAME_LEVELS = Object.freeze(["beginner", "intermediate", "advanced"]);
export const GAME_LANGUAGE_CODES = Object.freeze(["ar", "en", "fr"]);
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
