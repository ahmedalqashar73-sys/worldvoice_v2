import test from 'node:test';
import assert from 'node:assert/strict';
import {registerChatRoutes} from '../src/chat_routes.js';
import {transactionDb} from './helpers/transaction_db.js';
function setup() {
  const {db,values}=transactionDb({
    'users/alice':{},'users/bob':{},'users/carol':{},
    'users/alice/following/bob':{},'users/bob/following/alice':{},
    'users/alice/following/carol':{},'users/carol/following/alice':{},
  });
  const routes=new Map();
  const app={get:()=>{},post:(p,h)=>routes.set(p,h)};
  registerChatRoutes({app,db,authenticatedUser:async()=>({uid:'alice'})});
  const call=async(body={name:'Friends',memberIds:['bob','carol']})=>{
    let result; const res={json:d=>{result={status:200,...d};}};
    await routes.get('/chat/group/create')({body,headers:{'idempotency-key':'group_key_123456'}},res,
      e=>{result={status:e.status||500,error:e.message};});return result;
  };
  return {values,call};
}
test('repeated simultaneous group creation returns one group',async()=>{
  const {call,values}=setup();const results=await Promise.all([call(),call(),call()]);
  assert.ok(results.every(r=>r.status===200),JSON.stringify(results));
  assert.equal(new Set(results.map(r=>r.chatId)).size,1);
  assert.equal([...values.keys()].filter(p=>p.startsWith('chats/')).length,1);
  assert.equal((await call({name:'Different',memberIds:['bob','carol']})).status,409);
});
test('group rejects missing mutual following and blocking without creating',async()=>{
  for(const block of [false,true]) {
    const {call,values}=setup();
    if(block) values.set('users/bob/blocked_peers/alice',{});
    else values.delete('users/bob/following/alice');
    assert.equal((await call()).status,403);
    assert.equal([...values.keys()].some(p=>p.startsWith('chats/')),false);
  }
});
