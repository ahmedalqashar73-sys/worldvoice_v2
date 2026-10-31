// Verified server-side stale room cleanup. The client never gets to mark
// other users' rooms closed or decide who is present.
const activeAt = (d) => {
  const ts = d.updatedAt ?? d.joinedAt;
  return typeof ts?.toMillis === "function" ? ts.toMillis() :
    ts instanceof Date ? ts.getTime() : 0;
};

export const staleRoomDecision = ({room, participants, now, graceMs = 180000}) => {
  if (room?.isOpen !== true || !Array.isArray(participants)) return false;
  const started = activeAt({updatedAt: room.createdAt ?? room.updatedAt});
  if (!started || now - started < graceMs) return false;
  // Fail closed if a large room has more members than the query can inspect,
  // or if a participant has no usable timestamp (legacy/corrupt presence).
  // An incomplete sample is never proof of an empty room.
  if (participants.length >= 150 ||
      participants.some(p => activeAt(p) === 0)) return false;
  // A genuinely empty participants collection can be closed after the
  // requested three-minute grace period. A stale *document* is less certain:
  // backgrounded Android may temporarily suspend its 30-second heartbeat.
  // Use a longer safety window before declaring an abandoned participant.
  if (participants.length === 0) return true;
  const memberGraceMs = Math.max(graceMs, 15 * 60 * 1000);
  return !participants.some(p => activeAt(p) > now - memberGraceMs);
};

export function registerStaleRoomRoutes({app, db, authenticatedUser,
  clock = Date.now}) {
  let lastScanAt = 0;
  let scanInProgress = false;
  let scanAfter = null; // Rotate across active-room pages, not just first 45.
  app.get("/rooms/reconcile-stale", async (req, res, next) => {
    try {
      await authenticatedUser(req);
      const now = clock();
      if (scanInProgress || now - lastScanAt < 45000) {
        return res.json({ok:true, throttled:true});
      }
      scanInProgress = true;
      lastScanAt = now;
      try {
        const query = db.collection("rooms")
          .where("isOpen", "==", true)
          .orderBy("__name__");
        // A fixed limit without pagination may starve old rooms (such as a
        // prior testing room) when there are more than 45 open documents.
        let results = await (scanAfter
          ? query.startAfter(scanAfter) : query).limit(45).get();
        if (results.empty && scanAfter) {
          scanAfter = null;
          results = await query.limit(45).get();
        }
        scanAfter = results.docs.at(-1) ?? null;
        let closed = 0;
        for (const room of results.docs) {
          const participantsQuery = room.ref.collection("participants").limit(150);
          // Check the latest room and participant state inside the transaction:
          // no stale snapshot may close a newly occupied room.
          const ended = await db.runTransaction(async tx => {
            const [fresh, participants] = await Promise.all([
              tx.get(room.ref), tx.get(participantsQuery),
            ]);
            if (!staleRoomDecision({
              room: fresh.data(),
              participants: participants.docs.map(d => d.data()),
              now: clock(),
            })) return false;
            tx.update(room.ref, {
              isOpen:false, endedAt: new Date(clock()),
              updatedAt: new Date(clock()), closedReason:"inactive",
            });
            return true;
          });
          if (ended) closed++;
        }
        res.json({ok:true, checked:results.size, closed});
      } finally { scanInProgress = false; }
    } catch (error) {
      scanInProgress = false;
      next(error);
    }
  });
}
