import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/locale_controller.dart';
import '../core/localization/supported_language.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/services/auth_service.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/live/presentation/live_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/services/user_presence_service.dart';
import '../features/rooms/services/room_coin_purchase_service.dart';

class WorldVoiceApp extends StatefulWidget {
  const WorldVoiceApp({super.key});

  @override
  State<WorldVoiceApp> createState() => _WorldVoiceAppState();
}

class _WorldVoiceAppState extends State<WorldVoiceApp> with WidgetsBindingObserver {
  final LocaleController _localeController = LocaleController();
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  static const MethodChannel _liveLinks =
      MethodChannel('worldvoice/live_links');
  String? _pendingSharedLive;
  bool _openingSharedLive = false;
  final PresenceSession _presenceSession = PresenceSession();
  StreamSubscription<User?>? _authSubscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveLinks.setMethodCallHandler((call) async {
      if (call.method == 'openLive' && call.arguments is String) {
        _queueSharedLive(call.arguments as String);
      }
    });
    unawaited(_readInitialLiveLink());
    _localeController.addListener(_refresh);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _presenceSession.start();
        unawaited(AuthService.syncPrivilegedAccountEntitlements());
        unawaited(RoomCoinPurchaseService.instance.initialize());
        _scheduleOpenSharedLive();
      } else {
        _presenceSession.stop();
      }
    });
    _load();
  }

  Future<void> _load() async {
    await _localeController.load();
    if (mounted) {
      setState(() => _ready = true);
      _scheduleOpenSharedLive();
    }
  }

  Future<void> _readInitialLiveLink() async {
    try {
      final id = await _liveLinks.invokeMethod<String>('initial');
      if (id != null) _queueSharedLive(id);
    } on PlatformException {
      // iOS / older Android builds can still open the app normally.
    } on MissingPluginException {
      // No native link handler on this platform.
    }
  }

  void _queueSharedLive(String id) {
    if (!RegExp(r'^[A-Za-z0-9_-]{3,128}$').hasMatch(id)) return;
    _pendingSharedLive = id;
    _scheduleOpenSharedLive();
  }

  void _scheduleOpenSharedLive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openPendingSharedLive());
    });
  }

  Future<void> _openPendingSharedLive() async {
    if (!_ready || _openingSharedLive || _pendingSharedLive == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Retain the link across login.
    _openingSharedLive = true;
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (!AuthService.hasCompletedProfileData(profile.data())) {
        return; // Do not bypass login or onboarding.
      }
      if (!mounted) return;
      final navigator = _navigator.currentState;
      if (navigator == null) return;
      final id = _pendingSharedLive!;
      _pendingSharedLive = null;
      await navigator.push<void>(MaterialPageRoute(
        builder: (_) => WorldVoiceLiveInvitationPage(liveId: id),
      ));
    } catch (_) {
      // Profile unavailable/offline: keep the invitation for another attempt.
    } finally {
      _openingSharedLive = false;
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _presenceSession.start();
        _scheduleOpenSharedLive();
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
    _liveLinks.setMethodCallHandler(null);
    _authSubscription?.cancel();
    _presenceSession.dispose();
    _localeController.removeListener(_refresh);
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'WorldVoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
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
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _ProfileAccessError(
                localeController: localeController,
                isPermissionError: profileSnapshot.error
                    is FirebaseException &&
                    (profileSnapshot.error as FirebaseException).code ==
                        'permission-denied',
              );
            }
            if (!profileSnapshot.hasData) {
              return const _StartupLoading();
            }

            final data = profileSnapshot.data!.data();
            if (AuthService.hasCompletedProfileData(data)) {
              return HomeScreen(localeController: localeController);
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
            isPermissionError: result.error is FirebaseException &&
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
        return ProfileSetupScreen(
          localeController: widget.localeController,
        );
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded, size: 52),
              const SizedBox(height: 20),
              Text(
                ar ? 'تعذر تحميل بروفايلك المحفوظ' :
                    'Your saved profile could not be loaded',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                isPermissionError
                    ? (ar ? 'قواعد Firebase تمنع الوصول إلى الملف. بياناتك لم تُحذف. لا تنشئ بروفايلًا جديدًا.' :
                        'Firebase rules denied access. Your data was not deleted. Do not create a new profile.')
                    : (ar ? 'تحقق من الإنترنت ثم أعد فتح التطبيق. بيانات البروفايل لن تُستبدل.' :
                        'Check your connection and reopen the app. Your profile will not be overwritten.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () async => AuthService.signOut(),
                child: Text(ar ? 'تسجيل الخروج لاختيار الحساب الصحيح' :
                    'Sign out to choose the correct account'),
              ),
            ]),
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.manage_accounts_outlined, size: 54),
              const SizedBox(height: 18),
              Text(
                ar ? 'وجدنا بروفايلًا قديمًا مرتبطًا ببريدك' :
                    'A previous profile was found for your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                ar ? 'هذا الدخول يستخدم معرّف حساب مختلفًا. حفاظًا على بياناتك، لم ننشئ بروفايلًا جديدًا ولم ننسخ رصيدك. سجّل بنفس طريقة الدخول القديمة، أو اطلب ربط الحسابين بشكل آمن.' :
                    'This login has a different account ID. We did not create a duplicate profile or copy wallet data. Sign in using your original method or request secure account linking.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async => AuthService.signOut(),
                child: Text(ar ? 'العودة إلى تسجيل الدخول' : 'Return to sign in'),
              ),
            ]),
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
