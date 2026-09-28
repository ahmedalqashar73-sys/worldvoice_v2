# WorldVoice economy: private wallet staging and cutover

**Status: DRAFT. Do not deploy as a complete privacy fix.** Production is
unchanged. The existing `users/{uid}` financial fields remain readable to
other signed-in accounts under the old rules until the cutover below is complete.

## Existing first-stage changes

- The trusted backend's verified IAP purchase credit, store purchase, room/chat
  gift settlement, wallet settle/exchange/withdrawal/admin review, and verified
  Stripe refund/linked-recipient freeze paths now target private wallets on
  this **isolated branch**. Existing accounts must be migrated before these
  code paths can operate; do not deploy them against the old production data.
  Fresh zero-balance accounts can bootstrap an owner-only wallet via the
  authenticated backend. Native/web purchase paths preflight this first.
- Emulator tests now check owner-only private wallet access and prohibit
  client wallet writes; these are CI assertions, not proof of live deployment.
- The allowlist in `backend/src/private_wallet_projection.js` extracts
  private monetary fields and creates sanitized `public_profiles/{uid}`
  projection data; arbitrary legacy user fields are NEVER copied into public
  profiles.
- `backend/scripts/migrate-private-wallets.mjs` is dry-run by default.
  With `--apply --backup-confirmed`, it creates only missing private wallet
  and public profile documents. Each user is re-read transactionally. It never
  overwrites a private balance, modifies `users/{uid}`, deletes any data, or
  mints new credit.
- `requireLiveEconomy()` rejects every economic transaction unless BOTH
  `economy_config/current.enabled` and
  `economy_config/current.walletPrivacyCutover` are explicitly true.
  The seed sets both false. Never manually set either flag early.
- Flutter's existing coin-store sheet has a **disabled-by-default** build
  switch `WORLDVOICE_PRIVATE_WALLETS_ENABLED`. The switch is for coordinated
  releases only and is not yet proof the remainder of the app is migrated.

## Staging preview (no writes)

1. Save and independently verify a full Firestore backup from the staging
   project. Never include the backup or admin credentials in git.
2. Use a staging-only service account with narrow access.
3. From `backend/`, run:

   ```bash
   node scripts/migrate-private-wallets.mjs --project YOUR_STAGING_PROJECT --limit 100
   ```

4. Audit the reported *field names*, not personal balances. Compare profiles
   with approved public visibility requirements. Resolve invalid legacy
   monetary fields before applying anything.
5. When approved and backed up, run the exact same command with
   `--apply --backup-confirmed` **on staging only**. Repeat with the full
   dataset only after reviewing the limited run.
6. Verify every copied private wallet against an independent snapshot of its
   original legacy ledger. Re-running will skip existing records; it will NOT
   overwrite wallets whose legacy balances have since changed.

## Required coordinated cutover — NOT implemented by the staging script

1. Audit/test the now-modified server credit/debit/refund/chargeback,
   hold/release, exchange, purchase, withdrawal and admin paths against the
   same private-wallet document using the Firebase emulator and real payment
   provider sandboxes; reconcile each immutable ledger and diamond lot.
   Review every additional payment notification and new onboarding path
   before treating backend migration as complete.
2. Replace **every** Flutter balance and other-person profile reader across
   Rooms, Chat, Live, gifts, notifications, profile, levels and rewards.
   Other-person displays may read ONLY sanitized
   `public_profiles/{uid}`; owners read their private wallet. Review
   `public_profiles` schema against the user's visibility settings.
3. Take a new snapshot while transaction routes are stopped. Compare every
   migrated wallet to legacy balances and ledgers; reconcile discrepancies
   before allowing new transactions. Do not attempt to merge two concurrently
   writable balances.
4. Remove financial and confidential fields from legacy `users/{uid}` **only
   after** audited data integrity and client/backend migration. Never delete
   ledger, holds or receipt records during this cleanup.
5. Deploy reviewed Firestore Security Rules so other users cannot read legacy
   private fields. Existing client updates must not re-introduce legacy money.
   Test old-client behavior and force upgrades as required.
6. Verify a real two-device authenticated test and transaction-failure matrix:
   purchase replay, price spoof, gifts to non-members, free-first gifts,
   refund-before-credit, partial refund, disputed transfers, recipient freezes,
   exchange/withdrawal idempotency, offline/error/reopen and admin segregation.
7. Obtain approved USD prices, currency/rate/fee parameters and registered
   Android/iOS/web product IDs; finish Play/Apple sandbox purchase and refund
   notifications, true live session membership, VIP subscriptions,
   payout-provider/KYC adapters, and compliance review.
8. Only after all checks pass can a controlled release set
   `walletPrivacyCutover=true`, enable the corresponding Flutter build flag,
   and activate approved catalogs. Enable `economy_config.enabled` separately
   after finance approval. Do not copy sample test fixture prices to Firestore.

**Rollback:** While the two economy gates remain false, retain original
`users/{uid}` and all ledger data and leave production untouched. After a
real cutover, NEVER restore old balances over newer private-wallet operations;
use a reconciliation and recovery plan that accounts for later transactions.
