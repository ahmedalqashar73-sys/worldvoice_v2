# WorldVoice secure economy: private wallet and verified quiz cutover

STATUS: **STAGING ONLY**. Do not merge into main, deploy production rules, change
catalog activation flags or start real-money flows without completing the gates.
Preserve the current working Agora green room and the installed users' data.

## Architecture
- Public `users/{uid}` contains social profile metadata, gift-level *display*
  stats and permitted public VIP badges. It must **never** contain coins,
  diamonds, debt, payout holds, KYC eligibility or financial status.
- Owner-only `users/{uid}/private_wallet/summary` stores financial balances and
  controls. Admin SDK alone writes it; the device may only read its own wallet.
- Immutable `users/{uid}/wallet_transactions/{operationId}`, private hold lots,
  verified receipt tombstones, signed webhooks and anti-replay operation IDs
  remain server-authoritative.
- `economy_global_controls/privacy_migration` is server-only. Set
  `schemaVersion: 2, completed: true, approved: true` only after all checks;
  this **independent approval** is required even when
  `economy_config/current.enabled = true`.
- `quizRewardsEnabled` defaults false. The secure quiz backend keeps correct
  answers and submitted proof under `rooms/{roomId}/quiz_private`, which no
  client can read. Verified answer proof determines first-three winners.
  Prize amounts are read from `economy_config/current.quizFirstPrizeCoins`
  and credited **only to the private wallet** with an immutable prize ledger.
  Offline/free practice quizzes are explicitly non-monetary.

## Non-negotiable production rollout sequence
1. Back up the **entire** original production Firestore database and keep a
   separately retrievable export with documented timestamp. Record the
   currently published rules, backend and Android/iOS releases. Run on an
   isolated staging Firebase project first.
2. Read/approve exact economic rates, first recharge bonus, USD prices and
   Google/Apple/Stripe IDs for all seven packs; review each payout method, KYC
   and refund/chargeback rules. Leave every catalog inactive for this stage.
3. Run `node backend/scripts/migrate-private-wallets.mjs
   --project STAGING_PROJECT` from a properly authenticated admin machine.
   Review counters and address **all** conflicts; the preview never deletes.
   After verifying backup, run with `--apply --backup-confirmed`. The
   per-user transaction creates the private wallet and deletes legacy root
   finance fields together; it **never** overwrites a conflicting wallet.
4. Verify that no user root contains private balance/status fields, that
   stored private balances match the backed-up source, that all public
   profiles remain queryable, and that no lost/orphaned ledgers or holds
   exist. Run the Firestore emulator permission suite. Test fresh profile
   sign-up, wallet reads, existing users and the mandatory old-client
   upgrade path.
5. Upgrade trusted Node routes, Cloudflare auxiliary routing, Android/iOS
   client and Firestore rules in a coordinated maintenance window. An old
   client expects monetary root fields and is **not compatible** with this
   migration. A users collection query will fail closed until every legacy
   profile has been scrubbed.
6. Test real two-device quiz membership, forged Firestore answer denial,
   retries/double-clicks and round changes. Require an explicit full
   backend connection before showing monetary rewards. Start with
   `quizRewardsEnabled:false` and disabled economy config.
7. Verify sandbox Google/Apple purchases, receipt replay, Stripe Checkout
   signed webhooks, partial/full refunds and disputes, held diamond release,
   withdrawal reserve/reject and independent payout-provider reconciliation.
   Exercise signed Apple/Google refund notifications and migration/old-client
   compatibility *before* real-world launch.
8. Only after a finance/security owner approves all reconciliations, have
   an admin set the server-only privacy migration approval document.
   Enable approved values and active SKUs in a separate reviewed release.
   For real-money quiz credits, set `quizRewardsEnabled:true`,
   `quizFirstPrizeCoins` to the approved prize, and `walletSchemaVersion:2`.
   Never set these merely to make a demo pass.
9. Keep real payouts, native VIP subscriptions and unverified live video
   paid gifting separately **disabled** until each provider's eligibility,
   security and end-to-end verification are completed.

## Operational safety notes
- Live signed Stripe reversal processing must remain available even if new
  purchases are disabled; refunds can arrive before or after credit.
- The Cloudflare Worker is a token service/proxy, not an economy database.
  `AUX_BACKEND_URL` must point to a separately deployed trusted HTTPS backend
  and must not contain credentials in URLs. Store secrets in platform-managed
  backend environment variables.
- Never run the migration script on production simply because it has a
  `--apply` option; an operator must confirm backups and a coordinated
  maintenance window. No script auto-enables payments.
