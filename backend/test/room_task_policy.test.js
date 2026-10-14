import test from "node:test";
import assert from "node:assert/strict";
import {
  roomTaskSpec, roomLevelFromXp, advanceRoomLevel, castleTierForLevel,
  roomProgressAfterGift, roomXpRequiredForLevel, roomXpThresholdForLevel,
  roomCastleProgressSnapshot, castleMilestoneLevels, ROOM_MAX_XP,
  isRecentRoomParticipant,
} from "../src/room_task_policy.js";

test("explicit mission XP values are not silently invented", () => {
  assert.deepEqual(roomTaskSpec("ten_minutes", {}), {
    taskKey: "ten_minutes", xp: 4, requiredMinutes: 10, period: "day",
  });
  assert.deepEqual(roomTaskSpec("host_five", {}), {
    taskKey: "host_five", xp: 50, requiredCount: 5, period: "once",
  });
  assert.deepEqual(roomTaskSpec("three_gifts", {}), {
    taskKey: "three_gifts", xp: 20, requiredCount: 3, period: "once_per_room",
  });
  assert.deepEqual(roomTaskSpec("stay_hours", {}), {
    taskKey: "stay_hours", xp: 15, requiredMinutes: 120, period: "day",
  });
  assert.equal(roomTaskSpec("three_gifts",
    {sendThreeGiftsXp: 20}).xp, 20);
  assert.equal(roomTaskSpec("stay_hours",
    {stayHoursMinimum: 2, stayHoursXp: 15}).requiredMinutes, 120);
});

test("increasing room XP thresholds and safe level 50 cap", () => {
  assert.equal(roomXpRequiredForLevel(1), 300);
  assert.equal(roomXpRequiredForLevel(2), 400);
  assert.equal(roomXpRequiredForLevel(3), 700);
  assert.equal(roomXpRequiredForLevel(4), 1000);
  assert.equal(roomXpThresholdForLevel(2), 300);
  assert.equal(roomXpThresholdForLevel(3), 700);
  assert.equal(roomXpThresholdForLevel(4), 1400);
  assert.equal(roomLevelFromXp(0), 1);
  assert.equal(roomLevelFromXp(299), 1);
  assert.equal(roomLevelFromXp(300), 2);
  assert.equal(roomLevelFromXp(699), 2);
  assert.equal(roomLevelFromXp(700), 3);
  assert.equal(roomLevelFromXp(5900), 7);
  assert.equal(roomLevelFromXp(ROOM_MAX_XP), 50);
  assert.equal(roomLevelFromXp(ROOM_MAX_XP + 1000), 50);
  assert.deepEqual(advanceRoomLevel(295, 50), {
    oldLevel: 1, newLevel: 2, nextXp: 345, awardedXp: 50,
    unlockedLevels: [2],
  });
  assert.deepEqual(advanceRoomLevel(ROOM_MAX_XP - 2, 4), {
    oldLevel: 49, newLevel: 50, nextXp: ROOM_MAX_XP, awardedXp: 2,
    unlockedLevels: [50],
  });
  assert.throws(() => advanceRoomLevel(ROOM_MAX_XP, 4), {status: 409});
  assert.throws(() => advanceRoomLevel(-1, 4), {status: 409});
});

test("castle visual tier advances every five room levels", () => {
  assert.equal(castleTierForLevel(1), 1);
  assert.equal(castleTierForLevel(5), 1);
  assert.equal(castleTierForLevel(6), 2);
  assert.equal(castleTierForLevel(15), 3);
  assert.equal(castleTierForLevel(50), 10);
  assert.equal(castleTierForLevel(60), 10); // legacy room level compatibility
  assert.throws(() => castleTierForLevel(0), {status: 409});
});

test("Teacher-AI gift contributions follow growing XP thresholds", () => {
  assert.deepEqual(roomProgressAfterGift(295, 10), {nextXp: 305, newLevel: 2});
  assert.deepEqual(roomProgressAfterGift(690, 20), {nextXp: 710, newLevel: 3});
  assert.deepEqual(roomProgressAfterGift(ROOM_MAX_XP - 15, 40),
    {nextXp: ROOM_MAX_XP, newLevel: 50});
  assert.deepEqual(roomProgressAfterGift(ROOM_MAX_XP, 20),
    {nextXp: ROOM_MAX_XP, newLevel: 50});
  assert.throws(() => roomProgressAfterGift(-1, 10), {status: 409});
  assert.throws(() => roomProgressAfterGift(5, -1), {status: 409});
});

