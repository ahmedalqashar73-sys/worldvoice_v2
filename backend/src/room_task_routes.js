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
const ROOM_TASK_KEYS = ["ten_minutes", "host_five", "stage_five",
  "three_gifts", "stay_hours", "room_checkin", "visit_5", "visit_6",
  "visit_30", "visit_60"];
const ROOM_TASK_POLICY_VERSION = 3;
const roomTaskDay = (now = Date.now()) => new Date(now).toISOString().slice(0, 10);

function roomTaskId(key, uid, day) {
  const period = ["ten_minutes", "stay_hours", "room_checkin"].includes(key)
    ? day : "once";
  return `${key}_${uid}_${period}`;
}
// Host achievement requires only FIVE verified guests. Read recent attendance
// in bounded pages, newest first, instead of fetching up to 1,000 membership
// records on every presence heartbeat. Invalid/kicked accounts are skipped;
// later pages are checked to avoid false negatives when early rows are stale.
async function hasFiveVerifiedGuests(tx, roomRef, hostId, now) {
  const baseQuery = roomRef.collection("task_attendance")
    .where("lastSeenMs", ">=", now - 90000)
    .orderBy("lastSeenMs", "desc");
  const pageLimit = 25;
  const maxScanned = 1000;
  let scanned = 0;
  let cursor = null;
  let validGuests = 0;
  while (scanned < maxScanned && validGuests < 5) {
    const limit = Math.min(pageLimit, maxScanned - scanned);
    const query = cursor ? baseQuery.startAfter(cursor).limit(limit)
      : baseQuery.limit(limit);
    const results = await tx.get(query);
    if (results.empty) break;
    const participants = await Promise.all(results.docs.map(doc =>
      tx.get(roomRef.collection("participants").doc(doc.id))));
    for (let index = 0; index < results.docs.length; index++) {
      const entry = results.docs[index];
      if (entry.id !== hostId && participants[index].data()?.role === "listener" && isCurrentTaskMember(
        participants[index].data(), entry.data(), now)) {
        validGuests++;
      }
    }
    scanned += results.size;
    if (results.size < limit) break;
    cursor = results.docs[results.docs.length - 1];
  }
  return validGuests >= 5;
}

