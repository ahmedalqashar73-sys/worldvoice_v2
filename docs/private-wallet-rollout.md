# WorldVoice private-wallet privacy rollout (NOT DEPLOYED)

## Critical legacy finding
Legacy `users/{uid}` documents still contain `coins`, `diamonds`,
held balances, financial flags and other sensitive values, while legacy
Firestore rules allow any authenticated member to read those documents.
A wallet subcollection alone **does not solve this leak** until all callers
have migrated and the old fields have been scrubbed.

## Work staged in this branch
- `backend/src/profile_privacy.js`: narrow public-profile/private-wallet
  allowlists; no email, birth date, KYC, or balance in public projections;
  `city` is copied only for an explicit `hideCity === false` opt-in.
- `backend/scripts/prepare-wallet-privacy.mjs`: non-mutating default dry run;
  applying is explicitly staging-only and requires verified backup flags.
  Copies legacy balances to `users/{uid}/wallet/private`, creates sanitized
  `public_profiles/{uid}` only if absent, and refuses to overwrite
  conflicting existing private wallets. Does not remove any legacy data.
- Additive Firestore rules make new wallets owner-readable and deny all client
  writes. A read-only public profile collection is reserved for a later
  verified backend-backed synchronization path. Firestore emulator coverage
  enforces both boundaries.
- `economy_config/current.walletPrivacyCutoverComplete` defaults to
  `false`. All endpoints calling `requireLiveEconomy` fail closed even
  if someone incorrectly sets `enabled=true` before security cutover.
  Do not set the cutover flag merely because a snapshot script ran.

## Stage safely
1. Export Firestore using an admin-authorized backup and retain transaction
   ledgers plus prior mobile-version compatibility information.
2. Use **a dedicated staging Firebase project** and separate non-production
   billing test accounts; confirm no live user traffic.
3. From `backend/` with authorized Google ADC, dry-run:
   `node scripts/prepare-wallet-privacy.mjs --project YOUR_STAGING_PROJECT`.
4. Inspect counts and reconcile any unexpected balances/duplicate wallets.
5. Only after a verified staging backup, explicitly request:
   `node scripts/prepare-wallet-privacy.mjs --project YOUR_STAGING_PROJECT --apply --backup-confirmed --staging-confirmed`.
6. Read and test the new owner-only `wallet/private` docs, sanitized
   `public_profiles`, and existing transaction ledgers.
7. **Before production cutover**, update every wallet backend transaction,
   refund/chargeback handler, quiz reward and admin payout route to read/write
   only owner-private wallet docs; give each transaction canonical ledger
   idempotency. Update all Flutter wallet readers and public profile lookups.
   Add server-verified public-profile synchronization for registration, edit,
   followers and online presence. Preserve old clients or enforce a version
   upgrade during transition.
8. Run two-device profile/privacy tests, emulator rule denial tests and
   store/provider sandbox tests. Then schedule a controlled migration that
   stops financial writes, reconciles private copies against verified ledgers,
   removes sensitive legacy user fields, and atomically coordinates stricter
   owner-only `users/{uid}` rules with the app/backend release.
9. Only after this complete process and approved rates, SKU IDs, payout/KYC
   compliance and provider callbacks may the owner separately approve
   `walletPrivacyCutoverComplete=true` and enable financial operations.

## Deployment prohibition
Do **not** deploy this draft's new Firestore rules or financial backend
in isolation, mark wallets migrated after copying, or enable real money
transactions. Source code tests do not prove deployed provider/ledger safety.
