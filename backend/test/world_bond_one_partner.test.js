import test from "node:test";
import assert from "node:assert/strict";
import {registerWorldBondRoutes} from "../src/world_bond_routes.js";
import {transactionDb} from "./helpers/transaction_db.js";

function harness() {
  const {db: base, values} = transactionDb({
    "users/alice": {displayName:"Alice"},
    "users/bob": {displayName:"Bob"},
    "users/carol": {displayName:"Carol"},
    "users/dave": {displayName:"Dave"},
  });
  const db = {
    ...base,
    collection(name) {
      const collection = base.collection(name);
      if (name !== "world_bonds") return collection;
      return {
        ...collection,
        where(field, operator, value) {
          assert.equal(field, "members");
          assert.equal(operator, "array-contains");
          return {
            limit(max) {
              return {
                async get() {
                  return {docs: [...values].filter(([path, data]) =>
                    /^world_bonds\/[^/]+$/.test(path) &&
                    Array.isArray(data.members) &&
                    data.members.includes(value))
                    .slice(0, max)
                    .map(([path, data]) => ({
                      id: path.split("/")[1],
                      data: () => data,
                    }))};
                },
              };
            },
          };
        },
      };
    },
  };
  const routes = new Map();
  let uid = "alice";
  registerWorldBondRoutes({
    db, app:{get:(p, fn)=>routes.set("GET "+p,fn),
      post:(p, fn)=>routes.set("POST "+p,fn)},
    authenticatedUser:async()=>({uid}),
    clock:()=>new Date("2026-11-01T11:00:00Z").getTime(),
  });
  async function call(path, from, body = {}) {
    uid = from;
    let output;
    const res = {code:200,status(code){this.code=code;return this;},
      json(data){output={http:this.code,...data};}};
    await routes.get("POST "+path)(
      {body,headers:{}},res,e=>{output={http:e.status||500,error:e.message};});
    return output;
  }
  return {call, values};
}

test("one partner per type for both members; other relationship types remain free",async()=>{
  const {call,values}=harness();
  const invite = (from, peerId, type) => call("/world-bond/invite",from,{peerId,type});
  assert.equal((await invite("alice","bob","learning")).http,200);
  assert.equal((await invite("alice","carol","learning")).http,409);
  assert.equal((await invite("carol","bob","learning")).http,409);
  assert.equal((await invite("alice","carol","language")).http,200);
  assert.equal((await call("/world-bond/respond","bob",
    {peerId:"alice",type:"learning",decision:"accept"})).status,"active");
  assert.equal((await invite("alice","carol","learning")).http,409);
  assert.equal(values.get("users/alice/worldbond_slots/learning").peerId,"bob");
  assert.equal(values.get("users/bob/worldbond_slots/learning").peerId,"alice");

  assert.equal((await call("/world-bond/respond","alice",
    {peerId:"bob",type:"learning",decision:"leave"})).status,"ended");
  assert.equal((await invite("alice","carol","learning")).http,200);
});

test("rejecting an invite releases both slots without modifying other types",async()=>{
  const {call,values}=harness();
  const send=(from,peerId,type)=>call("/world-bond/invite",from,{peerId,type});
  await send("alice","bob","friend");
  await send("alice","carol","language");
  assert.equal((await call("/world-bond/respond","bob",
    {peerId:"alice",type:"friend",decision:"decline"})).status,"declined");
  assert.equal(values.get("users/bob/worldbond_slots/friend").peerId,null);
  assert.equal((await send("alice","dave","friend")).http,200);
  assert.equal(values.get("users/alice/worldbond_slots/language").peerId,"carol");
});

test("legacy active relationships without slots still block a second partner",async()=>{
  const {call,values}=harness();
  values.set("world_bonds/legacy",{
    members:["alice","bob"],type:"duo",status:"active",xp:150});
  assert.equal((await call("/world-bond/invite","alice",
    {peerId:"carol",type:"duo"})).http,409);
  assert.equal((await call("/world-bond/invite","carol",
    {peerId:"bob",type:"duo"})).http,409);
});
