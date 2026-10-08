import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/data_source.dart';

/// Menyimpan preferensi aplikasi di penyimpanan lokal.
///
/// Di-override di `main.dart` dengan instance yang sudah dimuat, dan di test
/// dengan `SharedPreferences.setMockInitialValues`. Sengaja di-throw di default
/// supaya kelewatan inisialisasi ketahuan saat runtime, bukan saat test gagal
/// dengan pesan membingungkan.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider harus di-override di main.dart atau test.',
  ),
);

/// Mode pengembang.
///
/// Saat aktif, seluruh data layer memakai `fake_*_data_source.dart` sehingga
/// aplikasi tetap bisa dipakai tanpa Firebase dan tanpa perangkat keras,
/// artinya fitur dapat dijalankan apa adanya saat tahap pengembangan.
final developerModeProvider = NotifierProvider<DeveloperModeController, bool>(
  DeveloperModeController.new,
);

/// Izin thumbnail pembacaan.
///
/// Default sengaja false. Menyalakannya dibatasi UI privasi dan hanya untuk
/// thumbnail kecil, bukan video/audio/lokasi.
final uploadThumbnailsPrivacyProvider =
    NotifierProvider<UploadThumbnailsPrivacyController, bool>(
      UploadThumbnailsPrivacyController.new,
    );

class UploadThumbnailsPrivacyController extends Notifier<bool> {
  static const String _storageKey = 'upload_thumbnails_privacy';

  @override
  bool build() {
    final preferences = ref.read(sharedPreferencesProvider);
    return preferences.getBool(_storageKey) ?? false;
  }

  Future<void> set(bool value) async {
    if (state == value) return;
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_storageKey, value);
  }

  Future<void> toggle() => set(!state);
}

class DeveloperModeController extends Notifier<bool> {
  static const String _storageKey = 'developer_mode';

  @override
  bool build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return preferences.getBool(_storageKey) ?? false;
  }

  /// Sumber data aktif berdasarkan mode ini.
  DataSource get dataSource =>
      state ? DataSource.simulation : DataSource.firebase;

  /// Mengganti sumber data aktif antara simulasi dan Firebase.
  ///
  /// Data simulasi disimpan in-memory, jadi tenang harus hilang saat mode
  /// dimatikan. Screens yang sedang terbuka perlu di-invalidate oleh router atau
  /// dengan me-refresh provider masing-masing.
  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(_storageKey, state);
  }

  /// Mengatur mode pengembang secara eksplisit, dipakai oleh test.
  Future<void> set(bool value) async {
    if (state == value) return;
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_storageKey, value);
  }
}
