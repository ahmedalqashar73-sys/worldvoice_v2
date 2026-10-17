import test from "node:test";
import assert from "node:assert/strict";
import {
  GAME_POINTS_PER_CORRECT, GAME_QUESTIONS_PER_SESSION,
  GAME_SECONDS_PER_QUESTION, GAME_SESSIONS_PER_DAY,
  canPlayGame, gameQuestions, gameIndex, gameTimeLeft,
  normalGameAnswer, roomGameLanguageCodes,
} from "../src/room_games_policy.js";

test("room language determines game content (not device locale)", () => {
  assert.deepEqual(roomGameLanguageCodes({languageCode: "fr"}), ["fr"]);
  assert.deepEqual(roomGameLanguageCodes({languageCode: "es-MX"}), ["es"]);
  assert.deepEqual(roomGameLanguageCodes({languageCode: "zh-CN"}), ["zh"]);
  assert.deepEqual(roomGameLanguageCodes({languageCode: "ko-KR"}), ["ko"]);
  assert.deepEqual(roomGameLanguageCodes({languageCodes: ["fr", "es", "zh", "ko"]}),
    ["fr", "es", "zh", "ko"]);
  assert.deepEqual(roomGameLanguageCodes({languageCodes: ["ar", "en"]}), ["ar", "en"]);
  assert.deepEqual(roomGameLanguageCodes({languageCode: "ja"}), []);
  for (const lang of ["ar", "en", "es", "zh", "ko", "fr"]) for (const level of ["beginner", "intermediate", "advanced"]) {
    for (const mode of ["vocabulary", "guess"]) {
      const questions = gameQuestions({language: lang, level, mode, seed: 11});
      assert.equal(questions.length, GAME_QUESTIONS_PER_SESSION);
      assert.ok(questions.every(q => q.answer.length > 1 && q.clue.length >= 2));
      if (mode === "vocabulary") assert.ok(questions.every(q => q.clue === q.definition));
      else assert.ok(questions.every(q => q.clue !== q.answer));
    }
  }
});
test("correct answers are normalized without guessing new lexical identity", () => {
  assert.equal(normalGameAnswer("  LIBRARY  "), "library");
  assert.equal(normalGameAnswer("مَكْتَبَة"), "مكتبة");
  assert.equal(normalGameAnswer("Bibliothèque"), "bibliothèque");
});
test("host selects level, server caps time and daily rounds", () => {
  assert.equal(GAME_SECONDS_PER_QUESTION, 30);
  assert.equal(GAME_SESSIONS_PER_DAY, 5);
  assert.equal(GAME_POINTS_PER_CORRECT, 10);
  const start = 1700000000000;
  assert.equal(gameIndex(start, start), 0);
  assert.equal(gameTimeLeft(start, start), 30);
  assert.equal(gameIndex(start, start + 29999), 0);
  assert.equal(gameIndex(start, start + 30000), 1);
  assert.equal(gameIndex(start, start + 150000), 5);
  assert.equal(gameTimeLeft(start, start + 150000), 0);
});
test("vocabulary includes listeners; guess is stage-only", () => {
  const listener = {uid: "visitor", hostId: "host", role: "listener"};
  assert.equal(canPlayGame("vocabulary", listener), true);
  assert.equal(canPlayGame("guess", listener), false);
  assert.equal(canPlayGame("guess", {...listener, role: "speaker", seatIndex: 2}), true);
  assert.equal(canPlayGame("guess", {...listener, role: "speaker", seatIndex: 12}), false);
  assert.equal(canPlayGame("guess", {uid: "host", hostId: "host", role: "host"}), true);
});

test("all six languages have 25 unique words at every graded difficulty", () => {
  for (const language of ["ar", "en", "es", "zh", "ko", "fr"]) {
    for (const level of ["beginner", "intermediate", "advanced"]) {
      const seen = new Set();
      for (let seed = 0; seed < 25; seed++) {
        const vocab = gameQuestions({language, level, mode: "vocabulary", seed});
        assert.equal(vocab.length, 5);
        const first = vocab[0];
        assert.ok(first.answer.length >= 2, language + ":" + level + ":" + seed);
        assert.ok(first.definition.length >= 15);
        assert.equal(normalGameAnswer(first.answer), normalGameAnswer(first.answer));
        seen.add(first.answer);
        const guess = gameQuestions({language, level, mode: "guess", seed});
        assert.equal(guess.length, 5);
        for (const item of guess) {
          assert.notEqual(item.clue, item.answer);
          assert.deepEqual([...item.clue].sort(), [...item.answer].sort());
        }
      }
      assert.equal(seen.size, 25,
        language + "/" + level + " needs 25 distinct answers");
    }
  }
});
