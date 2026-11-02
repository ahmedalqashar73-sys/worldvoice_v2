import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {worldVoiceGiftCatalog} from "./gift_catalog.js";
import {ownerBetaChatDebit} from "./owner_beta_chat_gifts.js";
import {privateWalletRef, requirePrivateWallet} from "./wallet_store.js";

export function validateBetaContextMembership({
  context, session, senderId, recipientId, senderMember, recipientMember,
  now = Date.now(),
}) {
  if (context === "room") {
    return session?.isOpen === true && senderMember?.exists === true &&
      recipientMember?.exists === true;
  }
  if (context !== "live") return false;
  const heartbeat = session?.hostHeartbeatAt?.toMillis?.() ?? 0;
  const validLive = session?.isLive === true &&
    heartbeat > now - 60000;
  const senderIsHost = session?.hostId === senderId;
  const recipientIsHost = session?.hostId === recipientId;
  const senderIsViewer = senderMember?.exists === true &&
    senderMember.data()?.uid === senderId;
  const recipientIsGuest = recipientMember?.exists === true &&
    recipientMember.data()?.uid === recipientId &&
    recipientMember.data()?.status === "accepted";
  return validLive && (senderIsHost || senderIsViewer) &&
    (recipientIsHost || recipientIsGuest);
}

