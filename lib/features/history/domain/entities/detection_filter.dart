import 'package:equatable/equatable.dart';

import '../../../monitoring/domain/entities/detection.dart';

/// Filter riwayat pembacaan pada domain.
///
/// Dipakai bersama oleh daftar (jenis + status + perangkat) dan panel
/// Statistik (rentang waktu [since]/[before]). Rentang waktu memakai
/// `createdAt` — waktu pembacaan dibuat — bukan `validatedAt`, supaya angka
/// panel statistik selalu sepakat dengan tanggal yang tampil di daftar.
class DetectionFilter extends Equatable {
  const DetectionFilter({
    this.type,
    this.status,
    this.deviceId,
    this.since,
    this.before,
  });

  final DetectionType? type;
  final ValidationStatus? status;
  final String? deviceId;

  /// Batas bawah `createdAt`, inklusif. Null = tanpa batas bawah.
  final DateTime? since;

  /// Batas atas `createdAt`, eksklusif. Null = tanpa batas atas.
  final DateTime? before;

  /// Salinan dengan field yang diisi; parameter null berarti "pertahankan".
  ///
  /// Untuk menghapus batas rentang, bangun filter baru — `since`/`before`
  /// sengaja tidak bisa di-null-kan lewat `copyWith` (kesalahan mudah terjadi
  /// bila "filter tanpa batas" tidak disengaja).
  DetectionFilter copyWith({
    DetectionType? type,
    ValidationStatus? status,
    String? deviceId,
    DateTime? since,
    DateTime? before,
  }) {
    return DetectionFilter(
      type: type ?? this.type,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      since: since ?? this.since,
      before: before ?? this.before,
    );
  }

  /// Apakah [detection] lolos filter ini (predikat murni, dipakai sumber data
  /// simulasi dan test).
  bool matches(Detection detection) {
    final since = this.since;
    final before = this.before;
    return (type == null || detection.type == type) &&
        (status == null || detection.validationStatus == status) &&
        (deviceId == null || detection.deviceId == deviceId) &&
        (since == null || !detection.createdAt.isBefore(since)) &&
        (before == null || detection.createdAt.isBefore(before));
  }

  @override
  List<Object?> get props => [type, status, deviceId, since, before];
}
