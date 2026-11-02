import {FieldValue} from "firebase-admin/firestore";

// Seat one belongs to the original host and never shifts. Compact speaking
// seats 2-8 without changing member role, Agora UID, mute or VIP attributes.
export function compactRoomSeatPlan(participants, hostId) {
  const speakers = participants.filter(p =>
    p.id !== hostId &&
    ["speaker", "coHost", "vipSeat"].includes(p.data?.role) &&
    Number.isInteger(p.data?.seatIndex) &&
    p.data.seatIndex >= 2 && p.data.seatIndex <= 8);
  speakers.sort((a, b) =>
    a.data.seatIndex - b.data.seatIndex || a.id.localeCompare(b.id));
  return speakers.map((p, i) =>
    ({id: p.id, from: p.data.seatIndex, to: i + 2}))
    .filter(change => change.from !== change.to);
}

export function registerRoomSeatCompactionRoutes({
  app, db, authenticatedUser, validChannelName,
}) {
  app.post("/room/seats/compact", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const roomId = String(req.body?.roomId || "").trim();
      if (!validChannelName(roomId)) {
        return res.status(400).json({error: "Invalid room ID."});
      }
      const roomRef = db.collection("rooms").doc(roomId);
      const result = await db.runTransaction(async tx => {
        const roomSnap = await tx.get(roomRef);
        if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
          throw Object.assign(new Error("Room is not open."), {status: 404});
        }
        const hostId = String(roomSnap.data().hostId || "");
        const participantsSnap = await tx.get(roomRef.collection("participants"));
        const current = participantsSnap.docs.find(d => d.id === user.uid);
        if (!current || (user.uid !== hostId &&
            current.data().isModerator !== true)) {
          throw Object.assign(new Error("Host or active moderator required."),
            {status: 403});
        }
        const plan = compactRoomSeatPlan(
          participantsSnap.docs.map(d => ({id: d.id, data: d.data()})), hostId);
        for (const move of plan) {
          tx.update(roomRef.collection("participants").doc(move.id), {
            seatIndex: move.to,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
        return {moved: plan.length};
      });
      res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });
}