// For the authenticated, verified owner only. Every gift is backed by a
// transaction and an actual room/live session; admin coins never become
// redeemable diamonds and ordinary production economy remains gated.
export function registerOwnerBetaContextGiftRoutes({
  app, db, authenticatedUser, isVerifiedOwner, validChannelName,
}) {
  app.post("/gift/owner-beta-context", async (req, res, next) => {
    try {
      if (process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED !== "true") {
        return res.status(503).json({error: "Owner beta gifts disabled."});
      }
      const sender = await authenticatedUser(req);
      if (!await isVerifiedOwner(sender)) {
        return res.status(403).json({error: "Verified owner required."});
      }
      const {context, contextId, recipientId, giftId} = req.body || {};
      const key = String(req.headers["idempotency-key"] || "").trim();
      if (!["room", "live"].includes(context) ||
          !validChannelName(contextId) ||
          !/^[A-Za-z0-9_-]{8,160}$/.test(recipientId) ||
          recipientId === sender.uid ||
          !/^wv_gift_[0-9]{3}$/.test(giftId) ||
          Number(req.body?.quantity ?? 1) !== 1 ||
          !/^[A-Za-z0-9_-]{12,100}$/.test(key)) {
        return res.status(400).json({error: "Invalid gift request."});
      }
      const gift = worldVoiceGiftCatalog.get(giftId);
      if (!gift || !Number.isSafeInteger(gift.priceCoins) ||
          gift.priceCoins <= 0) {
        return res.status(404).json({error: "Gift unavailable."});
      }
      const id = createHash("sha256")
        .update("owner-beta-context:" + sender.uid + ":" + key).digest("hex");
      const sessionRef = db.collection(
        context === "room" ? "rooms" : "live_sessions").doc(contextId);
      const senderRef = db.collection("users").doc(sender.uid);
      const recipientRef = db.collection("users").doc(recipientId);
      const walletRef = privateWalletRef(senderRef);
      const senderMemberRef = sessionRef.collection(
        context === "room" ? "participants" : "viewers").doc(sender.uid);
      const recipientMemberRef = sessionRef.collection(
        context === "room" ? "participants" : "join_requests").doc(recipientId);
      const operationRef = db.collection("owner_beta_gift_operations").doc(id);
      const blockedBySenderRef =
        senderRef.collection("blocked_peers").doc(recipientId);
      const blockedByRecipientRef =
        recipientRef.collection("blocked_peers").doc(sender.uid);
      const refs = [operationRef, sessionRef, senderMemberRef,
        recipientMemberRef, senderRef, recipientRef, walletRef,
        blockedBySenderRef, blockedByRecipientRef];
      const result = await db.runTransaction(async tx => {
        const [operation, session, senderMember, recipientMember,
          senderProfile, recipientProfile, walletSnap,
          senderBlock, recipientBlock] = await Promise.all(
          refs.map(ref => tx.get(ref)));
        if (operation.exists) {
          const old = operation.data();
          if (old.senderId !== sender.uid ||
              old.context !== context || old.contextId !== contextId ||
              old.recipientId !== recipientId || old.giftId !== giftId) {
            throw Object.assign(new Error("Idempotency key reused."),
              {status: 409});
          }
          return {...old.outcome, alreadyProcessed: true};
        }
        if (!session.exists || !senderProfile.exists ||
            !recipientProfile.exists || senderBlock.exists ||
            recipientBlock.exists ||
            !validateBetaContextMembership({
              context, session: session.data(), senderId: sender.uid,
              recipientId, senderMember, recipientMember,
            })) {
          throw Object.assign(new Error(
            "Active room/live membership and unblocked accounts required."),
          {status: 403});
        }
        if (context === "live" &&
            session.data()?.channelId !== contextId) {
          throw Object.assign(new Error("Live session mismatch."), {status: 403});
        }
        const wallet = requirePrivateWallet(walletSnap);
        const debit = ownerBetaChatDebit({
          coins: wallet.coins, adminCoins: wallet.adminCoins,
          priceCoins: gift.priceCoins,
          frozen: wallet.walletFrozen === true,
          debtCoins: wallet.walletDebtCoins ?? 0,
        });
        const senderName = String(
          senderProfile.data()?.displayName || "WorldVoice user");
        const recipientName = String(
          recipientProfile.data()?.displayName || "WorldVoice member");
        const receipt = {
          giftId, recipientId, context, contextId,
          chargedCoins: gift.priceCoins,
          balanceAfter: debit.balanceAfter, adminCoinsSpent: gift.priceCoins,
          paidCoinsSpent: 0, pendingDiamonds: 0,
          ownerBetaGift: true, nonRedeemable: true,
        };
        tx.update(walletRef, {
          coins: debit.balanceAfter, adminCoins: debit.adminAfter,
          giftSentPoints: FieldValue.increment(gift.priceCoins),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.create(senderRef.collection("wallet_transactions").doc(id), {
          type: "owner_beta_context_gift", currency: "coins",
          amount: -gift.priceCoins, balanceBefore: wallet.coins,
          balanceAfter: debit.balanceAfter, adminCoinsSpent: gift.priceCoins,
          paidCoinsSpent: 0, recipientId, giftId, context, contextId,
          nonRedeemable: true, createdAt: FieldValue.serverTimestamp(),
        });
        const card = {
          senderId: sender.uid, senderName, recipientId, recipientName,
          giftId, itemId: giftId, type: "gift", quantity: 1,
          points: gift.priceCoins, priceCoins: gift.priceCoins,
          name: gift.name, nameAr: gift.nameAr,
          ownerBetaGift: true, nonRedeemable: true, pendingDiamonds: 0,
          context, contextId, createdAt: FieldValue.serverTimestamp(),
        };
        tx.create(sessionRef.collection("gifts").doc(id), card);
        tx.create(recipientRef.collection("gift_notifications").doc(id), {
          ...card, seen: false,
        });
        tx.create(senderRef.collection("gift_wall_sent").doc(id), card);
        tx.create(operationRef, {
          senderId: sender.uid, recipientId, context, contextId,
          giftId, outcome: receipt, createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(db.collection("economy_audit").doc(id), {
          type: "owner_beta_context_gift", senderId: sender.uid, recipientId,
          giftId, context, contextId, adminCoinsSpent: gift.priceCoins,
          paidCoinsSpent: 0, nonRedeemable: true,
          createdAt: FieldValue.serverTimestamp(),
        });
        return {...receipt, alreadyProcessed: false};
      });
      return res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });
}
