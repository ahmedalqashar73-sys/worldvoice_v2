import test from "node:test";
import assert from "node:assert/strict";
import {compactRoomSeatPlan} from "../src/room_seat_compaction_routes.js";

const member = (id, seatIndex, role = "speaker") => ({
  id, data: {seatIndex, role, agoraUid: 900 + seatIndex,
    isModerator: role === "coHost"},
});

test("seat two departure shifts seats three and four forward, never host", () => {
  const plan = compactRoomSeatPlan([
    member("owner", 1, "host"),
    member("speaker3", 3),
    member("speaker4", 4),
    member("listener", 0, "listener"),
  ], "owner");
  assert.deepEqual(plan, [
    {id: "speaker3", from: 3, to: 2},
    {id: "speaker4", from: 4, to: 3},
  ]);
});

test("eight seats, fifth exits: sixth/seventh/eighth shift in order", () => {
  const seats = [member("owner", 1, "host"),
    member("s2", 2), member("s3", 3), member("s4", 4),
    member("s6", 6), member("s7", 7, "coHost"),
    member("s8", 8, "vipSeat")];
  assert.deepEqual(compactRoomSeatPlan(seats, "owner"), [
    {id: "s6", from: 6, to: 5},
    {id: "s7", from: 7, to: 6},
    {id: "s8", from: 8, to: 7},
  ]);
});
