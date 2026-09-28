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
| quizRewardsEnabled | boolean | Enables ONLY sealed server-owned quiz coin awards | false until sandbox review |
| quizFirstPrizeCoins | positive integer | First-place prize for sealed quiz | 5 (requested) |
| quizDailyRewardCapCoins | positive integer | Per-user daily anti-abuse award ceiling | **TBD** |
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
