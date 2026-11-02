import test from "node:test";
import assert from "node:assert/strict";
import {compactRoomSeatPlan} from "../src/room_seat_compaction_routes.js";

const member = (id, seatIndex, role = "speaker") => ({
  id, data: {seatIndex, role, agoraUid: 17, isModerator: true},
});

test("compacts six occupied seats after seat five departs", () => {
  const rows = [member("owner", 1, "host"), member("a", 2),
    member("b", 3), member("c", 4), member("d", 6),
    member("e", 7, "coHost"), member("f", 8, "vipSeat")];
  assert.deepEqual(compactRoomSeatPlan(rows, "owner"), [
    {id: "d", from: 6, to: 5},
    {id: "e", from: 7, to: 6},
    {id: "f", from: 8, to: 7},
  ]);
  assert.equal(rows[5].data.agoraUid, 17);
  assert.equal(rows[5].data.isModerator, true);
});

test("host seat stays reserved and listeners never shift", () => {
  const rows = [member("host", 1, "host"),
    member("a", 4, "speaker"), member("listener", 5, "listener")];
  assert.deepEqual(compactRoomSeatPlan(rows, "host"),
    [{id: "a", from: 4, to: 2}]);
});

test("full contiguous stage has no modifications", () => {
  const rows = [member("h", 1, "host"),
    ...Array.from({length: 7}, (_, i) => member("u" + i, i + 2))];
  assert.deepEqual(compactRoomSeatPlan(rows, "h"), []);
});
