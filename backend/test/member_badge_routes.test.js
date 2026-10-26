import test from 'node:test';
import assert from 'node:assert/strict';
import {registerMemberBadgeRoutes} from '../src/member_badge_routes.js';
// In-memory transaction adapter exercises the actual route and atomic writes.
function setup({vip=true, admin=false, coins=300}={}) {
  const values=new Map([
    ['users/tester',{isVip:vip}], ['users/tester/private/wallet',{coins}],
    ['admins/tester',admin?{active:true,role:'super_admin'}:{}],
    ['economy_config/current',{enabled:true,privateWalletCutoverVerified:true,publicProfileRulesVerified:true,
      coinsPerUsd:100,diamondUsdValue:.01,giftLevelPointsPerCoin:1,receiverSharePercent:40,withdrawalFeePercent:5,
      exchangeBonusPercent:0,webCardBonusPercent:0,firstRechargeBonusPercent:0,holdDays:3,minWithdrawalDiamonds:100,
      minExchangeDiamonds:100,giftingDailyCoinLimit:10000,purchaseDailyUsdLimit:100,payoutWindows:[1,15],withdrawalMethods:['paypal']}],
  ]);
  const ref=path=>({path,parent:{id:path.split('/').at(-2)},collection:n=>({doc:id=>ref(`${path}/${n}/${id}`)})});
  const snap=r=>({exists:values.has(r.path),data:()=>values.get(r.path)});
  const db={collection:n=>({doc:id=>ref(`${n}/${id}`)}),doc:ref,getAll:async(...refs)=>refs.map(snap),
    runTransaction:async fn=>{
      const writes=[];
      const value=await fn({get:async r=>snap(r),update:(r,d)=>writes.push([r,{...values.get(r.path),...d}]),
        set:(r,d)=>writes.push([r,{...values.get(r.path),...d}]),create:(r,d)=>{
          if(values.has(r.path))throw new Error('Duplicate');writes.push([r,d]);}});
      for(const [r,d] of writes)values.set(r.path,d);
      return value;
    }};
  const routes=new Map();
  registerMemberBadgeRoutes({db,app:{get:(p,h)=>routes.set('get',h),post:(p,h)=>routes.set('post',h)},authenticatedUser:async()=>({uid:'tester'})});
  let n=0;
  async function call(body,method='post') {
    let output;const res={code:200,status(code){this.code=code;return this;},json(data){output={status:this.code,data};}};
    await routes.get(method)({body:body?{requestId:`test_request_${++n}_key`,...body}:undefined},res,error=>{output={status:error.status??500,error:error.message};});return output;
  }
  return {values,call};
}
test('purchase is charged once across retries and equips owned design',async()=>{
  const {values,call}=setup();const body={design:'sakura',action:'purchase',requestId:'stable_request_123456'};
  assert.equal((await call(body)).status,200);
  assert.equal((await call(body)).status,200);
  assert.equal(values.get('users/tester/private/wallet').coins,180);
  assert.deepEqual(values.get('users/tester/private/member_badges').owned,['sakura']);
  assert.equal((await call({...body,design:'aurora'})).status,409);
  assert.equal((await call({design:'sakura',action:'purchase'})).data.paidCoins,0);
  assert.equal((await call({design:'automatic',action:'equip'})).data.selected,'monthly');
});
test('VIP, ownership, frozen wallets and balance are enforced',async()=>{
  assert.equal((await setup({vip:false}).call({design:'sakura',action:'purchase'})).status,403);
  assert.equal((await setup().call({design:'sakura',action:'equip'})).status,403);
  const low=setup({coins:1});assert.equal((await low.call({design:'sakura',action:'purchase'})).status,409);
  assert.equal(low.values.has('users/tester/private/member_badges'),false);
  const frozen=setup();frozen.values.get('users/tester/private/wallet').walletFrozen=true;
  assert.equal((await frozen.call({design:'sakura',action:'purchase'})).status,423);
});
test('server-authorized administrator equips for free without creating gift XP',async()=>{
  const {values,call}=setup({admin:true,coins:0});
  assert.equal((await call({design:'celestial',action:'purchase'})).data.paidCoins,0);
  assert.deepEqual(values.get('users/tester/private/wallet'),{coins:0});
  const result=await call(undefined,'get');assert.equal(result.data.selected,'celestial');
  assert.equal(result.data.progress.level,0);
});
