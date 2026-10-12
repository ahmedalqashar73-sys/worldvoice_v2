import test from 'node:test';
import assert from 'node:assert/strict';
import {canManageStore} from '../src/economy_policy.js';

test('cosmetic grants require active server-owned store permission', () => {
  for (const value of [undefined, {}, {isAdmin: true}, {role: 'host', active: true},
    {role: 'super_admin', active: false}, {active: true, permissions: 'manage_store'},
    {active: true, permissions: ['manage_rooms']}]) {
    assert.equal(canManageStore(value), false);
  }
  assert.equal(canManageStore({active: true, role: 'super_admin'}), true);
  assert.equal(canManageStore({active: true, permissions: ['manage_store']}), true);
});
