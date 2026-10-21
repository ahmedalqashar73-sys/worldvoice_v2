import 'package:shared_preferences/shared_preferences.dart';

/// Saved section checkpoint for each user, level, and Spanish lesson.
///
/// The curriculum's authoritative completed-lesson record remains
/// SpanishA1Progress. This checkpoint preserves only the last fully
/// completed section to support returning after a screen is closed.
abstract final class SpanishLessonStageProgress {
  static String _key(String? uid, String level, String lessonId) {
    final account = (uid == null || uid.isEmpty) ? 'guest' : uid;
    return 'worldvoice.spanish.stage.$account.$level.$lessonId';
  }

  static Future<int> load(
    String? uid, {
    required String level,
    required String lessonId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_key(uid, level, lessonId)) ?? 0).clamp(0, 7);
  }

  static Future<void> save(
    String? uid, {
    required String level,
    required String lessonId,
    required int unlockedStage,
  }) async {
    if (unlockedStage < 0 || unlockedStage > 7) {
      throw RangeError.range(unlockedStage, 0, 7, 'unlockedStage');
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _key(uid, level, lessonId);
    final current = prefs.getInt(key) ?? 0;
    if (unlockedStage > current) {
      await prefs.setInt(key, unlockedStage);
    }
  }

  static Future<void> clear(
    String? uid, {
    required String level,
    required String lessonId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid, level, lessonId));
  }
}
