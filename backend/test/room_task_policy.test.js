import test from "node:test";
import assert from "node:assert/strict";
import {
  roomTaskSpec, roomLevelFromXp, advanceRoomLevel,
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

test("levels progress from 1 to 60 and never overflow", () => {
  assert.equal(roomLevelFromXp(0), 1);
  assert.equal(roomLevelFromXp(100), 2);
  assert.equal(roomLevelFromXp(5900), 60);
  assert.equal(roomLevelFromXp(8000), 60);
  assert.deepEqual(advanceRoomLevel(95, 50), {
    oldLevel: 1, newLevel: 2, nextXp: 145, awardedXp: 50,
    unlockedLevels: [2],
  });
  assert.deepEqual(advanceRoomLevel(5898, 4), {
    oldLevel: 59, newLevel: 60, nextXp: 5900, awardedXp: 2,
    unlockedLevels: [60],
  });
  assert.throws(() => advanceRoomLevel(5900, 4), {status: 409});
  assert.throws(() => advanceRoomLevel(-1, 4), {status: 409});
});
