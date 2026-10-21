/**
 * Draft VIP Gold subscription records, always disabled by default.
 * No billing is activated by this script and existing records are untouched.
 *
 * Preview: node scripts/seed-vip-subscriptions.mjs --project YOUR_PROJECT
 * Create drafts: node scripts/seed-vip-subscriptions.mjs --project YOUR_PROJECT --apply
 *
 * Activation requires all of: approved Google/Apple subscription SKUs,
 * provider credentials, verified server configuration, privacy/tax/policy
 * compliance, and VIP_SUBSCRIPTIONS_ENABLED=true on the trusted backend.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

export const vipGoldDraft = Object.freeze({
  tier: "gold",
  name: "WorldVoice VIP Gold - Monthly",
  androidProductId: "wv_vip_gold_monthly",
  iosProductId: "wv_vip_gold_monthly",
  active: false,
});

export const disabledVipRollout = Object.freeze({
  enabled: false,
  storeIntegrationVerified: false,
});

async function main() {
  const args = process.argv.slice(2);
  const i = args.indexOf("--project");
  const projectId = i < 0 ? "" : args[i + 1] || "";
  if (!/^[a-z][a-z0-9-]+$/.test(projectId)) {
    throw new Error("Supply a valid --project Firebase project ID.");
  }
  if (!args.includes("--apply")) {
    console.log(JSON.stringify({
      dryRun: true, projectId, vipConfig: disabledVipRollout,
      product: vipGoldDraft,
    }, null, 2));
    return;
  }
  initializeApp({credential: applicationDefault(), projectId});
  const db = getFirestore();
  for (const [path, data] of [
    ["vip_config/current", disabledVipRollout],
    ["vip_products/vip_gold_monthly", vipGoldDraft],
  ]) {
    try {
      await db.doc(path).create(data);
      console.log("Draft created: " + path);
    } catch (error) {
      if (error.code === 6 || String(error.message).includes("ALREADY_EXISTS")) {
        console.log("Existing record preserved: " + path);
      } else {
        throw error;
      }
    }
  }
}

if (process.argv[1]?.endsWith("seed-vip-subscriptions.mjs")) {
  main().catch(error => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
