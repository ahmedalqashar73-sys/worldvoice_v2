import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {worldVoiceGiftCatalog} from "./gift_catalog.js";
import {chatIdFor, assertChatMembership} from "./chat_membership.js";
import {privateWalletRef, requirePrivateWallet} from "./wallet_store.js";

// Non-redeemable verified-owner-only gifts to a real private chat.
// Requires an explicit server setting. No diamond lots, no paid coins, no
// withdrawal or purchase policy is touched.
export function registerOwnerBetaChatGiftRoutes({
  app, db, authenticatedUser, isVerifiedOwner, notifyGift,
}) {
  app.post("/gift/owner-beta-chat", async (req, res, next) => {
    try {
      if (process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED !== "true") {
        return res.status(503).json({error: "Owner beta gifts are disabled."});
      }
      const sender = await authenticatedUser(req);
      if (!await isVerifiedOwner(sender)) {
        return res.status(403).json({error: "Verified owner required."});
      }
      const recipientId = String(req.body?.recipientId || "").trim();
      const chatId = String(req.body?.contextId || "").trim();
      const giftId = String(req.body?.giftId || "").trim();
      const key = String(req.headers["idempotency-key"] || "").trim();
      if (!/^[A-Za-z0-9_-]{8,160}$/.test(recipientId) ||
          !/^[a-f0-9]{64}$/.test(chatId) ||
          !/^wv_gift_[0-9]{3}$/.test(giftId) ||
          !/^[A-Za-z0-9_-]{12,100}$/.test(key) ||
          Number(req.body?.quantity ?? 1) !== 1 ||
          recipientId === sender.uid ||
          chatIdFor(sender.uid, recipientId) !== chatId) {
        return res.status(400).json({error: "Invalid beta gift request."});
      }
      const gift = worldVoiceGiftCatalog.get(giftId);
      if (!gift || !Number.isSafeInteger(gift.priceCoins) ||
          gift.priceCoins <= 0) {
        return res.status(404).json({error: "Unapproved gift."});
      }
      const id = createHash("sha256")
        .update("owner-beta-chat:" + sender.uid + ":" + key).digest("hex");
      const senderRef = db.collection("users").doc(sender.uid);
      const recipientRef = db.collection("users").doc(recipientId);
      const chatRef = db.collection("chats").doc(chatId);
      const walletRef = privateWalletRef(senderRef);
      const operationRef = db.collection("owner_beta_gift_operations").doc(id);
      const refs = [operationRef, chatRef, senderRef, recipientRef, walletRef,
        senderRef.collection("blocked_peers").doc(recipientId),
        recipientRef.collection("blocked_peers").doc(sender.uid)];
      const outcome = await db.runTransaction(async tx => {
        const [operation, chat, senderProfile, recipientProfile, walletSnap,
          senderBlocked, recipientBlocked] = await Promise.all(refs.map(ref => tx.get(ref)));
        if (operation.exists) {
          const old = operation.data();
          if (old.senderId !== sender.uid || old.recipientId !== recipientId ||
              old.chatId !== chatId || old.giftId !== giftId) {
            throw Object.assign(new Error("Idempotency key mismatch."), {status: 409});
          }
          return {...old.outcome, alreadyProcessed: true};
        }
        if (!chat.exists || !senderProfile.exists ||
            !recipientProfile.exists || senderBlocked.exists ||
            recipientBlocked.exists) {
          throw Object.assign(new Error("Chat or recipient unavailable."), {status: 403});
        }
        assertChatMembership(chat.data(), sender.uid, recipientId);
        const wallet = requirePrivateWallet(walletSnap);
        const before = wallet.coins;
        const administrative = wallet.adminCoins;
        if (![before, administrative].every(Number.isSafeInteger) ||
            before < gift.priceCoins || administrative < gift.priceCoins ||
            administrative > before ||
            wallet.walletFrozen === true ||
            Number(wallet.walletDebtCoins ?? 0) > 0) {
          throw Object.assign(new Error("Not enough valid administrative coins."), {status: 409});
        }
        const after = before - gift.priceCoins;
        const result = {
          giftId, recipientId, chargedCoins: gift.priceCoins,
          adminCoinsSpent: gift.priceCoins, paidCoinsSpent: 0,
          pendingDiamonds: 0, balanceAfter: after,
          nonRedeemable: true, ownerBetaGift: true,
        };
        tx.update(walletRef, {
          coins: after, adminCoins: administrative - gift.priceCoins,
          giftSentPoints: FieldValue.increment(gift.priceCoins),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.create(senderRef.collection("wallet_transactions").doc(id), {
          type: "owner_beta_chat_gift", currency: "coins",
          amount: -gift.priceCoins, balanceBefore: before, balanceAfter: after,
          adminCoinsSpent: gift.priceCoins, paidCoinsSpent: 0,
          giftId, recipientId, chatId, nonRedeemable: true,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(chatRef.collection("messages").doc(id), {
          type: "gift", senderId: sender.uid,
          senderName: String(senderProfile.data()?.displayName || "WorldVoice user"),
          recipientId,
          recipientName: String(recipientProfile.data()?.displayName || "WorldVoice member"),
          giftId, points: gift.priceCoins, quantity: 1,
          animationUrl: null, ownerBetaGift: true,
          pendingDiamonds: 0, nonRedeemable: true,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(chatRef, {
          latestText: "🎁 Gift (test)",
          lastMessageAt: FieldValue.serverTimestamp(),
        });
        tx.create(recipientRef.collection("gift_notifications").doc(id), {
          senderId: sender.uid, giftId, itemId: giftId,
          type: "gift", name: gift.name, nameAr: gift.nameAr,
          quantity: 1, priceCoins: gift.priceCoins,
          ownerBetaGift: true, pendingDiamonds: 0,
          nonRedeemable: true, seen: false,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(operationRef, {
          senderId: sender.uid, recipientId, chatId, giftId,
          outcome: result, createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(db.collection("economy_audit").doc(id), {
          type: "owner_beta_chat_gift",
          senderId: sender.uid, recipientId, giftId, chatId,
          adminCoinsSpent: gift.priceCoins, paidCoinsSpent: 0,
          pendingDiamonds: 0, nonRedeemable: true,
          createdAt: FieldValue.serverTimestamp(),
        });
        return {...result, alreadyProcessed: false};
      });
      res.json({ok: true, ...outcome});
      if (!outcome.alreadyProcessed && typeof notifyGift === "function") {
        void notifyGift(recipientId, giftId).catch(() => {});
      }
    } catch (error) { next(error); }
  });
}
