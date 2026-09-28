import {randomUUID} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {requireLiveEconomy} from "./economy_policy.js";
import {requirePrivateWalletCutover} from "./private_wallet_schema.js";
import {
  quizQuestion, quizChoice, matchesPrivateRound, rankVerifiedAnswers,
  approvedQuizPrize,
} from "./quiz_policy.js";

function bad(message, status = 409) {
  return Object.assign(new Error(message), {status});
}

export function registerQuizRoutes({app, db, authenticatedUser}) {
  app.post("/quiz/start", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomId = String(req.body?.roomId || "").trim();
      if (!roomId || roomId.length > 120) throw bad("Invalid room.", 400);
      const prepared = quizQuestion(req.body);
      const roomRef = db.collection("rooms").doc(roomId);
      const roundId = randomUUID();
      const privateRef = roomRef.collection("quiz_private").doc(roundId);
      await db.runTransaction(async tx => {
        const snap = await tx.get(roomRef);
        if (!snap.exists || snap.data()?.isOpen !== true) {
          throw bad("Room is not open.", 404);
        }
        if (snap.data()?.hostId !== user.uid) throw bad("Only the host can create a quiz.", 403);
        const previous = snap.data()?.quiz || {};
        if (previous.secure === true && previous.revealed !== true) {
          throw bad("Finish the current secure quiz before starting another.");
        }
        tx.create(privateRef, {
          roundId, question: prepared.question, options: prepared.options,
          correctIndex: prepared.correctIndex, closed: false,
          createdBy: user.uid, createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(roomRef, {
          quiz: {
            roundId, secure: true, practiceOnly: false,
            question: prepared.question, options: prepared.options,
            revealed: false, closed: false,
            startedAt: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      return res.status(201).json({ok: true, roundId});
    } catch (error) {
      next(error);
    }
  });

  app.post("/quiz/answer", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomId = String(req.body?.roomId || "").trim();
      const roundId = String(req.body?.roundId || "").trim();
      const selectedIndex = req.body?.selectedIndex;
      if (!roomId || !/^[0-9a-f-]{36}$/i.test(roundId)) {
        throw bad("Invalid quiz round.", 400);
      }
      const roomRef = db.collection("rooms").doc(roomId);
      const privateRef = roomRef.collection("quiz_private").doc(roundId);
      const memberRef = roomRef.collection("participants").doc(user.uid);
      const proofRef = privateRef.collection("answers").doc(user.uid);
      const publicAnswerRef = roomRef.collection("quiz_answers").doc(user.uid);
      const existing = await db.runTransaction(async tx => {
        const [room, secret, member, proof] = await Promise.all([
          roomRef, privateRef, memberRef, proofRef,
        ].map(ref => tx.get(ref)));
        if (!room.exists || room.data()?.isOpen !== true ||
            !member.exists || member.data()?.kicked === true) {
          throw bad("Active room membership is required.", 403);
        }
        const publicQuiz = room.data()?.quiz;
        matchesPrivateRound(publicQuiz, secret.data(), roundId);
        if (publicQuiz?.revealed === true || publicQuiz?.closed === true ||
            secret.data()?.closed === true) throw bad("Quiz is closed.");
        quizChoice(selectedIndex, secret.data().options.length);
        if (proof.exists) {
          if (proof.data()?.selectedIndex !== selectedIndex) {
            throw bad("Answer cannot be changed after submission.");
          }
          return true;
        }
        const displayName = String(member.data()?.displayName ||
          user.name || "WorldVoice user").slice(0, 80);
        const payload = {
          roundId, userId: user.uid, displayName, selectedIndex,
          isCorrect: selectedIndex === secret.data().correctIndex,
          answeredAt: FieldValue.serverTimestamp(),
        };
        tx.create(proofRef, payload);
        // The public record carries no correctness marker or hidden answer.
        tx.set(publicAnswerRef, {
          roundId, userId: user.uid, displayName, optionIndex: selectedIndex,
          answeredAt: FieldValue.serverTimestamp(),
        });
        return false;
      });
      return res.json({ok: true, alreadyAnswered: existing});
    } catch (error) {
      next(error);
    }
  });

  app.post("/quiz/finish", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomId = String(req.body?.roomId || "").trim();
      if (!roomId) throw bad("roomId is required.", 400);
      const roomRef = db.collection("rooms").doc(roomId);
      // Lock before fetching answers so a new answer cannot race with scoring.
      const round = await db.runTransaction(async tx => {
        const room = await tx.get(roomRef);
        if (!room.exists || room.data()?.isOpen !== true) throw bad("Room is not open.", 404);
        if (room.data()?.hostId !== user.uid) throw bad("Only the host can finish the quiz.", 403);
        const publicQuiz = room.data()?.quiz || {};
        const roundId = String(publicQuiz.roundId || "");
        if (!/^[0-9a-f-]{36}$/i.test(roundId)) {
          throw bad("Only server-started quizzes can use verified results.");
        }
        const privateRef = roomRef.collection("quiz_private").doc(roundId);
        const secret = await tx.get(privateRef);
        matchesPrivateRound(publicQuiz, secret.data(), roundId);
        if (publicQuiz.revealed === true) {
          return {roundId, done: true, winners: publicQuiz.winners || [],
            practiceOnly: publicQuiz.practiceOnly !== false};
        }
        tx.update(roomRef, {
          "quiz.closed": true, updatedAt: FieldValue.serverTimestamp(),
        });
        tx.update(privateRef, {closed: true});
        return {roundId, done: false};
      });
      if (round.done) return res.json({ok: true, alreadyFinished: true,
        winners: round.winners, practiceOnly: round.practiceOnly});
      const privateRef = roomRef.collection("quiz_private").doc(round.roundId);
      const [secretSnap, answerSnap, configSnap, privacySnap] = await Promise.all([
        privateRef.get(), privateRef.collection("answers").get(),
        db.doc("economy_config/current").get(),
        db.doc("economy_global_controls/privacy_migration").get(),
      ]);
      const secret = secretSnap.data();
      if (!secret) throw bad("Missing immutable quiz secret.");
      const winners = rankVerifiedAnswers(answerSnap.docs.map(doc => ({
        ...doc.data(), userId: doc.id,
        answeredAt: doc.data().answeredAt?.toMillis?.() ?? Number.MAX_SAFE_INTEGER,
      })), secret.correctIndex);
      const prize = approvedQuizPrize(configSnap.data());
      if (prize > 0) {
        requireLiveEconomy(configSnap.data());
        requirePrivateWalletCutover(privacySnap.data());
      }
      const first = prize > 0 && winners.length > 0 ? winners[0] : null;
      const walletRef = first
        ? db.doc(`users/${first.userId}/private_wallet/summary`) : null;
      const ledgerRef = first
        ? db.doc(`users/${first.userId}/wallet_transactions/quiz_${round.roundId}`) : null;
      const outcome = await db.runTransaction(async tx => {
        // Read all before any write.
        const [latestRoom, latestSecret, latestConfig, latestPrivacy,
          wallet, ledger] = await Promise.all([
          tx.get(roomRef), tx.get(privateRef),
          tx.get(db.doc("economy_config/current")),
          tx.get(db.doc("economy_global_controls/privacy_migration")),
          ...(walletRef ? [tx.get(walletRef), tx.get(ledgerRef)] : []),
        ]);
        const quiz = latestRoom.data()?.quiz || {};
        matchesPrivateRound(quiz, latestSecret.data(), round.roundId);
        if (quiz.revealed === true) {
          return {alreadyFinished: true, winners: quiz.winners || [],
            practiceOnly: quiz.practiceOnly !== false};
        }
        if (quiz.closed !== true || latestSecret.data()?.closed !== true) {
          throw bad("Quiz must be closed before scoring.");
        }
        // Finance controls must still match at the exact commit boundary,
        // not merely when the preceding network reads were performed.
        if (approvedQuizPrize(latestConfig.data()) !== prize) {
          throw bad("Quiz reward policy changed; retry finalization.", 409);
        }
        if (prize > 0) {
          requireLiveEconomy(latestConfig.data());
          requirePrivateWalletCutover(latestPrivacy.data());
        }
        const awardedWinners = winners.map((entry, index) => ({
          ...entry, prizeCoins: index === 0 ? (first ? prize : 0) : 0,
        }));
        if (first) {
          const walletData = wallet?.data();
          if (!wallet?.exists || walletData?.walletFrozen === true ||
              !Number.isSafeInteger(walletData?.coins) ||
              walletData.coins < 0) {
            throw bad("Verified winner's private wallet is unavailable.", 503);
          }
          if (ledger?.exists) throw bad("Prize ledger exists but round is unfinished.", 409);
          const next = walletData.coins + prize;
          if (!Number.isSafeInteger(next)) throw bad("Prize exceeds safe balance.", 409);
          tx.update(walletRef, {
            coins: next, quizCoinsEarned: FieldValue.increment(prize),
            updatedAt: FieldValue.serverTimestamp(),
          });
          tx.create(ledgerRef, {
            type: "verified_quiz_prize", amount: prize, currency: "coins",
            balanceBefore: walletData.coins, balanceAfter: next,
            source: "quiz", roomId, roundId: round.roundId,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        tx.update(roomRef, {
          "quiz.revealed": true, "quiz.practiceOnly": prize === 0,
          "quiz.correctIndex": secret.correctIndex,
          "quiz.winners": awardedWinners,
          "quiz.firstPrizeCoins": first ? prize : 0,
          "quiz.rewardedAt": FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return {alreadyFinished: false, winners: awardedWinners, practiceOnly: prize === 0};
      });
      return res.json({ok: true, ...outcome});
    } catch (error) {
      next(error);
    }
  });
}
