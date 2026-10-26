# WorldVoice room feature separation and room missions (staging)

The original room, seats, moderation, gift animations and real Agora audio
are retained. Do not create another gift system, background catalog or
translation service.

## Four independent tool groups

**Gifts**: a single `UnifiedGiftPanel` with four exclusive active-catalog
coin-price filters: 1–50, 51–150, 151–500 and luxury above 500.
These are browsing ranges, not actual coin exchange rates. The original
trusted gift API performs payment settlement; inactive products cannot send.
Backgrounds, frames and member VIP items never appear as gifts.

**Room look**: the existing `RoomBackgroundShopSheet` holds backgrounds and
frames. Hosts can choose Emerald, Green & Gold, Sky Blue or legacy Midnight
through `RoomFeatureService.setTheme`. Writing/color opens the EXISTING
board text and pen color controls; it does not create a second editor.
The separate VIP/entrance inventory is untouched but not mixed into this
background-and-frame view.

**Language**: the existing `RoomCaptionsSheet` presents three independent
controls: real-time subtitles via on-device speech recognition, on-device
ML Kit subtitle translation and optional Teacher AI transcript-based
pronunciation/grammar guidance with notes. The latter requires a deployed
Teacher AI backend and DOES NOT grade audio waveform pronunciation.
If the free token-only Worker lacks an auxiliary backend, a real error is
shown; no fake successful correction is displayed.

**Tasks/rewards**: the existing `RoomExtrasSheet` now contains only tasks,
leaderboard and reward eligibility. It no longer embeds gifts or themes.

## Room tasks and levels (October 16 staging revision)

Room progression is **level by level, 1 to 50**. The next-level requirements
are 300 XP (1→2), 400 XP (2→3), 700 XP (3→4), 1000 XP (4→5), then
increase by 300 XP per level. The UI shows current-level XP **and**
cumulative castle XP. Ten art assets remain shared among five levels each,
but leveling and progress are evaluated **individually** at every level.
Castle artwork floats on the dark emerald page without the old white border.

| Server-verified mission | Proof / eligibility | Room XP | Frequency |
|---|---|---:|---|
| Ten minutes | Member's server-observed heartbeat attendance | 4 | Once per room member per UTC day |
| Five listeners (`host_five`) | Host has five **current** distinct verified listeners | 10 | Once per host per room |
| Ten stage promotions (`stage_ten`) | Ten different users are observed as listeners and later as seated speakers by the backend in the same session; receipts survive seat rotation | 5 | Once per host per room |
| Stay 60 minutes (`stay_hours`) | Member's 60 accumulated server-verified room minutes in a UTC day | 60 | Once per member per UTC day |

Existing `three_gifts` server mission is retained for backwards
compatibility but no longer appears in the four tasks displayed in the
room. It does not use free gift previews as paid gift evidence.
The standalone attendance **gift** card has been removed from the room
tasks page, without deleting any gift or reward records. The Rewards tab
still displays legitimate room level reward entitlements.

`POST /room/tasks/heartbeat` verifies room membership, accumulates
short time intervals and alone creates server-owned `task_stage` receipts
when the same guest was first observed listening and then on stage.
Firestore clients cannot write stage receipts. `GET /room/tasks/status`
reports each task with verified counts. `POST /room/tasks/claim` verifies
the host/session, records completion idempotently and awards **only**
non-monetary room XP inside an atomic transaction. No money, coins or
spendable gift balances are minted. A stale or unknown XP migration
version fails safely rather than overwriting historic progress.

**Deployment boundary:** GitHub CI validation and a test APK are not
production deployment. The current `worldvoice-v2.onrender.com` service
still follows an older deployment branch, so these mission routes can
fail or time out on the phone until the reviewed server release is
deployed separately. Do not change the live Render branch, Firebase
rules or wallet balances without read-only reconciliation and an
approved staged rollout.

### Release validation

- Back up Firebase data and review deployed rules before migrating from
  legacy direct client-side task completion writes. The new version requires
  the hardened Firestore rules and real backend together.
- Test host and guest membership and ten-minute clock with two phones;
  ensure reconnecting resets continuous attendance and users cannot spoof
  `joinedAt` or arbitrary room XP.
- Verify the free token Worker forwards authenticated requests correctly
  only after auxiliary HTTPS backend configuration.
- Keep all real-money economy products disabled until private wallet and
  receipts pass their independent financial migration and sandbox tests.
