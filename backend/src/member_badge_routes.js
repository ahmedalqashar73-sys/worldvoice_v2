import {createHash} from 'node:crypto';
import {FieldValue} from 'firebase-admin/firestore';
import {privateWalletRef, requirePrivateWallet} from './wallet_store.js';
import {canManageStore, requireLiveEconomy} from './economy_policy.js';
import {extraBadges, giftProgress, automaticVipBadge, visibleVipBadge} from './member_badge_policy.js';
export const memberBadgeRef = (db, uid) => db.collection('users').doc(uid).collection('private').doc('member_badges');
export function registerMemberBadgeRoutes({app, db, authenticatedUser}) {
  app.get('/engagement/member-style', async (req, res, next) => {
    try {
      const user = await authenticatedUser(req), ref = db.collection('users').doc(user.uid);
      const [profile, wallet, state, admin] = await db.getAll(ref, privateWalletRef(ref), memberBadgeRef(db, user.uid), db.collection('admins').doc(user.uid));
      res.json({ok: true, progress: giftProgress(wallet.data()), automatic: automaticVipBadge(profile.data(), Date.now(), state.data()),
        selected: visibleVipBadge(profile.data(), state.data()), owned: state.data()?.owned ?? [],
        admin: canManageStore(admin.data()), catalog: extraBadges});
    } catch (error) { next(error); }
  });
  app.post('/engagement/member-style', async (req, res, next) => {
    try {
      const user = await authenticatedUser(req), {design, action, requestId} = req.body ?? {};
      if (!['purchase', 'equip'].includes(action) || typeof design !== 'string' ||
          !/^[A-Za-z0-9_-]{16,100}$/.test(requestId ?? '')) return res.status(400).json({error: 'INVALID_BADGE_REQUEST'});
      const ref = db.collection('users').doc(user.uid), stateRef = memberBadgeRef(db, user.uid);
      const walletRef = privateWalletRef(ref);
      const key = createHash('sha256').update(`${user.uid}:badge:${requestId}`).digest('hex');
      const operation = db.collection('economy_store_operations').doc(key);
      const outcome = await db.runTransaction(async tx => {
        const [profile, wallet, state, admin, prior, config] = await Promise.all([
          ref, walletRef, stateRef, db.collection('admins').doc(user.uid), operation, db.doc('economy_config/current')
        ].map(r => tx.get(r)));
        if (prior.exists) {
          if (prior.data().design !== design || prior.data().action !== action) throw Object.assign(new Error('REQUEST_CONFLICT'), {status: 409});
          return prior.data().outcome;
        }
        const automatic = automaticVipBadge(profile.data(), Date.now(), state.data());
        const isAdmin = canManageStore(admin.data());
        if (!automatic) throw Object.assign(new Error('VIP_REQUIRED'), {status: 403});
        const owned = state.data()?.owned ?? [];
        const price = extraBadges[design];
        if (design !== 'automatic' && !Object.hasOwn(extraBadges, design)) throw Object.assign(new Error('INVALID_BADGE'), {status: 400});
        let paidCoins = 0;
        if (design !== 'automatic' && !owned.includes(design)) {
          if (action !== 'purchase') throw Object.assign(new Error('BADGE_NOT_OWNED'), {status: 403});
          if (!isAdmin) {
            requireLiveEconomy(config.data());
            const balance = requirePrivateWallet(wallet);
            if (balance.walletFrozen || (balance.walletDebtCoins ?? 0) > 0) throw Object.assign(new Error('WALLET_FROZEN'), {status: 423});
            if (!Number.isSafeInteger(balance.coins) || balance.coins < price) throw Object.assign(new Error('NOT_ENOUGH_COINS'), {status: 409});
            paidCoins = price;
            tx.update(walletRef, {coins: balance.coins - price, updatedAt: FieldValue.serverTimestamp()});
            tx.create(ref.collection('wallet_transactions').doc(key), {type: 'badge_purchase', currency: 'coins', amount: -price,
              balanceBefore: balance.coins, balanceAfter: balance.coins-price, itemId: design, createdAt: FieldValue.serverTimestamp()});
          }
        }
        tx.set(stateRef, {selected: design, owned: design === 'automatic' ? owned : [...new Set([...owned, design])], updatedAt: FieldValue.serverTimestamp()}, {merge: true});
        const result = {ok: true, selected: design === 'automatic' ? automatic : design, paidCoins};
        tx.create(operation, {design, action, senderId: user.uid, outcome: result, createdAt: FieldValue.serverTimestamp()});
        tx.create(db.collection('economy_audit').doc(key), {type: isAdmin ? 'admin_badge_equip' : 'member_badge_equip', uid: user.uid, design, paidCoins, createdAt: FieldValue.serverTimestamp()});
        return result;
      });
      res.json(outcome);
    } catch (error) { next(error); }
  });
}
