import { createHash } from "node:crypto";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  validateEconomy, giftQuote, exchangeQuote, withdrawalQuote,
  positiveBalance, economyError,
} from "./economy_core.js";

const id = (s) => typeof s === "string" && s.length > 0 && s.length <= 128 && /^[\w-]+$/.test(s);
const dailyKey = () => new Date().toISOString().slice(0, 10);
const asDate = (v) => v?.toDate?.() ?? null;
const nowTimestamp = () => Timestamp.now();
const ledger = (tx, db, { userId, type, currency, amount, before, after, source, refId,
  context, relatedUserId = null, metadata = {} }) => {
  const entry = db.collection("wallet_transactions").doc();
  tx.create(entry, {
    userId, type, currency, amount, balanceBefore: before, balanceAfter: after,
    source, refId, context, relatedUserId, metadata,
    createdAt: FieldValue.serverTimestamp(),
  });
};

async function loadConfig(db) {
  const snapshot = await db.collection("economy_config").doc("global").get();
  return validateEconomy(snapshot.data());
}
async function memberDocument(tx, db, context, contextId, uid) {
  if (context === "room") {
    return tx.get(db.collection("rooms").doc(contextId).collection("participants").doc(uid));
  }
  // These collections must be backed by real live/chat membership before
  // their gift controls are enabled. Never trust a caller-supplied recipient.
  if (context === "live") return tx.get(
    db.collection("live_streams").doc(contextId).collection("members").doc(uid));
  if (context === "chat") return tx.get(
    db.collection("conversations").doc(contextId).collection("members").doc(uid));
  throw economyError("Unknown gift context.", 400);
}
function eventDestination(db, context, contextId) {
  if (context === "room") return db.collection("rooms").doc(contextId).collection("gifts");
  if (context === "live") return db.collection("live_streams").doc(contextId).collection("gifts");
  return db.collection("conversations").doc(contextId).collection("messages");
}
async function thresholdTable(db) {
  const levels = await db.collection("gift_level_thresholds").where("active", "==", true).get();
  return levels.docs.map((doc) => doc.data())
    .filter((x) => Number.isSafeInteger(x.level) && Number.isSafeInteger(x.minPoints))
    .sort((a, b) => a.minPoints - b.minPoints);
}
const levelAt = (points, rows, oldLevel) =>
  rows.reduce((level, row) => points >= row.minPoints ? Math.max(level, row.level) : level,
    oldLevel);

async function verifiedUser(authenticatedUser, req) {
  const user = await authenticatedUser(req);
  if (!user?.uid || !id(user.uid)) throw economyError("Valid login required.", 401);
  return user;
}

