import {createHash} from "node:crypto";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {giftProgress} from "./member_badge_policy.js";
import {privateWalletRef, requirePrivateWallet} from "./wallet_store.js";
import {requireLiveEconomy, calculateGiftSettlement} from "./economy_policy.js";
import {chatIdFor, assertChatMembership} from "./chat_membership.js";
import {BOND_TYPES, bondKey} from "./world_bond_routes.js";
import {approvedWorldVoiceGift, approvedWorldBondGift} from "./gift_catalog.js";
import {roomProgressAfterGift, roomCastleProgressSnapshot,
  ROOM_CASTLE_XP_VERSION} from "./room_task_policy.js";

// Separate authenticated APIs; one settlement implementation preserves wallet
// holds, shared daily limits, atomic receipts and existing room/live behavior.
export function registerGiftSendRoutes({app, db, authenticatedUser, validChannelName}) {
const send = bondOnly => async (req, res, next) => {
  try {
    const sender = await authenticatedUser(req);
    const {recipientId, giftId, type} = req.body || {};
    const context = bondOnly ? "worldbond" : req.body?.context;
    const contextId = bondOnly && BOND_TYPES.includes(type) && typeof recipientId === "string"
      ? bondKey(sender.uid, recipientId, type) : req.body?.contextId;
    const quantity = bondOnly ? 1 : Number(req.body?.quantity);
    const requestKey = String(req.headers["idempotency-key"] || "").trim();
    if (!(bondOnly ? context === "worldbond" && BOND_TYPES.includes(type) :
        ["room", "live", "chat"].includes(context)) ||
        !(["chat", "worldbond"].includes(context) ? /^[a-f0-9]{64}$/.test(contextId) :
          validChannelName(contextId)) ||
        typeof recipientId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(recipientId) ||
        recipientId === sender.uid ||
        typeof giftId !== "string" ||
        !(bondOnly ? approvedWorldBondGift(giftId) : /^wv_gift_[0-9]{3}$/.test(giftId)) ||
        !Number.isSafeInteger(quantity) || quantity <= 0 ||
        !/^[A-Za-z0-9_-]{12,100}$/.test(requestKey)) {
      return res.status(400).json({error: "Invalid gift request or idempotency key."});
    }
    if (context !== "room" && recipientId === "teacher_ai") {
      return res.status(400).json({error: "AI gift XP is room-only."});
    }
    const bondGift = approvedWorldBondGift(giftId);
    const requestHash = createHash("sha256")
      .update(`${bondOnly ? "worldbond:" : ""}${sender.uid}:${requestKey}`).digest("hex");
    const eventRef = db.collection(bondOnly ? "world_bond_gift_operations" : "economy_gift_operations").doc(requestHash);
    const senderRef = db.collection("users").doc(sender.uid);
    const senderWalletRef = privateWalletRef(senderRef);
    const recipientRef = recipientId === "teacher_ai" ? null
      : db.collection("users").doc(recipientId);
    const recipientWalletRef = recipientRef ? privateWalletRef(recipientRef) : null;
    const inventoryRef = senderRef.collection("inventory")
      .doc(`gift__${giftId}`);
    const itemRef = db.collection("store_items").doc(`gift__${giftId}`);
    const roomRef = bondOnly ? db.collection("world_bonds").doc(contextId) : context === "chat"
      ? db.collection("chats").doc(contextId)
      : context === "live"
        ? db.collection("live_sessions").doc(contextId)
        : db.collection("rooms").doc(contextId);
    const senderMemberRef = context === "room"
      ? roomRef.collection("participants").doc(sender.uid)
      : context === "live"
        ? roomRef.collection("viewers").doc(sender.uid)
        : roomRef;
    const recipientMemberRef = recipientRef
      ? context === "room"
        ? roomRef.collection("participants").doc(recipientId)
        : context === "live"
          ? roomRef.collection("join_requests").doc(recipientId)
          : roomRef
      : null;
    const senderFollow = context === "chat"
      ? senderRef.collection("following").doc(recipientId) : null;
    const recipientFollow = context === "chat"
      ? recipientRef.collection("following").doc(sender.uid) : null;
    const configRef = db.collection("economy_config").doc("current");
    const giftEventRef = bondOnly ? roomRef.collection("gifts").doc(requestHash) : context === "chat"
      ? roomRef.collection("messages").doc(requestHash)
      : roomRef.collection("gifts").doc(requestHash);

    const outcome = await db.runTransaction(async (tx) => {
      // All reads before writes (Firestore transaction requirement).
      const refs = [eventRef, configRef, itemRef, roomRef, senderMemberRef,
        senderRef, senderWalletRef, inventoryRef, ...(recipientRef
          ? [recipientMemberRef, recipientRef, recipientWalletRef] : []),
        ...(senderFollow ? [senderFollow, recipientFollow] : [])];
      const snapshots = await Promise.all(refs.map(ref => tx.get(ref)));
      const [existing, configSnap, itemSnap, roomSnap, senderMember,
        senderProfileSnap, senderSnap, freeGiftSnap] = snapshots;
      if (existing.exists) {
        const data = existing.data();
        if (data.userId !== sender.uid || data.context !== context ||
            data.contextId !== contextId || data.recipientId !== recipientId ||
            data.giftId !== giftId || data.quantity !== quantity) {
          throw Object.assign(new Error("Idempotency key reused for another request."),
            {status: 409});
        }
        return {...data.outcome, alreadyProcessed: true};
      }
      if (context === "room") {
        if (roomSnap.data()?.isOpen !== true ||
            !senderMember.exists ||
            (recipientMemberRef && !snapshots[8].exists)) {
          throw Object.assign(new Error("Room membership is required."),
            {status: 403});
        }
      } else if (context === "live") {
        const live = roomSnap.data() || {};
        const heartbeatMs = live.hostHeartbeatAt?.toMillis?.() ?? 0;
        const liveFresh = roomSnap.exists &&
          live.isLive === true &&
          live.channelId === contextId &&
          heartbeatMs > Date.now() - 60000;
        const senderIsHost = live.hostId === sender.uid;
        const senderIsViewer = senderMember.exists &&
          senderMember.data()?.uid === sender.uid;
        const recipientIsHost = live.hostId === recipientId;
        const recipientRequest = snapshots[8]?.data() || {};
        const recipientIsGuest = snapshots[8]?.exists &&
          recipientRequest.uid === recipientId &&
          recipientRequest.status === "accepted";
        if (!liveFresh || (!senderIsHost && !senderIsViewer) ||
            (!recipientIsHost && !recipientIsGuest)) {
          throw Object.assign(new Error("Active Live membership is required."),
            {status: 403});
        }
      } else if (!bondOnly) {
        if (!roomSnap.exists ||
            chatIdFor(sender.uid, recipientId) !== contextId ||
            !snapshots[11]?.exists || !snapshots[12]?.exists) {
          throw Object.assign(new Error("Mutual following required for chat gifts."),
            {status: 403});
        }
        assertChatMembership(roomSnap.data(), sender.uid, recipientId);
      }
      if (bondOnly) {
        const bond = roomSnap.data() || {};
        if (!roomSnap.exists || bond.status !== "active" || bond.type !== type ||
            !Array.isArray(bond.members) || bond.members.length !== 2 ||
            !bond.members.includes(sender.uid) || !bond.members.includes(recipientId)) {
          throw Object.assign(new Error("يجب قبول علاقة WorldBond أولًا."), {status: 403});
        }
        const blocks = await Promise.all([
          senderRef.collection("blocked_peers").doc(recipientId),
          recipientRef.collection("blocked_peers").doc(sender.uid),
        ].map(ref => tx.get(ref)));
        if (blocks.some(snap => snap.exists)) {
          throw Object.assign(new Error("لا يمكن الإهداء بين مستخدمين محظورين."), {status: 403});
        }
      }
      const config = requireLiveEconomy(configSnap.data());
      requirePrivateWallet(senderSnap);
      if (recipientRef) requirePrivateWallet(snapshots[10]);
      // The four WorldBond designs are server-priced built-ins. They do
      // not appear in store_items or the room/Live gift catalog.
      const item = bondGift
        ? {type: "gift", active: true, priceCoins: bondGift.priceCoins,
            name: bondGift.name, animationUrl: null, requiredGiftLevel: 0}
        : itemSnap.data();
      const price = Number(item?.priceCoins);
      const approvedGift = bondGift || approvedWorldVoiceGift(giftId, price);
      if ((!itemSnap.exists && !bondGift) ||
          item?.type !== "gift" || item?.active !== true ||
          !Number.isSafeInteger(price) || price <= 0 || !approvedGift) {
        throw Object.assign(new Error("This gift is unavailable."), {status: 404});
      }
      if (!senderProfileSnap.exists ||
          (recipientRef && !snapshots[9].exists)) {
        throw Object.assign(new Error("Gift wallet profiles are unavailable."),
          {status: 409});
      }
      const senderData = senderSnap.data() || {};
      if (giftProgress(senderData).level <
          Number(item.requiredGiftLevel || 0)) {
        throw Object.assign(new Error("Gift level requirement not met."),
          {status: 403});
      }
      const now = Date.now();
      const freeData = freeGiftSnap.data() || {};
      const freeExpiry = freeData.expiresAt?.toMillis?.() ?? null;
      // Never allow free room gifts to reduce a paid WorldBond price.
      const freeBalance = bondGift ? 0 :
        (freeExpiry !== null && freeExpiry <= now ? 0
          : Number(freeData.freeGiftBalance || 0));
      const amounts = calculateGiftSettlement({
        config, priceCoins: price, quantity, freeGiftBalance: freeBalance,
      });
      if (senderData.walletFrozen === true ||
          Number(senderData.walletDebtCoins || 0) > 0) {
        throw Object.assign(new Error("Wallet under payment review."), {status: 423});
      }
      const balance = Number(senderData.coins || 0);
      if (!Number.isSafeInteger(balance) || balance < amounts.chargedCoins) {
        throw Object.assign(new Error("NOT_ENOUGH_COINS"), {status: 409});
      }
      const after = balance - amounts.chargedCoins;
      const roomXp = Number(roomSnap.data()?.roomXp || 0);
      if (recipientId === "teacher_ai" &&
          (!Number.isSafeInteger(roomXp) || roomXp < 0 ||
            !Number.isSafeInteger(roomXp + amounts.giftLevelPoints))) {
        throw Object.assign(new Error("Room XP exceeds safe limits."), {status: 400});
      }
      // Server-enforced sender daily spend limit. Not configured => stop.
      if (!Number.isSafeInteger(config.giftingDailyCoinLimit) ||
          config.giftingDailyCoinLimit <= 0) {
        throw Object.assign(new Error("Gifting daily limit not configured."),
          {status: 503});
      }
      const day = new Date(now).toISOString().slice(0, 10);
      const dailyRef = senderRef.collection("economy_daily").doc(day);
      const dailySnap = await tx.get(dailyRef);
      const spent = Number(dailySnap.data()?.giftCoins || 0);
      if (!Number.isSafeInteger(spent) ||
          spent + amounts.chargedCoins > config.giftingDailyCoinLimit) {
        throw Object.assign(new Error("Daily gift limit reached."), {status: 429});
      }
      const recipientData = recipientRef ? snapshots[10].data() || {} : null;
      const recipientProfile = recipientRef ? snapshots[9].data() || {} : null;
      const recipientBefore = recipientData
        ? Number(recipientData.diamondsPending || 0) : 0;
      const receiverAfter = recipientBefore + amounts.pendingDiamonds;
      if (!Number.isSafeInteger(receiverAfter)) {
        throw Object.assign(new Error("Recipient settlement exceeds limits."),
          {status: 400});
      }
      const holdUntil = Timestamp.fromMillis(
        now + config.holdDays * 24 * 60 * 60 * 1000,
      );
      const outcome = {
        ...(bondOnly ? {operationId: requestHash, bondId: contextId} : {}),
        giftId, quantity, freeUnits: amounts.freeUnits,
        chargedCoins: amounts.chargedCoins, balanceAfter: after,
        pendingDiamonds: recipientRef ? amounts.pendingDiamonds : 0,
        holdUntil: recipientRef ? holdUntil.toDate().toISOString() : null,
      };
      tx.set(senderWalletRef, {
        coins: after,
        giftSentPoints: FieldValue.increment(amounts.chargedCoins),
        giftLevelCoins: giftProgress(senderData).points + amounts.chargedCoins,
        giftLevel: giftProgress({giftSentPoints: giftProgress(senderData).points + amounts.chargedCoins}).level,
        giftLevelPoints: FieldValue.increment(amounts.giftLevelPoints),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (freeGiftSnap.exists && amounts.freeUnits > 0) {
        tx.update(inventoryRef, {
          freeGiftBalance: freeBalance - amounts.freeUnits,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      tx.set(dailyRef, {
        giftCoins: spent + amounts.chargedCoins,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      tx.create(senderRef.collection("wallet_transactions").doc(requestHash), {
        type: "gift_send", amount: -amounts.chargedCoins, currency: "coins",
        balanceBefore: balance, balanceAfter: after, source: context,
        sourceId: contextId, itemId: giftId, quantity,
        freeUnits: amounts.freeUnits, operationId: requestHash,
        createdAt: FieldValue.serverTimestamp(),
      });
      if (recipientRef) {
        tx.set(recipientWalletRef, {
          diamondsPending: receiverAfter,
          giftReceivedPoints: FieldValue.increment(amounts.chargedCoins),
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
        if (amounts.pendingDiamonds > 0) {
          tx.create(recipientRef.collection("diamond_lots").doc(requestHash), {
            status: "pending", diamonds: amounts.pendingDiamonds,
            senderId: sender.uid, source: context,
            sourceId: contextId, giftId, operationId: requestHash,
            holdUntil, createdAt: FieldValue.serverTimestamp(),
          });
        }
        tx.create(recipientRef.collection("wallet_transactions")
          .doc(requestHash), {
          type: "gift_received_pending", amount: amounts.pendingDiamonds,
          currency: "diamonds_pending", balanceBefore: recipientBefore,
          balanceAfter: receiverAfter, holdUntil, source: context,
          sourceId: contextId, senderId: sender.uid, itemId: giftId,
          operationId: requestHash, createdAt: FieldValue.serverTimestamp(),
        });
      } else {
        // Teacher-AI gifts may support the room castle, but not exceed the
        // 50-level progression cap or erase XP from pre-existing level-60 rooms.
        const startingCastle = roomCastleProgressSnapshot(roomSnap.data());
        const progress = roomProgressAfterGift(startingCastle.xp,
          amounts.giftLevelPoints);
        tx.update(roomRef, {
          roomXp: progress.nextXp,
          roomLevel: progress.newLevel,
          roomCastleXpVersion: ROOM_CASTLE_XP_VERSION,
          ...(startingCastle.legacy ? {legacyRoomXp: roomXp} : {}),
        });
      }
      tx.create(giftEventRef, {
        ...(context === "chat" ? {type: "gift"} : {}),
        senderId: sender.uid,
        senderName: String(senderProfileSnap.data()?.displayName || "WorldVoice user"),
        recipientId, recipientName: recipientRef
          ? String(recipientProfile.displayName || "WorldVoice member")
          : "Teacher AI",
        giftId, points: amounts.chargedCoins, quantity,
        animationUrl: item.animationUrl || null,
        createdAt: FieldValue.serverTimestamp(),
      });
      if (context === "chat") {
        tx.update(roomRef, {
          latestText: bondGift ? "💝 WorldBond gift" : "🎁 Gift",
          lastMessageAt: FieldValue.serverTimestamp(),
        });
      }
      tx.create(eventRef, {
        userId: sender.uid, context, contextId, recipientId,
        giftId, quantity, ...(bondGift ? {giftCategory: "worldbond"} : {}),
        outcome,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.create(db.collection(bondOnly ? "world_bond_gift_history" : "economy_audit").doc(requestHash), {
        type: "gift_send", senderId: sender.uid, recipientId, context,
        contextId, giftId, quantity,
        ...(bondGift ? {giftCategory: "worldbond"} : {}),
        chargedCoins: amounts.chargedCoins,
        freeUnits: amounts.freeUnits, createdAt: FieldValue.serverTimestamp(),
      });
      return {...outcome, alreadyProcessed: false};
    });
    res.json({ok: true, ...outcome});
  } catch (error) {
    next(error);
  }
};
  app.post("/gift/send", send(false));
  app.post("/world-bond/gifts/send", send(true));
}
