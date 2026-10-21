/**
 * WorldVoice VIP badge catalog draft. Never executes without --apply.
 *
 * Usage:
 *   node scripts/seed-vip-badges.mjs --project YOUR_PROJECT
 *   node scripts/seed-vip-badges.mjs --project YOUR_PROJECT --apply
 *
 * Catalog prices below are test proposals only, not final pricing approval.
 * --apply creates MISSING records as INACTIVE; it never overwrites records
 * and never makes a cosmetic item purchasable in production.
 *
 * An operator must explicitly approve coins/prices/durations and activate
 * each product in the protected Firestore store_items collection.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

export const badgeDrafts = Object.freeze([
  {id: "badge__moon_cat", name: "Moon Cat", nameAr: "القطة القمرية", priceCoins: 150, durationDays: 7},
  {id: "badge__jade_heart", name: "Jade Heart", nameAr: "قلب الزمرد", priceCoins: 150, durationDays: 7},
  {id: "badge__golden_puppy", name: "Golden Puppy", nameAr: "الجرو الذهبي", priceCoins: 150, durationDays: 7},
  {id: "badge__sakura", name: "Sakura Bloom", nameAr: "زهرة الساكورا", priceCoins: 150, durationDays: 7},
  {id: "badge__mint_bear", name: "Mint Bear", nameAr: "الدب النعناعي", priceCoins: 350, durationDays: 15},
  {id: "badge__royal_crown", name: "Royal Crown", nameAr: "التاج الملكي", priceCoins: 350, durationDays: 15},
]);

async function main() {
  const args = process.argv.slice(2);
  const projectIndex = args.indexOf("--project");
  const projectId = projectIndex >= 0 ? args[projectIndex + 1] : "";
  if (!/^[a-z][a-z0-9-]+$/.test(projectId || "")) {
    throw new Error("Supply a valid --project Firebase project ID.");
  }
  if (!args.includes("--apply")) {
    console.log(JSON.stringify({
      dryRun: true, active: false, projectId, proposed: badgeDrafts,
    }, null, 2));
    return;
  }
  initializeApp({credential: applicationDefault(), projectId});
  const db = getFirestore();
  for (const item of badgeDrafts) {
    const doc = db.doc("store_items/" + item.id);
    try {
      await doc.create({
        type: "badge",
        name: item.name,
        nameAr: item.nameAr,
        priceCoins: item.priceCoins,
        durationDays: item.durationDays,
        requiredGiftLevel: 0,
        premiumOnly: true,
        active: false,
      });
      console.log("Draft created: " + item.id);
    } catch (error) {
      if (error.code === 6 || String(error.message).includes("ALREADY_EXISTS")) {
        console.log("Existing item preserved: " + item.id);
      } else {
        throw error;
      }
    }
  }
}

if (process.argv[1]?.endsWith("seed-vip-badges.mjs")) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
