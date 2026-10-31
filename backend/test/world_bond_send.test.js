import test from 'node:test';
import assert from 'node:assert/strict';
import {registerGiftSendRoutes} from '../src/gift_send_routes.js';
import {bondKey} from '../src/world_bond_routes.js';
import {transactionDb,economyFixture} from './helpers/transaction_db.js';

function setup({coins=2000, auth=true}={}) {
  const bondId=bondKey('alice','bob','friend');
  const {db,values}=transactionDb({
    'users/alice':{displayName:'Alice',coins:777},'users/bob':{displayName:'Bob'},
    'users/alice/private/wallet':{coins},'users/bob/private/wallet':{diamondsPending:0},
    'economy_config/current':economyFixture,
    [`world_bonds/${bondId}`]:{type:'friend',members:['alice','bob'],status:'active',xp:77},
  });
  const routes=new Map();
  registerGiftSendRoutes({db,app:{post:(p,h)=>routes.set(p,h)},
    validChannelName:v=>typeof v==='string' && /^[\w-]+$/.test(v),
    authenticatedUser:async()=>{
      if(!auth) throw Object.assign(new Error('Unauthenticated'),{status:401});
      return {uid:'alice'};
    }});
  const call=async (body={},key='bond_request_123456',path='/world-bond/gifts/send')=>{
    let result;
    const res={code:200,status(c){this.code=c;return this;},json(d){result={status:this.code,...d};}};
    await routes.get(path)({body:{recipientId:'bob',type:'friend',giftId:'wv_bond_01',...body},
      headers:{'idempotency-key':key}},res,e=>{result={status:e.status||500,error:e.message};});
    return result;
  };
  return {values,call,bondId};
}
test('server prices all four gifts; no free inventory or client price override',async()=>{
  for(const [id,price] of [['01',100],['02',200],['03',500],['04',1000]]) {
    const {values,call,bondId}=setup();
    values.set(`users/alice/inventory/gift__wv_bond_${id}`,{freeGiftBalance:100});
    const result=await call({giftId:`wv_bond_${id}`,priceCoins:1,quantity:100});
    assert.equal(result.status,200,JSON.stringify(result));
    assert.equal(result.chargedCoins,price);
    assert.equal(values.get('users/alice/private/wallet').coins,2000-price);
    assert.equal(values.get('users/alice').coins,777);
    assert.equal(values.get(`world_bonds/${bondId}`).xp,77);
    assert.equal([...values.keys()].filter(k=>k.startsWith('world_bond_gift_history/')).length,1);
    assert.equal([...values.keys()].some(k=>k.startsWith('economy_gift_operations/')),false);
  }
});
test('simultaneous retries debit once and payload collisions fail',async()=>{
  const {call,values}=setup();
  const results=await Promise.all(Array.from({length:10},()=>call()));
  assert.ok(results.every(r=>r.status===200),JSON.stringify(results));
  assert.equal(results.filter(r=>!r.alreadyProcessed).length,1);
  assert.equal(values.get('users/alice/private/wallet').coins,1900);
  assert.equal((await call({giftId:'wv_bond_04'})).status,409);
});
test('insufficient balance, self, unauthenticated, inactive, blocked, frozen fail without writes',async()=>{
  const cases=[
    [{coins:99},null,{},409], [{auth:false},null,{},401],
    [{},null,{recipientId:'alice'},400],
    [{},(v,id)=>v.get(`world_bonds/${id}`).status='pending',{},403],
    [{},v=>v.set('users/alice/blocked_peers/bob',{}),{},403],
    [{},v=>v.set('users/bob/blocked_peers/alice',{}),{},403],
    [{},v=>v.get('users/alice/private/wallet').walletFrozen=true,{},423],
    [{},v=>v.delete('users/alice/private/wallet'),{},503],
  ];
  for(const [options,mutate,body,status] of cases) {
    const {values,call,bondId}=setup(options);mutate?.(values,bondId);
    const before=JSON.stringify([...values]);
    assert.equal((await call(body)).status,status);
    assert.equal(JSON.stringify([...values]),before);
  }
});
test('both APIs reject the other catalog; ordinary room send still settles',async()=>{
  const {call,values}=setup();
  assert.equal((await call({giftId:'wv_gift_001'})).status,400);
  assert.equal((await call({context:'chat',contextId:'a'.repeat(64),quantity:1},undefined,'/gift/send')).status,400);
  values.set('rooms/testroom',{isOpen:true});
  values.set('rooms/testroom/participants/alice',{});
  values.set('rooms/testroom/participants/bob',{});
  // wv_gift_001 price comes from the original catalog.
  const {worldVoiceGiftCatalog}=await import('../src/gift_catalog.js');
  const item=worldVoiceGiftCatalog.get('wv_gift_001');
  values.set('store_items/gift__wv_gift_001',{...item,type:'gift',active:true});
  const result=await call({context:'room',contextId:'testroom',quantity:1,giftId:'wv_gift_001'},undefined,'/gift/send');
  assert.equal(result.status,200,JSON.stringify(result));
  assert.equal(result.chargedCoins,item.priceCoins);
});
