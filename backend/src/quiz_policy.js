// Policy shared by authenticated quiz handlers and dependency-free tests.
// Secure round answers and correctIndex must never enter readable room data.
export function quizQuestion(input) {
  const question = String(input?.question || "").trim();
  const options = input?.options;
  const correctIndex = input?.correctIndex;
  if (question.length < 1 || question.length > 500 ||
      !Array.isArray(options) || options.length < 2 || options.length > 4 ||
      !options.every(value => typeof value === "string" &&
        value.trim().length > 0 && value.trim().length <= 140) ||
      !Number.isInteger(correctIndex) ||
      correctIndex < 0 || correctIndex >= options.length) {
    throw Object.assign(new Error("Invalid quiz question, options or answer."), {status: 400});
  }
  const cleaned = options.map(value => value.trim());
  if (new Set(cleaned.map(value => value.toLocaleLowerCase())).size !== cleaned.length) {
    throw Object.assign(new Error("Quiz options must be distinct."), {status: 400});
  }
  return {question, options: cleaned, correctIndex};
}

export function quizChoice(index, optionCount) {
  if (!Number.isInteger(index) || index < 0 || index >= optionCount) {
    throw Object.assign(new Error("Invalid answer choice."), {status: 400});
  }
  return index;
}

export function matchesPrivateRound(publicQuiz, secret, roundId) {
  if (!secret || secret.roundId !== roundId ||
      publicQuiz?.roundId !== roundId ||
      publicQuiz?.secure !== true || publicQuiz?.practiceOnly === true ||
      publicQuiz?.question !== secret.question ||
      JSON.stringify(publicQuiz?.options) !== JSON.stringify(secret.options)) {
    throw Object.assign(new Error("The quiz round does not match its private server record."), {status: 409});
  }
  return true;
}

export function rankVerifiedAnswers(answers, correctIndex) {
  return answers.filter(row => Number.isInteger(row.selectedIndex) &&
    row.selectedIndex === correctIndex && row.isCorrect === true)
    .sort((a, b) => a.answeredAt - b.answeredAt ||
      a.userId.localeCompare(b.userId))
    .slice(0, 3)
    .map((row, index) => ({
      place: index + 1, userId: row.userId,
      displayName: row.displayName || "WorldVoice user",
    }));
}

export function approvedQuizPrize(config) {
  // Both owner launch flags are explicit. No prizes when the app is free,
  // before wallet privacy migration or while monetary config is incomplete.
  if (!config || config.enabled !== true || config.quizRewardsEnabled !== true) return 0;
  if (config.walletSchemaVersion !== 2 ||
      !Number.isSafeInteger(config.quizFirstPrizeCoins) ||
      config.quizFirstPrizeCoins < 1 || config.quizFirstPrizeCoins > 100000) {
    throw Object.assign(new Error("Quiz reward configuration or private wallet migration is incomplete."), {status: 503});
  }
  return config.quizFirstPrizeCoins;
}
