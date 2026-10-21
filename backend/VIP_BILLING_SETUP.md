# WorldVoice VIP Gold — store integration checklist

The Flutter storefront, native billing listener, Google subscriptions API v2
verification, and Apple signed transaction verification are in the development
branch. This feature is **disabled by default**. Do not enable paid checkout
before each item below is complete.

## Firestore draft setup
Run only with the correct Firebase Admin credentials:

```bash
cd backend
node scripts/seed-vip-subscriptions.mjs --project YOUR_PROJECT
node scripts/seed-vip-subscriptions.mjs --project YOUR_PROJECT --apply
node scripts/seed-vip-badges.mjs --project YOUR_PROJECT --apply
```

These scripts use create-only writes and never modify an existing record.
Both draft collections remain **inactive**.

Firestore:
- `vip_config/current`: `{enabled:false, storeIntegrationVerified:false}`
- `vip_products/vip_gold_monthly`:
  `{tier:"gold", androidProductId:"wv_vip_gold_monthly",
  iosProductId:"wv_vip_gold_monthly", active:false}`
- `store_items/badge__*`: proposed coin prices and durations, `active:false`.

Approved store SKUs are queried from Google Play / StoreKit; **prices are never
hard-coded in Flutter**. Native subscription SKUs must start with `wv_vip_`
to distinguish recurring memberships from consumable coin products.

## Google Play
1. Create a Play Console subscription with the exact app package name,
   `wv_vip_gold_monthly` product ID and active base plan.
2. Complete Play payments profile, subscription disclosures, tester/license
   configuration, and required policy declarations.
3. Grant the service account the minimum required Android Publisher API
   permissions; set `ANDROID_PACKAGE_NAME` and backend credentials.
4. Verify subscription purchase and restoration using Play license-testers.
5. Implement Google Real-time Developer Notifications and a server-side
   reconciliation job for renewals, holds, refunds, revocations, upgrades and
   expirations **before public launch**.

## App Store
1. Create an auto-renewable subscription in App Store Connect for the exact
   bundle ID and product ID. Complete subscription group, pricing, tax, and
   review metadata.
2. Store `APPLE_IAP_PRIVATE_KEY`, `APPLE_IAP_KEY_ID`,
   `APPLE_IAP_ISSUER_ID`, `IOS_BUNDLE_ID`, numeric `APPLE_APP_ID`
   as backend secrets.
3. Store official Apple root certificates as JSON array of base64 DER
   certificates in `APPLE_ROOT_CERTIFICATES_BASE64_JSON` (backend secret);
   the verifier validates Apple's signed transaction chain.
4. Test StoreKit sandbox and TestFlight restoration and automatic renewal.
5. Implement App Store Server Notifications V2 and reconcile subscription
   status/revocations **before public launch**.

## Activation (only after all verification checks pass)
- Set `vip_products/vip_gold_monthly.active=true` using trusted admin access.
- Set `vip_config/current.enabled=true` and
  `storeIntegrationVerified=true`.
- Set the backend secret `VIP_SUBSCRIPTIONS_ENABLED=true`.
- Test that verified purchases update `users/{uid}` and repeat/restore does
  not link the same receipt to a second account.
- Confirm a canceled-but-unexpired subscription stays active until expiry
  and an expired/revoked subscription does not grant benefits.

Do **not** enable the flags without working renewal and revocation handling.
`vip/iap/verify` handles the initial provider-verified transaction; server
notifications/reconciliation are a separate release blocker.

## Test
- `flutter analyze`
- `flutter test test/vip_entitlement_test.dart`
- `cd backend && npm test`
- Firestore emulator tests under `test/firestore`.
- Android device and iOS TestFlight sandbox end-to-end purchase tests.

The promised one-time 100-coin welcome credit, rewarded-ad verified unlocks,
and full membership lifecycle reconciliation are separate planned features;
they have **not** been activated by this change.
