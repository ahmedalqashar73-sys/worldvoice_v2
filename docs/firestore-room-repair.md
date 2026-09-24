# Room permissions repair

The rules copied from Firebase on 2026-09-24 predate the current room services.
They allow room documents and participants, but deny all unlisted subcollections.

The first deterministic failure for a non-VIP account is the read of
users/{uid}/room_usage/{dayKey} in RoomQuotaService.check, before room entry.
RoomHistoryService.recordEnter also needs users/{uid}/room_history/{roomId}.
Chat, board items, quiz answers, captions and AI notes need their own rules;
a rooms/{roomId} rule does not grant access to its subcollections.

Use the complete root firestore.rules file, not a blanket read/write allow.
It contains the current room permissions, owner-only history/usage access,
member-only content access, host controls, and backend-only AI note writes.
The active quiz uses the quiz map on the room document and quiz_answers;
the legacy RoomQuizService is not used by RoomQuizSheet.

## Apply from Firebase Console

1. Open project worldvoice-37896, Firestore Database, Rules.
2. Save a copy of the currently published rules.
3. Replace the editor contents with the complete root firestore.rules file.
4. Publish. A GitHub code change or new APK alone does not publish these rules.
5. With two signed-in test accounts: create a room, join, send a message,
   use the board, submit a quiz answer, reveal, raise a hand and leave.
   Confirm non-members cannot read room messages or write board content.

Or from the repository root, with Firebase CLI already signed in:

    firebase deploy --only firestore:rules --project worldvoice-37896

This deploys Firestore rules only. It does not deploy the backend, Storage rules,
or app binaries. AI replies and coin rewards still require their existing
backend configuration. No live deployment is performed by the tests.

## Regression check

    cd test/firestore
    npm install
    npx firebase emulators:exec --only firestore --project demo-worldvoice-rules "npm test"

The test configuration points at ../../firestore.rules. The demo project is
isolated from production. Java 21 and Node 22 are used in CI.
