import test from "node:test";
import assert from "node:assert/strict";
import {googleVipPeriod, appleVipPeriod} from "../src/vip_subscription_policy.js";

const now = Date.parse("2026-10-21T00:00:00Z");
test("Google subscription only grants a valid active period for expected SKU", () => {
  const base = {
    subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
    latestOrderId: "GPA.1234",
    lineItems: [{productId: "wv_vip_gold_monthly", expiryTime: "2026-11-21T00:00:00Z"}],
  };
  assert.equal(googleVipPeriod(base, "wv_vip_gold_monthly", now).receiptId, "GPA.1234");
  assert.equal(googleVipPeriod(base, "wrong-sku", now), null);
  assert.equal(googleVipPeriod({...base, subscriptionState: "SUBSCRIPTION_STATE_ON_HOLD"},
    "wv_vip_gold_monthly", now), null);
  assert.equal(googleVipPeriod({...base,
    lineItems: [{productId:"wv_vip_gold_monthly", expiryTime:"2026-10-20T00:00:00Z"}]},
    "wv_vip_gold_monthly", now), null);
  assert.equal(googleVipPeriod({...base, subscriptionState:"SUBSCRIPTION_STATE_CANCELED"},
    "wv_vip_gold_monthly", now)?.expiry > now, true);
});
test("Apple verification requires matching bundle SKU non-revoked future expiry", () => {
  const base = {productId:"wv_vip_gold_monthly",bundleId:"com.worldvoice.worldvoice",
    originalTransactionId:"T1234",expiresDate:Date.parse("2026-11-21T00:00:00Z")};
  assert.equal(appleVipPeriod(base,base.productId,base.bundleId,now).receiptId, "T1234");
  assert.equal(appleVipPeriod({...base,revocationDate:now},base.productId,base.bundleId,now),null);
  assert.equal(appleVipPeriod(base,"unapproved",base.bundleId,now),null);
  assert.equal(appleVipPeriod({...base,expiresDate:now},base.productId,base.bundleId,now),null);
  assert.equal(appleVipPeriod(base,base.productId,"wrong.bundle",now),null);
});
