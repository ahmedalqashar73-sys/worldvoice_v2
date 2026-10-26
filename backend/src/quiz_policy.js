// The client-visible room quiz must NEVER determine economic rewards.
// Server-only quiz answers live in rooms/{id}/quiz_private/current.
export function validateQuizDraft({question, options, correctIndex}) {
  const normalized = String(question || "").trim();
  if (!normalized || normalized.length > 500 ||
      !Array.isArray(options) || options.length < 2 || options.length > 4 ||
      options.some(value => typeof value !== "string" ||
        !value.trim() || value.trim().length > 220) ||
      !Number.isInteger(correctIndex) ||
      correctIndex < 0 || correctIndex >= options.length) {
    const error = new Error("Invalid quiz question or options.");
    error.status = 400;
    throw error;
  }
  return {question: normalized, options: options.map(v => v.trim()), correctIndex};
}

// Accept only answers created during this exact round. One answer/member.
// This function is deliberately independent from wallet writes.
export function quizWinners({answers, correctIndex, startedAt, roundId, limit = 3}) {
  const startedMillis = startedAt?.toMillis?.();
  if (!Number.isFinite(startedMillis) || !roundId) return [];
  return answers
    .filter(a => a && a.roundId === roundId &&
      Number.isInteger(a.optionIndex) && a.optionIndex === correctIndex &&
      a.answeredAt?.toMillis?.() >= startedMillis &&
      typeof a.userId === "string" && a.userId)
    .sort((a, b) => a.answeredAt.toMillis() - b.answeredAt.toMillis() ||
      a.userId.localeCompare(b.userId))
    .slice(0, limit)
    .map((a, index) => ({
      place: index + 1,
      userId: a.userId,
      displayName: String(a.displayName || "WorldVoice user").slice(0, 90),
      prizeCoins: 0, // Monetary prizes require a private wallet rollout.
    }));
}
