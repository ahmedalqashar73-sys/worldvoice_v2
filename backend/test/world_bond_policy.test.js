import test from "node:test";
import assert from "node:assert/strict";
import {
  BOND_TYPES, bondKey, bondLevel, exerciseForDay, worldBondExercises,
} from "../src/world_bond_routes.js";

test("WorldBond never conflates two unrelated users or relationship types", () => {
  const one = bondKey("user_alpha_123", "user_beta_456", "friend");
  assert.match(one, /^[a-f0-9]{64}$/);
  assert.equal(one, bondKey("user_beta_456", "user_alpha_123", "friend"));
  assert.notEqual(one, bondKey("user_alpha_123", "user_beta_456", "duo"));
  assert.notEqual(one, bondKey("user_alpha_123", "user_gamma_789", "friend"));
  assert.deepEqual(BOND_TYPES, ["language", "friend", "duo"]);
});

test("WorldBond levels use non-monetary progression thresholds", () => {
  assert.equal(bondLevel(0), 1);
  assert.equal(bondLevel(199), 1);
  assert.equal(bondLevel(200), 2);
  assert.equal(bondLevel(599), 2);
  assert.equal(bondLevel(600), 3);
  assert.equal(bondLevel(1200), 4);
  assert.equal(bondLevel(2200), 5);
});

test("Daily educational quiz is deterministic for the same pair and UTC day", () => {
  const id = bondKey("user_alpha_123", "user_beta_456", "language");
  const first = exerciseForDay(id, "2026-10-29");
  assert.equal(first, exerciseForDay(id, "2026-10-29"));
  assert.ok(worldBondExercises.includes(first));
  for (const quiz of worldBondExercises) {
    assert.equal(quiz.choices.length, 3);
    assert.ok(quiz.answer >= 0 && quiz.answer <= 2);
    assert.ok(quiz.explanation.length > 0);
  }
});
