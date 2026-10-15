import {engagementRef} from './engagement_routes.js';
import {addCyclePresence, cycleView, creativeAward} from './engagement_policy.js';
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {roomTaskSpec, advanceRoomLevel, roomLevelFromXp,
  roomCastleProgressSnapshot, ROOM_CASTLE_XP_VERSION, castleMilestoneLevels,
  ROOM_MAX_LEVEL, CASTLE_LEVEL_INTERVAL, castleTierForLevel,
  advanceRoomAttendance, verifiedRoomMinutes, isCurrentTaskMember} from "./room_task_policy.js";

export function registerRoomTaskRoutes({app, db, authenticatedUser}) {
/**
 * Non-monetary, server-verified room missions. Device buttons cannot grant
 * XP or level rewards. Invalid mission overrides fail closed; no task mints coins, diamonds or cashout inventory.
 */
const ROOM_TASK_KEYS = ["ten_minutes", "host_five", "three_gifts", "stay_hours"];
const roomTaskDay = (now = Date.now()) => new Date(now).toISOString().slice(0, 10);

function roomTaskId(key, uid, day) {
  const period = (key === "ten_minutes" || key === "stay_hours") ? day : "once";
  return `${key}_${uid}_${period}`;
}
// Only this authenticated endpoint writes attendance; Firestore's existing
// default-deny rule already protects task_attendance from every client.
app.post("/room/tasks/heartbeat", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.body?.roomId || "").trim();
    if (!roomId || roomId.length > 160 || roomId.includes("/")) {
      return res.status(400).json({error: "Invalid room ID."});
    }
    const roomRef = db.collection("rooms").doc(roomId);
    const memberRef = roomRef.collection("participants").doc(user.uid);
    const attendanceRef = roomRef.collection("task_attendance").doc(user.uid);
    await db.runTransaction(async tx => {
      const cycleRef = engagementRef(db, user.uid);
      const [room, member, prior, cycle] = await Promise.all([
        tx.get(roomRef), tx.get(memberRef), tx.get(attendanceRef), tx.get(cycleRef),
      ]);
      if (!room.exists || room.data()?.isOpen !== true ||
          !member.exists || member.data()?.kicked === true) {
        throw Object.assign(new Error("Join an open room first."), {status: 403});
      }
      const now = Date.now();
      const next = advanceRoomAttendance(prior.data(),
        member.data()?.joinedAt?.toMillis?.(), now);
      const delta = prior.data()?.day === next.day
        ? Math.max(0, next.activeMs - (prior.data()?.activeMs ?? 0)) : 0;
      let cycleState = cycle.data();
      const activeCycle = cycle.exists && cycleView(cycleState, now).startDay === cycleState.startDay &&
        cycleView(cycleState, now).day <= 3;
      if (activeCycle && room.data()?.hostId === user.uid && !cycleState.hostedFive) {
        const observed = await tx.get(roomRef.collection("task_attendance")
          .where("lastSeenMs", ">=", now - 90000).limit(1000));
        const memberships = await Promise.all(observed.docs.map(doc =>
          tx.get(roomRef.collection("participants").doc(doc.id))));
        const guests = memberships.filter((doc, i) => doc.id !== user.uid &&
          isCurrentTaskMember(doc.data(), observed.docs[i].data(), now));
        const view = cycleView(cycleState, now);
        if (guests.length >= 5 && cycleState.startDay === view.startDay && view.day <= 3) {
          cycleState = {...cycleState, hostedFive: true};
        }
      }
      tx.set(attendanceRef, next);
      if (activeCycle) tx.set(cycleRef, addCyclePresence(cycleState, delta, now));
    });
    return res.json({ok: true});
  } catch (error) { next(error); }
});

