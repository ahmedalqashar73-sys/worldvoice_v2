import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local, app-wide appearance preference. No network writes or account
/// synchronization are required just to choose Light/Dark/System.
final class WorldVoiceAppearance {
  WorldVoiceAppearance._();
  static final WorldVoiceAppearance instance = WorldVoiceAppearance._();
  static const _storageKey = 'worldvoice_appearance_mode_v1';
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_storageKey);
    mode.value = switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setMode(ThemeMode selection) async {
    mode.value = selection;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, selection.name);
  }
}
