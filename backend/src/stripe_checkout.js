// Stripe is web-only by default. App-store native linking requires separate
// enrollment/entitlement checks; this file never exposes a native link.
import { createHash } from "node:crypto";
import Stripe from "stripe";
import { FieldValue } from "firebase-admin/firestore";
import {
  validateEconomy, coinCredit, positiveBalance, economyError,
} from "./economy_core.js";

const secret = process.env.STRIPE_SECRET_KEY || "";
const signingKey = process.env.STRIPE_WEBHOOK_SECRET || "";
const stripe = secret ? new Stripe(secret) : null;
const webUrl = (process.env.WORLDVOICE_WEB_URL || "").trim().replace(/\/$/, "");
const allowed = (process.env.WORLDVOICE_WEB_CHECKOUT_ENABLED || "") === "true";
const receiptId = (sessionId) => createHash("sha256")
  .update("stripe:" + sessionId).digest("hex");
function requireWebCheckout() {
  if (!allowed || !stripe || !webUrl.startsWith("https://"))
    throw economyError("Card checkout is not enabled for this web market.", 503);
}
async function configFrom(db) {
  return validateEconomy((await db.collection("economy_config").doc("global").get()).data());
}
async function creditStripeSession(db, session, eventId) {
  if (!session?.id || session.payment_status !== "paid")
    throw economyError("Checkout session has not been paid.", 409);
  const orderRef = db.collection("stripe_orders").doc(session.id);
  const eventRef = db.collection("stripe_events").doc(eventId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw economyError("Checkout session has no approved order.", 409);
  const order = orderSnap.data() || {};
  if (order.userId !== session.metadata?.uid ||
      order.packId !== session.metadata?.packId ||
      Number(session.amount_total) !== Number(order.amountTotal) ||
      session.currency !== order.currency)
    throw economyError("Checkout amount/account mismatch.", 409);
  const cfg = await configFrom(db);
  const receiptRef = db.collection("iap_receipts").doc(receiptId(session.id));
  const userRef = db.collection("users").doc(order.userId);
  const dayRef = userRef.collection("economy_daily").doc(
    new Date().toISOString().slice(0, 10));
  await db.runTransaction(async (tx) => {
    const [existingEvent, existingOrder, receipt, user, today] =
      await Promise.all([tx.get(eventRef), tx.get(orderRef),
        tx.get(receiptRef), tx.get(userRef), tx.get(dayRef)]);
    if (existingEvent.exists) return;
    if (!existingOrder.exists || existingOrder.data()?.userId !== order.userId)
      throw economyError("Checkout order changed.", 409);
    if (existingOrder.data()?.refunded === true)
      throw economyError("Refunded checkout cannot be fulfilled.", 409);
    if (receipt.exists || existingOrder.data()?.fulfilled === true) {
      tx.create(eventRef, { type:"duplicate_payment_event",
        sessionId:session.id, createdAt:FieldValue.serverTimestamp() });
      return;
    }
    const purchasedUsd = Number(today.data()?.purchasedUsd || 0);
    if (!Number.isFinite(purchasedUsd) ||
        purchasedUsd + Number(order.priceUsd) > cfg.dailyPurchaseLimitUsd)
      throw economyError("DAILY_PURCHASE_LIMIT", 429);
    const old = user.data() || {};
    const before = positiveBalance(old.coins);
    const base = Number(order.coins);
    const credit = coinCredit(cfg, base, {
      webCard:true,
      firstRecharge:positiveBalance(old.purchasedCoins) === 0,
    });
    const after = before + credit.coins;
    if (!Number.isSafeInteger(after)) throw economyError("Wallet overflow.", 503);
    tx.set(userRef, {coins:after,
      purchasedCoins:positiveBalance(old.purchasedCoins)+base,
      updatedAt:FieldValue.serverTimestamp()}, {merge:true});
    tx.set(dayRef, {purchasedUsd:purchasedUsd+Number(order.priceUsd),
      updatedAt:FieldValue.serverTimestamp()}, {merge:true});
    tx.create(receiptRef, {userId:order.userId, platform:"stripe",
      catalogId:order.packId, coins:credit.coins, baseCoins:base,
      cardBonus:credit.cardBonus, firstBonus:credit.firstBonus,
      receiptId:session.id, creditedAt:FieldValue.serverTimestamp(),
      status:"credited"});
    tx.create(db.collection("wallet_transactions").doc("stripe_" + receiptId(session.id)), {
      userId:order.userId, type:"web_card_purchase", currency:"coins",
      amount:credit.coins, balanceBefore:before, balanceAfter:after,
      source:"stripe", refId:receiptRef.id,
      metadata:{baseCoins:base,cardBonus:credit.cardBonus,
        firstBonus:credit.firstBonus, packId:order.packId},
      createdAt:FieldValue.serverTimestamp()});
    tx.update(orderRef, {fulfilled:true, coinsCredited:credit.coins,
      paymentIntentId:session.payment_intent || null,
      fulfilledAt:FieldValue.serverTimestamp()});
    tx.create(eventRef, {type:"payment_fulfilled", sessionId:session.id,
      createdAt:FieldValue.serverTimestamp()});
  });
}

// Stripe raw webhook MUST be mounted before express.json(), otherwise signed
// event verification loses the original payload.
export function registerStripeWebhook(app, db) {
  app.post("/webhooks/stripe",
    (awaitExpressRaw())({ type:"application/json" }),
    async (req, res) => {
      if (!stripe || !signingKey) return res.status(503).json({error:"Webhook not configured."});
      let event;
      try {
        event = stripe.webhooks.constructEvent(
          req.body, req.headers["stripe-signature"], signingKey);
      } catch {
        return res.status(400).json({error:"Invalid webhook signature."});
      }
      try {
        if (["checkout.session.completed",
          "checkout.session.async_payment_succeeded"].includes(event.type)) {
          if (event.data.object.payment_status === "paid")
            await creditStripeSession(db, event.data.object, event.id);
        } else if (["charge.refunded", "charge.dispute.created"].includes(event.type)) {
          const intentId = String(event.data.object.payment_intent || "");
          if (intentId) {
            const matches = await db.collection("stripe_orders")
              .where("paymentIntentId", "==", intentId).limit(1).get();
            if (!matches.empty) await reverseStripePurchase(db, matches.docs[0].ref, event);
          }
        }
        res.json({received:true});
      } catch (error) {
        console.error("Stripe fulfillment failed:", error?.message);
        // Non-2xx makes Stripe retry; the Firestore transaction is idempotent.
        res.status(500).json({error:"Could not process verified event."});
      }
    });
}

// Express is already a dependency; injected raw middleware avoids parsing
// checkout signatures as JSON before verification.
import { raw as expressRaw } from "express";
function awaitExpressRaw() { return expressRaw; }

async function reverseStripePurchase(db, orderRef, event) {
  const eventRef = db.collection("stripe_events").doc(event.id);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) return;
  const order = orderSnap.data();
  const userRef = db.collection("users").doc(order.userId);
  const receiptRef = db.collection("iap_receipts").doc(receiptId(orderRef.id));
  await db.runTransaction(async (tx) => {
    const [prior, latestOrder, receipt, user] = await Promise.all([
      tx.get(eventRef), tx.get(orderRef), tx.get(receiptRef), tx.get(userRef)
    ]);
    if (prior.exists || latestOrder.data()?.refunded) return;
    const before = positiveBalance(user.data()?.coins);
    const credited = positiveBalance(receipt.data()?.coins);
    const deducted = Math.min(before, credited);
    const uncovered = credited - deducted;
    tx.set(userRef, {
      coins:before-deducted,
      coinDebt:positiveBalance(user.data()?.coinDebt)+uncovered,
      payoutHold:true,
      updatedAt:FieldValue.serverTimestamp(),
    }, {merge:true});
    tx.set(receiptRef, {
      status:event.type === "charge.refunded" ? "refunded" : "disputed",
      refundedAt:FieldValue.serverTimestamp(),
    }, {merge:true});
    tx.update(orderRef, {
      refunded:true, refundEventId:event.id,
      updatedAt:FieldValue.serverTimestamp()
    });
    tx.create(db.collection("wallet_transactions").doc("refund_" + event.id), {
      userId:order.userId, type:event.type === "charge.refunded" ?
        "refund" : "chargeback", currency:"coins", amount:-deducted,
      balanceBefore:before, balanceAfter:before-deducted,
      source:"stripe", refId:orderRef.id,
      metadata:{debtAdded:uncovered, reviewRequired:true},
      createdAt:FieldValue.serverTimestamp(),
    });
    tx.create(eventRef, {type:event.type, orderId:orderRef.id,
      createdAt:FieldValue.serverTimestamp()});
    // Exact recipient diamond tracing requires funded-lot provenance; never
    // indiscriminately confiscate other users' diamonds on uncertain linkage.
    tx.create(db.collection("economy_audit").doc(event.id), {
      type:"stripe_reversal", orderId:orderRef.id, userId:order.userId,
      pendingDiamondTrace:true, createdAt:FieldValue.serverTimestamp(),
    });
  });
}

