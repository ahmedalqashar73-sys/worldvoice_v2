import test from "node:test";
import assert from "node:assert/strict";
import {validateQuizDraft, quizWinners} from "../src/quiz_policy.js";

const timestamp = millis => ({toMillis: () => millis});

test("server quiz draft strips spaces but keeps answer private", () => {
  assert.deepEqual(validateQuizDraft({
    question: "  Bonjour? ", options: ["  yes  ", " no "], correctIndex: 0,
  }), {question: "Bonjour?", options: ["yes", "no"], correctIndex: 0});
  assert.throws(() => validateQuizDraft({
    question: "Unsafe?", options: ["", "ok"], correctIndex: 1,
  }), /Invalid quiz/);
  assert.throws(() => validateQuizDraft({
    question: "Unsafe?", options: ["a", "b"], correctIndex: 5,
  }), /Invalid quiz/);
});

test("winner results only score the current round, created after it started", () => {
  const answers = [
    {roundId: "old", userId: "a", optionIndex: 1, answeredAt: timestamp(120)},
    {roundId: "current", userId: "b", optionIndex: 1, answeredAt: timestamp(99)},
    {roundId: "current", userId: "c", optionIndex: 0, answeredAt: timestamp(101)},
    {roundId: "current", userId: "d", optionIndex: 1, answeredAt: timestamp(105)},
    {roundId: "current", userId: "e", optionIndex: 1, answeredAt: timestamp(103)},
    {roundId: "current", userId: "f", optionIndex: 1, answeredAt: timestamp(106)},
    {roundId: "current", userId: "g", optionIndex: 1, answeredAt: timestamp(107)},
  ];
  const winners = quizWinners({
    answers, correctIndex: 1, startedAt: timestamp(100), roundId: "current",
  });
  assert.deepEqual(winners.map(w => w.userId), ["e", "d", "f"]);
  assert.ok(winners.every(w => w.prizeCoins === 0));
});

test("quiz without trusted startedAt or roundId cannot award anyone", () => {
  const answer = [{roundId: "x", userId: "user", optionIndex: 1,
    answeredAt: timestamp(101)}];
  assert.deepEqual(quizWinners({
    answers: answer, correctIndex: 1, startedAt: null, roundId: "x",
  }), []);
  assert.deepEqual(quizWinners({
    answers: answer, correctIndex: 1, startedAt: timestamp(100), roundId: "",
  }), []);
});
