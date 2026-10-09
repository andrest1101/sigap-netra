import 'package:equatable/equatable.dart';

/// Jenis pembacaan dari perangkat.
enum DetectionType { money, text }

/// Status validasi manusia untuk satu pembacaan.
enum ValidationStatus { pending, match, mismatch }

/// Pembacaan dari perangkat, dipakai untuk Validasi dan Riwayat.
///
/// Nama field mengikuti `docs/firestore_schema.md` bagian 4.2. `deviceName`
/// bukan field Firestore: diisi dari dokumen perangkat (join client-side)
/// supaya nama tampilan tidak diduplikasi di setiap dokumen deteksi.
class Detection extends Equatable {
  const Detection({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.createdAt,
    this.amount,
    this.currency = 'IDR',
    this.label,
    this.confidence,
    this.distanceCm,
    this.ocrText,
    this.thumbnailId,
    this.processingMs,
    this.seq,
    this.validationStatus = ValidationStatus.pending,
    this.validatedBy,
    this.validatedAt,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final DetectionType type;
  final DateTime createdAt;
  final int? amount;
  final String currency;
  final String? label;
  final double? confidence;
  final int? distanceCm;
  final String? ocrText;

  /// ID dokumen di subkoleksi `media`. Null bila opt-in thumbnail mati atau
  /// thumbnail gagal dibuat. App memuat gambar lewat ID ini, tidak pernah
  /// lewat query daftar (skema bagian 4.3).
  final String? thumbnailId;

  /// [PERLU KONFIRMASI] Metadata debug opsional, bukan bagian skema final.
  /// Reader harus tahan bila field ini hilang.
  final int? processingMs;
  final int? seq;
  final ValidationStatus validationStatus;
  final String? validatedBy;
  final DateTime? validatedAt;

  Detection withValidationStatus({
    required ValidationStatus validationStatus,
    required String? validatedBy,
    required DateTime? validatedAt,
  }) {
    return Detection(
      id: id,
      deviceId: deviceId,
      deviceName: deviceName,
      type: type,
      createdAt: createdAt,
      amount: amount,
      currency: currency,
      label: label,
      confidence: confidence,
      distanceCm: distanceCm,
      ocrText: ocrText,
      thumbnailId: thumbnailId,
      processingMs: processingMs,
      seq: seq,
      validationStatus: validationStatus,
      validatedBy: validatedBy,
      validatedAt: validatedAt,
    );
  }

  /// Nama pendek lazim, untuk ringkasan kartu.
  String get displayLabel {
    if (type == DetectionType.money) {
      final amountText = amount == null ? '-' : 'Rp $amount';
      return '$amountText${label == null ? '' : ' - $label'}';
    }
    final text = ocrText ?? label ?? '-';
    return text.length > 80 ? '${text.substring(0, 80)}...' : text;
  }

  @override
  List<Object?> get props => [
    id,
    deviceId,
    deviceName,
    type,
    createdAt,
    amount,
    currency,
    label,
    confidence,
    distanceCm,
    ocrText,
    thumbnailId,
    processingMs,
    seq,
    validationStatus,
    validatedBy,
    validatedAt,
  ];
}
