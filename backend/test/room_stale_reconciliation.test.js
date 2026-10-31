import test from "node:test";
import assert from "node:assert/strict";
import {staleRoomDecision} from "../src/room_stale_reconciliation.js";

const now = Date.parse("2026-11-01T12:00:00Z");
const at = ms => ({toMillis:()=>ms});
const room = (ageMin, isOpen=true) => ({
  isOpen, createdAt: at(now - ageMin * 60000),
});
const member = ageMin => ({
  updatedAt: at(now - ageMin * 60000),
});

test("closes a stale room with no participants after three minutes",()=>{
  assert.equal(staleRoomDecision({room:room(4),participants:[],now}),true);
  assert.equal(staleRoomDecision({
    room:room(12),participants:[member(12),member(7)],now}),true);
});
test("never closes a room with active host, moderator or listener",()=>{
  assert.equal(staleRoomDecision({
    room:room(25),participants:[member(10),member(0.2)],now}),false);
  assert.equal(staleRoomDecision({
    room:room(3),participants:[member(2.9)],now}),false);
  assert.equal(staleRoomDecision({
    room:room(0.5),participants:[],now}),false);
});
test("never closes already-ended, unverified or missing presence rooms",()=>{
  assert.equal(staleRoomDecision({
    room:room(100,false),participants:[],now}),false);
  assert.equal(staleRoomDecision({
    room:{isOpen:true},participants:[],now}),false);
  assert.equal(staleRoomDecision({
    room:room(100),participants:null,now}),false);
});

test("never closes an oversized room with a possibly incomplete member scan",()=>{
  assert.equal(staleRoomDecision({
    room:room(30),participants:Array.from({length:150},()=>member(15)),now,
  }),false);
  assert.equal(staleRoomDecision({
    room:room(30),participants:[{},member(15)],now,
  }),false);
});