app.get("/room/tasks/status", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.query.roomId || "").trim();
    if (!roomId || roomId.length > 160 || roomId.includes("/")) {
      return res.status(400).json({error: "Invalid room ID."});
    }
    const roomRef = db.collection("rooms").doc(roomId);
    const participantRef = roomRef.collection("participants").doc(user.uid);
    const now = Date.now();
    const day = roomTaskDay(now);
    const room = await roomRef.get();
    const [participant, attendance, members, gifts, config, ...completions] =
      await Promise.all([
        participantRef.get(),
        roomRef.collection("task_attendance").doc(user.uid).get(),
        room.data()?.hostId === user.uid ? roomRef.collection("task_attendance")
          .where("lastSeenMs", ">=", now - 90000).limit(1000).get()
          : Promise.resolve({empty: true, docs: []}),
        roomRef.collection("gifts").where("senderId", "==", user.uid)
          .limit(3).get(),
        db.doc("room_task_config/current").get(),
        ...ROOM_TASK_KEYS.map(key =>
          roomRef.collection("task_completions")
            .doc(roomTaskId(key, user.uid, day)).get()),
      ]);
    if (!room.exists || room.data()?.isOpen !== true || !participant.exists || participant.data()?.kicked === true) {
      return res.status(403).json({error: "Join an open room to view its tasks."});
    }
    const liveMemberships = members.empty ? [] : await db.getAll(
      ...members.docs.map(doc => roomRef.collection("participants").doc(doc.id)));
    const observed = new Map(members.docs.map(doc => [doc.id, doc.data()]));
    const activeIds = new Set(liveMemberships.filter(doc =>
      isCurrentTaskMember(doc.data(), observed.get(doc.id), now)).map(doc => doc.id));
    const isHost = room.data()?.hostId === user.uid;
    const guestCount = isHost ?
      members.docs.filter(doc => activeIds.has(doc.id) && doc.id !== user.uid &&
        verifiedRoomMinutes(doc.data(), now) !== null).length : 0;
    const currentMember = isCurrentTaskMember(participant.data(), attendance.data(), now);
    const minutes = currentMember ? verifiedRoomMinutes(attendance.data(), now) : 0;
    const progress = {minutes, guestCount, giftsSent: gifts.size};
    const configData = config.data() || {};
    const castle = roomCastleProgressSnapshot(room.data());
    const xp = castle.xp;
    const castleAtMaxLevel = castle.level >= ROOM_MAX_LEVEL;
    const missions = ROOM_TASK_KEYS.map((key, index) => {
      let spec;
      try {
        spec = roomTaskSpec(key, configData);
      } catch (error) {
        if (error.status !== 503) throw error;
        return {key, configured: false, claimed: completions[index].exists,
          requiredMinutes: key === "stay_hours" ? null : undefined,
          xp: null};
      }
      const current = key === "ten_minutes" || key === "stay_hours"
        ? minutes : key === "host_five" ? guestCount : gifts.size;
      const required = spec.requiredMinutes ?? spec.requiredCount;
      return {key, configured: true, claimed: completions[index].exists,
        eligible: currentMember &&
          !completions[index].exists && !castleAtMaxLevel && current >= required,
        current, required, xp: spec.xp};
    });
    return res.json({ok: true, roomId, xp, level: roomLevelFromXp(xp),
      maxLevel: ROOM_MAX_LEVEL, maxed: castleAtMaxLevel,
      castleTier: castleTierForLevel(roomLevelFromXp(xp)),
      progress, missions});
  } catch (error) {
    next(error);
  }
});

