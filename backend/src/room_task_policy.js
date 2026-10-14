// Non-monetary room progression only. No coins, diamonds or cash-equivalent
// rewards may be minted by tasks or written by an untrusted phone.
export const ROOM_MAX_LEVEL = 50;
export const CASTLE_LEVEL_INTERVAL = 5;

export function castleTierForLevel(level) {
  if (!Number.isSafeInteger(level) || level < 1) {
    throw Object.assign(new Error('Invalid castle level.'), {status: 409});
  }
  return Math.min(10, Math.ceil(Math.min(level, ROOM_MAX_LEVEL) / CASTLE_LEVEL_INTERVAL));
}
// The requirement is XP to reach the NEXT level, not cumulative XP.
// Lv1:100, Lv2:300, Lv3:400, Lv4:500; each later step grows by 100.
export function roomXpRequiredForLevel(level) {
  if (!Number.isSafeInteger(level) || level < 1 || level >= ROOM_MAX_LEVEL) {
    throw Object.assign(new Error("Invalid room XP level."), {status: 409});
  }
  return level === 1 ? 100 : (level + 1) * 100;
}

export function roomXpThresholdForLevel(level) {
  if (!Number.isSafeInteger(level) || level < 1 || level > ROOM_MAX_LEVEL) {
    throw Object.assign(new Error("Invalid room level."), {status: 409});
  }
  // Sum: first 100, then 300, 400, ... up to the prior level.
  return level === 1 ? 0 : 100 + (level * (level + 1) / 2 - 3) * 100;
}

export const ROOM_MAX_XP = roomXpThresholdForLevel(ROOM_MAX_LEVEL);

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
      return {taskKey, xp: 50, requiredCount: 5, period: "once"};
    case "three_gifts":
      return {taskKey, xp: configuredPoints(config?.sendThreeGiftsXp,
        "Three-gift mission"), requiredCount: 3, period: "once_per_room"};
    case "stay_hours": {
      const hours = config?.stayHoursMinimum;
      if (!Number.isSafeInteger(hours) || hours < 1 || hours > 24) {
        throw Object.assign(new Error(
          "Hours mission needs an approved stayHoursMinimum from 1 to 24."),
        {status: 503});
      }
      return {taskKey, xp: configuredPoints(config?.stayHoursXp,
        "Hours mission"), requiredMinutes: hours * 60, period: "day"};
    }
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
