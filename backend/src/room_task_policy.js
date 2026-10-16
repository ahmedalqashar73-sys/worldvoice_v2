// Non-monetary room progression only. No coins, diamonds or cash-equivalent
// rewards may be minted by tasks or written by an untrusted phone.
export const ROOM_MAX_LEVEL = 50;
export const CASTLE_LEVEL_INTERVAL = 5;

// Only the ten visible castle upgrades grant a milestone eligibility document.
// Regular levels still grant progress, but do not spam every participant with
// placeholder gift-pack documents at every intermediate level.
export function castleMilestoneLevels(unlockedLevels) {
  if (!Array.isArray(unlockedLevels)) {
    throw new TypeError("Expected unlocked room levels.");
  }
  return unlockedLevels.filter(level =>
    Number.isSafeInteger(level) &&
    level >= CASTLE_LEVEL_INTERVAL &&
    level <= ROOM_MAX_LEVEL &&
    level % CASTLE_LEVEL_INTERVAL === 0);
}


export function castleTierForLevel(level) {
  if (!Number.isSafeInteger(level) || level < 1) {
    throw Object.assign(new Error('Invalid castle level.'), {status: 409});
  }
  return Math.min(10, Math.ceil(Math.min(level, ROOM_MAX_LEVEL) / CASTLE_LEVEL_INTERVAL));
}
// The requirement is XP to reach the NEXT level, not cumulative XP.
// Lv1:300, Lv2:400, Lv3:700, Lv4:1000; thereafter +300 per level.
export function roomXpRequiredForLevel(level) {
  if (!Number.isSafeInteger(level) || level < 1 || level >= ROOM_MAX_LEVEL) {
    throw Object.assign(new Error("Invalid room XP level."), {status: 409});
  }
  return level === 1 ? 300 : level === 2 ? 400 : 700 + (level - 3) * 300;
}

export function roomXpThresholdForLevel(level) {
  if (!Number.isSafeInteger(level) || level < 1 || level > ROOM_MAX_LEVEL) {
    throw Object.assign(new Error("Invalid room level."), {status: 409});
  }
  // Cumulative XP at the start of this level; progression starts at level 1.
  let total = 0;
  for (let previous = 1; previous < level; previous++) {
    total += roomXpRequiredForLevel(previous);
  }
  return total;
}

export const ROOM_MAX_XP = roomXpThresholdForLevel(ROOM_MAX_LEVEL);

// Version 1: historical castles gained one level per 100 XP (up to 60).
// Version 2: the approved graduated 300, 400, 700, 1000... curve to level 50.
// Keep the original XP in legacyRoomXp on first write for auditability.
// This projection is pure so both reads and transactional writes agree.
export const ROOM_CASTLE_XP_VERSION = 2;
export function roomCastleProgressSnapshot(data) {
  // Never overwrite a higher stored level with an inferred lower one. Older
  // records may have a level but missing XP, or use an unidentified curve.
  // Pause writes for reconciliation rather than minting XP or losing progress.
  const checked = snapshot => {
    const storedLevel = data?.roomLevel;
    if (storedLevel != null && (!Number.isSafeInteger(storedLevel) ||
        storedLevel < 1 || Math.min(storedLevel, ROOM_MAX_LEVEL) > snapshot.level)) {
      throw Object.assign(new Error("Stored room level requires reconciliation."), {status: 409});
    }
    return snapshot;
  };
  // roomPoints was client-writable historically; never mint authoritative XP
  // from it without a separately reviewed reconciliation.
  if (data?.roomXp == null && data?.roomPoints != null && data.roomPoints !== 0) {
    throw Object.assign(new Error("Legacy roomPoints requires reconciliation."), {status: 409});
  }
  const rawXp = data?.roomXp ?? 0;
  if (data?.roomCastleXpVersion != null &&
      ![1, ROOM_CASTLE_XP_VERSION].includes(data.roomCastleXpVersion)) {
    throw Object.assign(new Error("Unknown room XP version; reconcile before writing."), {status: 409});
  }
  if (!Number.isSafeInteger(rawXp) || rawXp < 0) {
    throw Object.assign(new Error("Room XP requires reconciliation."), {status: 409});
  }
  if (data?.roomCastleXpVersion === ROOM_CASTLE_XP_VERSION) {
    return checked({xp: rawXp, level: roomLevelFromXp(rawXp), legacy: false});
  }
  const priorLevel = Math.min(ROOM_MAX_LEVEL, Math.floor(rawXp / 100) + 1);
  if (priorLevel >= ROOM_MAX_LEVEL) {
    return checked({xp: ROOM_MAX_XP, level: ROOM_MAX_LEVEL, legacy: true});
  }
  const withinOldLevel = rawXp % 100;
  const xp = roomXpThresholdForLevel(priorLevel) +
    Math.floor(roomXpRequiredForLevel(priorLevel) * withinOldLevel / 100);
  return checked({xp, level: priorLevel, legacy: true});
}


