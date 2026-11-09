import test from 'node:test';
import assert from 'node:assert/strict';
import {registerGiftSendRoutes} from '../src/gift_send_routes.js';
import {transactionDb} from './helpers/transaction_db.js';
import {worldVoiceGiftCatalog} from '../src/gift_catalog.js';
function setup() {
  const {db,values}=transactionDb({
    'users/alice':{displayName:'Alice'},'users/bob':{displayName:'Bob'},
    'rooms/testroom':{isOpen:true},
    'rooms/testroom/participants/alice':{},'rooms/testroom/participants/bob':{},
    'users/alice/inventory/gift__wv_gift_001':{type:'gift',freeGiftBalance:2},
    'store_items/gift__wv_gift_001':{...worldVoiceGiftCatalog.get('wv_gift_001'),type:'gift',active:true},
  });
  const routes=new Map();
  registerGiftSendRoutes({db,app:{post:(p,h)=>routes.set(p,h)},validChannelName:()=>true,
    authenticatedUser:async()=>({uid:'alice'})});
  const call=async(body={},key='owned_request_123456')=>{
    let result;
    const res={code:200,status(c){this.code=c;return this;},json(d){result={status:this.code,...d};}};
    await routes.get('/gift/send')({body:{context:'room',contextId:'testroom',recipientId:'bob',
      giftId:'wv_gift_001',quantity:1,inventoryOnly:true,...body},headers:{'idempotency-key':key}},res,
      e=>{result={status:e.status||500,error:e.message};});
    return result;
  };
  return {values,call};
}
test('ordinary user sends owned reward with economy off and no wallets; retries consume once',async()=>{
  const {values,call}=setup();
  const results=await Promise.all(Array.from({length:8},()=>call()));
  assert.ok(results.every(r=>r.status===200),JSON.stringify(results));
  assert.equal(results.filter(r=>!r.alreadyProcessed).length,1);
  assert.equal(results[0].chargedCoins,0);
  assert.equal(results[0].pendingDiamonds,0);
  assert.equal(values.get('users/alice/inventory/gift__wv_gift_001').freeGiftBalance,1);
  assert.equal(values.has('users/alice/private/wallet'),false);
  assert.equal(values.has('users/bob/private/wallet'),false);
  assert.equal([...values.keys()].filter(k=>k.startsWith('users/bob/gift_notifications/')).length,1);
});
test('unavailable owned gift cannot fall back to spending coins',async()=>{
  const {values,call}=setup();
  values.get('users/alice/inventory/gift__wv_gift_001').freeGiftBalance=0;
  values.set('users/alice/private/wallet',{coins:1000});
  const before=JSON.stringify([...values]);
  assert.equal((await call()).error,'OWNED_GIFT_UNAVAILABLE');
  assert.equal(JSON.stringify([...values]),before);
});
test('owned gifts retain membership, blocking and self-send checks',async()=>{
  for (const [mutate,body,status] of [
    [v=>v.delete('rooms/testroom/participants/bob'),{},403],
    [v=>v.set('users/bob/blocked_peers/alice',{}),{},403],
    [()=>{},{recipientId:'alice'},400],
  ]) {
    const {values,call}=setup();mutate(values);const before=JSON.stringify([...values]);
    assert.equal((await call(body)).status,status);
    assert.equal(JSON.stringify([...values]),before);
  }
});
test('expired inventory fails and existing wallet balances stay unchanged on free send',async()=>{
  const {Timestamp}=await import('firebase-admin/firestore');
  const {values,call}=setup();
  values.get('users/alice/inventory/gift__wv_gift_001').expiresAt=Timestamp.fromMillis(1);
  assert.equal((await call()).error,'OWNED_GIFT_UNAVAILABLE');
  delete values.get('users/alice/inventory/gift__wv_gift_001').expiresAt;
  values.set('users/alice/private/wallet',{coins:77,adminCoins:20});
  values.set('users/bob/private/wallet',{diamondsPending:9});
  const result=await call();
  assert.equal(result.status,200,JSON.stringify(result));
  assert.equal(result.balanceAfter,77);
  assert.deepEqual(values.get('users/alice/private/wallet'),{coins:77,adminCoins:20});
  assert.deepEqual(values.get('users/bob/private/wallet'),{diamondsPending:9});
});
