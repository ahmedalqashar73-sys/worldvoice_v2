import test from "node:test";
import assert from "node:assert/strict";
import {sanitizedPublicProfile, extractPrivateWallet} from "../src/wallet_privacy.js";

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