// A task must not credit time or guests from abandoned room memberships.
// The Flutter room refreshes its server-timestamped presence every 30 seconds.
// This is a short-lived presence check, not proof of active learning or speech.
export function isRecentRoomParticipant(participant, nowMs) {
  if (!Number.isSafeInteger(nowMs) || nowMs < 0) return false;
  const joined = participant?.joinedAt?.toMillis?.();
  const seen = participant?.updatedAt?.toMillis?.();
  if (!Number.isSafeInteger(joined) || !Number.isSafeInteger(seen)) {
    return false;
  }
  return joined <= nowMs + 5000 && seen >= joined &&
    seen <= nowMs + 5000 && nowMs - seen <= 90000;
}

// Non-monetary beta mission defaults keep all four tasks usable even when a
// new room has not been assigned an optional owner-specific mission config.
// These values award castle XP only; never coins or inventory.
export const ROOM_TASK_DEFAULTS = Object.freeze({
  sendThreeGiftsXp: 20,
  stayHoursMinimum: 1,
  stayHoursXp: 60,
});

function configuredPoints(raw, label) {
  if (!Number.isSafeInteger(raw) || raw < 1 || raw > 500) {
    throw Object.assign(
      new Error(label + " needs an approved positive XP value in room_task_config/current."),
      {status: 503},
    );
  }
  return raw;
}

export function roomTaskSpec(taskKey, config) {
  switch (taskKey) {
    case "ten_minutes":
      return {taskKey, xp: 4, requiredMinutes: 10, period: "day"};
    case "host_five":
      return {taskKey, xp: 10, requiredCount: 5, period: "once"};
    case "stage_five":
      return {taskKey, xp: 5, requiredCount: 5, period: "once"};
    // Eight visible missions include four lifetime visit milestones.
    // Visit rewards are room-specific, not wallet coins or purchasable goods.
    case "room_checkin":
      return {taskKey, xp: 2, requiredCount: 1, period: "day"};
    case "visit_5":
      return {taskKey, xp: 15, requiredCount: 5, period: "once"};
    case "visit_6":
      return {taskKey, xp: 20, requiredCount: 6, period: "once"};
    case "visit_30":
      return {taskKey, xp: 100, requiredCount: 30, period: "once"};
    case "visit_60":
      return {taskKey, xp: 200, requiredCount: 60, period: "once"};
    case "three_gifts":
      return {taskKey, xp: configuredPoints(config?.sendThreeGiftsXp ?? ROOM_TASK_DEFAULTS.sendThreeGiftsXp,
        "Three-gift mission"), requiredCount: 3, period: "once_per_room"};
    case "stay_hours":
      return {taskKey, xp: 60, requiredMinutes: 60, period: "day"};
    default:
      throw Object.assign(new Error("Unknown room task."), {status: 400});
  }
}

