import test from "node:test";
import assert from "node:assert/strict";
import {
  roomTaskSpec, roomLevelFromXp, advanceRoomLevel, castleTierForLevel,
  roomProgressAfterGift, roomXpRequiredForLevel, roomXpThresholdForLevel, ROOM_MAX_XP,
} from "../src/room_task_policy.js";

test("explicit mission XP values are not silently invented", () => {
  assert.deepEqual(roomTaskSpec("ten_minutes", {}), {
    taskKey: "ten_minutes", xp: 4, requiredMinutes: 10, period: "day",
  });
  assert.deepEqual(roomTaskSpec("host_five", {}), {
    taskKey: "host_five", xp: 50, requiredCount: 5, period: "once",
  });
  assert.throws(() => roomTaskSpec("three_gifts", {}), {status: 503});
  assert.throws(() => roomTaskSpec("stay_hours", {}), {status: 503});
  assert.equal(roomTaskSpec("three_gifts",
    {sendThreeGiftsXp: 20}).xp, 20);
  assert.equal(roomTaskSpec("stay_hours",
    {stayHoursMinimum: 2, stayHoursXp: 15}).requiredMinutes, 120);
});

test("increasing room XP thresholds and safe level 50 cap", () => {
  assert.equal(roomXpRequiredForLevel(1), 100);
  assert.equal(roomXpRequiredForLevel(2), 300);
  assert.equal(roomXpRequiredForLevel(3), 400);
  assert.equal(roomXpRequiredForLevel(4), 500);
  assert.equal(roomXpThresholdForLevel(2), 100);
  assert.equal(roomXpThresholdForLevel(3), 400);
  assert.equal(roomXpThresholdForLevel(4), 800);
  assert.equal(roomLevelFromXp(0), 1);
  assert.equal(roomLevelFromXp(99), 1);
  assert.equal(roomLevelFromXp(100), 2);
  assert.equal(roomLevelFromXp(399), 2);
  assert.equal(roomLevelFromXp(400), 3);
  assert.equal(roomLevelFromXp(5900), 10);
  assert.equal(roomLevelFromXp(ROOM_MAX_XP), 50);
  assert.equal(roomLevelFromXp(ROOM_MAX_XP + 1000), 50);
  assert.deepEqual(advanceRoomLevel(95, 50), {
    oldLevel: 1, newLevel: 2, nextXp: 145, awardedXp: 50,
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
  assert.deepEqual(roomProgressAfterGift(95, 10), {nextXp: 105, newLevel: 2});
  assert.deepEqual(roomProgressAfterGift(390, 20), {nextXp: 410, newLevel: 3});
  assert.deepEqual(roomProgressAfterGift(ROOM_MAX_XP - 15, 40),
    {nextXp: ROOM_MAX_XP, newLevel: 50});
  assert.deepEqual(roomProgressAfterGift(ROOM_MAX_XP, 20),
    {nextXp: ROOM_MAX_XP, newLevel: 50});
  assert.throws(() => roomProgressAfterGift(-1, 10), {status: 409});
  assert.throws(() => roomProgressAfterGift(5, -1), {status: 409});
});
