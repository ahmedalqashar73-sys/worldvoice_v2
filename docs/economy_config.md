# WorldVoice economy configuration (draft; not published)

## Single source of economic policy

Firestore document: `economy_config/current`. Server-side code must reject monetary
transactions when required configuration is missing, inactive or invalid. Do
not put policy values in Flutter, Firestore Security Rules, or environment
variables. Firestore Rules enforce authorization; the trusted backend enforces
catalog prices, limits, conversion and inventory.

| Field | Type | Meaning | Approval |
|---|---|---|---|
| coinsPerUsd | number > 0 | Normal-priced coins per USD for gift valuation | **TBD** |
| receiverSharePercent | number, 0..100 | Percentage of gift's USD value allocated to receiver | **TBD** |
| diamondUsdValue | number > 0 | USD value of one redeemable diamond | **TBD** |
| withdrawalFeePercent | number, 0..100 | Cash withdrawal service fee | **TBD** |
| minWithdrawalDiamonds | positive integer | Minimum withdrawal request | **TBD** |
| holdDays | integer ≥ 0 | Time after gift before related diamonds unlock | **TBD** |
| giftLevelPointsPerCoin | number | Sender gift level points per paid coin | 1 (requested) |
| exchangeBonusPercent | number | Diamond-to-coin exchange bonus | 10 (requested) |
| webCardBonusPercent | number | Web card checkout coin bonus | 10 (requested) |
| minExchangeDiamonds | positive integer | Minimum diamond exchange | 100 (requested) |
| firstRechargeBonusPercent | number | First recharge promotion | **TBD** |
| purchaseDailyUsdLimit | number | Configurable anti-abuse purchase limit | **TBD** |
| giftingDailyCoinLimit | integer | Configurable anti-abuse gifting limit | **TBD** |
| payoutWindows | array | Two monthly payout processing windows | **TBD** |
| enabled | boolean | Explicit economy launch gate | false until financial approvals |

### Catalogs

`coin_products/{id}`: `priceUsd`, `coins`, `androidProductId`,
`iosProductId`, `webPriceId`, `active`. **Seven proposed pack sizes**
(10 / 50 / 100 / 500 / 1000 / 5000 / 10000 coins) have not had USD
prices, store product IDs or final approval supplied. Keep them **inactive**
until those values and store registrations are approved.

`store_items/{id}`: `type` (gift/background/frame/entrance/vip),
`priceCoins`, `requiredGiftLevel`, `durationDays` (null for permanent),
`animationUrl`, `active`. Migrate legacy catalog entries only after
backend endpoints and read-only Flutter consumers have switched to this
collection; never silently delete existing inventory or catalog.

`users/{uid}/inventory/{itemId}`: `expiresAt`, `freeGiftBalance`,
`quantity`, `source`, `updatedAt`. Admin-backend only.
`users/{uid}/wallet_transactions/{id}`: immutable type / amount /
balanceBefore / balanceAfter / source / createdAt; payment receipts and
chargebacks use externally-derived idempotency keys.

### Deployment gates

1. Populate and approve complete economy_config + all 7 store product IDs.
2. Preserve a snapshot/export of legacy inventory, gift and purchase data.
3. Test exact-once verified IAP + signed Stripe webhooks, refunds, chargebacks
   and app-store purchasing compliance on production-like staging.
4. Backfill inventory/ledger, switch backend and Flutter callers, then tighten
   Firestore Rules before releasing that app version.
5. Live/Chat gifts, cash withdrawals and payouts remain **disabled** until the
   corresponding backend moderation, identity verification and store-review
   integration is deployed. Cloudflare Agora Worker is only a token service;
   it is **not** the full economy backend.


### Private wallet / public profile rollout (not activated)

Legacy `users/{uid}` documents remain readable by all signed-in clients and
still hold balances. This is a **release blocker**, even if Firestore also
contains private wallet copies. Do not enable purchases/gifts/payouts until
the full profile-reader and ledger-writer migration below is completed.

A non-destructive **staging-only** tool and regression tests now exist:
- `backend/src/profile_projection.js` uses explicit public-profile and
  private-wallet field allowlists, never spreading arbitrary user fields.
- `backend/test/profile_projection.test.js` verifies balance redaction,
  separation, and invalid legacy balance rejection.
- `backend/scripts/stage-private-wallet.mjs` previews users by default,
  logs only field counts, validates legacy balances, and can atomically
  create missing `users/{uid}/private/wallet` and
  `public_profiles/{uid}` records. It never overwrites source balances
  or deletes a legacy document.

For a Firebase **emulator**, run after a separate data backup:
```bash
cd backend
npm test
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/stage-private-wallet.mjs --project demo-worldvoice
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/stage-private-wallet.mjs --project demo-worldvoice --apply --confirm-project demo-worldvoice
```
Outside the emulator, `--apply` is restricted to a named test/staging
project with matching confirmation and disabled
`economy_config/current.enabled`. **Do not point it at production.**

To finish this migration, in order:
1. Back up and verify legacy `users`, inventories, wallet ledgers and
   receipts; suspend legacy mobile-client financial writes.
2. Stage and audit copies for all accounts; reconcile balances with immutable
   transactions and existing receipts. Reject mismatches; do not reset them.
3. Change all *server* purchase, refund, gift, exchange, withdrawal,
   VIP-entitlement and wallet-hold operations to transact against
   `users/{uid}/private/wallet` exclusively. Remove legacy public writes,
   cover retries/idempotency and refund rollback in tests.
4. Change all *client* wallet/coin/diamond/profile consumers to read the
   private wallet for their own account and `public_profiles` for others.
   Handle older app versions explicitly rather than silently breaking them.
5. Only after staging two-device, Firestore-emulator and payment tests pass,
   remove legacy financial fields from public documents and restrict
   `users/{uid}` reads; verify unauthenticated and unrelated signed-in
   clients cannot retrieve another person's financial records.
6. Obtain approved USD prices/SKUs, actual platform sandbox receipts,
   signed store refund notification handlers, KYC and payout-provider
   integration; otherwise retain `enabled=false` and inactive products.

**This staging addition does not complete steps 1–6 or make live money safe.**
