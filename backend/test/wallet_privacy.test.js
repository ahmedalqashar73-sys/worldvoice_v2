import test from "node:test";
import assert from "node:assert/strict";
import {sanitizedPublicProfile, extractPrivateWallet, auditPrivacySnapshot} from "../src/wallet_privacy.js";

test("public profile projection cannot expose emails, full DOB, city or money", () => {
  const source = {
    uid: "owner", displayName: "Name", username: "handle",
    country: "SA", city: "Private city", birthDate: "1990-01-01",
    email: "private@example.com", coins: 1000, diamondsPending: 25,
    walletDebtCoins: 4, identityVerified: true,
  };
  assert.deepEqual(sanitizedPublicProfile("owner", source), {
    uid: "owner", displayName: "Name", username: "handle", country: "SA",
  });
  assert.deepEqual(extractPrivateWallet(source), {
    coins: 1000, diamondsPending: 25, walletDebtCoins: 4,
    identityVerified: true,
  });
});

test("broken legacy money stops the migration rather than resetting it", () => {
  assert.throws(() => extractPrivateWallet({coins: -2}), /Invalid legacy/);
  assert.throws(() => extractPrivateWallet({diamonds: 4.5}), /Invalid legacy/);
  assert.throws(() => extractPrivateWallet({walletDebtCoins: -1}), /Invalid legacy/);
});

test("new accounts may start with an empty private wallet", () => {
  assert.deepEqual(extractPrivateWallet({displayName: "New"}), {});
});

test("privacy audit accepts a reconciled wallet and allowlisted projection", () => {
  const legacy = {
    displayName: "Owner", country: "SA", city: "private", coins: 150,
    diamonds: 7, walletFrozen: false,
  };
  assert.deepEqual(auditPrivacySnapshot("u1", legacy,
    {coins: 150, diamonds: 7, walletFrozen: false},
    {uid: "u1", displayName: "Owner", country: "SA",
      migrationVersion: 1, snapshotAt: "audit fixture"}), []);
});

test("privacy audit blocks missing and diverged balances without leaking amounts", () => {
  const legacy = {displayName: "Owner", coins: 150, diamonds: 7};
  const safe = {uid: "u1", displayName: "Owner"};
  assert.deepEqual(
    auditPrivacySnapshot("u1", legacy, null, null).sort(),
    ["missing_private_wallet", "missing_public_profile"],
  );
  assert.deepEqual(
    auditPrivacySnapshot("u1", legacy, {coins: 100, diamonds: 7}, safe),
    ["wallet_mismatch"],
  );
  assert.deepEqual(
    auditPrivacySnapshot("u1", legacy, {coins: 150, diamonds: 7}, {
      ...safe, coins: 150,
    }),
    ["unsafe_public_profile_field"],
  );
  assert.deepEqual(
    auditPrivacySnapshot("u1", legacy, {coins: 150, diamonds: 7}, {
      uid: "u1", displayName: "Stale name",
    }),
    ["public_profile_mismatch"],
  );
  assert.deepEqual(
    auditPrivacySnapshot("u1", {...legacy, coins: -1},
      {coins: 0, diamonds: 7}, safe),
    ["invalid_legacy_wallet"],
  );
});
