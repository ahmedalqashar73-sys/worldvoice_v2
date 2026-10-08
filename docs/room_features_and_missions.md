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

## Room tasks and levels

Level formula: start at level 1, add one level per 100 room XP and cap at
level 60 (5,900 XP). These are NON-MONETARY game XP, not coins/diamonds.

| Server-verified task | Eligibility | XP | Frequency |
|---|---|---:|---|
| Stay ten minutes | Member's server-timestamped continuous room entry reaches ten minutes | 4 | Once per member, room, UTC day |
| Host five participants | Five other member records are simultaneously present while claimant is host | 50 | Once per claimant and room |
| Send three gifts | Three trusted backend gift events from claimant in this room | Owner-set `sendThreeGiftsXp` | Once per claimant and room |
| Stay for hours | Continuous member attendance reaches owner-set `stayHoursMinimum` hours | Owner-set `stayHoursXp` | Once per claimant, room, UTC day |

The owner has not provided the last two XP amounts or the hourly
threshold. Neither task is claimable until `room_task_config/current`
has valid, approved integer values for these fields. Do NOT guess them.
The fixed 4 and 50 XP values were provided by the owner.

`GET /room/tasks/status?roomId=...` reports validated status and progress.
`POST /room/tasks/claim` checks an authenticated Firebase ID token, active
membership, server timestamps and immutable room gift events inside a
Firestore transaction. Duplicate claims return the original outcome;
the phone cannot write XP or create level rewards in Security Rules.
Level-reward eligibility metadata is created by the server and may need a
separately activated gift catalog to become actual inventory. It does NOT
fund cash-equivalent gifts by itself.

The existing token-only Worker forwards both routes only if its
`AUX_BACKEND_URL` points to a separately deployed authenticated Node
backend. Without it, the missions display a clear unavailable state.
Do not claim these are currently working on-device merely because Flutter
renders the progress UI.

### Release validation

- Back up Firebase data and review deployed rules before migrating from
  legacy direct client-side `completeTask` writes. The new version requires
  the hardened Firestore rules and real backend together.
- Test host and guest membership and ten-minute clock with two phones;
  ensure reconnecting resets continuous attendance and users cannot spoof
  `joinedAt` or arbitrary room XP.
- Verify the free token Worker forwards authenticated requests correctly
  only after auxiliary HTTPS backend configuration.
- Keep all real-money economy products disabled until private wallet and
  receipts pass their independent financial migration and sandbox tests.
