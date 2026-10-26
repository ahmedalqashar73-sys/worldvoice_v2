import {giftProgress, visibleVipBadge} from './member_badge_policy.js';
import {memberBadgeRef} from './member_badge_routes.js';
import {privateWalletRef} from './wallet_store.js';
import {FieldValue} from 'firebase-admin/firestore';
import {cycleView, cycleEvidence, creativeAward, CYCLE_GIFT_ID} from './engagement_policy.js';
export const engagementRef = (db, uid) => db.collection('users').doc(uid)
  .collection('engagement').doc('cycle');
export function registerEngagementRoutes({app, db, authenticatedUser, clock = Date.now}) {
  app.get('/engagement/status', async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const state = (await engagementRef(db, user.uid).get()).data() ?? {};
      const now = clock();
      return res.json({ok: true, ...cycleView(state, now), ...cycleEvidence(state, now),
        serverNowMs: now, creativeCycles: state.creativeCycles ?? 0,
        creativeAwardedAtMs: state.creativeAwardedAtMs ?? null,
        completedCycles: state.completedCycles ?? 0, giftId: CYCLE_GIFT_ID});
    } catch (error) { next(error); }
  });
  // Public achievements only: never expose attendance, wallet or private cycle dates.
  app.get('/engagement/badges', async (req, res, next) => {
    try {
      await authenticatedUser(req);
      const ids = [...new Set(String(req.query.userIds ?? '').split(','))];
      if (!ids.length || ids.length > 30 || ids.some(id => !/^[A-Za-z0-9_-]{1,128}$/.test(id))) {
        return res.status(400).json({error: 'Invalid user IDs.'});
      }
      const docs = await db.getAll(...ids.map(uid => engagementRef(db, uid)));
      const wallets = await db.getAll(...ids.map(uid => privateWalletRef(db.collection('users').doc(uid))));
      const profiles = await db.getAll(...ids.map(uid => db.collection('users').doc(uid)));
      const styles = await db.getAll(...ids.map(uid => memberBadgeRef(db, uid)));
      return res.json({ok: true, badges: Object.fromEntries(docs.map((doc, i) => {
        const data = doc.data() ?? {};
        const giftLevel = giftProgress(wallets[i].data()).level;
        return [ids[i], {giftLevel: Number.isSafeInteger(giftLevel) && giftLevel >= 0 ? giftLevel : null,
          vipBadge: visibleVipBadge(profiles[i].data(), styles[i].data()),
          creativeCycles: data.creativeCycles ?? 0,
          creativeAwardedAtMs: data.creativeAwardedAtMs ?? null,
          completedCycles: data.completedCycles ?? 0}];
      }))});
    } catch (error) { next(error); }
  });
  app.post('/engagement/claim', async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const ref = engagementRef(db, user.uid);
      const userRef = db.collection('users').doc(user.uid);
      const itemRef = db.collection('store_items').doc(`gift__${CYCLE_GIFT_ID}`);
      const inventoryRef = userRef.collection('inventory').doc(`gift__${CYCLE_GIFT_ID}`);
      const result = await db.runTransaction(async tx => {
        const [prior, item, inventory, profile] = await Promise.all(
          [ref, itemRef, inventoryRef, userRef].map(r => tx.get(r)));
        const now = clock(), state = prior.data() ?? {}, view = cycleView(state, now);
        // Echo server-issued cycle/day; a delayed retry cannot claim tomorrow.
        if (req.body?.startDay !== view.startDay || req.body?.day !== view.day) {
          throw Object.assign(new Error('Refresh the reward journey.'), {status: 409});
        }
        if (!view.canClaim) return {alreadyProcessed: true};
        if (!profile.exists || item.data()?.active !== true ||
            item.data()?.type !== 'gift' || item.data()?.priceCoins !== 1) {
          throw Object.assign(new Error('Reward gift is not available yet.'), {status: 503});
        }
        const previous = inventory.data() ?? {};
        const expired = previous.expiresAt?.toMillis?.() <= now;
        if (!expired && previous.expiresAt != null && (previous.freeGiftBalance ?? 0) > 0) {
          throw Object.assign(new Error('Timed inventory requires reconciliation.'), {status: 409});
        }
        const balance = expired ? 0 : previous.freeGiftBalance ?? 0;
        if (!Number.isSafeInteger(balance) || balance < 0 || !Number.isSafeInteger(balance + view.day)) {
          throw Object.assign(new Error('Inventory requires reconciliation.'), {status: 409});
        }
        let updated = {...state, ...cycleEvidence(state, now), startDay: view.startDay,
          claimedDays: view.day, lastClaimAtMs: now,
          ...(view.startDay !== state.startDay ? {lastPresenceMs: now} : {}),
          completedCycles: (state.completedCycles ?? 0) + (view.day === 3 ? 1 : 0)};
        updated = creativeAward(updated, now);
        tx.set(ref, updated);
        tx.set(inventoryRef, {type: 'gift', giftId: CYCLE_GIFT_ID,
          freeGiftBalance: balance + view.day, expiresAt: null,
          lastRewardSource: 'three_day_cycle', updatedAt: FieldValue.serverTimestamp()}, {merge: true});
        tx.create(userRef.collection('engagement_receipts').doc(`${view.startDay}_${view.day}`), {
          source: 'three_day_cycle', giftId: CYCLE_GIFT_ID, quantity: view.day,
          cycleStartDay: view.startDay, day: view.day, grantedAtMs: now});
        return {alreadyProcessed: false, quantity: view.day};
      });
      return res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });
}
