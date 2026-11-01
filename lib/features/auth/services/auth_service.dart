import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../rooms/data/room_backend_config.dart';

import '../../profile/services/user_presence_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;
  static const String _backend =
      RoomBackendConfig.giftStoreBaseUrl;

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

  /// Call from a deliberate owner action to surface the server's grant
  /// outcome. The backend verifies owner identity and enforces one grant per
  /// Riyadh calendar month; the client never writes money to Firestore.
  static Future<Map<String, dynamic>> syncOwnerMonthlyCoinsNow() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to refresh your wallet.');
    final root = Uri.tryParse(_backend.trim());
    if (root == null ||
        root.scheme != 'https' ||
        !root.hasAuthority ||
        root.userInfo.isNotEmpty ||
        root.hasQuery ||
        root.hasFragment) {
      throw StateError('Owner reward backend is not configured.');
    }

    // Force-refresh signed custom claims after admin enrollment.
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify your Firebase sign-in.');
    }
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
    Map<String, dynamic> result = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) result = decoded;
    } catch (_) {
      // Keep a useful HTTP error if the backend returns an invalid body.
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['ok'] != true) {
      throw StateError(result['error']?.toString() ??
          'Owner wallet sync failed (HTTP ${response.statusCode}).');
    }
    return result;
  }

  /// Owner-only troubleshooting information, returned from the authenticated
  /// backend. It contains no account identifiers or monetary balances.
  static Future<Map<String, dynamic>> ownerReadinessNow() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in first.');
    final root = Uri.tryParse(_backend.trim());
    if (root == null || root.scheme != 'https' || !root.hasAuthority ||
        root.userInfo.isNotEmpty || root.hasQuery || root.hasFragment) {
      throw StateError('Owner backend URL is invalid.');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Unable to refresh Firebase sign-in.');
    }
    final basePath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    final result = await http.get(
      root.replace(path: '$basePath/account/owner-readiness'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    final Map<String, dynamic> payload;
    try {
      final data = jsonDecode(result.body);
      payload = data is Map<String, dynamic>
          ? data : <String, dynamic>{};
    } catch (_) {
      throw StateError('Owner readiness server returned invalid data.');
    }
    if (result.statusCode < 200 || result.statusCode >= 300 ||
        payload['ok'] != true) {
      throw StateError(payload['error']?.toString() ??
          'Owner readiness check failed (HTTP ${result.statusCode}).');
    }
    return payload;
  }

  static Future<void> syncPrivilegedAccountEntitlements() async {
    try {
      await syncOwnerMonthlyCoinsNow();
    } catch (_) {
      // Automatic sync stays best-effort and must never block sign-in.
      // The owner can use the profile's manual sync to see the precise error.
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

  /// Confirms ownership of a legacy Firebase owner account using a fresh
  /// Google ID token without changing the active Firebase UID or profile.
  /// The backend checks the signed Google token and the protected owner UID.
  static Future<Map<String, dynamic>> verifyOwnerWithGoogleNow() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Sign in to your existing WorldVoice account first.');
    }
    await _initializeGoogle();
    final googleAccount = await GoogleSignIn.instance.authenticate();
    final googleIdToken = googleAccount.authentication.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw StateError('Google did not supply identity proof.');
    }
    final root = Uri.tryParse(_backend.trim());
    if (root == null || root.scheme != 'https' || !root.hasAuthority ||
        root.userInfo.isNotEmpty || root.hasQuery || root.hasFragment) {
      throw StateError('Owner verification backend is not configured.');
    }
    final firebaseToken = await currentUser.getIdToken(true);
    if (firebaseToken == null || firebaseToken.isEmpty) {
      throw StateError('Firebase session could not be verified.');
    }
    final basePath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    final response = await http.post(
      root.replace(path: '$basePath/account/owner/verify-google'),
      headers: {
        'Authorization': 'Bearer $firebaseToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'googleIdToken': googleIdToken}),
    ).timeout(const Duration(seconds: 20));
    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {
      // Invalid responses are reported as HTTP errors without exposing tokens.
    }
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        payload['ok'] != true) {
      throw StateError(payload['error']?.toString() ??
          'Google verification failed (HTTP ${response.statusCode}).');
    }
    // Attach Google to the existing Firebase UID when it is not already
    // linked. An existing Google credential owned by another UID must never
    // trigger silent account switching or automatic data migration.
    String? googleLinkWarning;
    await currentUser.reload();
    final reloaded = _auth.currentUser;
    if (reloaded?.uid != currentUser.uid) {
      throw StateError('Firebase session changed during owner verification.');
    }
    if (!reloaded!.providerData.any((p) => p.providerId == 'google.com')) {
      try {
        await reloaded.linkWithCredential(
          GoogleAuthProvider.credential(idToken: googleIdToken),
        );
      } on FirebaseAuthException catch (error) {
        if (const {
          'credential-already-in-use',
          'email-already-in-use',
          'provider-already-linked',
        }.contains(error.code)) {
          googleLinkWarning = error.code;
        } else {
          rethrow;
        }
      }
    }
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
    return <String, dynamic>{
      ...payload,
      'googleLinked': _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') == true,
      if (googleLinkWarning != null) 'googleLinkWarning': googleLinkWarning,
    };
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