export function registerEconomyRoutes(app, { db, authenticatedUser }) {
  app.get("/economy/config", async (_req, res, next) => {
    try {
      const config = await loadConfig(db);
      const { enabled, coinsPerUsd, receiverSharePercent, diamondUsdValue,
        withdrawalFeePercent, minWithdrawalDiamonds, holdDays,
        giftLevelPointsPerCoin, exchangeBonusPercent, minExchangeDiamonds } = config;
      res.json({ enabled, coinsPerUsd, receiverSharePercent, diamondUsdValue,
        withdrawalFeePercent, minWithdrawalDiamonds, holdDays,
        giftLevelPointsPerCoin, exchangeBonusPercent, minExchangeDiamonds });
    } catch (error) { next(error); }
  });

  // Existing RoomShopService continues to call /store/purchase. Entitlements
  // and spending are now server-only, and all types share store_items.
  app.post("/store/purchase", async (req, res, next) => {
    try {
      const user = await verifiedUser(authenticatedUser, req);
      const { itemId, recipientId, requestId } = req.body || {};
      if (!id(itemId) || !id(requestId) || (recipientId != null && !id(recipientId)))
        throw economyError("Invalid catalog purchase.", 400);
      const config = await loadConfig(db);
      const ownerId = recipientId || user.uid;
      const senderRef = db.collection("users").doc(user.uid);
      const ownerRef = db.collection("users").doc(ownerId);
      const itemRef = db.collection("store_items").doc(itemId);
      const inventoryRef = ownerRef.collection("inventory").doc(itemId);
      const legacyBackgroundRef = ownerRef.collection("room_backgrounds").doc(itemId);
      const dayRef = senderRef.collection("economy_daily").doc(dailyKey());
      const operationRef = db.collection("economy_actions").doc(
        createHash("sha256").update(user.uid + ":purchase:" + requestId).digest("hex"));
      const result = await db.runTransaction(async (tx) => {
        const [previous, listing, sender, owner, inventory, legacy, daily] =
          await Promise.all([tx.get(operationRef), tx.get(itemRef),
            tx.get(senderRef), tx.get(ownerRef), tx.get(inventoryRef),
            tx.get(legacyBackgroundRef), tx.get(dayRef)]);
        if (previous.exists) {
          if (previous.data()?.ownerId !== ownerId ||
              previous.data()?.itemId !== itemId)
            throw economyError("Purchase ID was reused.", 409);
          return { ...previous.data().result, alreadyProcessed:true };
        }
        if (!owner.exists || !sender.exists)
          throw economyError("Account not available.", 404);
        const item = listing.data() || {};
        if (!listing.exists || item.active !== true ||
            !["background", "frame", "entrance", "vip"].includes(item.type))
          throw economyError("This item is not for sale.", 409);
        const cost = item.priceCoins;
        if (!Number.isSafeInteger(cost) || cost < 0)
          throw economyError("Invalid store item price.", 503);
        const owned = inventory.data() || {};
        const previousExpiry = asDate(owned.expiresAt);
        const indefinite = inventory.exists &&
          owned.permanent === true && item.type !== "vip";
        if (indefinite) throw economyError("Item already owned permanently.", 409);
        const ttl = item.durationDays;
        if (ttl != null && (!Number.isSafeInteger(ttl) || ttl <= 0))
          throw economyError("Invalid item duration.", 503);
        if (item.type === "vip" && ttl == null)
          throw economyError("VIP must have a fixed duration.", 503);
        const before = positiveBalance(sender.data()?.coins);
        if (positiveBalance(sender.data()?.coinDebt) > 0 || sender.data()?.payoutHold === true)
          throw economyError("WALLET_UNDER_REVIEW", 403);
        if (before < cost) throw economyError("NOT_ENOUGH_COINS", 409);
        const dailyCoins = positiveBalance(daily.data()?.storeCoinsSpent);
        if (dailyCoins + cost > config.dailySendLimitCoins)
          throw economyError("DAILY_STORE_LIMIT", 429);
        const validCurrentExpiry = previousExpiry && previousExpiry > new Date()
          ? previousExpiry.getTime() : Date.now();
        const expiresAt = ttl == null ? null : Timestamp.fromMillis(
          validCurrentExpiry + ttl * 24 * 60 * 60 * 1000);
        tx.set(senderRef, {
          coins: before - cost, updatedAt:FieldValue.serverTimestamp(),
        }, { merge:true });
        tx.set(inventoryRef, {
          itemId, type:item.type, name:item.name || itemId,
          animationUrl:item.animationUrl || null, themeId:item.themeId || itemId,
          backgroundUrl:item.previewUrl || null,
          permanent: ttl == null, expiresAt,
          source:ownerId === user.uid ? "purchase" : "gift",
          updatedAt:FieldValue.serverTimestamp(),
        }, { merge:true });
        // Preserve legacy background display until its Flutter sheet has been
        // switched over completely to the inventory collection.
        if (item.type === "background") tx.set(legacyBackgroundRef, {
          itemId, themeId:item.themeId || itemId, name:item.name || itemId,
          backgroundUrl:item.previewUrl || null, source:"store_items",
          purchasedAt:FieldValue.serverTimestamp(),
          ...(expiresAt ? {expiresAt} : {}),
        }, { merge:true });
        if (item.type === "vip") {
          const previousVip = asDate(owner.data()?.vipUntil);
          const base = previousVip && previousVip > new Date()
            ? previousVip.getTime() : Date.now();
          // A gift extends a currently active VIP period.
          const until = Timestamp.fromMillis(base + ttl * 24 * 60 * 60 * 1000);
          tx.set(ownerRef, {
            vipUntil:until, isVip:true, updatedAt:FieldValue.serverTimestamp()
          }, { merge:true });
        }
        tx.set(dayRef, {storeCoinsSpent:dailyCoins+cost,
          updatedAt:FieldValue.serverTimestamp()}, {merge:true});
        ledger(tx, db, { userId:user.uid, type:ownerId===user.uid ?
          "store_purchase" : "store_gift", currency:"coins",
          amount:-cost, before, after:before-cost, source:"store",
          refId:operationRef.id, relatedUserId:ownerId,
          metadata:{itemId, itemType:item.type} });
        const output = {ok:true, balance:before-cost, ownerId,
          itemId, expiresAt: expiresAt ? expiresAt.toMillis() : null};
        tx.create(operationRef, {userId:user.uid, ownerId, itemId,
          result:output, createdAt:FieldValue.serverTimestamp()});
        return output;
      });
      res.json(result);
    } catch (error) {next(error);}
  });

  app.post("/gift/send", async (req, res, next) => {
    try {
      const user = await verifiedUser(authenticatedUser, req);
      const { context, contextId, recipientId, giftId, quantity,
        requestId } = req.body || {};
      if (!["room", "live", "chat"].includes(context) ||
          ![contextId, recipientId, giftId, requestId].every(id) ||
          !Number.isSafeInteger(quantity) || quantity < 1 || quantity > 100 ||
          recipientId === user.uid)
        throw economyError("Invalid gift request.", 400);
      if (recipientId === "teacher_ai" && context !== "room")
        throw economyError("Teacher AI only accepts gifts inside a room.", 400);
      const config = await loadConfig(db);
      const rows = await thresholdTable(db);
      const storeRef = db.collection("store_items").doc(giftId);
      const senderRef = db.collection("users").doc(user.uid);
      const recipientRef = db.collection("users").doc(recipientId);
      const stockRef = senderRef.collection("inventory").doc(giftId);
      const dayRef = senderRef.collection("economy_daily").doc(dailyKey());
      const dedupeId = createHash("sha256").update(user.uid + ":" + requestId).digest("hex");
      const dedupeRef = db.collection("economy_actions").doc(dedupeId);
      const dest = eventDestination(db, context, contextId).doc(dedupeId);
      const roomRef = db.collection("rooms").doc(contextId);

      const result = await db.runTransaction(async (tx) => {
        const [dedupe, product, sender, stock, today, senderMember,
          recipientMember, recipient] = await Promise.all([
          tx.get(dedupeRef), tx.get(storeRef), tx.get(senderRef), tx.get(stockRef),
          tx.get(dayRef), memberDocument(tx, db, context, contextId, user.uid),
          recipientId === "teacher_ai"
            ? Promise.resolve(null)
            : memberDocument(tx, db, context, contextId, recipientId),
          recipientId === "teacher_ai" ? Promise.resolve(null) : tx.get(recipientRef),
        ]);
        if (dedupe.exists) {
          const prior = dedupe.data() || {};
          if (prior.context !== context || prior.contextId !== contextId ||
              prior.recipientId !== recipientId || prior.giftId !== giftId ||
              prior.quantity !== quantity) throw economyError("Request ID was reused.", 409);
          return { ...prior.result, alreadyProcessed: true };
        }
        if (!senderMember.exists || (recipientId !== "teacher_ai" && !recipientMember?.exists))
          throw economyError("Sender and recipient must belong to this context.", 403);
        if (context === "chat" && recipientId === "teacher_ai")
          throw economyError("Invalid recipient.", 400);
        const item = product.data() || {};
        if (!product.exists || item.active !== true || item.type !== "gift")
          throw economyError("This gift is unavailable.", 409);
        const priceCoins = Number(item.priceCoins);
        const requiredGiftLevel = Number(item.requiredGiftLevel ?? 0);
        const senderData = sender.data() || {};
        if (!sender.exists || !Number.isSafeInteger(requiredGiftLevel) ||
            positiveBalance(senderData.giftLevel ?? 0) < requiredGiftLevel)
          throw economyError("Gift level requirement is not met.", 403);
        if (recipientId !== "teacher_ai" && !recipient?.exists)
          throw economyError("Recipient does not exist.", 404);
        const existingStock = stock.data() || {};
        const freeAvailable = asDate(existingStock.expiresAt) &&
          asDate(existingStock.expiresAt) <= new Date()
            ? 0 : positiveBalance(existingStock.freeGiftBalance ?? 0);
        const freeUsed = Math.min(freeAvailable, quantity);
        const paidQuantity = quantity - freeUsed;
        const quote = paidQuantity
          ? giftQuote(config, priceCoins, paidQuantity)
          : { coins: 0, diamonds: 0, receiverUsd: 0, giftLevelPoints: 0 };
        const senderCoinsBefore = positiveBalance(senderData.coins);
        if (positiveBalance(senderData.coinDebt) > 0 || senderData.payoutHold === true)
          throw economyError("WALLET_UNDER_REVIEW", 403);
        if (senderCoinsBefore < quote.coins)
          throw economyError("NOT_ENOUGH_COINS", 409);
        const spentToday = positiveBalance(today.data()?.giftCoinsSent);
        if (spentToday + quote.coins > config.dailySendLimitCoins)
          throw economyError("DAILY_GIFT_LIMIT", 429);
        const senderCoinsAfter = senderCoinsBefore - quote.coins;
        const levelPointsBefore = positiveBalance(senderData.giftLevelPoints);
        const levelPointsAfter = levelPointsBefore + quote.giftLevelPoints;
        const senderName = String(senderData.displayName || user.name || "WorldVoice user");
        const recipientName = recipientId === "teacher_ai" ? "Teacher AI"
          : String(recipient.data()?.displayName || "WorldVoice member");
        const giftEvent = {
          senderId: user.uid, senderName,
          recipientId, recipientName, giftId, quantity, freeUsed,
          points: quote.coins, priceCoins, diamonds: quote.diamonds,
          context, contextId, ...(item.animationUrl ? { animationUrl: item.animationUrl } : {}),
          createdAt: FieldValue.serverTimestamp(),
          type: context === "chat" ? "gift" : undefined,
        };
        if (giftEvent.type === undefined) delete giftEvent.type;
        tx.set(senderRef, {
          coins: senderCoinsAfter,
          giftSentPoints: positiveBalance(senderData.giftSentPoints) + quote.coins,
          giftLevelPoints: levelPointsAfter,
          giftLevel: levelAt(levelPointsAfter, rows, positiveBalance(senderData.giftLevel)),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        if (freeUsed) tx.set(stockRef, {
          freeGiftBalance: freeAvailable - freeUsed,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        if (quote.coins) tx.set(dayRef, {
          giftCoinsSent: spentToday + quote.coins,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        if (recipientId === "teacher_ai") {
          // Backend-only XP. Free gifts cannot mint XP.
          tx.set(roomRef, { roomXp: FieldValue.increment(quote.giftLevelPoints),
            updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        } else {
          const before = positiveBalance(recipient.data()?.diamonds);
          const after = before + quote.diamonds;
          tx.set(recipientRef, {
            diamonds: after, giftReceivedPoints:
              positiveBalance(recipient.data()?.giftReceivedPoints) + quote.coins,
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
          if (quote.diamonds) {
            const holdMs = config.holdDays * 24 * 60 * 60 * 1000;
            tx.create(recipientRef.collection("diamond_lots").doc(dedupeId), {
              sourceGiftEventId: dest.id, senderId: user.uid,
              source: "gift", diamonds: quote.diamonds,
              remaining: quote.diamonds, frozen: false,
              createdAt: FieldValue.serverTimestamp(),
              availableAt: Timestamp.fromMillis(Date.now() + holdMs),
            });
            ledger(tx, db, { userId: recipientId, type: "gift_received",
              currency: "diamonds", amount: quote.diamonds, before, after,
              source: context, refId: dest.id, context, relatedUserId: user.uid });
          }
        }
        tx.create(dest, giftEvent);
        ledger(tx, db, { userId: user.uid, type: "gift_sent",
          currency: "coins", amount: -quote.coins, before: senderCoinsBefore,
          after: senderCoinsAfter, source: context, refId: dest.id,
          context, relatedUserId: recipientId, metadata: { freeUsed, giftId, quantity } });
        const response = { ok: true, coinsSpent: quote.coins,
          freeGiftsUsed: freeUsed, diamondsCredited: quote.diamonds,
          balance: senderCoinsAfter, giftEventId: dest.id };
        tx.create(dedupeRef, { userId: user.uid, context, contextId,
          recipientId, giftId, quantity, result: response,
          createdAt: FieldValue.serverTimestamp() });
        return response;
      });
      res.json(result);
    } catch (error) { next(error); }
  });

  app.post("/wallet/exchange", async (req, res, next) => {
    try {
      const user = await verifiedUser(authenticatedUser, req);
      const diamonds = req.body?.diamonds;
      const requestId = req.body?.requestId;
      if (!id(requestId)) throw economyError("Request ID is required.", 400);
      const config = await loadConfig(db);
      const quote = exchangeQuote(config, diamonds);
      const userRef = db.collection("users").doc(user.uid);
      const actionRef = db.collection("economy_actions").doc(
        createHash("sha256").update(user.uid + ":exchange:" + requestId).digest("hex"));
      const eligible = await userRef.collection("diamond_lots")
        .where("availableAt", "<=", nowTimestamp()).limit(100).get();
      const result = await db.runTransaction(async (tx) => {
        const prior = await tx.get(actionRef);
        if (prior.exists) return { ...prior.data().result, alreadyProcessed: true };
        const [wallet, ...lots] = await Promise.all([
          tx.get(userRef), ...eligible.docs.map((doc) => tx.get(doc.ref))
        ]);
        if (wallet.data()?.payoutHold === true ||
            positiveBalance(wallet.data()?.coinDebt) > 0)
          throw economyError("WALLET_UNDER_REVIEW", 403);
        let remaining = diamonds;
        const consume = [];
        for (const lot of lots) {
          if (lot.data()?.frozen === true) continue;
          const take = Math.min(remaining, positiveBalance(lot.data()?.remaining));
          if (take) consume.push([lot.ref, positiveBalance(lot.data()?.remaining) - take]);
          remaining -= take;
          if (!remaining) break;
        }
        if (remaining > 0) throw economyError("DIAMONDS_STILL_ON_HOLD", 409);
        const oldDiamonds = positiveBalance(wallet.data()?.diamonds);
        if (oldDiamonds < diamonds) throw economyError("NOT_ENOUGH_DIAMONDS", 409);
        const oldCoins = positiveBalance(wallet.data()?.coins);
        for (const [ref, balance] of consume) tx.update(ref, { remaining: balance });
        tx.set(userRef, { diamonds: oldDiamonds - diamonds,
          coins: oldCoins + quote.totalCoins,
          updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        ledger(tx, db, { userId:user.uid, type:"diamond_exchange",
          currency:"diamonds", amount:-diamonds, before:oldDiamonds,
          after:oldDiamonds-diamonds, source:"exchange", refId:actionRef.id });
        ledger(tx, db, { userId:user.uid, type:"diamond_exchange",
          currency:"coins", amount:quote.totalCoins, before:oldCoins,
          after:oldCoins+quote.totalCoins, source:"exchange", refId:actionRef.id });
        const result = { ok:true, ...quote, coinsBalance:oldCoins+quote.totalCoins };
        tx.create(actionRef, { userId:user.uid, type:"exchange", result,
          createdAt:FieldValue.serverTimestamp() });
        return result;
      });
      res.json(result);
    } catch (error) { next(error); }
  });

  // A withdrawal request reserves eligible diamonds. Payment is NEVER made
  // automatically: KYC and payout-provider approvals are administrator gates.
  app.post("/wallet/withdraw", async (req, res, next) => {
    try {
      const user = await verifiedUser(authenticatedUser, req);
      const config = await loadConfig(db);
      const { diamonds, method, requestId } = req.body || {};
      const supported = ["paypal", "payoneer", "bank", "local_wallet"];
      if (!id(requestId) || !supported.includes(method))
        throw economyError("Invalid withdrawal request.", 400);
      const currentDay = new Date().getUTCDate();
      if (!config.withdrawalWindowDays.includes(currentDay))
        throw economyError("WITHDRAWAL_WINDOW_CLOSED", 409);
      const quote = withdrawalQuote(config, diamonds);
      const userRef = db.collection("users").doc(user.uid);
      const actionRef = db.collection("economy_actions").doc(
        createHash("sha256").update(user.uid + ":withdraw:" + requestId).digest("hex"));
      const requestRef = db.collection("withdraw_requests").doc(actionRef.id);
      const eligible = await userRef.collection("diamond_lots")
        .where("availableAt", "<=", nowTimestamp()).limit(100).get();
      const result = await db.runTransaction(async (tx) => {
        const previous = await tx.get(actionRef);
        if (previous.exists) return { ...previous.data().result, alreadyProcessed: true };
        const [wallet, ...lots] = await Promise.all([
          tx.get(userRef), ...eligible.docs.map((doc) => tx.get(doc.ref))
        ]);
        if (wallet.data()?.payoutHold === true ||
            positiveBalance(wallet.data()?.coinDebt) > 0)
          throw economyError("WALLET_UNDER_REVIEW", 403);
        if (wallet.data()?.kycStatus !== "verified")
          throw economyError("IDENTITY_VERIFICATION_REQUIRED", 403);
        let left = diamonds;
        const consume = [];
        for (const lot of lots) {
          if (lot.data()?.frozen === true) continue;
          const take = Math.min(left, positiveBalance(lot.data()?.remaining));
          if (take) consume.push([lot.ref, positiveBalance(lot.data()?.remaining) - take]);
          left -= take;
          if (!left) break;
        }
        if (left) throw economyError("DIAMONDS_STILL_ON_HOLD", 409);
        const before = positiveBalance(wallet.data()?.diamonds);
        if (before < diamonds) throw economyError("NOT_ENOUGH_DIAMONDS", 409);
        for (const [ref, count] of consume) tx.update(ref, { remaining: count });
        tx.set(userRef, {
          diamonds: before - diamonds,
          diamondsPendingWithdrawal:
            positiveBalance(wallet.data()?.diamondsPendingWithdrawal) + diamonds,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.create(requestRef, { userId:user.uid, method, diamonds,
          grossUsd:quote.grossUsd, feeUsd:quote.feeUsd, netUsd:quote.netUsd,
          status:"pending_admin_review", kycVerifiedAtRequest:true,
          requestedAt:FieldValue.serverTimestamp() });
        ledger(tx, db, { userId:user.uid, type:"withdrawal_reserved",
          currency:"diamonds", amount:-diamonds, before, after:before-diamonds,
          source:"withdrawal", refId:requestRef.id });
        const result = { ok:true, requestId:requestRef.id, status:"pending_admin_review", ...quote };
        tx.create(actionRef, { userId:user.uid, type:"withdraw", result,
          createdAt:FieldValue.serverTimestamp() });
        return result;
      });
      res.json(result);
    } catch (error) { next(error); }
  });
  // Admin-only audit/review. Firebase custom claims are assigned from an
  // offline trusted administrator environment, never by mobile clients.
  app.get("/admin/withdrawals", async (req, res, next) => {
    try {
      const moderator = await verifiedUser(authenticatedUser, req);
      if (moderator.admin !== true)
        throw economyError("Administrator authorization required.", 403);
      const status = String(req.query.status || "pending_admin_review");
      if (!["pending_admin_review", "approved_awaiting_payout",
        "paid", "rejected"].includes(status))
        throw economyError("Invalid withdrawal status.", 400);
      const snapshot = await db.collection("withdraw_requests")
        .where("status", "==", status).limit(100).get();
      res.json({ ok:true, requests:snapshot.docs.map((doc) =>
        ({id:doc.id, ...doc.data()})) });
    } catch (error) { next(error); }
  });

  app.post("/admin/withdrawals/:requestId/decision", async (req, res, next) => {
    try {
      const admin = await verifiedUser(authenticatedUser, req);
      if (admin.admin !== true)
        throw economyError("Administrator authorization required.", 403);
      const requestId = req.params.requestId;
      const decision = String(req.body?.decision || "");
      const reason = String(req.body?.reason || "").trim();
      if (!id(requestId) || !["approve", "reject"].includes(decision))
        throw economyError("Invalid review decision.", 400);
      if (decision === "reject" && !reason)
        throw economyError("Rejection requires a reason.", 400);
      const ref = db.collection("withdraw_requests").doc(requestId);
      const original = await ref.get();
      if (!original.exists) throw economyError("Request not found.", 404);
      const userRef = db.collection("users").doc(original.data().userId);
      const result = await db.runTransaction(async (tx) => {
        const [request, wallet] = await Promise.all([
          tx.get(ref), tx.get(userRef),
        ]);
        const data = request.data() || {};
        if (data.status !== "pending_admin_review")
          throw economyError("Request has already been reviewed.", 409);
        if (decision === "approve" &&
            (wallet.data()?.kycStatus !== "verified" ||
             wallet.data()?.payoutHold === true ||
             positiveBalance(wallet.data()?.coinDebt) > 0))
          throw economyError("Payout is blocked pending wallet/KYC review.", 403);
        const pending = positiveBalance(wallet.data()?.diamondsPendingWithdrawal);
        const count = Number(data.diamonds);
        if (!Number.isSafeInteger(count) || count <= 0 || pending < count)
          throw economyError("Withdrawal ledger mismatch.", 503);
        if (decision === "reject") {
          const before = positiveBalance(wallet.data()?.diamonds);
          tx.set(userRef, {
            diamonds:before+count,
            diamondsPendingWithdrawal:pending-count,
            updatedAt:FieldValue.serverTimestamp(),
          }, {merge:true});
          // Restore eligible diamonds without resetting the old hold period:
          // it already elapsed before the original withdrawal request.
          tx.create(userRef.collection("diamond_lots").doc("return_"+requestId), {
            source:"withdrawal_reversal",
            remaining:count, diamonds:count, frozen:false,
            createdAt:FieldValue.serverTimestamp(),
            availableAt:nowTimestamp(),
          });
          ledger(tx, db, {userId:data.userId, type:"withdrawal_rejected",
            currency:"diamonds", amount:count, before, after:before+count,
            source:"admin_review", refId:requestId,
            metadata:{reason,reviewedBy:admin.uid}});
        }
        const status = decision === "approve"
          ? "approved_awaiting_payout" : "rejected";
        tx.update(ref, {status, reviewReason:reason, reviewerUid:admin.uid,
          reviewedAt:FieldValue.serverTimestamp()});
        tx.create(db.collection("economy_audit").doc(), {
          type:"withdrawal_review", withdrawRequestId:requestId,
          decision,status, reviewerUid:admin.uid, reason,
          createdAt:FieldValue.serverTimestamp(),
        });
        return {ok:true, status};
      });
      res.json(result);
    } catch (error) {next(error);}
  });

  // Payout confirmation requires a real provider reference. This route
  // RECORDS an already completed manual transfer; it does NOT send money.
  app.post("/admin/withdrawals/:requestId/mark-paid", async (req, res, next) => {
    try {
      const admin = await verifiedUser(authenticatedUser, req);
      if (admin.admin !== true)
        throw economyError("Administrator authorization required.", 403);
      const requestId = req.params.requestId;
      const providerReference = String(req.body?.providerReference || "").trim();
      if (!id(requestId) || providerReference.length < 8 || providerReference.length > 180)
        throw economyError("An external payout reference is required.", 400);
      const ref = db.collection("withdraw_requests").doc(requestId);
      const snapshot = await ref.get();
      if (!snapshot.exists) throw economyError("Withdrawal not found.", 404);
      const userRef = db.collection("users").doc(snapshot.data().userId);
      const result = await db.runTransaction(async (tx) => {
        const [request, wallet] = await Promise.all([
          tx.get(ref), tx.get(userRef),
        ]);
        const data = request.data() || {};
        if (data.status !== "approved_awaiting_payout")
          throw economyError("Request is not ready for payout confirmation.", 409);
        const diamonds = Number(data.diamonds);
        const pending = positiveBalance(wallet.data()?.diamondsPendingWithdrawal);
        if (!Number.isSafeInteger(diamonds) || pending < diamonds)
          throw economyError("Withdrawal reserve mismatch.", 503);
        tx.update(ref, {status:"paid", providerReference,
          paidAt:FieldValue.serverTimestamp(),
          confirmedBy:admin.uid});
        tx.set(userRef, {diamondsPendingWithdrawal:pending-diamonds,
          updatedAt:FieldValue.serverTimestamp()}, {merge:true});
        tx.create(db.collection("economy_audit").doc(), {
          type:"withdrawal_marked_paid", withdrawRequestId:requestId,
          method:data.method, providerReference, confirmedBy:admin.uid,
          createdAt:FieldValue.serverTimestamp(),
        });
        return {ok:true,status:"paid"};
      });
      res.json(result);
    } catch (error) {next(error);}
  });

}
