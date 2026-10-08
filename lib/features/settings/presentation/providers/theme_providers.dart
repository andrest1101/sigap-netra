import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_providers.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  AppThemePreference withThemeMode() => this;
}

AppThemePreference themePreferenceFromName(String? name) => switch (name) {
  'light' => AppThemePreference.light,
  'dark' => AppThemePreference.dark,
  _ => AppThemePreference.system,
};

/// Preferensi tema lokal.
///
/// Selama backend belum siap, tema disimpan di `SharedPreferences`.
final appThemePreferenceProvider =
    NotifierProvider<ThemePreferenceController, AppThemePreference>(
      ThemePreferenceController.new,
    );

class ThemePreferenceController extends Notifier<AppThemePreference> {
  static const String _storageKey = 'theme_mode';

  @override
  AppThemePreference build() {
    final preferences = ref.read(sharedPreferencesProvider);
    return themePreferenceFromName(preferences.getString(_storageKey));
  }

  Future<void> set(AppThemePreference value) async {
    state = value;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_storageKey, value.name);
  }
}
