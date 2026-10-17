import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {reversalDelta} from "./reversal_policy.js";
import {privateWalletRef, requirePrivateWallet} from "./wallet_store.js";

const err = (message, status = 409) =>
  Object.assign(new Error(message), {status});

/**
 * Use signed Stripe events only. Atomic receipt reversal, sender freeze and
 * linked-recipient payout hold; overlarge histories freeze ALL payouts until
 * reviewed instead of silently ignoring unscanned recipient liabilities.
 */
export async function reverseVerifiedWebPurchase({stripe, db, event}) {
  const dispute = event.type === "charge.dispute.created";
  const charge = dispute
    ? await stripe.charges.retrieve(String(event.data.object.charge || ""))
    : event.data.object;
  const paymentIntent = typeof charge.payment_intent === "string"
    ? charge.payment_intent : charge.payment_intent?.id;
  if (!paymentIntent) throw err("Refund has no linked Stripe PaymentIntent.", 503);
  const sessions = await stripe.checkout.sessions.list({
    payment_intent: paymentIntent, limit: 3,
  });
  if (sessions.data.length !== 1 || sessions.has_more) {
    throw err("Cannot uniquely match Stripe Checkout transaction.", 503);
  }
  const session = sessions.data[0];
  const uid = String(session.client_reference_id || "");
  const catalogId = String(session.metadata?.catalogId || "");
  if (!uid || !catalogId || session.currency !== "usd" ||
      !Number.isSafeInteger(session.amount_total) || session.amount_total <= 0) {
    throw err("Stripe Checkout reversal metadata mismatch.", 503);
  }
  const receiptKey = createHash("sha256")
    .update(`web:${session.id}`).digest("hex");
  const opKey = createHash("sha256")
    .update(`stripe:event:${event.id}`).digest("hex");
  const receiptRef = db.collection("iap_receipts").doc(receiptKey);
  const operation = db.collection("economy_refund_operations").doc(opKey);
  const userRef = db.collection("users").doc(uid);
  const userWalletRef = privateWalletRef(userRef);
  const globalRef = db.doc("economy_global_controls/payouts");
  // Freezes every recent gift receiver from the chargeback sender, until
  // finance can trace lots to their funding purchases.
  const gifts = await db.collection("economy_gift_operations")
    .where("userId", "==", uid).limit(91).get();
  const recipients = [...new Set(
    gifts.docs.map(d => String(d.data().recipientId || ""))
      .filter(id => id && id !== "teacher_ai" && id !== uid),
  )];
  const overLimit = gifts.size >= 91 || recipients.length >= 80;
  const recipientRefs = overLimit ? [] : recipients.map(id =>
    privateWalletRef(db.collection("users").doc(id)));
  const amountRefunded = dispute
    ? session.amount_total
    : Number(charge.amount_refunded);
  if (!Number.isSafeInteger(amountRefunded) || amountRefunded < 0) {
    throw err("Invalid signed Stripe refund amount.", 503);
  }
  return db.runTransaction(async tx => {
    const refs = [operation, receiptRef, userWalletRef, globalRef, ...recipientRefs];
    const snaps = await Promise.all(refs.map(ref => tx.get(ref)));
    const [old, receiptSnap, userSnap] = snaps;
    if (old.exists) return {...old.data().outcome, alreadyProcessed: true};
    const targetCents = Math.min(amountRefunded, session.amount_total);
    if (targetCents <= 0) throw err("No refunded amount on signed event.", 503);
    const existing = receiptSnap.data() || {};
    if (receiptSnap.exists && (existing.platform !== "web" ||
        existing.userId !== uid || existing.catalogId !== catalogId ||
        existing.receiptId !== session.id)) {
      throw err("Payment ownership mismatch; payout review required.", 503);
    }
    if (!receiptSnap.exists) {
      // Out-of-order refund/dispute arriving before the checkout callback:
      // a tombstone prevents the late checkout event from minting any coins.
      tx.create(receiptRef, {
        platform: "web", userId: uid, receiptId: session.id, catalogId,
        productId: null, coins: 0, debitedCoins: 0, refundedCents: targetCents,
        reversed: true, status: "refunded_before_credit",
        createdAt: FieldValue.serverTimestamp(),
      });
      if (overLimit) tx.set(globalRef, {frozen: true,
        reason: "stripe_refund_history_overflow",
        updatedAt: FieldValue.serverTimestamp()}, {merge: true});
      tx.create(operation, {userId: uid, receiptId: session.id,
        type: event.type, outcome: {pendingCreditBlocked: true},
        createdAt: FieldValue.serverTimestamp()});
      return {pendingCreditBlocked: true, alreadyProcessed: false};
    }
    const creditedCoins = Number(existing.coins);
    const priceCents = Number(existing.priceCents);
    if (!Number.isSafeInteger(priceCents) || priceCents !== session.amount_total ||
        !Number.isSafeInteger(creditedCoins) || creditedCoins <= 0) {
      if (existing.status === "refunded_before_credit") {
        tx.create(operation, {userId: uid, receiptId: session.id,
          type: event.type, outcome: {pendingCreditBlocked: true},
          createdAt: FieldValue.serverTimestamp()});
        return {pendingCreditBlocked: true, alreadyProcessed: false};
      }
      throw err("Unverifiable historical credit; manual review needed.", 503);
    }
    const previousRefund = Number(existing.refundedCents || 0);
    const requestedTarget = Math.max(previousRefund, targetCents);
    const result = reversalDelta({
      creditedCoins, priceCents, targetRefundCents: requestedTarget,
      alreadyDebitedCoins: Number(existing.debitedCoins || 0),
    });
    requirePrivateWallet(userSnap);
    const missingRecipientWallet = recipientRefs.some((_, index) =>
      !snaps[index + 4].exists);
    const recipientRiskHold = overLimit || missingRecipientWallet;
    const before = Number(userSnap.data()?.coins || 0);
    const debtBefore = Number(userSnap.data()?.walletDebtCoins || 0);
    const purchased = Number(userSnap.data()?.purchasedCoins || 0);
    if (!Number.isSafeInteger(before) || before < 0 ||
        !Number.isSafeInteger(debtBefore) || debtBefore < 0 ||
        !Number.isSafeInteger(purchased) || purchased < 0) {
      throw err("Wallet reconciliation required.", 503);
    }
    const availableDebit = Math.min(before, result.deltaCoins);
    const debt = result.deltaCoins - availableDebit;
    const outcome = {
      deductedCoins: availableDebit, debtCoins: debt,
      targetRefundCents: requestedTarget,
      payoutFrozen: true, recipientsFrozen: recipientRiskHold ? "global" : recipients.length,
    };
    tx.set(userWalletRef, {
      coins: before - availableDebit,
      purchasedCoins: Math.max(0, purchased - result.deltaCoins),
      walletDebtCoins: debtBefore + debt,
      walletFrozen: true, payoutFrozen: true,
      // Reversal does NOT reset eligibility for first-recharge rewards.
      firstRechargeUsed: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    for (const ref of (recipientRiskHold ? [] : recipientRefs)) {
      tx.set(ref, {payoutFrozen: true,
        payoutFreezeReason: "linked_gift_sender_refund",
        updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    }
    if (recipientRiskHold) {
      tx.set(globalRef, {frozen: true,
        reason: missingRecipientWallet ? "stripe_missing_recipient_wallet"
          : "stripe_refund_history_overflow",
        updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    }
    tx.update(receiptRef, {
      debitedCoins: result.totalDebit, refundedCents: requestedTarget,
      reversed: result.reversed || dispute,
      refundReviewRequired: true,
      lastRefundEvent: event.id,
    });
    tx.create(userRef.collection("wallet_transactions").doc(opKey), {
      type: dispute ? "card_chargeback" : "card_refund",
      currency: "coins", amount: -availableDebit,
      balanceBefore: before, balanceAfter: before - availableDebit,
      debtAdded: debt, source: "stripe_webhook", receiptKey,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(db.collection("economy_audit").doc(opKey), {
      type: event.type, userId: uid, receiptKey,
      ...outcome, createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(operation, {userId: uid, receiptId: session.id,
      type: event.type, outcome, createdAt: FieldValue.serverTimestamp()});
    return {...outcome, alreadyProcessed: false};
  });
}
