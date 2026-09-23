import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/locale_controller.dart';
import '../core/localization/supported_language.dart';
import '../core/theme/app_theme.dart';
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

class _WorldVoiceAppState extends State<WorldVoiceApp> with WidgetsBindingObserver {
  final LocaleController _localeController = LocaleController();
  final PresenceSession _presenceSession = PresenceSession();
  StreamSubscription<User?>? _authSubscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localeController.addListener(_refresh);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _presenceSession.start();
        unawaited(RoomCoinPurchaseService.instance.initialize());
      } else {
        _presenceSession.stop();
      }
    });
    _load();
  }

  Future<void> _load() async {
    await _localeController.load();
    if (mounted) setState(() => _ready = true);
  }

  void _refresh() {
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
    _presenceSession.dispose();
    _localeController.removeListener(_refresh);
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            if (!profileSnapshot.hasData) {
              return const _StartupLoading();
            }

            final data = profileSnapshot.data!.data();
            final completed = data?['profileCompleted'] == true;

            if (completed) {
              return HomeScreen(localeController: localeController);
            }

            return ProfileSetupScreen(localeController: localeController);
          },
        );
      },
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
