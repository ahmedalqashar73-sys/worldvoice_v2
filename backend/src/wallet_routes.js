import {createHash} from "node:crypto";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {requireLiveEconomy} from "./economy_policy.js";
import {withdrawalQuote} from "./wallet_policy.js";

const fail = (message, status = 400) => {
  throw Object.assign(new Error(message), {status});
};
const pos = (n) => Number.isSafeInteger(n) && n > 0;
const safe = (n) => Number.isSafeInteger(n) && n >= 0;
function keyFor(uid, label, header) {
  if (typeof header !== "string" || !/^[A-Za-z0-9_-]{12,100}$/.test(header)) {
    fail("Valid Idempotency-Key header required.");
  }
  return createHash("sha256").update(`${uid}:${label}:${header}`).digest("hex");
}
const dateDay = (date) => date.toISOString().slice(0, 10);

/** All routes are additive to existing room backend; never run on the Agora Worker. */
export function registerWalletRoutes({app, db, authenticatedUser}) {
  app.post("/wallet/settle", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const ref = db.collection("users").doc(user.uid);
      const now = Timestamp.now();
      const list = await ref.collection("diamond_lots")
        .where("status", "==", "pending").where("holdUntil", "<=", now)
        .limit(50).get();
      if (list.empty) return res.json({ok: true, diamondsReleased: 0});
      const outcome = await db.runTransaction(async tx => {
        const [userSnap, configSnap, controlSnap, ...lots] = await Promise.all([
          tx.get(ref), tx.get(db.doc("economy_config/current")),
          tx.get(db.doc("economy_global_controls/payouts")),
          ...list.docs.map(d => tx.get(d.ref)),
        ]);
        requireLiveEconomy(configSnap.data());
        if (controlSnap.data()?.frozen === true) fail("Payouts are on hold.", 423);
        if (userSnap.data()?.payoutFrozen === true ||
            userSnap.data()?.walletFrozen === true) {
          fail("Wallet is under review.", 423);
        }
        const chosen = lots.filter(l => l.exists &&
          l.data()?.status === "pending" &&
          l.data()?.holdUntil?.toMillis?.() <= now.toMillis());
        const released = chosen.reduce((sum, l) =>
          sum + Number(l.data().diamonds), 0);
        const beforePending = Number(userSnap.data()?.diamondsPending || 0);
        const beforeAvailable = Number(userSnap.data()?.diamonds || 0);
        if (!safe(released) || !safe(beforePending) || !safe(beforeAvailable) ||
            beforePending < released || !safe(beforeAvailable + released)) {
          fail("Holding lot balance mismatch; contact support.", 409);
        }
        if (released === 0) return 0;
        const key = createHash("sha256").update(
          user.uid + ":settle:" + chosen.map(l => l.ref.id).sort().join(","),
        ).digest("hex");
        const ledger = ref.collection("wallet_transactions").doc(key);
        const existingLedger = await tx.get(ledger);
        if (existingLedger.exists) return 0;
        tx.update(ref, {
          diamonds: beforeAvailable + released,
          diamondsPending: beforePending - released,
          updatedAt: FieldValue.serverTimestamp(),
        });
        for (const l of chosen) tx.update(l.ref, {
          status: "available", releasedAt: FieldValue.serverTimestamp(),
        });
        tx.create(ledger, {
          type: "diamond_hold_release", currency: "diamonds",
          amount: released, balanceBefore: beforeAvailable,
          balanceAfter: beforeAvailable + released,
          source: "gift_holding_lots", createdAt: FieldValue.serverTimestamp(),
        });
        return released;
      });
      res.json({ok: true, diamondsReleased: outcome});
    } catch (error) { next(error); }
  });

  app.post("/wallet/exchange", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const amount = Number(req.body?.diamonds);
      if (!pos(amount)) fail("Invalid diamonds amount.");
      const key = keyFor(user.uid, "exchange", req.headers["idempotency-key"]);
      const ref = db.collection("users").doc(user.uid);
      const opRef = db.collection("economy_exchange_operations").doc(key);
      const outcome = await db.runTransaction(async tx => {
        const [old, snap, config, controls] = await Promise.all([
          tx.get(opRef), tx.get(ref), tx.get(db.doc("economy_config/current")),
          tx.get(db.doc("economy_global_controls/payouts")),
        ]);
        if (old.exists) {
          if (old.data()?.diamonds !== amount) fail("Reused idempotency key.", 409);
          return {...old.data().outcome, alreadyProcessed: true};
        }
        const policy = requireLiveEconomy(config.data());
        if (controls.data()?.frozen === true) fail("Economy review hold.", 423);
        if (!pos(policy.minExchangeDiamonds) || amount < policy.minExchangeDiamonds) {
          fail("Exchange amount is below the configured minimum.");
        }
        if (snap.data()?.walletFrozen === true ||
            snap.data()?.payoutFrozen === true) fail("Wallet is under review.", 423);
        const diamondBefore = Number(snap.data()?.diamonds || 0);
        const coinBefore = Number(snap.data()?.coins || 0);
        const base = Math.floor(amount * policy.diamondUsdValue * policy.coinsPerUsd);
        const bonus = Math.floor(base * policy.exchangeBonusPercent / 100);
        const resultCoins = base + bonus;
        if (!safe(diamondBefore) || !safe(coinBefore) ||
            !pos(resultCoins) || !safe(coinBefore + resultCoins) ||
            diamondBefore < amount) fail("Insufficient redeemable diamonds.", 409);
        const outcome = {spentDiamonds: amount, receivedCoins: resultCoins,
          bonusCoins: bonus, diamondBalance: diamondBefore - amount,
          coinBalance: coinBefore + resultCoins};
        tx.update(ref, {
          diamonds: outcome.diamondBalance, coins: outcome.coinBalance,
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.create(ref.collection("wallet_transactions").doc(key + "_diamond"), {
          type: "diamond_exchange_debit", amount: -amount, currency: "diamonds",
          balanceBefore: diamondBefore, balanceAfter: outcome.diamondBalance,
          source: "exchange", operationId: key,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(ref.collection("wallet_transactions").doc(key + "_coin"), {
          type: "diamond_exchange_credit", amount: resultCoins, currency: "coins",
          balanceBefore: coinBefore, balanceAfter: outcome.coinBalance,
          source: "exchange", bonusCoins: bonus, operationId: key,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(opRef, {userId: user.uid, diamonds: amount, outcome,
          createdAt: FieldValue.serverTimestamp()});
        return {...outcome, alreadyProcessed: false};
      });
      res.json({ok: true, ...outcome});
    } catch (error) {next(error);}
  });

  app.post("/wallet/withdraw/quote", async (req, res, next) => {
    try {
      await authenticatedUser(req);
      const [configSnap, controlSnap] = await Promise.all([
        db.doc("economy_config/current").get(),
        db.doc("economy_global_controls/payouts").get(),
      ]);
      if (controlSnap.data()?.frozen === true) fail("Payouts under review.", 423);
      res.json({ok: true, ...withdrawalQuote(requireLiveEconomy(configSnap.data()),
        Number(req.body?.diamonds), new Date())});
    } catch (error) {next(error);}
  });

  app.post("/wallet/withdraw", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const amount = Number(req.body?.diamonds);
      const method = String(req.body?.method || "");
      // Only opaque tokens produced by a future approved payout provider, not
      // raw IBAN, bank-account or sensitive identity details in the app.
      const payoutAccountToken = String(req.body?.payoutAccountToken || "");
      if (!/^[A-Za-z0-9_:-]{12,160}$/.test(payoutAccountToken)) {
        fail("An approved payout account token is required.");
      }
      const key = keyFor(user.uid, "withdraw", req.headers["idempotency-key"]);
      const ref = db.collection("users").doc(user.uid);
      const withdrawalRef = db.collection("withdraw_requests").doc(key);
      const now = new Date();
      const outcome = await db.runTransaction(async tx => {
        const [existing, config, snapshot, control] = await Promise.all([
          tx.get(withdrawalRef), tx.get(db.doc("economy_config/current")),
          tx.get(ref), tx.get(db.doc("economy_global_controls/payouts")),
        ]);
        if (existing.exists) {
          if (existing.data()?.userId !== user.uid ||
              existing.data()?.diamonds !== amount ||
              existing.data()?.method !== method ||
              existing.data()?.payoutAccountToken !== payoutAccountToken) {
            fail("Reused idempotency key.", 409);
          }
          return {...existing.data()?.quote, alreadyProcessed: true};
        }
        if (control.data()?.frozen === true) fail("Payouts under review.", 423);
        const policy = requireLiveEconomy(config.data());
        const quote = withdrawalQuote(policy, amount, now);
        if (!policy.withdrawalMethods.includes(method)) {
          fail("Withdrawal method is not configured.");
        }
        const data = snapshot.data() || {};
        if (data.identityVerified !== true || data.walletFrozen === true ||
            data.payoutFrozen === true) {
          fail("Identity verification or wallet review is required.", 403);
        }
        const available = Number(data.diamonds || 0);
        const reserved = Number(data.diamondsReserved || 0);
        if (!safe(available) || !safe(reserved) || available < amount ||
            !safe(reserved + amount)) fail("Insufficient unlocked diamonds.", 409);
        tx.update(ref, {
          diamonds: available - amount, diamondsReserved: reserved + amount,
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.create(withdrawalRef, {
          userId: user.uid, diamonds: amount, method, payoutAccountToken,
          quote, status: "pending_admin_review",
          requestedAt: FieldValue.serverTimestamp(),
        });
        tx.create(ref.collection("wallet_transactions").doc(key), {
          type: "withdrawal_reserved", amount: -amount, currency: "diamonds",
          balanceBefore: available, balanceAfter: available - amount,
          source: method, operationId: key, createdAt: FieldValue.serverTimestamp(),
        });
        return {...quote, alreadyProcessed: false};
      });
      res.json({ok: true, requestId: key, ...outcome,
        // No claim of transfer: administrative/provider payout is separate.
        status: "pending_admin_review"});
    } catch (error) {next(error);}
  });

  app.post("/admin/withdraw/review", async (req, res, next) => {
    try {
      const reviewer = await authenticatedUser(req);
      if (reviewer.admin !== true && reviewer.economyAdmin !== true) {
        fail("Admin authorization required.", 403);
      }
      const requestId = String(req.body?.requestId || "");
      const decision = String(req.body?.decision || "");
      if (!/^[a-f0-9]{64}$/.test(requestId) ||
          !["approve", "reject"].includes(decision)) fail("Invalid review request.");
      const withdrawalRef = db.collection("withdraw_requests").doc(requestId);
      const snapshot = await withdrawalRef.get();
      if (!snapshot.exists) fail("Withdrawal not found.", 404);
      const ownerRef = db.collection("users").doc(snapshot.data()?.userId);
      const result = await db.runTransaction(async tx => {
        const [withdrawal, owner, control] = await Promise.all([
          tx.get(withdrawalRef), tx.get(ownerRef),
          tx.get(db.doc("economy_global_controls/payouts")),
        ]);
        if (decision === "approve" && control.data()?.frozen === true) {
          fail("Global payout hold requires resolution.", 423);
        }
        // A refund, dispute or account suspension can arrive after a user
        // reserves their withdrawal. Re-check owner status at review time.
        if (decision === "approve" &&
            (owner.data()?.walletFrozen === true ||
             owner.data()?.payoutFrozen === true ||
             Number(owner.data()?.walletDebtCoins || 0) > 0 ||
             owner.data()?.identityVerified !== true)) {
          fail("Wallet review or identity hold prevents payout approval.", 423);
        }
        if (withdrawal.data()?.status !== "pending_admin_review") {
          fail("Withdrawal has already been reviewed.", 409);
        }
        const amount = Number(withdrawal.data()?.diamonds);
        const reserved = Number(owner.data()?.diamondsReserved);
        const available = Number(owner.data()?.diamonds || 0);
        if (!pos(amount) || !safe(reserved) || reserved < amount ||
            !safe(available)) fail("Reserved balance mismatch.", 409);
        if (decision === "reject") {
          if (!safe(available + amount)) fail("Balance overflow.", 409);
          tx.update(ownerRef, {
            diamonds: available + amount, diamondsReserved: reserved - amount,
            updatedAt: FieldValue.serverTimestamp(),
          });
          tx.create(ownerRef.collection("wallet_transactions")
            .doc(requestId + "_rejected"), {
            type: "withdrawal_rejected_refund", currency: "diamonds",
            amount, balanceBefore: available, balanceAfter: available + amount,
            source: "admin_review", operationId: requestId,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        // Approval means reviewed and queued; it does NOT assert a payment
        // was processed by PayPal, Payoneer or a bank.
        tx.update(withdrawalRef, {
          status: decision === "approve" ? "approved_for_payout" : "rejected",
          reviewedBy: reviewer.uid, reviewedAt: FieldValue.serverTimestamp(),
        });
        return decision;
      });
      res.json({ok: true, decision: result});
    } catch (error) {next(error);}
  });
}
