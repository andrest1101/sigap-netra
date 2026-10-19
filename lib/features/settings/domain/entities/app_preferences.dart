import 'package:equatable/equatable.dart';

/// Preferensi aplikasi pendamping (disimpan lokal di perangkat pengguna).
///
/// Berbeda dengan `DeviceSettings` (pengaturan milik device di Firestore):
/// objek ini hanya tentang aplikasi — izin privasi lokal.
///
/// Catatan: aplikasi terang-saja (keputusan produk 2026-10-18), jadi tidak ada
/// lagi preferensi tema di sini.
class AppPreferences extends Equatable {
  const AppPreferences({this.uploadThumbnailsConsented = false});

  /// Apakah pengguna sudah menyetujui opt-in thumbnail lewat dialog consent
  /// eksplisit (PRD F8). Default `false`; persetujuan dapat dicabut kapan saja.
  final bool uploadThumbnailsConsented;

  AppPreferences copyWith({bool? uploadThumbnailsConsented}) {
    return AppPreferences(
      uploadThumbnailsConsented:
          uploadThumbnailsConsented ?? this.uploadThumbnailsConsented,
    );
  }

  @override
  List<Object?> get props => [uploadThumbnailsConsented];
}
