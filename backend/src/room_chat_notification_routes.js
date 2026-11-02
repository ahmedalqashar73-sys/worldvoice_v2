/**
 * Voice-room comments are visible only in the live Firestore chat.
 * They must never produce OS/FCM notifications, even when an old Android
 * build still calls this legacy route after a comment is saved.
 * Direct messages, stage invitations and gift events use separate routes.
 */
export function registerRoomChatNotificationRoutes({
  app, authenticatedUser,
}) {
  app.post("/system/room-message/notify", async (req, res, next) => {
    try {
      await authenticatedUser(req);
      res.json({ok: true, disabled: true, receivers: 0});
    } catch (error) {
      next(error);
    }
  });
}
