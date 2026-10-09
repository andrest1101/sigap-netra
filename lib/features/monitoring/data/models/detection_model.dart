import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/detection.dart';

/// Nama field Firestore untuk dokumen deteksi.
///
/// Satu-satunya tempat yang menulis nama field ini di sisi aplikasi, sesuai
/// `docs/firestore_schema.md` bagian 4.2.
abstract final class DetectionFields {
  static const String type = 'type';
  static const String label = 'label';
  static const String amount = 'amount';
  static const String currency = 'currency';
  static const String confidence = 'confidence';
  static const String distanceCm = 'distanceCm';
  static const String ocrText = 'ocrText';
  static const String thumbnailId = 'thumbnailId';
  static const String validationStatus = 'validationStatus';
  static const String validatedBy = 'validatedBy';
  static const String validatedAt = 'validatedAt';
  static const String createdAt = 'createdAt';

  /// Nilai enum `type` di Firestore.
  static const String typeMoney = 'money';
  static const String typeText = 'text';

  /// Nilai enum `validationStatus` di Firestore.
  static const String statusPending = 'pending';
  static const String statusMatch = 'match';
  static const String statusMismatch = 'mismatch';
}

/// Pemetaan dokumen Firestore ke entity domain [Detection].
///
/// Hanya file ini yang boleh tahu nama field Firestore. Semua field opsional
/// dipetakan defensif karena firmware lama bisa tidak mengirim field baru
/// (backward compatibility, `docs/device_protocol.md` bagian 10).
abstract final class DetectionModel {
  /// Konversi snapshot deteksi menjadi entity domain.
  ///
  /// [deviceId] dan [deviceName] dioper masuk karena dokumen deteksi tidak
  /// menyimpan nama tampilan perangkat; nama diambil dari dokumen perangkat
  /// (join client-side). [now] tidak dipakai di sini tetapi dipertahankan
  /// untuk konsistensi pola pemetaan deterministik.
  static Detection fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String deviceId,
    required String deviceName,
  }) {
    return fromData(
      data: snapshot.data(),
      id: snapshot.id,
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }

  /// Konversi map mentah menjadi entity domain.
  ///
  /// Dipisah dari [fromDocument] agar pemetaan bisa diuji tanpa Firestore.
  /// [data] boleh null untuk dokumen yang belum punya field apa pun.
  static Detection fromData({
    required Map<String, dynamic>? data,
    required String id,
    required String deviceId,
    required String deviceName,
  }) {
    final fields = data ?? const <String, dynamic>{};
    return Detection(
      id: id,
      deviceId: deviceId,
      deviceName: deviceName,
      type: _readType(fields[DetectionFields.type]),
      createdAt:
          _readTimestamp(fields[DetectionFields.createdAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      amount: _readInt(fields[DetectionFields.amount]),
      currency: _readString(fields[DetectionFields.currency]) ?? 'IDR',
      label: _readString(fields[DetectionFields.label]),
      confidence: _readConfidence(fields[DetectionFields.confidence]),
      distanceCm: _readInt(fields[DetectionFields.distanceCm]),
      ocrText: _readOcrText(fields[DetectionFields.ocrText]),
      thumbnailId: _readString(fields[DetectionFields.thumbnailId]),
      validationStatus: _readValidationStatus(
        fields[DetectionFields.validationStatus],
      ),
      validatedBy: _readString(fields[DetectionFields.validatedBy]),
      validatedAt: _readTimestamp(fields[DetectionFields.validatedAt]),
    );
  }

  /// Map update validasi untuk tulis app.
  ///
  /// Hanya tiga field ini yang boleh ditulis app
  /// (`docs/firestore_schema.md` bagian 1). `validatedAt` memakai server
  /// timestamp agar urutan tidak bergantung pada jam perangkat pengguna.
  static Map<String, Object?> validationUpdate({
    required ValidationStatus status,
    required String? validatedBy,
  }) {
    return <String, Object?>{
      DetectionFields.validationStatus: _writeValidationStatus(status),
      DetectionFields.validatedBy: validatedBy,
      DetectionFields.validatedAt: FieldValue.serverTimestamp(),
    };
  }

  static DetectionType _readType(Object? raw) {
    if (raw == DetectionFields.typeText) return DetectionType.text;
    // Default `money` untuk nilai tak dikenal supaya kartu tetap tampil
    // daripada seluruh daftar gagal; nilai mentah tidak disimpan.
    return DetectionType.money;
  }

  static ValidationStatus _readValidationStatus(Object? raw) {
    if (raw == DetectionFields.statusMatch) return ValidationStatus.match;
    if (raw == DetectionFields.statusMismatch) {
      return ValidationStatus.mismatch;
    }
    return ValidationStatus.pending;
  }

  static String _writeValidationStatus(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.match:
        return DetectionFields.statusMatch;
      case ValidationStatus.mismatch:
        return DetectionFields.statusMismatch;
      case ValidationStatus.pending:
        return DetectionFields.statusPending;
    }
  }

  static double? _readConfidence(Object? raw) {
    if (raw is num) return raw.toDouble().clamp(0.0, 1.0);
    return null;
  }

  /// Membaca teks OCR dengan pemotongan pengaman di sisi app.
  ///
  /// Device seharusnya sudah memotong 500 karakter, tetapi app memotong lagi
  /// sebagai pengaman (`docs/firestore_schema.md` bagian 4.2).
  static String? _readOcrText(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    if (raw.length <= kMaxOcrTextLength) return raw;
    return raw.substring(0, kMaxOcrTextLength);
  }

  static DateTime? _readTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    // Device yang menulis lewat REST mungkin mengirim milidetik sebagai angka.
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  static String? _readString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  static int? _readInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }
}
