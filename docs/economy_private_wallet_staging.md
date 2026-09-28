# WorldVoice staged economy: private wallets and release controls

**Status: STAGING ONLY; NOT DEPLOYED.** This branch is based on
`fix/finish-room-hub-quiz-gift-20260928`. The existing deployed free Agora
voice room and existing Firebase project are deliberately unchanged.

## Current implementation
- Private `users/{uid}` profile (including email/exact DOB) is readable only
  by its owner; `public_profiles/{uid}` is an explicit non-financial
  allowlist, containing approximate age, public biography and optional city.
- Backend balances and VIP expiry live in server-controlled, owner-readable
  `wallets/{uid}`, with `schemaVersion: 1`. Backend rejects any wallet
  that has not been explicitly initialized or migrated.
- **Do not move/delete** the established
  `users/{uid}/wallet_transactions`, `inventory`, `diamond_lots`,
  `economy_daily`, `room_rewards` collections: their paths and operation
  identifiers are preserved. No client write is allowed to balances or
  immutable transaction collections.
- Staged flows: server-verified Google/Apple consumable purchases, Stripe
  web-only signed checkout/refunds, owner-gated catalogs and gifts, diamond
  holding lots, exchange, quotes, withdrawal requests and admin review.
  Withdrawal approval alone is not a bank or payout provider transfer.
- Secure server-owned quiz answer key in `room_quiz_secrets`; one member vote
  per sealed round. Legacy/public-key quizzes are strictly non-monetary
  practice. Both `quizRewardsEnabled` and approved daily cap must be set for
  actual payouts; leave disabled until audited.

## Before applying any migration to a production account
1. Get an independently verified Firestore export AND save the currently
   deployed Firestore rules and hosted backend/Worker configuration.
2. Confirm the installed old app clients are retired or compatible with
   owner-only `users` reads and private `wallets`, including the
   unauthenticated public profile, own store and VIP access experiences.
   Apply compatible client changes as one managed release; otherwise leave
   production unchanged. Never publish restrictive rules ahead of that work.
3. On a **separate staging Firebase project**, stop backend writes and keep
   `economy_config/current.enabled=false`; back up that project too.
4. From `backend`, use authenticated staging service credentials and:
   `node scripts/seed-economy.mjs --project STAGING_PROJECT`
   then `node scripts/migrate-private-wallets.mjs --project STAGING_PROJECT`.
   Dry run makes **no writes**.
5. Inspect dry-run output, reconcile every historical dual-balance alias and
   conflicting already-migrated wallet manually before ANY apply.
6. ONLY after independent backup verification and explicit operator approval:
   set `ECONOMY_MIGRATION_APPROVED=YES`,
   `ECONOMY_WRITES_PAUSED=YES`, and execute
   `node scripts/migrate-private-wallets.mjs --project STAGING_PROJECT --backup-verified --apply`.
   The script refuses to run if the economy is active. It creates sanitized
   public profiles and private wallets and deletes legacy monetary fields
   atomically for each user. Do not manually delete inventory or ledgers.
7. Run Flutter analyzer/tests, backend unit tests and the Firestore emulator
   regression suite; separately audit every existing user's migrated
   balance vs the export, including pending/held/reserved diamonds, receipt
   credits, negative debt and linked refund freezes.
8. Rehearse duplicate/out-of-order purchase callbacks, refunds, chargebacks,
   expired inventory, repeated gifts and concurrent wallet spending against
   a test merchant and staging database. Test sign-in/onboarding, public
   profiles, room entry, gift animations and repeated Agora reconnect with
   two physical phones.
9. Do not deploy or launch monetization until the documented outstanding
   gates below are signed off. Do not interpret a green CI check as live
   merchant, app-store or end-to-end settlement verification.

## Configuration decisions required from the project owner
- Exact USD prices and unique **real** Android / iOS / web product IDs for
  all seven intended coin packages; until then `coin_products.active=false`.
- Approved `coinsPerUsd`, `receiverSharePercent`,
  `diamondUsdValue`, `withdrawalFeePercent`,
  `minWithdrawalDiamonds`, `holdDays`, daily gift/purchase limits,
  first-recharge bonus, two payout windows and actual supported methods.
  These are owned by `economy_config/current`, NOT Dart or Firestore rules.
- Approved quiz daily anti-abuse cap and test evidence before enabling
  `quizRewardsEnabled`. A requested first-place value of five coins is
  seeded as a proposal only.
- Actual merchant account setup, seller certificates/keys, sandbox users and
  legitimate business policy. Do not put seller credentials in Git or chat.

## Still blocked; not production-ready
- Cryptographically verified Apple/Google store **refund notification**
  handlers and end-to-end receipt reconciliation; native personal VIP
  recurring subscription and expiration handling.
- Exact per-receipt coin-to-gift-to-diamond funding provenance for partial
  chargeback/fraud reconciliation. Current Stripe reversal freezes the payer
  and conservatively linked recipients; oversized or unmigrated lists cause a
  global hold for manual finance review.
- Real KYC, PayPal/Payoneer/bank/local payout provider execution, sanctions and
  geographic eligibility review, withdrawal reversal/chargeback operations
  and independent settlement reconciliation. No automated transfers now.
- Server-verified Agora live video session membership/ACLs, live-media E2E
  testing, and explicit production release authorization.
- Reconcile divergent draft economy branch PR #13 with the chat/room follow-up
  branches and resolve any conflicting finance/rules changes; never merge
  unrelated branches blindly.

**Production defaults until every gate passes:** all seven coin packs
inactive, economy disabled, quiz monetary rewards disabled, withdrawals
unavailable, no production rule deployment.
