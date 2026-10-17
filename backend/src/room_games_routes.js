import {randomUUID} from "node:crypto";
import {
  GAME_MODES, GAME_LEVELS, GAME_QUESTIONS_PER_SESSION,
  GAME_SECONDS_PER_QUESTION, GAME_SESSIONS_PER_DAY,
  GAME_POINTS_PER_CORRECT, roomGameLanguageCodes, gameQuestions,
  gameDay, gameIndex, gameTimeLeft, normalGameAnswer, canPlayGame,
} from "./room_games_policy.js";

function httpError(message, status) {
  return Object.assign(new Error(message), {status});
}
function memberValid(room, member) {
  const data = member.data() || {};
  return room.exists && room.data()?.isOpen === true && member.exists &&
    data.kicked !== true && data.role !== "teacherAi";
}
function gamePath(db, roomId) {
  if (!/^[a-zA-Z0-9_-]{1,128}$/.test(roomId ?? "")) {
    throw httpError("Invalid room ID.", 400);
  }
  return db.collection("rooms").doc(roomId);
}
function responseInfo({room, pointer, session, now, uid, member, scores,
  answered, winner, answerEvents = [], usage}) {
  const languages = roomGameLanguageCodes(room.data());
  const remaining = Object.fromEntries(GAME_MODES.map(mode => [
    mode, Math.max(0, GAME_SESSIONS_PER_DAY -
      (Number.isSafeInteger(usage[mode]) ? usage[mode] : 0)),
  ]));
  const data = session?.data();
  if (!data) return {ok: true, languages, remaining,
    active: false, hostId: room.data().hostId};
  const index = gameIndex(data.startedAtMs, now);
  const finished = index >= GAME_QUESTIONS_PER_SESSION;
  const item = finished ? null : data.questions[index];
  const winnerData = winner?.data() ?? null;
  const roundLocked = !finished && winnerData !== null;
  return {
    ok: true, languages, remaining, active: !finished, finished,
    hostId: room.data().hostId, mode: data.mode, level: data.level,
    language: data.language, sessionId: data.sessionId,
    totalWords: GAME_QUESTIONS_PER_SESSION, questionIndex: index,
    secondsLeft: gameTimeLeft(data.startedAtMs, now),
    canAnswer: !finished && !roundLocked && memberValid(room, member) &&
      canPlayGame(data.mode, {uid, hostId: room.data().hostId,
        role: member.data()?.role, seatIndex: member.data()?.seatIndex}),
    answered: Boolean(answered?.exists),
    // Verified public game chat: all in-room members see sent guesses and
    // correct/wrong verdicts, without exposing hidden word-bank answers.
    answerEvents: answerEvents.map(doc => ({
      id: doc.id,
      userId: doc.data().userId,
      name: doc.data().name,
      answer: doc.data().answer,
      correct: doc.data().correct === true,
      wordIndex: doc.data().wordIndex,
      submittedAtMs: doc.data().submittedAtMs,
    })),
    roundLocked,
    winner: roundLocked ? {
      userId: winnerData.userId,
      name: winnerData.name,
      answer: winnerData.answer,
      wordIndex: index,
    } : null,
    question: item ? {clue: item.clue,
      ...(data.mode === "guess" ? {scrambled: item.clue} : {})} : null,
    // Finished games may reveal their words; never reveal during an active round.
    ...(finished ? {solutions: data.questions.map(q => q.answer)} : {}),
    leaderboard: scores.map(doc => ({
      userId: doc.id,
      name: doc.data().name ?? "WorldVoice",
      points: doc.data().points ?? 0,
      correctCount: doc.data().correctCount ?? 0,
      firstCorrectAtMs: doc.data().firstCorrectAtMs ?? 0,
    })).filter(player => player.points > 0)
      .sort((left, right) =>
      right.points - left.points ||
      left.firstCorrectAtMs - right.firstCorrectAtMs ||
      left.userId.localeCompare(right.userId)),
  };
}

