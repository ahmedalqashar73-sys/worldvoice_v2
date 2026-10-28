import 'dart:async';
import '../features/chat/services/chat_delivery_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/chat/services/worldvoice_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/ads/academy_lesson_ads.dart';
import '../core/localization/locale_controller.dart';
import '../core/localization/supported_language.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/worldvoice_appearance.dart';
import '../features/auth/services/auth_service.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/services/user_presence_service.dart';
import '../features/rooms/services/room_coin_purchase_service.dart';

class WorldVoiceApp extends StatefulWidget {
  const WorldVoiceApp({super.key});

  @override
  State<WorldVoiceApp> createState() => _WorldVoiceAppState();
}

class _WorldVoiceAppState extends State<WorldVoiceApp>
    with WidgetsBindingObserver {
  final LocaleController _localeController = LocaleController();
  final PresenceSession _presenceSession = PresenceSession();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _pushTokenSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundPushSubscription;
  Future<void> _pushSignOutCleanup = Future<void>.value();
  final _notificationMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localeController.addListener(_refresh);
    _pushOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      WorldVoiceNotificationService.openedPush,
    );
    _foregroundPushSubscription = FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['type']?.toString();
      if (type != 'worldvoice_activity' &&
          type != 'worldvoice_announcement' &&
          type != 'story_interaction') {
        return;
      }
      final ar = _localeController.locale?.languageCode == 'ar';
      final messenger = _notificationMessengerKey.currentState;
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message.notification?.body ??
                (ar
                    ? 'لديك إشعار جديد من WorldVoice'
                    : 'New WorldVoice notification'),
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: ar ? 'عرض' : 'View',
            onPressed: () => WorldVoiceNotificationService.openedPush(message),
          ),
        ),
      );
    });
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) {
          if (message != null)
            WorldVoiceNotificationService.openedPush(message);
        })
        .catchError((Object error) {
          debugPrint('WorldVoice initial push unavailable: $error');
          return null;
        });
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(ChatDeliveryService.instance.setAccount(user?.uid));
      if (user != null) {
        _presenceSession.start();
        unawaited(AuthService.syncPrivilegedAccountEntitlements());
        unawaited(RoomCoinPurchaseService.instance.initialize());
        unawaited(_setupPushForAccount());
      } else {
        _presenceSession.stop();
        _pushTokenSubscription?.cancel();
        _pushTokenSubscription = null;
        // Logout revokes this device's token before the next account registers.
        // Avoid exposing a prior member's room notifications on a shared phone.
        _pushSignOutCleanup = _pushSignOutCleanup
            .then((_) async {
              await WorldVoiceNotificationService.clearAnnouncementTopic();
              await FirebaseMessaging.instance.deleteToken();
            })
            .catchError((Object error) {
              debugPrint('WorldVoice push logout cleanup: $error');
            });
      }
    });
    _load();
  }

  Future<void> _setupPushForAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _pushSignOutCleanup;
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      final token = await messaging.getToken();
      if (token != null && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        await WorldVoiceNotificationService.registerDevice(
          token: token,
          languageCode: _localeController.locale?.languageCode ?? 'en',
        );
      }
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      await WorldVoiceNotificationService.syncAnnouncementTopic(
        _localeController.locale?.languageCode ?? 'en',
      );
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      await _pushTokenSubscription?.cancel();
      _pushTokenSubscription = messaging.onTokenRefresh.listen((newToken) {
        if (FirebaseAuth.instance.currentUser?.uid == user.uid) {
          unawaited(
            WorldVoiceNotificationService.registerDevice(
              token: newToken,
              languageCode: _localeController.locale?.languageCode ?? 'en',
            ),
          );
        }
      });
    } catch (error) {
      debugPrint('WorldVoice FCM setup unavailable: $error');
    }
  }

  Future<void> _load() async {
    await Future.wait([
      _localeController.load(),
      WorldVoiceAppearance.instance.load(),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  void _refresh() {
    if (FirebaseAuth.instance.currentUser != null) {
      unawaited(
        WorldVoiceNotificationService.syncAnnouncementTopic(
          _localeController.locale?.languageCode ?? 'en',
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _presenceSession.start();
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _presenceSession.stop();
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _pushTokenSubscription?.cancel();
    _pushOpenSubscription?.cancel();
    _foregroundPushSubscription?.cancel();
    _presenceSession.dispose();
    _localeController.removeListener(_refresh);
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: WorldVoiceAppearance.instance.mode,
      builder: (context, selectedTheme, _) => MaterialApp(
        title: 'WorldVoice',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _notificationMessengerKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: selectedTheme,
        locale: _localeController.locale,
        supportedLocales: SupportedLanguages.locales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: !_ready
            ? const _StartupLoading()
            : _StartupGate(localeController: _localeController),
      ),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate({required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            authSnapshot.data == null) {
          return const _StartupLoading();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return WelcomeScreen(localeController: localeController);
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _ProfileAccessError(
                localeController: localeController,
                isPermissionError:
                    profileSnapshot.error is FirebaseException &&
                    (profileSnapshot.error as FirebaseException).code ==
                        'permission-denied',
              );
            }
            if (!profileSnapshot.hasData) {
              return const _StartupLoading();
            }

            final data = profileSnapshot.data!.data();
            if (AuthService.hasCompletedProfileData(data)) {
              return _AcademyHomeLaunchGate(
                key: ValueKey('academy-app-launch-${user.uid}'),
                uid: user.uid,
                isVip: data?['isVip'] == true,
                localeController: localeController,
              );
            }
            // Do not create a duplicate profile from a missing local cache.
            // Check the server for legacy profiles with this verified email.
            return _MissingProfileGate(
              key: ValueKey(user.uid),
              user: user,
              localeController: localeController,
            );
          },
        );
      },
    );
  }
}

/// Count only real, authenticated app launches after a saved profile loaded.
/// Keep the startup loading screen visible while a third-launch AppOpenAd
/// loads/shows, never display it unexpectedly over interactive home content.
class _AcademyHomeLaunchGate extends StatefulWidget {
  const _AcademyHomeLaunchGate({
    required this.uid,
    required this.isVip,
    required this.localeController,
    super.key,
  });

  final String uid;
  final bool isVip;
  final LocaleController localeController;

  @override
  State<_AcademyHomeLaunchGate> createState() => _AcademyHomeLaunchGateState();
}

class _AcademyHomeLaunchGateState extends State<_AcademyHomeLaunchGate> {
  late final Future<void> _startupAd;

  @override
  void initState() {
    super.initState();
    _startupAd = AcademyAppLaunchAdGate.beforeHome(
      uid: widget.uid,
      isVip: widget.isVip,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _startupAd,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _StartupLoading();
      }
      return HomeScreen(localeController: widget.localeController);
    },
  );
}

class _MissingProfileGate extends StatefulWidget {
  const _MissingProfileGate({
    required this.user,
    required this.localeController,
    super.key,
  });

  final User user;
  final LocaleController localeController;

  @override
  State<_MissingProfileGate> createState() => _MissingProfileGateState();
}

class _MissingProfileGateState extends State<_MissingProfileGate> {
  late Future<bool> _legacyLookup;

  @override
  void initState() {
    super.initState();
    _legacyLookup = AuthService.hasLegacyProfileForVerifiedEmail(widget.user);
  }

  @override
  void didUpdateWidget(covariant _MissingProfileGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _legacyLookup = AuthService.hasLegacyProfileForVerifiedEmail(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _legacyLookup,
      builder: (context, result) {
        if (result.hasError) {
          return _ProfileAccessError(
            localeController: widget.localeController,
            isPermissionError:
                result.error is FirebaseException &&
                (result.error as FirebaseException).code == 'permission-denied',
          );
        }
        if (!result.hasData) return const _StartupLoading();
        if (result.data == true) {
          return _LegacyProfileNotice(
            localeController: widget.localeController,
          );
        }
        // A partial document from an older version needs completing, not
        // accidental recreation of a fresh account with a new user ID.
        return ProfileSetupScreen(localeController: widget.localeController);
      },
    );
  }
}

class _ProfileAccessError extends StatelessWidget {
  const _ProfileAccessError({
    required this.localeController,
    required this.isPermissionError,
  });

  final LocaleController localeController;
  final bool isPermissionError;

  @override
  Widget build(BuildContext context) {
    final ar = localeController.locale?.languageCode == 'ar';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 52),
                const SizedBox(height: 20),
                Text(
                  ar
                      ? 'تعذر تحميل بروفايلك المحفوظ'
                      : 'Your saved profile could not be loaded',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  isPermissionError
                      ? (ar
                            ? 'قواعد Firebase تمنع الوصول إلى الملف. بياناتك لم تُحذف. لا تنشئ بروفايلًا جديدًا.'
                            : 'Firebase rules denied access. Your data was not deleted. Do not create a new profile.')
                      : (ar
                            ? 'تحقق من الإنترنت ثم أعد فتح التطبيق. بيانات البروفايل لن تُستبدل.'
                            : 'Check your connection and reopen the app. Your profile will not be overwritten.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () async => AuthService.signOut(),
                  child: Text(
                    ar
                        ? 'تسجيل الخروج لاختيار الحساب الصحيح'
                        : 'Sign out to choose the correct account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyProfileNotice extends StatelessWidget {
  const _LegacyProfileNotice({required this.localeController});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final ar = localeController.locale?.languageCode == 'ar';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.manage_accounts_outlined, size: 54),
                const SizedBox(height: 18),
                Text(
                  ar
                      ? 'وجدنا بروفايلًا قديمًا مرتبطًا ببريدك'
                      : 'A previous profile was found for your email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  ar
                      ? 'هذا الدخول يستخدم معرّف حساب مختلفًا. حفاظًا على بياناتك، لم ننشئ بروفايلًا جديدًا ولم ننسخ رصيدك. سجّل بنفس طريقة الدخول القديمة، أو اطلب ربط الحسابين بشكل آمن.'
                      : 'This login has a different account ID. We did not create a duplicate profile or copy wallet data. Sign in using your original method or request secure account linking.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async => AuthService.signOut(),
                  child: Text(
                    ar ? 'العودة إلى تسجيل الدخول' : 'Return to sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
