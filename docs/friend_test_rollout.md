# WorldVoice — friend-test gift preview rollout

## Exactly what this release enables

The shared emerald/gold first tier includes all 30 SVG gift illustrations.
Friends on separate signed-in Android phones can show each other **free DEMO
animations** over the same voice/Live room; the same mechanism is available
within an existing verified one-to-one conversation. The animation says
**preview/no coins charged** and shows sender/recipient names resolved from
stored participant/chat membership. All notices live in a separate
`gift_previews/{senderUid}` collection. The real `gifts` and `messages`
collections, diamonds, coins, XP, and wallets are not written.

The separate friend-demo switch defaults to OFF in all normal production
builds. **Only** this friend-test APK opts in using
`WORLDVOICE_FRIEND_GIFT_PREVIEW=true`.

**Room and Live friend testing:** the app first uses the dedicated preview
collection, and if the deployed Firebase rules have not been updated yet,
it can use the existing authenticated room-chat transport for the same
clearly labeled free animation. The chat transport may leave a short
"free demo" line in the room chat. The fallback works only if the room
already supports normal Firestore chat messages for both friends.

**Private one-to-one chats:** the isolated preview collection needs the
reviewed new Firebase rules; creating real conversations still needs the
separately deployed, authenticated full chat backend.

Before deliberately deploying any rules, compare and back up the currently
deployed production configuration. Do not overwrite security improvements
in the active Firebase project. The repository's older profile rules need
independent privacy review; no automatic Firebase deployment is performed.

## Tests before inviting friends

1. GitHub Actions must show green for **Validate WorldVoice** (Flutter
   analyze + widget tests, backend and isolated Firestore-rule emulator),
   **Agora Worker Unit Tests**, and the latest Android Cloud Test APK job.
2. On your own phone, enter an actual open voice room; choose **Gifts** and
   a friend who is also a current participant; select a first-tier gift.
   Use **Preview effect** to inspect local art, or **Show demo to friend**
   to send a free animation. A real friend must already be on the list;
   Teacher AI and empty placeholders cannot receive a friend demo.
3. Both phones should see the marked free overlay with genuine membership
   names (not a paid gift or a promise of diamonds).
4. Repeat from the same sender no more than once every 3 seconds. Test a
   second voice room and a Live voice room. Test existing authenticated
   private conversation only if the separately deployed full chat backend
   and verified mutual-follow membership work.
5. Verify coin balance, diamond balance, XP and paid gift history are all
   **unchanged**. Real coin purchasing and paid live gifting remain
   disabled until separate authorized launch steps.

If dedicated preview rules have not been deployed, voice and Live room
demos can use the existing authenticated room chat as a compatibility
transport. Existing chat rules and a current room membership are required.
For one-to-one chats, no such fallback exists: deploy reviewed preview
rules and the full authenticated chat backend first.

## How Ahmed tests in PowerShell

First preserve any local changes shown by `git status` rather than
overwriting uncommitted work. With a clean working tree:

```powershell
cd C:\Users\AHMED\worldvoice_v2
git switch fix/finish-room-hub-quiz-gift-20260928
git pull --ff-only origin fix/finish-room-hub-quiz-gift-20260928
flutter pub get
flutter run --dart-define=WORLDVOICE_FRIEND_GIFT_PREVIEW=true --dart-define=AGORA_APP_ID=fa41476c6813471eb45c059bcb4a0e19 --dart-define=WORLDVOICE_ROOM_BACKEND_URL=https://worldvoice-agora-token.worldvoice.workers.dev
```

The **GitHub Actions Android Cloud Test APK** uses the same demo switch
and public Agora Worker URL. Download its latest
`WorldVoice-friend-gift-demo-test-apk` artifact. The test APK uses
temporary CI/debug signing: switching signing keys may require removing a
previous installation first, which clears on-device-only caches, but must
never delete remote Firebase data.

After local testing, a *locally built* APK can be distributed through your
existing authenticated Firebase App Distribution account:

```powershell
.\scripts\build_free_android_test.ps1 -WorkerUrl "https://worldvoice-agora-token.worldvoice.workers.dev"
.\scripts\distribute_android_test.ps1 -Testers "friend1@example.com,friend2@example.com"
```

Replace example addresses with only friends who consent to testing. Log in
to Firebase CLI and configure App Distribution for your Android application
first. We do not possess your tester addresses or Firebase deployment
authorization. Invitation acceptance and successful installation should
be verified on their own phones.

## Payments are a separate launch, not part of this demo

- Android digital coin packs: **Google Play Billing** with developer account,
  approved consumable SKUs, sandbox/internal-track product availability and
  server-side purchase-token verification.
- iOS: **App Store** with App Store Connect SKUs and sandbox/StoreKit verification.
- Visa/Mastercard on the web: **Stripe hosted Checkout**, matching approved
  catalogue `webPriceId`, verified webhook, company merchant onboarding and
  payout settings. Do **not** add direct card checkout as a bypass for Google
  Play digital-goods rules on Android.
- All seven coin-pack slots remain visible but disabled until the actual
  store approves prices/identifiers and the private wallet / public profile
  migration is independently verified. A test APK is not a billing
  acceptance test.
- Premium SVG art is NOT rigged 3D; custom 3D geometry, motion and reviewed
  commercial-use source files remain a separate creative asset task.

Never paste API secrets, merchant credentials or customer card numbers in a
chat, issue, GitHub source file, Firestore document, or application build flag.
