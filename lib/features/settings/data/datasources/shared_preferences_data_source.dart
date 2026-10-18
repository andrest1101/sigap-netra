import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_preferences.dart';
import 'preferences_data_source.dart';

/// Sumber data preferensi berbasis SharedPreferences (penyimpanan lokal).
///
/// Catatan kontrak: `settings.uploadThumbnails` di Firestore ditulis oleh
/// device, bukan app (`docs/firestore_schema.md` bagian 5). Consent lokal di
/// sini adalah izin pengguna di sisi aplikasi; tidak ada tulis Firestore
/// untuk preferensi ini.
///
/// Aplikasi terang-saja (keputusan produk 2026-10-18) — preferensi tema
/// dihapus; kunci `theme_mode` lama (bila ada di instalasi lawas) diabaikan.
class SharedPreferencesDataSource implements PreferencesDataSource {
  SharedPreferencesDataSource(this._preferences);

  final SharedPreferences _preferences;

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
      uploadThumbnailsConsented:
          _preferences.getBool(uploadThumbnailsKey) ?? false,
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    await _preferences.setBool(
      uploadThumbnailsKey,
      preferences.uploadThumbnailsConsented,
    );
    _controller.add(preferences);
  }
}
