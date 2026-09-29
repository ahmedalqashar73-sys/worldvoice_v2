// Non-monetary room progression only. No coins, diamonds or cash-equivalent
// rewards may be minted by tasks or written by an untrusted phone.
export const ROOM_MAX_LEVEL = 60;
export const ROOM_XP_PER_LEVEL = 100;
export const ROOM_MAX_XP = (ROOM_MAX_LEVEL - 1) * ROOM_XP_PER_LEVEL;

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
  return Math.min(ROOM_MAX_LEVEL, 1 + Math.floor(roomXp / ROOM_XP_PER_LEVEL));
}

export function advanceRoomLevel(currentXp, earnedXp) {
  const oldLevel = roomLevelFromXp(currentXp);
  if (!Number.isSafeInteger(earnedXp) || earnedXp < 1 || earnedXp > 500) {
    throw Object.assign(new Error("Invalid mission XP."), {status: 503});
  }
  if (currentXp >= ROOM_MAX_XP) {
    throw Object.assign(new Error("Room has reached level 60."), {status: 409});
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
