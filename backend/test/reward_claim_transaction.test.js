import test from 'node:test';
import assert from 'node:assert/strict';
import {registerEngagementRoutes} from '../src/engagement_routes.js';
import {DAY_MS} from '../src/engagement_policy.js';
import {transactionDb} from './helpers/transaction_db.js';
import {worldVoiceGiftCatalog} from '../src/gift_catalog.js';
test('three new daily claims deliver distinct gifts once with names and no wallet writes',async()=>{
 const {db,values}=transactionDb({'users/alice':{displayName:'Alice'}});
 for(const id of ['001','002','003']) values.set(`store_items/gift__wv_gift_${id}`,
   {...worldVoiceGiftCatalog.get(`wv_gift_${id}`),type:'gift',active:true});
 const routes=new Map();let now=21000*DAY_MS;
 registerEngagementRoutes({db,clock:()=>now,authenticatedUser:async()=>({uid:'alice'}),
   app:{get:(p,h)=>routes.set(p,h),post:(p,h)=>routes.set(p,h)}});
 for(let day=1;day<=3;day++) {
  now=(21000+day-1)*DAY_MS;
  for(let retry=0;retry<2;retry++) {
   let result;
   await routes.get('/engagement/claim')({body:{startDay:21000,day}},
    {json:r=>{result=r;}},e=>{throw e;});
   assert.equal(result.alreadyProcessed,retry===1);
  }
  const gift=values.get(`users/alice/inventory/gift__wv_gift_00${day}`);
  assert.equal(gift.freeGiftBalance,1);
  assert.ok(gift.nameAr);
 }
 assert.equal(values.has('users/alice/private/wallet'),false);
});
