// Transaction test double: serializable calls, staged atomic writes, detects
// reads after writes. Production uses Firestore's retrying runTransaction.
export function transactionDb(seed) {
  const values = new Map(Object.entries(seed));
  const ref = path => ({path, id: path.split('/').at(-1),
    parent: {id: path.split('/').at(-2)},
    collection: n => ({doc: id => ref(`${path}/${n}/${id}`)})});
  const snap = r => ({id:r.id, exists:values.has(r.path), data:()=>values.get(r.path)});
  let queue = Promise.resolve();
  const db = {collection:n=>({doc:id=>ref(`${n}/${id}`)}),
    runTransaction(fn) {
      const pending = queue.then(async () => {
        const writes=[];
        const value = await fn({get:async r=>{
          if(writes.length) throw new Error('Read after write');
          return snap(r);
        }, set:(r,d)=>writes.push([r,{...values.get(r.path),...d}]),
        update:(r,d)=>writes.push([r,{...values.get(r.path),...d}]),
        create:(r,d)=>{
          if(values.has(r.path)) throw new Error('Duplicate create');
          writes.push([r,d]);
        }});
        for(const [r,d] of writes) values.set(r.path,d);
        return value;
      });
      queue=pending.catch(()=>{});
      return pending;
    }};
  return {db,values};
}
export const economyFixture = {
  enabled:true,privateWalletCutoverVerified:true,publicProfileRulesVerified:true,
  coinsPerUsd:100,diamondUsdValue:.01,giftLevelPointsPerCoin:1,receiverSharePercent:40,
  withdrawalFeePercent:5,exchangeBonusPercent:0,webCardBonusPercent:0,
  firstRechargeBonusPercent:0,holdDays:3,minWithdrawalDiamonds:100,
  minExchangeDiamonds:100,giftingDailyCoinLimit:10000,purchaseDailyUsdLimit:100,
  payoutWindows:[1,15],withdrawalMethods:['paypal'],
};