test("legacy rooms retain castle level and convert XP only once", () => {
  const brandNew = roomCastleProgressSnapshot({roomXp: 0, roomLevel: 1});
  assert.deepEqual(brandNew, {xp: 0, level: 1, legacy: true});

  const oldTwo = roomCastleProgressSnapshot({roomXp: 100, roomLevel: 2});
  assert.deepEqual(oldTwo, {xp: 300, level: 2, legacy: true});

  const oldThirty = roomCastleProgressSnapshot({roomXp: 2900, roomLevel: 30});
  assert.equal(oldThirty.level, 30);
  assert.equal(oldThirty.xp, roomXpThresholdForLevel(30));

  const oldSixty = roomCastleProgressSnapshot({roomXp: 5900, roomLevel: 60});
  assert.equal(oldSixty.level, 50);
  assert.equal(oldSixty.xp, ROOM_MAX_XP);

  const migrated = roomCastleProgressSnapshot({
    roomXp: 450, roomLevel: 2, roomCastleXpVersion: 2,
  });
  assert.deepEqual(migrated, {xp: 450, level: 2, legacy: false});
  assert.throws(() => roomCastleProgressSnapshot({roomXp: -1}), {status: 409});
});

test("config overrides defaults and rejects unsafe values", () => {
  assert.equal(roomTaskSpec("three_gifts", {sendThreeGiftsXp: 30}).xp, 30);
  assert.equal(roomTaskSpec("stay_hours", {stayHoursMinimum: 3, stayHoursXp: 40}).requiredMinutes, 180);
  assert.throws(() => roomTaskSpec("three_gifts", {sendThreeGiftsXp: -2}), {status: 503});
  assert.throws(() => roomTaskSpec("stay_hours", {stayHoursMinimum: 0}), {status: 503});
});

test("castle XP progression remains strictly increasing through level 50", () => {
  let previousThreshold = -1;
  for (let level = 1; level <= 50; level++) {
    const threshold = roomXpThresholdForLevel(level);
    assert.ok(threshold > previousThreshold);
    assert.equal(roomLevelFromXp(threshold), level);
    if (level < 50) {
      const needed = roomXpRequiredForLevel(level);
      assert.equal(roomLevelFromXp(threshold + needed - 1), level);
      assert.equal(roomLevelFromXp(threshold + needed), level + 1);
    }
    previousThreshold = threshold;
  }
  assert.equal(ROOM_MAX_XP, roomXpThresholdForLevel(50));
});

test("castle tiers have five levels each, including both boundaries", () => {
  for (let level = 1; level <= 50; level++) {
    assert.equal(castleTierForLevel(level), Math.ceil(level / 5));
  }
});

test("only ten five-level castle milestones generate fanout rewards", () => {
  assert.deepEqual(castleMilestoneLevels([2, 3, 4]), []);
  assert.deepEqual(castleMilestoneLevels([4, 5, 6]), [5]);
  assert.deepEqual(castleMilestoneLevels([24, 25, 26, 29, 30]), [25, 30]);
  assert.deepEqual(castleMilestoneLevels([49, 50, 51, 60]), [50]);
  assert.deepEqual(castleMilestoneLevels(
    Array.from({length: 50}, (_, index) => index + 1)),
    [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]);
});

test("stale room members cannot earn attendance or host guest credit", () => {
  const now = 1_800_000_000_000;
  const timestamp = ms => ({toMillis: () => ms});
  const present = {
    joinedAt: timestamp(now - 10 * 60_000),
    updatedAt: timestamp(now - 30_000),
  };
  const stale = {
    joinedAt: timestamp(now - 10 * 60_000),
    updatedAt: timestamp(now - 4 * 60_000),
  };
  assert.equal(isRecentRoomParticipant(present, now), true);
  assert.equal(isRecentRoomParticipant(stale, now), false);
  assert.equal(isRecentRoomParticipant({
    joinedAt: timestamp(now - 20_000),
    updatedAt: timestamp(now + 10_000),
  }, now), false);
  assert.equal(isRecentRoomParticipant({joinedAt: timestamp(now)}, now), false);
  assert.equal(isRecentRoomParticipant({}, now), false);
});
