import test from "node:test";
import assert from "node:assert/strict";
import {
  roomTaskSpec, roomLevelFromXp, advanceRoomLevel, castleTierForLevel,
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

test("levels progress from 1 to 50 and never overflow", () => {
  assert.equal(roomLevelFromXp(0), 1);
  assert.equal(roomLevelFromXp(100), 2);
  assert.equal(roomLevelFromXp(4900), 50);
  assert.equal(roomLevelFromXp(8000), 50);
  assert.equal(roomLevelFromXp(5900), 50); // preserve legacy XP without level 60
  assert.deepEqual(advanceRoomLevel(95, 50), {
    oldLevel: 1, newLevel: 2, nextXp: 145, awardedXp: 50,
    unlockedLevels: [2],
  });
  assert.deepEqual(advanceRoomLevel(4898, 4), {
    oldLevel: 49, newLevel: 50, nextXp: 4900, awardedXp: 2,
    unlockedLevels: [50],
  });
  assert.throws(() => advanceRoomLevel(4900, 4), {status: 409});
  assert.throws(() => advanceRoomLevel(5900, 4), {status: 409});
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
