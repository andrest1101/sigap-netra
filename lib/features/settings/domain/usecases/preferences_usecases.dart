import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

/// Kontrak pemantauan preferensi aplikasi.
class WatchPreferences {
  const WatchPreferences(this._repository);

  final PreferencesRepository _repository;

  Stream<AppPreferences> call() => _repository.watchPreferences();
}

/// Kontrak penyimpanan preferensi aplikasi.
class UpdatePreferences {
  const UpdatePreferences(this._repository);

  final PreferencesRepository _repository;

  Future<void> call(AppPreferences preferences) {
    return _repository.updatePreferences(preferences);
  }
}
