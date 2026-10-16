# WorldVoice Games — first playable beta, 2026-10-17

## Approved host and player rules
- Only the **room host** selects the game mode, room language and **one common difficulty** for each session. Members cannot override the host's level.
- **Vocabulary** shows a same-language definition and requires a written answer. Host, stage speakers and **listeners** can participate.
- **Guess the Word** shows scrambled letters. Only the host and seated stage speakers/co-hosts/VIP seat participants can submit answers; listeners can watch.
- Each session contains exactly **five questions**. For this beta, **each question has 30 seconds** (150 seconds for five words). This interprets the spoken time request; confirm whether the intended 30 seconds is instead for the whole five-word session.
- Free daily quota: **five sessions of Vocabulary AND five sessions of Guess the Word per host**, counted across all of their rooms, UTC midnight reset. The backend rejects sixth attempts with 429. Listeners are not charged for joining the host's session.
- Each correct verified written answer yields **10 game points**, up to 50 per five-word session. Incorrect answers yield zero. Game points are score-only and do **not** mint wallet coins, diamonds, VIP or room XP. No payment or USD checkout was added.

## Room language and content
- The backend checks the canonical room language/languageCodes in Firestore; device language does not decide questions.
- Reviewed beta word banks: Arabic `ar`, English `en`, French `fr`, seven original word/definition pairs per difficulty and language, five selected per round.
- Beginner, Intermediate and Advanced use progressively more complex terms. Host also selects one language from a mixed-language room's supported tags.
- Unsupported room languages are disabled safely until reviewed word banks exist. Do not silently fall back to English in an Arabic/other-language room.
- The vocabulary definition and answer always use the *same language*; word guessing uses characters of that language.

## Implementation
- Games button is accessible through the bottom room Tools grid. The existing moderator/title-only Quiz action and traditional multiple-choice quiz remain unchanged.
- Added `RoomGamesService` to the existing `room_quiz_service.dart` instead of duplicating the quiz services.
- Added `RoomGamesSheet` to render host selectors, the shared five-word panel, input, live local countdown, and top score list.
- Trusted HTTP endpoints:
  - `GET /room/games/status?roomId=<room>`
  - `POST /room/games/start` (host only)
  - `POST /room/games/answer` (server checks auth, seat, current 30-second window and no duplicate submission)
- Firestore state `rooms/{room}/private_games/current` and individual session documents are **server-only**, with scores and attempt receipts below sessions. Per-host quota: `users/{uid}/game_usage/{UTCday}_{gameMode}`, server-only.
- Scores are calculated only from server-held answers and are displayed on a round-specific leaderboard. Answers do not appear in API status until all five 30-second windows finish.
- Node policy tests, Firestore emulator transactional replay tests, rules security tests, and Flutter widget tests are included.
- An attempt to play does not consume a second daily start; a start uses one quota slot via atomic transaction. Players get one answer attempt per word.

## Deployment gate
- The features are on the GitHub development branch and require a new verified backend deployment before they work on physical phones.
- Do not switch Render's auto-deploy branch or merge this broad feature PR into a live backend without code isolation, secret/config compatibility review, current wallet/XP reconciliation, and phone testing.
- The existing live `worldvoice_v2` Render release should be left intact. A dedicated release PR from its exact baseline can backport these game routes after CI green.
- Android beta artifact is built in GitHub Actions; installing it alone will **not** activate routes on an older server.
- Future improvements: expand 12+ other languages with reviewed definitions, add word-bank content management and repeated-word rotation, reduce Firestore polling for large rooms, profanity filtering, performance/load testing, and optional accessibility modes.

## Cost
- This implementation uses no paid AI calls per question: reviewed local server word banks and Firebase-backed state.
- Render/Firebase usage (CPU, bandwidth, reads and writes) is **not inherently $0** and should be monitored. No dollar estimate can be made without expected active rooms and players.
