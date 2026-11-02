// Read-only gift wall, with received gifts visible to signed-in visitors.
// Sent gifts never leave the account owner’s authenticated session.
export function registerGiftWallRoutes({app, db, authenticatedUser}) {
  app.get("/gift-wall/:uid", async (req, res, next) => {
    try {
      const viewer = await authenticatedUser(req);
      const uid = String(req.params.uid || "").trim();
      const direction = String(req.query?.direction || "received");
      if (!/^[A-Za-z0-9_-]{8,160}$/.test(uid) ||
          !["received", "sent"].includes(direction)) {
        return res.status(400).json({error: "Invalid gift wall request."});
      }
      if (direction === "sent" && viewer.uid !== uid) {
        return res.status(403).json({error: "Sent gifts are private."});
      }
      const profile = await db.collection("users").doc(uid).get();
      if (!profile.exists) {
        return res.status(404).json({error: "Profile not found."});
      }
      const collection = direction === "sent"
        ? "gift_wall_sent" : "gift_notifications";
      const snapshots = await db.collection("users").doc(uid)
        .collection(collection).orderBy("createdAt", "desc").limit(100).get();
      const items = snapshots.docs.map(doc => {
        const d = doc.data() || {};
        return {
          id: doc.id, senderId: String(d.senderId || ""),
          senderName: String(d.senderName || "WorldVoice user").slice(0, 100),
          recipientId: direction === "sent" ? String(d.recipientId || "") : uid,
          recipientName: String(d.recipientName || "WorldVoice member").slice(0, 100),
          itemId: String(d.itemId || d.giftId || "").slice(0, 128),
          giftId: String(d.giftId || "").slice(0, 128),
          name: String(d.name || "").slice(0, 120),
          nameAr: String(d.nameAr || "").slice(0, 120),
          type: String(d.type || "gift").slice(0, 35),
          context: String(d.context || "").slice(0, 20),
          quantity: Number.isSafeInteger(d.quantity) ? d.quantity : 1,
          priceCoins: Number.isSafeInteger(d.priceCoins)
            ? d.priceCoins : Number.isSafeInteger(d.points) ? d.points : 0,
          durationDays: Number.isSafeInteger(d.durationDays) ? d.durationDays : null,
          nonRedeemable: d.nonRedeemable === true,
          createdAt: d.createdAt?.toDate?.()?.toISOString?.() || null,
        };
      });
      return res.json({ok: true, direction, items});
    } catch (error) { next(error); }
  });
}
