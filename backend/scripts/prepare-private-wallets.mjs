/**
 * Legacy command retained as a safe compatibility alias.
 * One migration implementation lives in stage-private-wallet.mjs.
 *
 * Preview:
 *   node scripts/prepare-private-wallets.mjs --project demo-worldvoice
 *
 * Apply ONLY after a verified backup and on an emulator/test project:
 *   node scripts/prepare-private-wallets.mjs --project demo-worldvoice \
 *     --apply --backup-confirmed --confirm-project demo-worldvoice
 *
 * A production --apply is deliberately unsupported.
 */
if (process.argv.includes("--apply") &&
    !process.argv.includes("--backup-confirmed")) {
  throw new Error("First verify a Firestore backup; pass --backup-confirmed.");
}
await import("./stage-private-wallet.mjs");
