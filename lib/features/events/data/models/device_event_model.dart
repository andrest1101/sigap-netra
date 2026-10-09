import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/device_event.dart';

/// Nama field Firestore untuk dokumen event.
///
/// Satu-satunya tempat yang menulis nama field ini di sisi aplikasi, sesuai
/// `docs/firestore_schema.md` bagian 4.4.
abstract final class DeviceEventFields {
  static const String type = 'type';
  static const String severity = 'severity';
  static const String message = 'message';
  static const String createdAt = 'createdAt';

  /// Nilai enum `severity` di Firestore.
  static const String severityInfo = 'info';
  static const String severityWarning = 'warning';
  static const String severityError = 'error';
}

/// Pemetaan dokumen Firestore ke entity domain [DeviceEvent].
///
/// Hanya file ini yang boleh tahu nama field Firestore. `type` diteruskan
/// mentah karena daftar finalnya masih `[PERLU KONFIRMASI]` (skema 4.4);
/// kode tidak mengasumsikan daftar tertutup.
abstract final class DeviceEventModel {
  /// Konversi snapshot event menjadi entity domain.
  static DeviceEvent fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String deviceId,
  }) {
    return fromData(data: snapshot.data(), id: snapshot.id, deviceId: deviceId);
  }

  /// Konversi map mentah menjadi entity domain.
  ///
  /// Dipisah dari [fromDocument] agar pemetaan bisa diuji tanpa Firestore.
  /// [data] boleh null untuk dokumen yang belum punya field apa pun.
  static DeviceEvent fromData({
    required Map<String, dynamic>? data,
    required String id,
    required String deviceId,
  }) {
    final fields = data ?? const <String, dynamic>{};
    return DeviceEvent(
      id: id,
      deviceId: deviceId,
      type: _readString(fields[DeviceEventFields.type]) ?? 'unknown',
      severity: _readSeverity(fields[DeviceEventFields.severity]),
      message: _readString(fields[DeviceEventFields.message]) ?? '',
      createdAt:
          _readTimestamp(fields[DeviceEventFields.createdAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static EventSeverity _readSeverity(Object? raw) {
    if (raw == DeviceEventFields.severityWarning) return EventSeverity.warning;
    if (raw == DeviceEventFields.severityError) return EventSeverity.error;
    return EventSeverity.info;
  }

  static DateTime? _readTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  static String? _readString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}
