import test from 'node:test';
import assert from 'node:assert/strict';
import {isActiveVipProfile, requireRoomTeacherVip} from '../src/vip_feature_policy.js';

test('VIP AI access validates explicit membership and expiry', () => {
  const now = Date.parse('2026-10-21T10:00:00Z');
  assert.equal(isActiveVipProfile(undefined, now), false);
  assert.equal(isActiveVipProfile({isVip:false}, now), false);
  assert.equal(isActiveVipProfile({isVip:true}, now), true);
  assert.equal(isActiveVipProfile({isVip:true,
    vipExpiresAt:new Date('2026-10-22T00:00:00Z')}, now), true);
  assert.equal(isActiveVipProfile({isVip:true,
    vipExpiresAt:{toDate:()=>new Date('2026-10-20T00:00:00Z')}}, now), false);
  assert.equal(isActiveVipProfile({isVip:true, vipExpiresAt:'bad-date'}, now), false);
});
test('room Teacher AI rejects free user before external provider processing', async () => {
  const db={collection:()=>({doc:()=>({get:async()=>({
    exists:true,data:()=>({isVip:false})})})})};
  await assert.rejects(()=>requireRoomTeacherVip(db,'free123'),
    error=>error.status===403&&error.message.startsWith('VIP_REQUIRED'));
  await assert.rejects(()=>requireRoomTeacherVip(db,''),
    error=>error.status===401);
});
test('active VIP is allowed',async()=>{
  const db={collection:()=>({doc:()=>({get:async()=>({
    exists:true,data:()=>({isVip:true})})})})};
  await assert.doesNotReject(()=>requireRoomTeacherVip(db,'vip456'));
});