app.post("/room/tasks/claim", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.body?.roomId || "").trim();
    const taskKey = String(req.body?.taskKey || "").trim();
    if (!roomId || roomId.length > 160 || roomId.includes("/") || !ROOM_TASK_KEYS.includes(taskKey)) {
      return res.status(400).json({error: "Invalid room mission."});
    }
    const roomRef = db.collection("rooms").doc(roomId);
    const memberRef = roomRef.collection("participants").doc(user.uid);
    const configRef = db.doc("room_task_config/current");
    const now = Date.now();
    const day = roomTaskDay(now);
    const completionRef = roomRef.collection("task_completions")
      .doc(roomTaskId(taskKey, user.uid, day));

    const outcome = await db.runTransaction(async tx => {
      // Read all snapshots and evidence BEFORE the first transaction write.
      const cycleRef = engagementRef(db, user.uid);
      const [room, member, attendance, config, prior, gifts, cycle] = await Promise.all([
        tx.get(roomRef), tx.get(memberRef),
        tx.get(roomRef.collection("task_attendance").doc(user.uid)), tx.get(configRef),
        tx.get(completionRef),
        taskKey === "three_gifts"
          ? tx.get(roomRef.collection("gifts").where(
              "senderId", "==", user.uid).limit(3))
          : Promise.resolve(null),
        tx.get(cycleRef),
      ]);
      if (!room.exists || room.data()?.isOpen !== true || !member.exists) {
        throw Object.assign(new Error("Join an open room first."), {status: 403});
      }
      if (prior.exists) return {...prior.data().outcome,
        rewardRecipientIds: prior.data().rewardRecipientIds ?? [], alreadyProcessed: true};
      if (!isCurrentTaskMember(member.data(), attendance.data(), now)) {
        throw Object.assign(new Error("Refresh verified room presence first."), {status: 409});
      }
      const spec = roomTaskSpec(taskKey, config.data());
      const castle = roomCastleProgressSnapshot(room.data());
      const advancement = advanceRoomLevel(castle.xp, spec.xp);
      const rewardLevels = castleMilestoneLevels(advancement.unlockedLevels);
      const members = taskKey === "host_five" || rewardLevels.length
        ? await tx.get(roomRef.collection("task_attendance")
          .where("lastSeenMs", ">=", now - 90000).limit(1001)) : {docs: []};
      if (rewardLevels.length && members.docs.length > 1000) {
        throw Object.assign(new Error("Milestone audience needs paginated reconciliation."), {status: 409});
      }
      const liveMemberships = await Promise.all(members.docs.map(doc =>
        tx.get(roomRef.collection("participants").doc(doc.id))));
      const observed = new Map(members.docs.map(doc => [doc.id, doc.data()]));
      const activeIds = new Set(liveMemberships.filter(doc =>
        isCurrentTaskMember(doc.data(), observed.get(doc.id), now)).map(doc => doc.id));
      let count = 0;
      switch (taskKey) {
        case "ten_minutes":
        case "stay_hours":
          count = verifiedRoomMinutes(attendance.data(), now) ?? 0;
          break;
        case "host_five":
          if (room.data()?.hostId !== user.uid) {
            throw Object.assign(new Error("Only the host may claim this mission."),
              {status: 403});
          }
          count = members.docs.filter(doc => activeIds.has(doc.id) && doc.id !== user.uid &&
            verifiedRoomMinutes(doc.data(), now) !== null).length;
          break;
        case "three_gifts":
          count = gifts.size;
          break;
      }
      const required = spec.requiredMinutes ?? spec.requiredCount;
      if (count < required) {
        throw Object.assign(new Error("Mission conditions are not verified yet."),
          {status: 409});
      }
      if (taskKey === "host_five" && cycle.exists) {
        const state = cycle.data(), view = cycleView(state, now);
        if (state.startDay === view.startDay && view.day <= 3) {
          tx.set(cycleRef, creativeAward({...state, hostedFive: true}, now));
        }
      }
      // Freeze the audience at the milestone, never expand it on a retry.
      // Bounded to 1,000 recently verified accounts per room milestone.
      const rewardRecipientIds = rewardLevels.length ? members.docs
        .filter(doc => activeIds.has(doc.id) && verifiedRoomMinutes(doc.data(), now) !== null)
        .map(doc => doc.id) : [];
      const result = {taskKey, awardedXp: advancement.awardedXp,
        roomXp: advancement.nextXp, roomLevel: advancement.newLevel,
        castleTier: castleTierForLevel(advancement.newLevel),
        unlockedLevels: advancement.unlockedLevels, rewardLevels,
        completedAtMillis: now};
      tx.create(completionRef, {
        taskKey, userId: user.uid, rewardRecipientIds, points: advancement.awardedXp,
        periodKey: day, evidence: {observed: count, required},
        outcome: result, completedAt: FieldValue.serverTimestamp(),
      });
      tx.update(roomRef, {
        roomXp: advancement.nextXp,
        roomLevel: advancement.newLevel,
        roomCastleXpVersion: ROOM_CASTLE_XP_VERSION,
        ...(castle.legacy ? {legacyRoomXp: room.data()?.roomXp ?? room.data()?.roomPoints ?? 0} : {}),
        lastTaskCompletionId: completionRef.id,
        updatedAt: FieldValue.serverTimestamp(),
      });
      for (const level of rewardLevels) {
        tx.set(roomRef.collection("rewards").doc(`level_${level}`), {
          level, type: level === 5 ? "background_month" : "castle_milestone",
          ...(level % CASTLE_LEVEL_INTERVAL === 0 ? {
            castleMilestone: true, castleTier: castleTierForLevel(level),
          } : {}),
          unlockedBy: user.uid, sourceTaskId: completionRef.id,
          unlockedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      return {...result, rewardRecipientIds, alreadyProcessed: false};
    });

    // Idempotent retry also retries fanout if a previous response was lost.
    // These are non-monetary, catalog-dependent reward eligibility documents.
    const levels = castleMilestoneLevels(
      outcome.rewardLevels ?? outcome.unlockedLevels ?? []);
    if (levels.length) {
      const recipients = outcome.rewardRecipientIds ?? [];
      const expiration = Timestamp.fromMillis(
        outcome.completedAtMillis + 30 * 24 * 60 * 60 * 1000);
      const membersPerBatch = Math.max(1, Math.floor(450 / levels.length));
      for (let offset = 0; offset < recipients.length; offset += membersPerBatch) {
        const batch = db.batch();
        for (const recipientId of recipients.slice(offset, offset + membersPerBatch)) {
          for (const level of levels) {
            const rewardId = `${roomId}_level_${level}`;
            batch.set(db.collection("users").doc(recipientId)
              .collection("room_rewards").doc(rewardId), {
              userId: recipientId, roomId, level,
              type: level === 5 ? "background_month" : "castle_milestone",
              castleMilestone: true,
              castleTier: castleTierForLevel(level),
              sourceRewardId: `level_${level}`,
              ...(level === 5 ? {expiresAt: expiration} : {}),
              grantedAt: Timestamp.fromMillis(outcome.completedAtMillis),
            }, {merge: true});
          }
        }
        await batch.commit();
      }
    }
    const {rewardRecipientIds: _privateAudience, ...publicOutcome} = outcome;
    return res.json({ok: true, ...publicOutcome});
  } catch (error) {
    next(error);
  }
});

}
