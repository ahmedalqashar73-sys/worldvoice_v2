import test from "node:test";
import assert from "node:assert/strict";
import {sortedQuizWinners, rewardPolicy} from "../src/quiz_routes.js";

const answer = (id, roundId, optionIndex, timestamp) => ({
  id,
  data: () => ({
    userId: id, displayName: id, roundId, optionIndex,
    answeredAt: {toMillis: () => timestamp},
  }),
});

test("only sealed-round correct answers win, ordered by immutable timestamp", () => {
  const winners = sortedQuizWinners([
    answer("late", "round-a", 1, 300),
    answer("old", "round-old", 1, 1),
    answer("wrong", "round-a", 0, 2),
    answer("fast", "round-a", 1, 100),
    answer("middle", "round-a", 1, 200),
    answer("fourth", "round-a", 1, 400),
  ], 1, "round-a");
  assert.deepEqual(winners.map(w => w.userId), ["fast", "middle", "late"]);
  assert.ok(winners.every(w => w.prizeCoins === 0));
});

test("no coin awards without sealed eligible round and approved risk limit", () => {
  const config = {
    enabled: true, quizRewardsEnabled: true,
    quizFirstPrizeCoins: 5, quizDailyRewardCapCoins: 15,
  };
  assert.deepEqual(rewardPolicy(config, {rewardEligible: true}),
    {prize: 5, cap: 15});
  assert.equal(rewardPolicy(config, {rewardEligible: false}), null);
  assert.equal(rewardPolicy({...config, enabled: false},
    {rewardEligible: true}), null);
  assert.equal(rewardPolicy({...config, quizDailyRewardCapCoins: null},
    {rewardEligible: true}), null);
  assert.equal(rewardPolicy({...config, quizDailyRewardCapCoins: 4},
    {rewardEligible: true}), null);
});
