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
  // A single fresh host, moderator, or listener keeps the room alive.
  // All presence timestamps must be older than the grace period.
  return !participants.some(p => activeAt(p) > now - graceMs);
};

export function registerStaleRoomRoutes({app, db, authenticatedUser,
  clock = Date.now}) {
  let lastScanAt = 0;
  let scanInProgress = false;
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
        const results = await db.collection("rooms")
          .where("isOpen", "==", true).limit(45).get();
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
