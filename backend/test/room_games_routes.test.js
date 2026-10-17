import test from "node:test";
import assert from "node:assert/strict";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {registerRoomGameRoutes} from "../src/room_games_routes.js";

// Transactions and quotas are tested on a demo emulator, never production.
test("games routes: immutable answers, role access and host-only free quota",
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async t => {
  const app = initializeApp({projectId: "demo-worldvoice-rules"}, "games-tests");
  const db = getFirestore(app);
  const routes = new Map();
  let now = Date.UTC(2026, 9, 17, 10, 0, 0);
  let seq = 0;
  registerRoomGameRoutes({db, app: {
    get: (p, h) => routes.set(p, h), post: (p, h) => routes.set(p, h),
  }, authenticatedUser: async req => ({uid: req.uid}),
  clock: () => now, newId: () => "round-" + (++seq)});
  const roomId = "games-emulator-room";
  const room = db.collection("rooms").doc(roomId);
  async function request(path, caller, body = {}) {
    let result;
    const res = {statusCode: 200, status(n) {this.statusCode = n; return this;},
      json(value) {result = {status: this.statusCode, body: value}; return this;}};
    await routes.get("/room/games/" + path)({uid: caller,
      body: {roomId, ...body}, query: {roomId}}, res,
      e => {result = {status: e.status ?? 500, body: {error: e.message}};});
    return result;
  }
  try {
    await room.set({hostId: "game-host", isOpen: true, languageCode: "en"});
    for (const [id, role, seatIndex] of [
      ["game-host", "host", 1], ["game-listener", "listener", null],
      ["game-speaker", "speaker", 2]]) {
      await room.collection("participants").doc(id).set({
        role, ...(seatIndex != null ? {seatIndex} : {}),
        kicked: false, updatedAt: Timestamp.fromMillis(now),
      });
      await db.collection("users").doc(id).set({displayName: id});
    }
    await t.test("only host chooses game, level and room language", async () => {
      assert.equal((await request("start", "game-listener",
        {mode: "vocabulary", level: "beginner", language: "en"})).status, 403);
      assert.equal((await request("start", "game-host",
        {mode: "vocabulary", level: "beginner", language: "fr"})).status, 422);
      const start = await request("start", "game-host",
        {mode: "vocabulary", level: "beginner", language: "en"});
      assert.equal(start.status, 200);
      assert.equal(start.body.remainingToday, 4);
      assert.equal((await request("start", "game-host",
        {mode: "vocabulary", level: "advanced", language: "en"})).status, 409);
      const status = await request("status", "game-listener");
      assert.equal(status.body.active, true);
      assert.equal(status.body.questionIndex, 0);
      assert.equal(status.body.canAnswer, true);
      assert.equal(status.body.secondsLeft, 30);
      assert.ok(!JSON.stringify(status.body).includes('"answer"'));
      assert.ok(status.body.question.clue.length > 3);
    });
    await t.test("first answer only, no client-granted currency and no duplicate score", async () => {
      const round = (await request("status", "game-listener")).body;
      const correct = (await room.collection("private_games")
        .doc(round.sessionId).get()).data().questions[0].answer;
      const result = await request("answer", "game-listener", {
        sessionId: round.sessionId, wordIndex: 0, answer: correct.toUpperCase()});
      assert.equal(result.status, 200);
      assert.equal(result.body.pointsAwarded, 10);
      assert.equal(result.body.correctCount, 1);
      assert.equal(result.body.roundClosed, true);
      const winner = (await request("status", "game-speaker")).body;
      assert.equal(winner.roundLocked, true);
      assert.equal(winner.canAnswer, false);
      assert.equal(winner.winner.name, "game-listener");
      assert.equal(winner.winner.answer, correct);
      assert.equal(winner.answerEvents.length, 1);
      assert.equal(winner.answerEvents[0].answer, correct.toUpperCase());
      assert.equal(winner.answerEvents[0].correct, true);
      const repeat = await request("answer", "game-listener", {
        sessionId: round.sessionId, wordIndex: 0, answer: correct});
      assert.equal(repeat.body.alreadySubmitted, true);
      assert.equal((await room.collection("private_games").doc(round.sessionId)
        .collection("scores").doc("game-listener").get()).data().points, 10);
      const blocked = await request("answer", "game-speaker", {
        sessionId: round.sessionId, wordIndex: 0, answer: "badanswer"});
      assert.equal(blocked.status, 200);
      assert.equal(blocked.body.roundClosed, true);
      assert.equal(blocked.body.pointsAwarded, undefined);
      assert.equal((await request("status", "game-host")).body.answerEvents.length, 1);
      const board = await request("status", "game-host");
      assert.equal(board.body.leaderboard[0].points, 10);
      assert.equal(board.body.leaderboard[0].correctCount, 1);
      assert.equal((await db.collection("users").doc("game-listener").get()).data().coins, undefined);
    });
    await t.test("two simultaneous correct answers award exactly one winner", async () => {
      now += 30000;
      const round = (await request("status", "game-listener")).body;
      assert.equal(round.questionIndex, 1);
      assert.equal(round.roundLocked, false);
      const correct = (await room.collection("private_games")
        .doc(round.sessionId).get()).data().questions[1].answer;
      const wrong = await request("answer", "game-host", {
        sessionId: round.sessionId, wordIndex: 1,
        answer: "   definitely-not-the-answer   "});
      assert.equal(wrong.body.correct, false);
      assert.equal(wrong.body.roundClosed, false);
      const visibleWrong = (await request("status", "game-speaker")).body.answerEvents;
      assert.equal(visibleWrong[0].name, "game-host");
      assert.equal(visibleWrong[0].answer, "definitely-not-the-answer");
      assert.equal(visibleWrong[0].correct, false);
      const [first, second] = await Promise.all([
        request("answer", "game-listener", {
          sessionId: round.sessionId, wordIndex: 1, answer: correct}),
        request("answer", "game-speaker", {
          sessionId: round.sessionId, wordIndex: 1, answer: correct}),
      ]);
      assert.equal([first, second].filter(x => x.body.pointsAwarded === 10).length, 1);
      assert.equal([first, second].filter(x => x.body.roundClosed === true).length, 2);
      const scoreboard = (await request("status", "game-host")).body;
      assert.equal(scoreboard.winner.wordIndex, 1);
      assert.equal(scoreboard.answerEvents.length, 3);
      assert.equal(scoreboard.answerEvents.filter(a => a.correct).length, 2);
      assert.equal(scoreboard.answerEvents.filter(a => !a.correct).length, 1);
      assert.equal(scoreboard.answerEvents.filter(a => a.wordIndex === 1 && a.correct).length, 1);
      const scores = await room.collection("private_games").doc(round.sessionId)
        .collection("scores").get();
      assert.equal(scores.docs.reduce((sum, x) => sum + x.data().points, 0), 20);
      const winners = await room.collection("private_games").doc(round.sessionId)
        .collection("winners").get();
      assert.equal(winners.size, 2);
    });
    await t.test("five words, 30 seconds each; correct words never leak early", async () => {
      const session = (await request("status", "game-listener")).body.sessionId;
      // Advance beyond the second word won by the prior concurrent test.
      now += 30000;
      assert.equal((await request("answer", "game-listener", {
        sessionId: session, wordIndex: 0, answer: "late"})).status, 409);
      assert.equal((await request("status", "game-listener")).body.questionIndex, 2);
      now += 90000;
      const finish = await request("status", "game-listener");
      assert.equal(finish.body.finished, true);
      assert.equal(finish.body.solutions.length, 5);
    });
    await t.test("guess mode is stage-only; different mode has separate quota", async () => {
      const guess = await request("start", "game-host", {
        mode: "guess", level: "intermediate", language: "en"});
      assert.equal(guess.status, 200);
      const state = await request("status", "game-listener");
      assert.equal(state.body.mode, "guess");
      assert.equal(state.body.canAnswer, false);
      assert.equal((await request("answer", "game-listener", {
        sessionId: guess.body.sessionId, wordIndex: 0, answer: "library"})).status, 403);
      assert.equal((await request("status", "game-speaker")).body.canAnswer, true);
      const ok = await request("answer", "game-speaker", {
        sessionId: guess.body.sessionId, wordIndex: 0, answer: "wrong"});
      assert.equal(ok.status, 200);
    });
    await t.test("five free starts per game per UTC day across rooms", async () => {
      // Previous mode uses one start, then exactly four are left.
      for (let i = 0; i < 4; i++) {
        now += 150000;
        assert.equal((await request("start", "game-host", {
          mode: "guess", level: "beginner", language: "en"})).status, 200);
      }
      now += 150000;
      assert.equal((await request("start", "game-host", {
        mode: "guess", level: "beginner", language: "en"})).status, 429);
      // Vocabulary still has its own independent daily allowance.
      assert.equal((await request("start", "game-host", {
        mode: "vocabulary", level: "advanced", language: "en"})).status, 200);
    });
    await t.test("only host closes a game, resets room mode and preserves usage", async () => {
      const current = await request("status", "game-host");
      assert.ok(current.sessionId);
      const wrong = await request("close", "game-speaker",
        {sessionId: current.sessionId});
      assert.equal(wrong.status, 403);
      const stale = await request("close", "game-host",
        {sessionId: "another-round"});
      assert.equal(stale.status, 409);
      assert.equal((await request("status", "game-host")).body.sessionId,
        current.sessionId);
      const result = await request("close", "game-host",
        {sessionId: current.sessionId});
      assert.equal(result.status, 200);
      assert.equal(result.body.closed, true);
      const idle = await request("status", "game-listener");
      assert.equal(idle.body.active, false);
      assert.equal(idle.body.sessionId, undefined);
      assert.equal(idle.body.remaining.vocabulary, 5);
      const usage = await db.collection("users").doc("game-host")
        .collection("game_usage").doc("2026-10-17_vocabulary").get();
      assert.equal(usage.data()?.count, 2);
      const oldRound = await room.collection("private_games")
        .doc(current.sessionId).get();
      assert.equal(oldRound.exists, true);
      assert.equal((await request("close", "game-host",
        {sessionId: current.sessionId})).body.alreadyClosed, true);
    });
    await t.test("inactive room or kicked listener cannot play", async () => {
      await room.collection("participants").doc("game-listener").update({kicked: true});
      assert.equal((await request("status", "game-listener")).status, 403);
      await room.update({isOpen: false});
      assert.equal((await request("start", "game-host",
        {mode: "vocabulary", level: "beginner", language: "en"})).status, 403);
    });
  } finally {
    await room.delete().catch(() => {});
    await deleteApp(app);
  }
});
