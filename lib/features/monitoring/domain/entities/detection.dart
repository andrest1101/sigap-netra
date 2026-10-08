import 'package:equatable/equatable.dart';

/// Jenis pembacaan dari perangkat.
enum DetectionType { money, text }

/// Status validasi manusia untuk satu pembacaan.
enum ValidationStatus { pending, match, mismatch }

/// Pembacaan dari perangkat, dipakai untuk Validasi dan Riwayat.
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
    validationStatus,
    validatedBy,
    validatedAt,
  ];
}
