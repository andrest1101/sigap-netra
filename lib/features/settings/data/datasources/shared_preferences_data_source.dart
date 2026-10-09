import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_preferences.dart';
import 'preferences_data_source.dart';

/// Sumber data preferensi berbasis SharedPreferences (penyimpanan lokal).
///
/// Catatan kontrak: `settings.uploadThumbnails` di Firestore ditulis oleh
/// device, bukan app (`docs/firestore_schema.md` bagian 5). Consent lokal di
/// sini adalah izin pengguna di sisi aplikasi; tidak ada tulis Firestore
/// untuk preferensi ini.
class SharedPreferencesDataSource implements PreferencesDataSource {
  SharedPreferencesDataSource(this._preferences);

  final SharedPreferences _preferences;

  static const String themeModeKey = 'theme_mode';
  static const String uploadThumbnailsKey = 'upload_thumbnails_privacy';

  final StreamController<AppPreferences> _controller =
      StreamController<AppPreferences>.broadcast();

  @override
  Stream<AppPreferences> watchPreferences() {
    return Stream<AppPreferences>.multi((controller) {
      controller.add(read());
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  /// Membaca preferensi saat ini.
  AppPreferences read() {
    return AppPreferences(
      themeMode: _readThemeMode(_preferences.getString(themeModeKey)),
      uploadThumbnailsConsented:
          _preferences.getBool(uploadThumbnailsKey) ?? false,
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    await _preferences.setString(
      themeModeKey,
      _writeThemeMode(preferences.themeMode),
    );
    await _preferences.setBool(
      uploadThumbnailsKey,
      preferences.uploadThumbnailsConsented,
    );
    _controller.add(preferences);
  }

  static ThemeMode _readThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _writeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
