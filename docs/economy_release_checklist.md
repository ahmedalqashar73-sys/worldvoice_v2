# WorldVoice economy: staging and release gate

## Implemented on this branch

- Central `economy_config/current` policy validator (all rates, caps, bonuses,
  payout days and withdrawal methods must be explicitly approved).
- Draft, non-destructive migration for 7 inactive `coin_products`,
  `store_items` and existing background entitlements.
- Verified Google Play / Apple IAP and web-only Stripe Checkout server paths.
  One receipt is credited at most once; full and cumulative partial Stripe
  refunds / disputes reduce verified credit and freeze sender wallets. Linked
  gift recipients are payout-frozen conservatively, with a global freeze on
  oversized histories requiring finance intervention.
- Single catalog-backed room gift panel and verified paid chat gifts after
  BOTH users accept the conversation. Host's existing `_RoomGiftOverlay`
  remains the one room animation. Chat renders actual gift event messages.
- Frames, entrances, backgrounds and fixed-duration gifted VIP use the
  existing shop service and server-owned inventory.
- Pending diamond lots with policy hold; on-demand maturity settlement,
  diamond-to-coin conversion and ledger entries. Minimum-based withdrawal
  quotes, account-token-only withdrawal requests and custom-claim protected
  review. APPROVAL is NOT a payment or transfer.
- Read-only live gift-event overlay only for server-verified broadcasts;
  spending in live remains disabled without a verified live-media session.
- Firestore rules reject forged initial money, inventory, wallet history,
  receipt records, pending diamond lots and admin finance flags.

## IMPORTANT: still blocked, NOT production complete

1. `users/{uid}` is currently readable by any signed-in account, yet legacy
   balances live in that document. Before enabling paid transactions, migrate
   financial values into an owner-only `users/{uid}/wallet/summary` document;
   update all existing app/backend readers; remove legacy private values
   from publicly-readable user documents; enforce public sanitized profiles
   via a separate collection and re-test profile, Discover, rooms and chat.
   **Do not enable the real-money economy until this privacy migration is done.**
2. Seven package USD prices and platform-specific product IDs have NOT been
   approved or registered. Seed leaves them inactive. Do not invent prices.
3. Real Google Play / Apple receipts need platform seller credentials and
   actual product registration + Sandbox / license-tester end-to-end tests.
   Mobile VIP self-subscriptions still need dedicated verified subscription
   fulfillment rather than the coin-product purchase route.
4. Web Stripe requires WEBSITE checkout policy, signed webhook secret,
   approved products, verified refund tests and payment account onboarding.
   Do not add a general Stripe button to App Store / Google Play builds.
5. Provider-verified Apple/Google refund notifications, exact per-receipt
   diamond-funding provenance, privacy migration and comprehensive accounting
   reconciliation remain launch blockers.
6. Live gifting is not enabled until real Agora video/live media membership is
   cryptographically or server-verified end-to-end. Do not fabricate an active
   live audience or silently charge users. Chat gifts require both acceptances.
7. PayPal, Payoneer, bank and local-wallet transfers need real approved payout
   provider adapters, KYC verification, fraud/dispute review and legal review.
   Reviewing a withdrawal does not send funds.
8. Do not deploy branch Firestore rules over production without backing up
   current rules and verifying all current old-app clients and migrations.

## Safe inspection on laptop (no paid transfers)

```powershell
cd C:\Users\AHMED\worldvoice_v2
git fetch origin
git worktree add -b dev/economy-review "$HOME\worldvoice_economy_review" origin/feat/economy-foundation-20260928
cd "$HOME\worldvoice_economy_review"
flutter pub get
flutter analyze
```

Backend static/unit tests:
```powershell
cd "$HOME\worldvoice_economy_review\backend"
npm install
npm test
node --check src/server.js
```

Dry-run migration (never run --apply on production before reviewing):
```powershell
node scripts/seed-economy.mjs --project worldvoice-37896
```

Debug build can still use the free `WORLDVOICE_ROOM_BACKEND_URL` Agora
Cloudflare Worker for voice, but **never** set
`WORLDVOICE_ECONOMY_ENDPOINT` to that token-only Worker. Economy endpoints
require their own properly secured HTTPS Node backend with Firebase Admin
credentials and configured verification providers. Missing URL => all paid
buttons fail closed by design.

When the owner's complete approved economy rates + store product IDs arrive,
run the staging tests and separate privacy migration BEFORE toggling
`economy_config/current.enabled` true. Real checkout, payouts and gift
economics cannot be fully tested with unset financial/provider credentials.
