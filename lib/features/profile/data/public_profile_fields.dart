import 'package:cloud_firestore/cloud_firestore.dart';

/// Only explicitly approved public-facing fields can leave the private user
/// document. Never copy balances, email, exact DOB, identity or payout data.
class PublicProfileFields {
  const PublicProfileFields._();

  static Map<String, dynamic> project(Map<String, dynamic> privateProfile) {
    const allowed = <String>{
      'uid', 'displayName', 'username', 'bio', 'country', 'gender',
      'photoUrl', 'coverUrl', 'nativeLanguageCode', 'nativeLanguage',
      'learningLanguageCodes', 'learningLanguages', 'languageLevel',
      'professionKey', 'profession', 'travel', 'learningGoals', 'interests',
      'voiceBioUrl', 'isPartner', 'isOnline', 'lastActiveAt', 'lastSeenAt',
      'followersCount', 'followingCount', 'hideCity', 'city',
      'profileCompleted',
    };
    final result = <String, dynamic>{
      for (final key in allowed)
        if (privateProfile.containsKey(key)) key: privateProfile[key],
    };
    final rawDate = privateProfile['birthDate'];
    final birthday = rawDate is Timestamp ? rawDate.toDate()
        : rawDate is DateTime ? rawDate : null;
    if (birthday != null) {
      final today = DateTime.now().toUtc();
      var age = today.year - birthday.year;
      if (today.month < birthday.month ||
          (today.month == birthday.month && today.day < birthday.day)) {
        age--;
      }
      if (age >= 0 && age <= 120) result['ageYears'] = age;
    }
    if (privateProfile['hideCity'] == true) result.remove('city');
    return result;
  }

  static Map<String, dynamic> editable(Map<String, dynamic> changes) {
    final public = project(changes);
    // Never let a profile edit silently overwrite previously derived age.
    return public;
  }
}
