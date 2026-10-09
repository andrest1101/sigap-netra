import '../../domain/entities/app_preferences.dart';

/// Kontrak sumber data preferensi aplikasi pada data layer.
abstract interface class PreferencesDataSource {
  Stream<AppPreferences> watchPreferences();

  Future<void> savePreferences(AppPreferences preferences);
}
