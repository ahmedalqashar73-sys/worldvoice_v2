# WorldVoice code audit — 2026-10-14

Scope: repository inspection only. No production Firebase, Render or main changes.

## Confirmed existing components
- `backend/src/room_task_policy.js`: room level 1..60, 100 XP/level, task keys `ten_minutes`, `host_five`, `three_gifts`, `stay_hours`.
- `backend/src/server.js`: imports room task policy and private wallet helpers.
- `backend/src/wallet_store.js`: private wallet under `users/{uid}/private/wallet`, explicitly fails closed if migration has not run.
- `backend/src/wallet_routes.js`: Firestore transactions and idempotency for wallet exchange, hold releases and ledger entries.
- `firestore.rules`: client-side economy field protections; rules must be reviewed in full before modification.

## Design decisions to preserve compatibility
1. The owner approved reducing room levels to 50. The existing XP field is never reduced in old rooms; the API and UI display a maximum of 50, while historical XP is retained until a separate reviewed migration. Every five levels correspond to one of ten castle tiers.
2. Reuse existing room task keys and room progression endpoint; add personal XP as a separate, server-authoritative track.
3. Do not treat gifting as equivalent to language-learning XP. Separate learning XP and support/gift recognition.
4. Keep the private wallet as the only authoritative balance location. No parallel wallet ledger or PostgreSQL migration yet.
5. Add world bags only after checking wallet migration status and verifying atomic escrow + idempotent claims.
6. Keep new feature flags disabled by default; older Android builds must continue to work.
7. Profile, room, wallet and entitlement reads should have bounded listeners and query limits; benchmark before optimization.
8. Keep Agora audio off the critical path of progress and visual animation.

## Risk and test checklist
- Existing private wallet migration incomplete -> money operations fail closed; verify migration counts without exposing private balances.
- Concurrent claims -> unique bag/user claim IDs and one-time settlement.
- Concurrent XP -> task completion idempotency and transactional aggregate update.
- Client disconnect -> snapshot refresh, avoid replaying paid rewards.
- Re-login -> Firebase UID identity and existing profile restored.
- Firestore hotspots -> avoid rapid updates to a single room document.
- Economy correctness -> assert sum of debits and credits matches funded amount.
- Security -> full review of Firestore rules and deployed rules parity.
- CI -> run backend tests, lint and flutter analyze on actual source before release.

## Next implementation pass
- Inventory backend room-task routes and Flutter room-task UI/service calls.
- Review all wallet migration scripts and their dry-run behavior.
- Write tests for room XP cap, idempotency and wallet fail-closed behavior.
- Only then add additive progression APIs on the isolated branch.

This document is an audit note, not a claim of completed implementation or production validation.

## Implementation update (feature branch only)
- `room_task_policy.js` caps new room task XP at level 50 and maps level spans to ten castle tiers.
- `server.js` reports maxLevel=50, limits participant reads needed for the 5-guest task, prevents claiming XP once capped, and keeps Teacher-AI-gift room level in sync with XP.
- Existing Flutter tasks sheet and room header display corresponding illustrated castle asset (SVG) and levels 1..50.
- `assets/castles/castle_tier_01.svg` .. `castle_tier_10.svg` are lightweight vector illustrations. **These are not rigged 3D GLB models or animations**; final premium 3D assets may replace them later under the same tier contract.
- Tests cover castle tier boundaries, legacy room XP, Teacher-AI-gift XP capping, and asset loading/rendering.
- No production deployment, Firebase migration, or spending of coins was performed by these source edits.
