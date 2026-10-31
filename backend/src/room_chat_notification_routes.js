import {FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

const validId = value => typeof value === "string" &&
  /^[A-Za-z0-9_-]{8,160}$/.test(value);

/**
 * An authenticated message author may request a push ONLY for an existing
 * Firestore message they actually wrote to an active room. The recipient list
 * comes from trusted room presence, never a client-supplied list.
 */
export function registerRoomChatNotificationRoutes({app, db, authenticatedUser,
  now = Date.now}) {
  app.post("/system/room-message/notify", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomId = String(req.body?.roomId || "");
      const messageId = String(req.body?.messageId || "");
      if (!validId(roomId) || !validId(messageId)) {
        return res.status(400).json({error:"Invalid room message"});
      }
      const roomRef = db.collection("rooms").doc(roomId);
      const [room, message, senderPresence] = await Promise.all([
        roomRef.get(),
        roomRef.collection("messages").doc(messageId).get(),
        roomRef.collection("participants").doc(user.uid).get(),
      ]);
      const data = message.data() || {};
      const timestamp = data.createdAt?.toMillis?.() || 0;
      if (!room.exists || room.data()?.isOpen !== true ||
          !message.exists || data.userId !== user.uid ||
          !senderPresence.exists ||
          !timestamp || Math.abs(now() - timestamp) > 5 * 60 * 1000) {
        return res.status(403).json({error:"Verified room message required"});
      }

      const receipt = db.collection("room_chat_notification_receipts")
        .doc(roomId + "_" + messageId);
      const claimed = await db.runTransaction(async tx => {
        const old = await tx.get(receipt);
        if (old.exists) return false;
        tx.create(receipt, {
          roomId, messageId, senderId:user.uid,
          createdAt:FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (!claimed) return res.json({ok:true, alreadySent:true});

      const participants = await roomRef.collection("participants")
        .limit(120).get();
      // Avoid inventing a full audience if the query was truncated.
      const ids = participants.docs
        .filter(d => d.id !== user.uid)
        .filter(d => {
          const updated = d.data().updatedAt?.toMillis?.() ??
            d.data().joinedAt?.toMillis?.() ?? 0;
          return updated > now() - 15 * 60 * 1000;
        })
        .slice(0, 100).map(d => d.id);
      const devicePages = await Promise.all(ids.map(async uid => {
        const owner = db.collection("users").doc(uid);
        const profile = await owner.get();
        if (profile.data()?.roomMessageNotificationsEnabled === false) return [];
        const devices = await owner.collection("notification_devices")
          .limit(3).get();
        return devices.docs.map(d => String(d.data()?.token || ""))
          .filter(token => token.length >= 30);
      }));
      const tokens = [...new Set(devicePages.flat())];
      if (tokens.length) {
        try {
          await getMessaging().sendEachForMulticast({
            tokens: tokens.slice(0, 300),
            notification: {
              title: String(room.data()?.title || "WorldVoice Voice Room").slice(0, 100),
              body: String(data.text || "New room message").slice(0, 130),
            },
            data: {type:"room_chat_message", roomId},
            android: {priority:"high"},
          });
        } catch (error) {
          console.warn("Room chat push unavailable:",error?.code || "unknown");
        }
      }
      res.json({ok:true, receivers:ids.length});
    } catch (error) {next(error);}
  });
}
