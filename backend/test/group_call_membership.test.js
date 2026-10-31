import test from "node:test";
import assert from "node:assert/strict";
import {assertGroupCallMembership} from "../src/group_call_routes.js";

const group = {
  type: "group",
  active: true,
  memberIds: ["creator", "member1", "member2"],
};

test("a current member of a real group may join its call", () => {
  assert.doesNotThrow(() => assertGroupCallMembership(group, "member1"));
});

test("outsiders, former members and inactive groups cannot join", () => {
  assert.throws(() => assertGroupCallMembership(group, "outsider"),
    /Active group membership required/);
  assert.throws(() => assertGroupCallMembership({...group, active: false}, "member1"),
    /Active group membership required/);
  assert.throws(() => assertGroupCallMembership({...group, type: "direct"}, "member1"),
    /Active group membership required/);
});

test("group calls always need at least three members and at most thirty", () => {
  assert.throws(() => assertGroupCallMembership(
    {...group, memberIds: ["creator", "member1"]}, "member1",
  ), /Active group membership required/);
  assert.throws(() => assertGroupCallMembership(
    {...group, memberIds: Array(31).fill(0).map((_, i) => "member" + i)},
    "member0",
  ), /Active group membership required/);
});