export function roomLevelFromXp(roomXp) {
  if (!Number.isSafeInteger(roomXp) || roomXp < 0) {
    throw Object.assign(new Error("Room XP requires reconciliation."), {status: 409});
  }
  let low = 1;
  let high = ROOM_MAX_LEVEL;
  while (low < high) {
    const mid = Math.ceil((low + high) / 2);
    if (roomXp >= roomXpThresholdForLevel(mid)) low = mid;
    else high = mid - 1;
  }
  return low;
}

// A paid gift to Teacher AI can contribute to the room castle, but must
// never mint coins or erase historic XP from older 60-level rooms.
export function roomProgressAfterGift(currentXp, giftXp) {
  if (!Number.isSafeInteger(currentXp) || currentXp < 0 ||
      !Number.isSafeInteger(giftXp) || giftXp < 0 ||
      !Number.isSafeInteger(currentXp + giftXp)) {
    throw Object.assign(new Error("Invalid room gift contribution."), {status: 409});
  }
  const nextXp = currentXp >= ROOM_MAX_XP ? currentXp :
    Math.min(ROOM_MAX_XP, currentXp + giftXp);
  return {nextXp, newLevel: roomLevelFromXp(nextXp)};
}

export function advanceRoomLevel(currentXp, earnedXp) {
  const oldLevel = roomLevelFromXp(currentXp);
  if (!Number.isSafeInteger(earnedXp) || earnedXp < 1 || earnedXp > 500) {
    throw Object.assign(new Error("Invalid mission XP."), {status: 503});
  }
  if (currentXp >= ROOM_MAX_XP) {
    throw Object.assign(new Error("Room has reached level 50."), {status: 409});
  }
  const nextXp = Math.min(ROOM_MAX_XP, currentXp + earnedXp);
  const newLevel = roomLevelFromXp(nextXp);
  return {
    oldLevel, newLevel, nextXp, awardedXp: nextXp - currentXp,
    unlockedLevels: Array.from(
      {length: newLevel - oldLevel},
      (_, index) => oldLevel + index + 1,
    ),
  };
}

// Server-observed attendance, scoped to the UTC mission day. An absent
// heartbeat never earns offline time. Retries cannot credit the same interval.
export function advanceRoomAttendance(prior, joinedAtMs, nowMs) {
  if (!Number.isSafeInteger(nowMs) || !Number.isSafeInteger(joinedAtMs) ||
      joinedAtMs > nowMs || joinedAtMs < 0) {
    throw Object.assign(new Error("Invalid room session."), {status: 409});
  }
  const day = new Date(nowMs).toISOString().slice(0, 10);
  const sameDay = prior?.day === day;
  const previous = prior?.lastSeenMs;
  const gap = Number.isSafeInteger(previous) ? nowMs - previous : -1;
  const sameSession = prior?.joinedAtMs === joinedAtMs;
  const dayStart = Date.parse(day + "T00:00:00Z");
  const creditedMs = sameSession && gap >= 0 && gap <= 90000
    ? nowMs - Math.max(previous, dayStart) : 0;
  const saved = sameDay && Number.isSafeInteger(prior?.activeMs)
    && prior.activeMs >= 0 ? prior.activeMs : 0;
  return {day, joinedAtMs, lastSeenMs: nowMs,
    activeMs: Math.min(86400000, saved + creditedMs)};
}

export function verifiedRoomMinutes(attendance, nowMs) {
  const seen = attendance?.lastSeenMs;
  if (!Number.isSafeInteger(seen) || seen > nowMs || nowMs - seen > 90000 ||
      attendance?.day !== new Date(nowMs).toISOString().slice(0, 10) ||
      !Number.isSafeInteger(attendance?.activeMs) || attendance.activeMs < 0) {
    return null;
  }
  return Math.floor(attendance.activeMs / 60000);
}

export function isCurrentTaskMember(member, attendance, nowMs) {
  return member != null && member.kicked !== true &&
    member.joinedAt?.toMillis?.() === attendance?.joinedAtMs &&
    verifiedRoomMinutes(attendance, nowMs) !== null;
}
