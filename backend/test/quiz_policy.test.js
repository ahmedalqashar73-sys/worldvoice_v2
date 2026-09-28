import test from "node:test";
import assert from "node:assert/strict";
import {quizQuestion, quizChoice, matchesPrivateRound, rankVerifiedAnswers, approvedQuizPrize} from "../src/quiz_policy.js";

test("quiz policy validates question, distinct options and index", () => {
  assert.deepEqual(quizQuestion({question:" Question? ", options:[" One ","Two"], correctIndex:1}),
    {question:"Question?", options:["One","Two"], correctIndex:1});
  assert.throws(() => quizQuestion({question:"?", options:["A","a"], correctIndex:0}));
  assert.throws(() => quizQuestion({question:"?", options:["A","B"], correctIndex:2}));
  assert.throws(() => quizChoice(-1,2));
  assert.equal(quizChoice(1,2),1);
});
test("server round binding prevents public Firestore answer-key changes", () => {
  const secret={roundId:"server-round",question:"2+2",options:["3","4"]};
  assert.equal(matchesPrivateRound({secure:true,roundId:"server-round",question:"2+2",options:["3","4"]},secret,"server-round"),true);
  assert.throws(() => matchesPrivateRound({secure:true,roundId:"server-round",question:"2+2",options:["4","3"]},secret,"server-round"));
  assert.throws(() => matchesPrivateRound({secure:false,roundId:"server-round",question:"2+2",options:["3","4"]},secret,"server-round"));
});
test("only server-verified correct choices rank; first three by server time", () => {
  assert.deepEqual(rankVerifiedAnswers([
    {userId:"fake",selectedIndex:1,isCorrect:false,answeredAt:1},
    {userId:"late",selectedIndex:1,isCorrect:true,answeredAt:4},
    {userId:"first",selectedIndex:1,isCorrect:true,answeredAt:2},
    {userId:"second",selectedIndex:1,isCorrect:true,answeredAt:3},
    {userId:"fourth",selectedIndex:1,isCorrect:true,answeredAt:5},
  ],1).map(x=>x.userId),["first","second","late"]);
});
test("rewards disabled until explicit approved private wallet readiness", () => {
  assert.equal(approvedQuizPrize({enabled:false,quizRewardsEnabled:true,quizFirstPrizeCoins:5}),0);
  assert.equal(approvedQuizPrize({enabled:true,quizRewardsEnabled:false,quizFirstPrizeCoins:5}),0);
  assert.throws(() => approvedQuizPrize({enabled:true,quizRewardsEnabled:true,quizFirstPrizeCoins:5,walletSchemaVersion:1}));
  assert.equal(approvedQuizPrize({enabled:true,quizRewardsEnabled:true,quizFirstPrizeCoins:5,walletSchemaVersion:2}),5);
});
