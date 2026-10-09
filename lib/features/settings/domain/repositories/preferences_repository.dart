import '../entities/app_preferences.dart';

/// Kontrak repository preferensi aplikasi pada domain.
abstract interface class PreferencesRepository {
  /// Memantau preferensi aplikasi.
  Stream<AppPreferences> watchPreferences();

  /// Menyimpan preferensi aplikasi.
  Future<void> updatePreferences(AppPreferences preferences);
}
