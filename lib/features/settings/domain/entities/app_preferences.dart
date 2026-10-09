import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Preferensi aplikasi pendamping (disimpan lokal di perangkat pengguna).
///
/// Berbeda dengan `DeviceSettings` (pengaturan milik device di Firestore):
/// objek ini hanya tentang aplikasi — tema dan izin privasi lokal.
class AppPreferences extends Equatable {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.uploadThumbnailsConsented = false,
  });

  /// Mode tema aplikasi. Default mengikuti sistem (ui_spec bagian 1).
  final ThemeMode themeMode;

  /// Apakah pengguna sudah menyetujui opt-in thumbnail lewat dialog consent
  /// eksplisit (PRD F8). Default `false`; persetujuan dapat dicabut kapan saja.
  final bool uploadThumbnailsConsented;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? uploadThumbnailsConsented,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      uploadThumbnailsConsented:
          uploadThumbnailsConsented ?? this.uploadThumbnailsConsented,
    );
  }

  @override
  List<Object?> get props => [themeMode, uploadThumbnailsConsented];
}
