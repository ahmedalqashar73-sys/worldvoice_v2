import {randomUUID, createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {walletRef, requireMigratedWallet} from "./wallet_schema.js";

const fail = (message, status = 409) => {
  throw Object.assign(new Error(message), {status});
};
const safeCoinCount = value => Number.isSafeInteger(value) && value >= 0;
const dayKey = () => new Date().toISOString().slice(0, 10);

// Only the backend may read the answer key. No amount of client-side
// Firestore access can reveal a payable quiz answer before finalization.
export function sortedQuizWinners(answerDocs, correctIndex, roundId) {
  return answerDocs.map(doc => ({id: doc.id, ...doc.data()}))
    .filter(answer => answer.roundId === roundId &&
      Number(answer.optionIndex) === correctIndex)
    .sort((a, b) => {
      const first = a.answeredAt?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;
      const second = b.answeredAt?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;
      return first - second || a.id.localeCompare(b.id);
    })
    .slice(0, 3)
    .map((a, index) => ({
      place: index + 1, userId: String(a.userId || a.id),
      displayName: String(a.displayName || "WorldVoice user"),
      prizeCoins: 0,
    }));
}

export function rewardPolicy(config, secret) {
  const prize = Number(config?.quizFirstPrizeCoins);
  const cap = Number(config?.quizDailyRewardCapCoins);
  if (secret?.rewardEligible !== true || config?.enabled !== true ||
      config?.quizRewardsEnabled !== true || !safeCoinCount(prize) ||
      !safeCoinCount(cap) || prize <= 0 || cap < prize) return null;
  return {prize, cap};
}

export function registerQuizRoutes({app, db, authenticatedUser}) {
  app.post("/quiz/start", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const {roomId, question, options, correctIndex} = req.body || {};
      if (typeof roomId !== "string" || !/^[A-Za-z0-9_-]{1,120}$/.test(roomId) ||
          typeof question !== "string" || !question.trim() ||
          question.length > 400 || !Array.isArray(options) ||
          options.length < 2 || options.length > 4 ||
          !options.every(v => typeof v === "string" &&
            v.trim().length > 0 && v.length <= 160) ||
          !Number.isInteger(correctIndex) || correctIndex < 0 ||
          correctIndex >= options.length) {
        return res.status(400).json({error: "Invalid quiz question."});
      }

      const roomRef = db.collection("rooms").doc(roomId);
      const secretRef = db.collection("room_quiz_secrets").doc(roomId);
      const [room, config] = await Promise.all([
        roomRef.get(), db.doc("economy_config/current").get(),
      ]);
      if (!room.exists || room.data()?.isOpen !== true ||
          room.data()?.hostId !== user.uid) fail("Only the open-room host can start a quiz.", 403);
      const roundId = randomUUID();
      const rewardEligible = config.data()?.enabled === true &&
        config.data()?.quizRewardsEnabled === true &&
        rewardPolicy(config.data(), {rewardEligible: true}) != null;
      // All previous votes must be removed together with the new question.
      // Fail instead of partially clearing a room with unusually many votes.
      const previous = await roomRef.collection("quiz_answers").limit(451).get();
      if (previous.size > 450) fail("Too many quiz answers to reset safely.", 409);
      const batch = db.batch();
      for (const vote of previous.docs) batch.delete(vote.ref);
      batch.set(secretRef, {
        roundId, correctIndex, rewardEligible, createdBy: user.uid,
        createdAt: FieldValue.serverTimestamp(),
      });
      batch.update(roomRef, {
        quiz: {
          roundId, secure: true, acceptingAnswers: true,
          question: question.trim(),
          options: options.map(v => v.trim()), revealed: false,
          startedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      });
      await batch.commit();
      res.json({ok: true, roundId, rewardEligible});
    } catch (error) {next(error);}
  });

  app.post("/quiz/finish", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomId = String(req.body?.roomId || "").trim();
      if (!/^[A-Za-z0-9_-]{1,120}$/.test(roomId)) {
        return res.status(400).json({error: "Valid roomId is required."});
      }
      const roomRef = db.collection("rooms").doc(roomId);
      const secretRef = db.collection("room_quiz_secrets").doc(roomId);
      const [room, secret] = await Promise.all([
        roomRef.get(), secretRef.get(),
      ]);
      if (!room.exists || room.data()?.isOpen !== true) {
        return res.status(404).json({error: "Room is not open."});
      }
      if (room.data()?.hostId !== user.uid) {
        return res.status(403).json({error: "Only the host may finish the quiz."});
      }
      const quiz = room.data()?.quiz || {};
      if (quiz.revealed === true || quiz.rewardedAt != null) {
        return res.json({ok: true, alreadyFinished: true,
          winners: Array.isArray(quiz.winners) ? quiz.winners : []});
      }
      // Legacy client-created questions put correctIndex in public room data.
      // Such rounds may display practice winners, but can NEVER mint coins.
      const secured = quiz.secure === true && secret.exists &&
        secret.data()?.roundId === quiz.roundId &&
        Number.isInteger(secret.data()?.correctIndex);
      const answerKey = secured ? secret.data().correctIndex :
        Number(quiz.correctIndex);
      if (!Number.isInteger(answerKey) || answerKey < 0) {
        fail("No active quiz to finish.");
      }

      // Close the answer gate BEFORE reading votes; retries after an
      // interrupted finish see the same immutable set of votes.
      if (secured && quiz.acceptingAnswers === true) {
        await db.runTransaction(async tx => {
          const latest = await tx.get(roomRef);
          if (latest.data()?.hostId !== user.uid ||
              latest.data()?.quiz?.roundId !== quiz.roundId) {
            fail("Quiz changed during finalization.", 409);
          }
          if (latest.data()?.quiz?.acceptingAnswers === true) {
            tx.update(roomRef, {"quiz.acceptingAnswers": false,
              updatedAt: FieldValue.serverTimestamp()});
          }
        });
      }

      const answers = await roomRef.collection("quiz_answers").get();
      const winners = secured
        ? sortedQuizWinners(answers.docs, answerKey, quiz.roundId)
        : answers.docs.map(doc => ({id: doc.id, ...doc.data()}))
          .filter(a => Number(a.optionIndex) === answerKey)
          .sort((a, b) => (a.answeredAt?.toMillis?.() ?? 0) -
            (b.answeredAt?.toMillis?.() ?? 0))
          .slice(0, 3).map((a, index) => ({
            place: index + 1, userId: String(a.userId || a.id),
            displayName: String(a.displayName || "WorldVoice user"),
            prizeCoins: 0,
          }));

      const winnerId = winners[0]?.userId;
      const balanceRef = winnerId ? walletRef(db, winnerId) : null;
      const ledgerRef = winnerId ? db.collection("users").doc(winnerId)
        .collection("wallet_transactions")
        .doc(createHash("sha256").update(`quiz:${roomId}:${quiz.roundId || "legacy"}`)
          .digest("hex")) : null;
      const dailyRef = winnerId ? db.collection("users").doc(winnerId)
        .collection("economy_daily").doc(dayKey()) : null;
      const configRef = db.doc("economy_config/current");
      const result = await db.runTransaction(async tx => {
        const refs = [roomRef, secretRef, configRef,
          ...(balanceRef ? [balanceRef, ledgerRef, dailyRef] : [])];
        const snaps = await Promise.all(refs.map(ref => tx.get(ref)));
        const [latest, latestSecret, config] = snaps;
        const current = latest.data()?.quiz || {};
        if (current.revealed === true || current.rewardedAt != null) {
          return {alreadyFinished: true,
            winners: Array.isArray(current.winners) ? current.winners : []};
        }
        if (current.roundId !== quiz.roundId ||
            (secured && (current.acceptingAnswers !== false ||
             latestSecret.data()?.roundId !== quiz.roundId))) {
          fail("Quiz changed during finalization.", 409);
        }
        // A reward is allowed ONLY for a server-created sealed round with
        // owner-approved config and a migrated recipient wallet.
        const policy = secured ? rewardPolicy(config.data(),
          latestSecret.data()) : null;
        let prize = 0;
        if (policy && winnerId) {
          const [balance, ledger, daily] = snaps.slice(3);
          const wallet = requireMigratedWallet(balance);
          const earned = Number(daily.data()?.quizCoins || 0);
          const coins = Number(wallet.coins || 0);
          if (!safeCoinCount(earned) || !safeCoinCount(coins)) {
            fail("Quiz wallet audit required.", 503);
          }
          if (earned + policy.prize <= policy.cap) {
            if (ledger.exists) fail("Quiz ledger already exists.", 409);
            if (!safeCoinCount(coins + policy.prize)) fail("Quiz credit overflow.", 503);
            prize = policy.prize;
            tx.update(balanceRef, {
              coins: coins + prize, quizCoinsEarned: FieldValue.increment(prize),
              updatedAt: FieldValue.serverTimestamp(),
            });
            tx.set(dailyRef, {quizCoins: earned + prize,
              updatedAt: FieldValue.serverTimestamp()}, {merge: true});
            tx.create(ledgerRef, {
              type: "quiz_winner", amount: prize, currency: "coins",
              balanceBefore: coins, balanceAfter: coins + prize,
              source: "secure_room_quiz", roomId, roundId: quiz.roundId,
              createdAt: FieldValue.serverTimestamp(),
            });
          }
        }
        const completed = winners.map((w, i) => ({
          ...w, prizeCoins: i === 0 ? prize : 0,
        }));
        tx.update(roomRef, {
          "quiz.revealed": true, "quiz.acceptingAnswers": false,
          "quiz.correctIndex": answerKey, "quiz.practiceOnly": prize === 0,
          "quiz.winners": completed, "quiz.firstPrizeCoins": prize,
          "quiz.rewardedAt": FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return {alreadyFinished: false, practiceOnly: prize === 0,
          winners: completed};
      });
      res.json({ok: true, ...result});
    } catch (error) {next(error);}
  });
}
