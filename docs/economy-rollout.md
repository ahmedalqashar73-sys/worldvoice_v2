# WorldVoice: unified economy rollout (NOT live yet)

This branch adds safe backend primitives while keeping the existing green
room/Agora release unchanged. Cloudflare's Agora token-only Worker does NOT
host /gift/send, Stripe, or /wallet endpoints. Deploy a separate authenticated
Node backend after review; never aim economy writes at the token Worker.

## Firestore layout
- economy_config/global: authoritative rates, bonuses, daily limits and two
  allowed payout window days; server refuses missing config or enabled=false.
- coin_products/{id}: all seven sale packages (priceUsd, coins, platform IDs,
  Stripe webPriceId, active). Actual mobile billing amounts come from store APIs.
- store_items/{id}: gift/background/frame/entrance/vip catalog; prices must be
  integers in Coins; giftLevel and animationUrl are catalog data, not client input.
- users/{uid}/inventory/{itemId}: owned item and expiresAt or freeGiftBalance.
- users/{uid}/diamond_lots/{eventId}: hold release time and unspent balance.
- wallet_transactions/{eventId}: server-only, user-visible immutable ledger.
- economy_actions/{hash}: backend idempotency for every payment/spend.
- withdraw_requests/{id}: identity-verified reservations for human review.

## Populate the seven packages
Edit a PRIVATE copy of config/economy.template.json. Unknown economic amounts
are intentionally null: these MUST be supplied by the owner, not guessed.
Do not put Google/Apple/Stripe secrets in JSON or Flutter. From the repository
root, set Firebase Admin credentials and FIREBASE_PROJECT_ID, then:

node scripts/seed_economy.mjs --input economy.private.json
node scripts/seed_economy.mjs --input economy.private.json --apply --migrate-legacy

The migration is non-destructive and keeps migrated products INACTIVE. Check
gift types/IDs, animation URLs, and duplicate catalog IDs before activation.
Keep old legacy documents for rollback while all clients migrate.

## Safety and payment go-live gates
1. Finalize seven prices and package IDs in Google/Apple/Stripe dashboards.
2. Verify server-side Google/Apple purchases and receipt-id uniqueness with
   sandbox test accounts, including refund/voided purchase notifications.
3. Configure and verify a Stripe test webhook using raw request bytes and a
   Stripe signing secret; test duplicate deliveries and asynchronous completion.
4. Enroll in any necessary country/store program before showing external card
   checkout links *inside a published app*. Otherwise web Checkout may be
   offered only on a distinct web site; native apps retain their store payment.
5. Select a KYC provider and approved payout providers; do not release payout
   money automatically from the withdraw_requests queue.
6. Review legacy reward flows and run emulator permission tests. Deploy the
   reviewed rules and backend together; old gift clients must upgrade.
7. Set economy_config/global.enabled=true only AFTER every gate passes.

Never place this economy behind the old local 127.0.0.1:8080 endpoint.