export function registerStripeCheckout(app, {db, authenticatedUser}) {
  app.post("/web/checkout", async (req, res, next) => {
    try {
      requireWebCheckout();
      // Route is intended for a stand-alone compliant WEB storefront. Native
      // clients MUST NOT surface this URL without store program eligibility.
      if (req.get("origin") !== webUrl)
        throw economyError("Checkout requires approved WorldVoice web origin.", 403);
      const auth = await authenticatedUser(req);
      const packId = String(req.body?.packId || "");
      if (!/^[\w-]+$/.test(packId)) throw economyError("Invalid coin package.", 400);
      const cfg = await configFrom(db);
      const listing = await db.collection("coin_products").doc(packId).get();
      const pack = listing.data() || {};
      if (!listing.exists || pack.active !== true || !pack.webPriceId)
        throw economyError("Package is not configured for web checkout.", 409);
      const price = await stripe.prices.retrieve(pack.webPriceId);
      if (!price.active || price.currency !== "usd" ||
          price.unit_amount !== Math.round(Number(pack.priceUsd) * 100))
        throw economyError("Stripe price does not match coin_products.", 503);
      const userRef = db.collection("users").doc(auth.uid);
      const [user, purchases] = await Promise.all([
        userRef.get(),
        userRef.collection("economy_daily").doc(
          new Date().toISOString().slice(0,10)).get()
      ]);
      if (!user.exists) throw economyError("User profile is missing.", 404);
      if (Number(purchases.data()?.purchasedUsd || 0) +
          Number(pack.priceUsd) > cfg.dailyPurchaseLimitUsd)
        throw economyError("DAILY_PURCHASE_LIMIT", 429);
      const session = await stripe.checkout.sessions.create({
        mode:"payment", payment_method_types:["card"],
        line_items:[{price:pack.webPriceId, quantity:1}],
        success_url:webUrl+"/purchase/result?session_id={CHECKOUT_SESSION_ID}",
        cancel_url:webUrl+"/purchase/canceled",
        client_reference_id:auth.uid,
        metadata:{uid:auth.uid,packId},
      });
      // Webhook must find this server-generated order before granting coins.
      await db.collection("stripe_orders").doc(session.id).create({
        userId:auth.uid, packId, coins:pack.coins,
        priceUsd:pack.priceUsd, currency:price.currency,
        amountTotal:price.unit_amount, fulfilled:false, refunded:false,
        createdAt:FieldValue.serverTimestamp(),
      });
      res.json({ok:true,url:session.url});
    } catch (error) { next(error); }
  });
}
