# WorldVoice scalable progression foundation

Status: design only; no production database migration or deployed behavior changes.

## Safety constraints
- Keep main and production Firebase/Render untouched until code review and staging tests pass.
- Preserve Firebase Auth identities and existing profiles.
- No client-authoritative wallet, XP, VIP, or gift rewards.
- Do not create parallel implementations of existing task/economy services.

## Initial architecture
- Flutter/Agora for client UI and voice; server validates tasks and rewards.
- Firestore for profiles, progress snapshots and low-frequency room metadata.
- Backend API for idempotent XP grants, level-up events and entitlement checks.
- One authoritative wallet ledger with idempotency keys and atomic debit/credit; do not activate real-coin World Bags before ledger audit.
- Room event delivery separate from persistent records; snapshot on join and resync on reconnect.
- Avoid per-second writes to one room document; use validated task completions and aggregation.
- VIP entitlements have explicit source, start, expiry and revocation semantics.
- Asset references rather than embedding media in real-time messages.

## Proposed logical entities (map to existing collections/services first)
- user_progress(user_id, total_xp, level, season_xp, version)
- room_progress(room_id, total_xp, castle_level, season_xp, version)
- task_definitions(task_id, revision, eligibility, limits, xp)
- task_completions(idempotency_key, task_id, user_id, room_id, period, granted_at)
- reward_catalog(reward_id, asset_id, unlock_rules)
- user_entitlements(user_id, reward_id, source, expires_at)
- room_events(room_id, sequence, event_id, type, payload, created_at)
- world_bags(bag_id, room_id, sender_id, status, funded_amount, expires_at)
- world_bag_claims(bag_id, user_id, allocated_amount)

## Before implementation
1. Inventory actual Firestore rules, indexes, collections, Flutter listeners and backend routes.
2. Review current wallet authority and existing quiz/tasks/level systems.
3. Define event and API contracts without breaking older APKs.
4. Implement on staging with feature flags disabled by default.
5. Test duplicate requests, disconnects, room contention, account relogin and rollback.
6. Run flutter analyze and integration/load tests; document files changed.
7. Merge only after explicit validation; deploy separately from merge.

## Performance targets to test, not guarantees
- No double grants or negative balances.
- Bounded active listeners per room; unsubscribe on exit.
- No high-frequency contention on one Firestore document.
- Smooth audio while effects animate on representative Android devices.
