import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../profile/services/user_presence_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;

  static bool hasCompletedProfileData(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['profileCompleted'] == true) return true;

    final displayName = (data['displayName'] ?? data['name'] ?? '')
        .toString()
        .trim();
    final username = (data['username'] ?? '').toString().trim();
    final nativeLanguage =
        (data['nativeLanguageCode'] ?? data['nativeLanguage'] ?? '')
            .toString()
            .trim();
    final country = (data['country'] ?? '').toString().trim();
    final gender = (data['gender'] ?? '').toString().trim();
    final hasBirthDate = data['birthDate'] != null;

    final identitySignals = <bool>[
      nativeLanguage.isNotEmpty,
      country.isNotEmpty,
      gender.isNotEmpty,
      hasBirthDate,
    ].where((value) => value).length;

    // Older WorldVoice profiles may pre-date profileCompleted. Do not force
    // those users through onboarding again when their identity already exists.
    return displayName.isNotEmpty && username.isNotEmpty && identitySignals > 0;
  }

  static Future<void> _initializeGoogle() async {
    if (_googleInitialized) return;

    // Android needs the Firebase Web OAuth client as serverClientId when
    // google_sign_in 7.x is used with authenticate().
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '149108991969-iqb745f7jtpr690m6mhq5kf0du6md3mf.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  static Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogle();

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> createWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    await UserPresenceService.markOffline();
    try {
      await _initializeGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Email/Apple sessions do not require Google sign-out.
    }
    await _auth.signOut();
  }
}
