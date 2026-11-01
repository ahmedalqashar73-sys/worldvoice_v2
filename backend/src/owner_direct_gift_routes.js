import {createHash} from "node:crypto";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {worldVoiceGiftCatalog, approvedWorldVoiceGift} from "./gift_catalog.js";
import {requireLiveEconomy} from "./economy_policy.js";
import {giftProgress} from "./member_badge_policy.js";
import {privateWalletRef, requirePrivateWallet} from "./wallet_store.js";
import {splitOwnerCoinSpend, diamondsForPaidCoins} from "./owner_coin_policy.js";

// Direct delivery of EXISTING gifts to any user for the verified owner.
// This is a private gift receipt, not a fabricated room/live/chat activity.
export function registerOwnerDirectGiftRoutes({
  app, db, authenticatedUser, isVerifiedOwner, notifyGift,
}) {
  app.post("/gift/owner-direct", async (req, res, next) => {
    try {
      const sender = await authenticatedUser(req);
      if (!isVerifiedOwner(sender)) {
        return res.status(403).json({error: "Owner access required."});
      }
      const recipientId = String(req.body?.recipientId || "").trim();
      const giftId = String(req.body?.giftId || "").trim();
      const quantity = Number(req.body?.quantity ?? 1);
      const key = String(req.headers["idempotency-key"] || "").trim();
      if (!/^[A-Za-z0-9_-]{1,128}$/.test(recipientId) ||
          recipientId === sender.uid ||
          !/^wv_gift_[0-9]{3}$/.test(giftId) ||
          !Number.isSafeInteger(quantity) || quantity < 1 || quantity > 100 ||
          !/^[A-Za-z0-9_-]{12,100}$/.test(key)) {
        return res.status(400).json({error: "Invalid direct gift request."});
      }
      const catalog = worldVoiceGiftCatalog.get(giftId);
      if (!catalog) return res.status(404).json({error: "Gift unavailable."});
      const id = createHash("sha256")
        .update("owner-direct:" + sender.uid + ":" + key).digest("hex");
      const senderRef = db.collection("users").doc(sender.uid);
      const recipientRef = db.collection("users").doc(recipientId);
      const payerWalletRef = privateWalletRef(senderRef);
      const recipientWalletRef = privateWalletRef(recipientRef);
      const operationRef = db.collection("economy_gift_operations").doc(id);
      const itemRef = db.collection("store_items").doc("gift__" + giftId);
      const configRef = db.doc("economy_config/current");
      const senderBlockRef = senderRef.collection("blocked_peers").doc(recipientId);
      const recipientBlockRef = recipientRef.collection("blocked_peers").doc(sender.uid);
      const outcome = await db.runTransaction(async tx => {
        const [operation, senderProfile, recipientProfile, payerWallet,
          recipientWallet, item, configSnap, senderBlock, recipientBlock] =
            await Promise.all([operationRef, senderRef, recipientRef,
              payerWalletRef, recipientWalletRef, itemRef, configRef,
              senderBlockRef, recipientBlockRef].map(ref => tx.get(ref)));
        if (operation.exists) {
          const old = operation.data();
          if (old.senderId !== sender.uid || old.recipientId !== recipientId ||
              old.giftId !== giftId || old.quantity !== quantity) {
            throw Object.assign(new Error("Idempotency key reused."),
              {status: 409});
          }
          return {...old.outcome, alreadyProcessed: true};
        }
        const config = requireLiveEconomy(configSnap.data());
        requirePrivateWallet(payerWallet);
        requirePrivateWallet(recipientWallet);
        const product = item.data() || {};
        if (!item.exists || product.type !== "gift" ||
            product.active !== true ||
            !approvedWorldVoiceGift(giftId, product.priceCoins)) {
          throw Object.assign(new Error("Gift is not published."),
            {status: 404});
        }
        if (!senderProfile.exists || !recipientProfile.exists ||
            senderBlock.exists || recipientBlock.exists) {
          throw Object.assign(new Error("Recipient not available for gifting."),
            {status: 403});
        }
        const wallet = payerWallet.data() || {};
        if (wallet.walletFrozen === true ||
            Number(wallet.walletDebtCoins || 0) > 0) {
          throw Object.assign(new Error("Wallet under review."), {status: 423});
        }
        if (giftProgress(wallet).level <
            Number(product.requiredGiftLevel || 0)) {
          throw Object.assign(new Error("Gift level requirement not met."),
            {status: 403});
        }
        const amount = catalog.priceCoins * quantity;
        if (!Number.isSafeInteger(amount) || amount <= 0) {
          throw Object.assign(new Error("Gift total is invalid."),
            {status: 400});
        }
        const coinsBefore = Number(wallet.coins);
        if (!Number.isSafeInteger(coinsBefore) || coinsBefore < amount) {
          throw Object.assign(new Error("NOT_ENOUGH_COINS"), {status: 409});
        }
        const split = splitOwnerCoinSpend({
          coins: coinsBefore, adminCoins: Number(wallet.adminCoins ?? 0), amount,
        });
        const pendingDiamonds = diamondsForPaidCoins({
          config, paidCoins: split.paidSpent,
        });
        const previousPending = Number(recipientWallet.data()?.diamondsPending || 0);
        if (!Number.isSafeInteger(previousPending) || previousPending < 0 ||
            !Number.isSafeInteger(previousPending + pendingDiamonds)) {
          throw Object.assign(new Error("Recipient wallet requires review."),
            {status: 409});
        }
        const points = giftProgress(wallet).points + amount;
        if (!Number.isSafeInteger(points) ||
            !Number.isSafeInteger(amount * config.giftLevelPointsPerCoin)) {
          throw Object.assign(new Error("Gift level overflow."),
            {status: 409});
        }
        const holdUntil = Timestamp.fromMillis(
          Date.now() + config.holdDays * 86400000);
        const result = {
          giftId, recipientId, quantity, chargedCoins: amount,
          adminCoinsSpent: split.adminSpent, paidCoinsSpent: split.paidSpent,
          pendingDiamonds, balanceAfter: split.remainingCoins,
          name: catalog.name, nameAr: catalog.nameAr,
        };
        tx.update(payerWalletRef, {
          coins: split.remainingCoins, adminCoins: split.remainingAdminCoins,
          giftSentPoints: FieldValue.increment(amount),
          giftLevelCoins: points,
          giftLevel: giftProgress({giftSentPoints: points}).level,
          giftLevelPoints: FieldValue.increment(
            amount * config.giftLevelPointsPerCoin),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.update(recipientWalletRef, {
          giftReceivedPoints: FieldValue.increment(amount),
          diamondsPending: previousPending + pendingDiamonds,
          updatedAt: FieldValue.serverTimestamp(),
        });
        if (pendingDiamonds > 0) {
          tx.create(recipientRef.collection("diamond_lots").doc(id), {
            status: "pending", diamonds: pendingDiamonds, senderId: sender.uid,
            source: "owner_direct", giftId, holdUntil,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        tx.create(senderRef.collection("wallet_transactions").doc(id), {
          type: "owner_direct_gift", currency: "coins", amount: -amount,
          balanceBefore: coinsBefore, balanceAfter: split.remainingCoins,
          adminCoinsSpent: split.adminSpent, paidCoinsSpent: split.paidSpent,
          recipientId, itemId: giftId, quantity,
          createdAt: FieldValue.serverTimestamp(),
        });
        if (pendingDiamonds > 0) {
          tx.create(recipientRef.collection("wallet_transactions").doc(id), {
            type: "gift_received_pending", currency: "diamonds_pending",
            amount: pendingDiamonds, balanceBefore: previousPending,
            balanceAfter: previousPending + pendingDiamonds,
            holdUntil, senderId: sender.uid, itemId: giftId,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        tx.create(recipientRef.collection("gift_notifications").doc(id), {
          senderId: sender.uid, senderName:
            String(senderProfile.data()?.displayName || "WorldVoice user"),
          itemId: giftId, type: "gift", name: catalog.name,
          nameAr: catalog.nameAr, quantity, priceCoins: amount,
          seen: false, createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(operationRef, {
          senderId: sender.uid, recipientId, giftId, quantity,
          outcome: result, createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(db.collection("economy_audit").doc(id), {
          type: "owner_direct_gift", senderId: sender.uid, recipientId,
          giftId, quantity, chargedCoins: amount,
          adminCoinsSpent: split.adminSpent, paidCoinsSpent: split.paidSpent,
          pendingDiamonds, createdAt: FieldValue.serverTimestamp(),
        });
        return {...result, alreadyProcessed: false};
      });
      res.json({ok: true, ...outcome});
      if (!outcome.alreadyProcessed && typeof notifyGift === "function") {
        void notifyGift(recipientId, giftId).catch(() => {});
      }
    } catch (error) {
      next(error);
    }
  });
}