// Room task status is frequently refreshed by clients. Stop after finding
// the five verified guests needed by the host mission rather than reading up
// to 1,000 membership documents on every refresh. Pagination handles stale
// attendance entries preceding active guests without trusting client counts.
async function countVerifiedGuestsForStatus(db, roomRef, hostId, now) {
  const baseQuery = roomRef.collection("task_attendance")
    .where("lastSeenMs", ">=", now - 90000)
    .orderBy("lastSeenMs", "desc");
  const pageSize = 25;
  const maxScanned = 1000;
  let cursor = null;
  let scanned = 0;
  let valid = 0;
  while (valid < 5 && scanned < maxScanned) {
    const limit = Math.min(pageSize, maxScanned - scanned);
    const query = cursor ? baseQuery.startAfter(cursor).limit(limit)
      : baseQuery.limit(limit);
    const page = await query.get();
    if (page.empty) break;
    const members = await db.getAll(...page.docs.map(doc =>
      roomRef.collection("participants").doc(doc.id)));
    for (let index = 0; index < page.docs.length; index++) {
      const attendance = page.docs[index];
      if (attendance.id !== hostId &&
          members[index].data()?.role === "listener" &&
          isCurrentTaskMember(members[index].data(), attendance.data(), now)) {
        valid++;
        if (valid >= 5) break;
      }
    }
    scanned += page.size;
    if (page.size < limit) break;
    cursor = page.docs[page.docs.length - 1];
  }
  return Math.min(5, valid);
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
    const visitRef = roomRef.collection("task_visits").doc(user.uid);
    await db.runTransaction(async tx => {
      const cycleRef = engagementRef(db, user.uid);
      const [room, member, prior, cycle, visits] = await Promise.all([
        tx.get(roomRef), tx.get(memberRef), tx.get(attendanceRef),
        tx.get(cycleRef), tx.get(visitRef),
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
        const hasFive = await hasFiveVerifiedGuests(tx, roomRef, user.uid, now);
        const view = cycleView(cycleState, now);
        if (hasFive && cycleState.startDay === view.startDay && view.day <= 3) {
          cycleState = {...cycleState, hostedFive: true};
        }
      }
      // A listener must be observed before being promoted to a real seat.
      // Server-owned receipts accumulate unique promotions beyond the 7 guest seats.
      const data = member.data() || {};
      const sameSession = prior.data()?.joinedAtMs === next.joinedAtMs;
      const seenAsListener = data.role === "listener" ||
        (sameSession && prior.data()?.seenAsListener === true);
      const staged = ["speaker", "coHost", "vipSeat"].includes(data.role) &&
        Number.isSafeInteger(data.seatIndex) && data.seatIndex >= 2 &&
        data.seatIndex <= 8 && room.data()?.hostId !== user.uid && seenAsListener;
      const stageRef = roomRef.collection("task_stage").doc(user.uid);
      const stageReceipt = staged ? await tx.get(stageRef) : null;
      // Count distinct UTC days. Re-entry, multiple devices and retrying the
      // same day cannot increase days; only this authenticated server writes.
      const priorVisit = visits.data() || {};
      const alreadyVisited = priorVisit.lastDay === next.day;
      const priorDays = priorVisit.dayCount ?? 0;
      if (!Number.isSafeInteger(priorDays) || priorDays < 0 || priorDays > 50000) {
        throw Object.assign(new Error("Room visit history needs reconciliation."),
          {status: 409});
      }
      tx.set(attendanceRef, {...next, seenAsListener});
      if (!alreadyVisited) {
        tx.set(visitRef, {userId: user.uid, lastDay: next.day,
          dayCount: priorDays + 1, updatedAtMs: now}, {merge: true});
      }
      if (staged && !stageReceipt.exists) {
        tx.create(stageRef, {userId: user.uid, hostId: room.data().hostId,
          joinedAtMs: next.joinedAtMs, observedAtMs: now});
      }
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
    const [participant, attendance, gifts, config, visits, ...completions] =
      await Promise.all([
        participantRef.get(),
        roomRef.collection("task_attendance").doc(user.uid).get(),
        roomRef.collection("gifts").where("senderId", "==", user.uid)
          .limit(3).get(),
        db.doc("room_task_config/current").get(),
        roomRef.collection("task_visits").doc(user.uid).get(),
        ...ROOM_TASK_KEYS.map(key =>
          roomRef.collection("task_completions")
            .doc(roomTaskId(key, user.uid, day)).get()),
      ]);
    if (!room.exists || room.data()?.isOpen !== true || !participant.exists || participant.data()?.kicked === true) {
      return res.status(403).json({error: "Join an open room to view its tasks."});
    }
    const host = room.data()?.hostId === user.uid;
    const [guestCount, stageCount] = await Promise.all([
      host ? countVerifiedGuestsForStatus(db, roomRef, user.uid, now) : 0,
      host ? roomRef.collection("task_stage").where("hostId", "==", user.uid)
        .limit(10).get().then(snapshot => snapshot.size) : 0,
    ]);
    const currentMember = isCurrentTaskMember(participant.data(), attendance.data(), now);
    const minutes = currentMember ? verifiedRoomMinutes(attendance.data(), now) : 0;
    const visitData = visits.data() || {};
    const dayCount = Number.isSafeInteger(visitData.dayCount) &&
      visitData.dayCount >= 0 ? visitData.dayCount : 0;
    const checkedInToday = visitData.lastDay === day;
    const progress = {minutes, guestCount, stageCount, giftsSent: gifts.size,
      dayCount, checkedInToday};
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
        ? minutes : key === "host_five" ? guestCount
          : key === "stage_five" ? stageCount
            : key === "room_checkin" ? (checkedInToday ? 1 : 0)
              : key.startsWith("visit_") ? dayCount : gifts.size;
      const required = spec.requiredMinutes ?? spec.requiredCount;
      return {key, configured: true, claimed: completions[index].exists,
        eligible: currentMember &&
          (!["host_five", "stage_five"].includes(key) || host) &&
          !completions[index].exists && !castleAtMaxLevel && current >= required,
        current, required, xp: spec.xp};
    });
    return res.json({ok: true, taskPolicyVersion: ROOM_TASK_POLICY_VERSION,
      roomId, xp, level: roomLevelFromXp(xp),
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
      const [room, member, attendance, config, prior, gifts, cycle, staged, visits] = await Promise.all([
        tx.get(roomRef), tx.get(memberRef),
        tx.get(roomRef.collection("task_attendance").doc(user.uid)), tx.get(configRef),
        tx.get(completionRef),
        taskKey === "three_gifts"
          ? tx.get(roomRef.collection("gifts").where(
              "senderId", "==", user.uid).limit(3))
          : Promise.resolve(null),
        tx.get(cycleRef),
        taskKey === "stage_five"
          ? tx.get(roomRef.collection("task_stage")
            .where("hostId", "==", user.uid).limit(5))
          : Promise.resolve(null),
        tx.get(roomRef.collection("task_visits").doc(user.uid)),
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
      // Scan the full audience only when issuing a castle milestone reward.
      // A normal host-five claim needs five recent verified guests, not a
      // 1,001-row Firestore query plus 1,001 individual membership reads.
      const members = rewardLevels.length
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
      // Pagination stops once the five required guests are established.
      // Perform this read before any transaction writes.
      const hostHasFive = taskKey === "host_five" && !rewardLevels.length
        ? await hasFiveVerifiedGuests(tx, roomRef, user.uid, now) : false;
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
          count = rewardLevels.length
            ? members.docs.filter((doc, index) => activeIds.has(doc.id) && doc.id !== user.uid &&
              liveMemberships[index]?.data()?.role === "listener" &&
              verifiedRoomMinutes(doc.data(), now) !== null).length
            : (hostHasFive ? 5 : 0);
          break;
        case "stage_five":
          if (room.data()?.hostId !== user.uid) {
            throw Object.assign(new Error("Only the host may claim this mission."),
              {status: 403});
          }
          count = staged.size;
          break;
        case "room_checkin":
          count = visits.data()?.lastDay === day ? 1 : 0;
          break;
        case "visit_5":
        case "visit_6":
        case "visit_30":
        case "visit_60":
          count = Number.isSafeInteger(visits.data()?.dayCount)
            ? visits.data().dayCount : 0;
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
