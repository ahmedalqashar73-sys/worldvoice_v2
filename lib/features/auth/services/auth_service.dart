import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../rooms/data/room_backend_config.dart';

import '../../profile/services/user_presence_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;
  static const String _backend =
      RoomBackendConfig.economyBaseUrl;

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

  // Read-only detection: the signed-in account may have a *different* UID
  // than an older account using the same verified email. Never take ownership
  // of that document or copy private wallet/VIP data from the mobile client.
  // A backend-verified account-linking flow is required for migration.
  static Future<bool> hasLegacyProfileForVerifiedEmail(User user) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty || !user.emailVerified) return false;

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(10)
        .get(const GetOptions(source: Source.server));
    for (final doc in result.docs) {
      if (doc.id != user.uid && hasCompletedProfileData(doc.data())) {
        return true;
      }
    }
    return false;
  }

  static Future<void> syncPrivilegedAccountEntitlements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final root = Uri.tryParse(_backend.trim());
    if (root == null ||
        root.scheme != 'https' ||
        !root.hasAuthority ||
        root.userInfo.isNotEmpty) {
      return;
    }

    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) return;
      final basePath = root.path.endsWith('/')
          ? root.path.substring(0, root.path.length - 1)
          : root.path;
      final response = await http
          .post(
            root.replace(path: '$basePath/account/sync-entitlements'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
    } catch (_) {
      // Entitlement sync is best-effort. It must never block sign-in.
    }
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

  /// Native Sign in with Apple for iPhone/iPad. The Apple provider must be
  /// enabled in Firebase Auth and the Runner App ID must carry the matching
  /// Sign in with Apple entitlement in Apple Developer.
  /// This does not silently merge an existing Google identity with a new
  /// Apple private-relay email: explicit verified account linking is required.
  static Future<UserCredential> signInWithApple() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw FirebaseAuthException(
        code: 'apple-platform-unsupported',
        message: 'Sign in with Apple is currently enabled only on iOS.',
      );
    }
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    return _auth.signInWithProvider(provider);
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
