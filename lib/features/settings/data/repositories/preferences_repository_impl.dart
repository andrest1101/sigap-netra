import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_data_source.dart';

/// Implementasi [PreferencesRepository] di atas kontrak
/// [PreferencesDataSource].
class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._dataSource);

  final PreferencesDataSource _dataSource;

  @override
  Stream<AppPreferences> watchPreferences() => _dataSource.watchPreferences();

  @override
  Future<void> updatePreferences(AppPreferences preferences) {
    return _dataSource.savePreferences(preferences);
  }
}