export function registerRoomGameRoutes({app, db, authenticatedUser,
  clock = Date.now, newId = randomUUID}) {
  app.get("/room/games/status", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomRef = gamePath(db, String(req.query.roomId ?? ""));
      const memberRef = roomRef.collection("participants").doc(user.uid);
      const pointerRef = roomRef.collection("private_games").doc("current");
      const [room, member, pointer] = await Promise.all([
        roomRef.get(), memberRef.get(), pointerRef.get(),
      ]);
      if (!memberValid(room, member)) throw httpError("Join the room first.", 403);
      const now = clock(), day = gameDay(now), usage = {};
      const usageResults = room.data().hostId === user.uid
        ? await Promise.all(GAME_MODES.map(mode => db.collection("users").doc(user.uid)
          .collection("game_usage").doc(day + "_" + mode).get()))
        : [];
      GAME_MODES.forEach((mode, i) => {
        usage[mode] = usageResults[i]?.data()?.count ?? 0;
      });
      const sessionId = pointer.data()?.sessionId;
      if (!sessionId) return res.json(responseInfo({
        room, member, pointer, session: null, now, uid: user.uid, scores: [], usage,
      }));
      const sessionRef = roomRef.collection("private_games").doc(sessionId);
      const session = await sessionRef.get();
      if (!session.exists) throw httpError("Room game requires reconciliation.", 409);
      const index = gameIndex(session.data().startedAtMs, now);
      const [scoreboard, answered, winner, eventList] = await Promise.all([
        sessionRef.collection("scores").orderBy("points", "desc").limit(10).get(),
        index < GAME_QUESTIONS_PER_SESSION
          ? sessionRef.collection("answers").doc(user.uid + "_" + index).get()
          : Promise.resolve(null),
        index < GAME_QUESTIONS_PER_SESSION
          ? sessionRef.collection("winners").doc("word_" + index).get()
          : Promise.resolve(null),
        sessionRef.collection("public_attempts")
          .orderBy("submittedAtMs", "desc").limit(25).get(),
      ]);
      return res.json(responseInfo({
        room, member, pointer, session, now, uid: user.uid,
        usage, scores: scoreboard.docs, answered, winner,
        answerEvents: eventList.docs,
      }));
    } catch (error) { next(error); }
  });

  app.post("/room/games/start", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const {roomId, mode, level, language} = req.body ?? {};
      const roomRef = gamePath(db, roomId);
      if (!GAME_MODES.includes(mode) || !GAME_LEVELS.includes(level)) {
        throw httpError("Choose a valid game and difficulty.", 400);
      }
      const now = clock(), day = gameDay(now);
      const pointerRef = roomRef.collection("private_games").doc("current");
      const usageRef = db.collection("users").doc(user.uid)
        .collection("game_usage").doc(day + "_" + mode);
      const room = await roomRef.get();
      if (!room.exists || room.data()?.isOpen !== true ||
        room.data()?.hostId !== user.uid) {
        throw httpError("Only the active room host may choose the game level.", 403);
      }
      const allowed = roomGameLanguageCodes(room.data());
      if (!allowed.includes(language)) {
        throw httpError("Use a supported language selected in room settings.", 422);
      }
      const sessionId = newId();
      const roundRef = roomRef.collection("private_games").doc(sessionId);
      const outcome = await db.runTransaction(async tx => {
        const [latest, member, pointer, usage] = await Promise.all([
          tx.get(roomRef), tx.get(roomRef.collection("participants").doc(user.uid)),
          tx.get(pointerRef), tx.get(usageRef),
        ]);
        if (latest.data()?.isOpen !== true || latest.data()?.hostId !== user.uid ||
            !memberValid(latest, member)) throw httpError("Host is not in the room.", 403);
        if (!roomGameLanguageCodes(latest.data()).includes(language)) {
          throw httpError("Room language changed. Refresh the game.", 409);
        }
        if (pointer.data()?.endAtMs > now) {
          throw httpError("Finish the previous five-word session first.", 409);
        }
        const count = usage.data()?.count ?? 0;
        if (!Number.isSafeInteger(count) || count < 0) {
          throw httpError("Game usage needs reconciliation.", 409);
        }
        if (count >= GAME_SESSIONS_PER_DAY) {
          throw httpError("Five free sessions of this game have been used today.", 429);
        }
        const questions = gameQuestions({mode, level, language,
          seed: Math.floor(now / 1000) + count * 17});
        tx.create(roundRef, {sessionId, hostId: user.uid, mode, level, language,
          startedAtMs: now, endsAtMs: now +
            GAME_SECONDS_PER_QUESTION * GAME_QUESTIONS_PER_SESSION * 1000,
          questions});
        tx.set(pointerRef, {sessionId,
          endAtMs: now + GAME_SECONDS_PER_QUESTION *
            GAME_QUESTIONS_PER_SESSION * 1000});
        tx.set(usageRef, {day, mode, count: count + 1, updatedAtMs: now});
        return {sessionId, used: count + 1};
      });
      return res.json({ok: true, ...outcome, questions: GAME_QUESTIONS_PER_SESSION,
        secondsPerQuestion: GAME_SECONDS_PER_QUESTION,
        remainingToday: GAME_SESSIONS_PER_DAY - outcome.used});
    } catch (error) { next(error); }
  });

  app.post("/room/games/answer", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const {roomId, sessionId, wordIndex, answer} = req.body ?? {};
      const roomRef = gamePath(db, roomId);
      if (!/^[a-zA-Z0-9_-]{1,128}$/.test(sessionId ?? "") ||
          !Number.isInteger(wordIndex) || wordIndex < 0 ||
          wordIndex >= GAME_QUESTIONS_PER_SESSION ||
          typeof answer !== "string" || !answer.trim() ||
          answer.length > 80) {
        throw httpError("Invalid word game answer.", 400);
      }
      const pointerRef = roomRef.collection("private_games").doc("current");
      const roundRef = roomRef.collection("private_games").doc(sessionId);
      const attemptRef = roundRef.collection("answers").doc(user.uid + "_" + wordIndex);
      const publicAttemptRef = roundRef.collection("public_attempts")
        .doc(user.uid + "_" + wordIndex);
      const scoreRef = roundRef.collection("scores").doc(user.uid);
      const winnerRef = roundRef.collection("winners").doc("word_" + wordIndex);
      const now = clock();
      const result = await db.runTransaction(async tx => {
        const [room, member, pointer, round, attempt, score, winner, profile] =
          await Promise.all([
            tx.get(roomRef), tx.get(roomRef.collection("participants").doc(user.uid)),
            tx.get(pointerRef), tx.get(roundRef), tx.get(attemptRef),
            tx.get(scoreRef), tx.get(winnerRef),
            tx.get(db.collection("users").doc(user.uid)),
          ]);
        if (!memberValid(room, member)) throw httpError("Join the room first.", 403);
        if (!round.exists || pointer.data()?.sessionId !== sessionId) {
          throw httpError("This round is no longer active.", 409);
        }
        const data = round.data();
        if (data.hostId !== room.data().hostId) {
          throw httpError("Room host changed; restart the game.", 409);
        }
        if (!canPlayGame(data.mode, {
          uid: user.uid, hostId: room.data().hostId,
          role: member.data()?.role, seatIndex: member.data()?.seatIndex,
        })) throw httpError("Only participants on stage may guess the word.", 403);
        if (gameIndex(data.startedAtMs, now) !== wordIndex) {
          throw httpError("The 30-second word window has closed.", 409);
        }
        if (attempt.exists) return {alreadySubmitted: true};
        // The first correct answer wins this word. Every answer submission
        // reads the same winner document inside one Firestore transaction:
        // concurrent correct attempts cannot both win, even across servers.
        if (winner.exists) {
          return {roundClosed: true, winnerName: winner.data()?.name ?? ""};
        }
        const correct = normalGameAnswer(answer) ===
          normalGameAnswer(data.questions[wordIndex].answer);
        const priorScore = score.data()?.points ?? 0;
        if (!Number.isSafeInteger(priorScore) || priorScore < 0 ||
            priorScore > GAME_QUESTIONS_PER_SESSION * GAME_POINTS_PER_CORRECT) {
          throw httpError("Invalid score requires reconciliation.", 409);
        }
        const priorCorrectCount = score.data()?.correctCount ?? 0;
        if (!Number.isSafeInteger(priorCorrectCount) ||
            priorCorrectCount < 0 || priorCorrectCount > GAME_QUESTIONS_PER_SESSION) {
          throw httpError("Invalid correct answer count.", 409);
        }
        const pointsAwarded = correct ? GAME_POINTS_PER_CORRECT : 0;
        const name = String(profile.data()?.displayName ?? "WorldVoice user")
          .slice(0, 60);
        tx.create(attemptRef, {uid: user.uid, wordIndex, submittedAtMs: now,
          correct, pointsAwarded});
        // Only a verified submission is shown; losers are not publicly
        // marked correct. Each answer appears once and can never be edited.
        tx.create(publicAttemptRef, {
          userId: user.uid, name, wordIndex,
          answer: answer.trim().replace(/[\r\n\t]+/g, " ").slice(0, 80),
          correct, submittedAtMs: now,
        });
        if (correct) {
          tx.create(winnerRef, {userId: user.uid, name,
            answer: data.questions[wordIndex].answer, wordIndex,
            correctAtMs: now});
        }
        tx.set(scoreRef, {points: priorScore + pointsAwarded,
          correctCount: priorCorrectCount + (correct ? 1 : 0),
          firstCorrectAtMs: (score.data()?.firstCorrectAtMs ?? 0) > 0
            ? score.data().firstCorrectAtMs : (correct ? now : 0),
          name, lastAnsweredAtMs: now});
        return {alreadySubmitted: false, correct, pointsAwarded,
          roundClosed: correct, winnerName: correct ? name : null,
          correctCount: priorCorrectCount + (correct ? 1 : 0),
          totalPoints: priorScore + pointsAwarded};
      });
      return res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });
}
