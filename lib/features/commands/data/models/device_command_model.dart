import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/device_command.dart';

/// Nama field Firestore untuk dokumen perintah.
///
/// Satu-satunya tempat yang menulis nama field ini di sisi aplikasi, sesuai
/// `docs/firestore_schema.md` bagian 4.5.
abstract final class DeviceCommandFields {
  static const String type = 'type';
  static const String payload = 'payload';
  static const String status = 'status';
  static const String requestedBy = 'requestedBy';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String resultNote = 'resultNote';

  /// Nilai enum `type` di Firestore.
  static const String typeSyncNow = 'sync_now';
  static const String typeSpeakText = 'speak_text';
  static const String typeSetVolume = 'set_volume';
  static const String typeRestart = 'restart';
  static const String typeReprovision = 'reprovision';

  /// Nilai enum `status` di Firestore.
  static const String statusPending = 'pending';
  static const String statusSent = 'sent';
  static const String statusAcked = 'acked';
  static const String statusDone = 'done';
  static const String statusFailed = 'failed';
}

/// Pemetaan dokumen Firestore ke entity domain [DeviceCommand].
///
/// Hanya file ini yang boleh tahu nama field Firestore. Aplikasi hanya
/// menulis dokumen baru dengan status `pending`; transisi status ditulis
/// device (`docs/firestore_schema.md` bagian 1).
abstract final class DeviceCommandModel {
  /// Konversi snapshot perintah menjadi entity domain.
  static DeviceCommand fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String deviceId,
  }) {
    return fromData(data: snapshot.data(), id: snapshot.id, deviceId: deviceId);
  }

  /// Konversi map mentah menjadi entity domain.
  ///
  /// Dipisah dari [fromDocument] agar pemetaan bisa diuji tanpa Firestore.
  /// [data] boleh null untuk dokumen yang belum punya field apa pun.
  static DeviceCommand fromData({
    required Map<String, dynamic>? data,
    required String id,
    required String deviceId,
  }) {
    final fields = data ?? const <String, dynamic>{};
    return DeviceCommand(
      id: id,
      deviceId: deviceId,
      type: _readType(fields[DeviceCommandFields.type]),
      status: _readStatus(fields[DeviceCommandFields.status]),
      createdAt:
          _readTimestamp(fields[DeviceCommandFields.createdAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      payload: _readPayload(fields[DeviceCommandFields.payload]),
      requestedBy: _readString(fields[DeviceCommandFields.requestedBy]),
      updatedAt: _readTimestamp(fields[DeviceCommandFields.updatedAt]),
      resultNote: _readString(fields[DeviceCommandFields.resultNote]),
    );
  }

  /// Map dokumen perintah baru untuk tulis app.
  ///
  /// Status selalu `pending`, `createdAt` memakai server timestamp.
  /// `payload` wajib kosong untuk `sync_now`/`restart`/`reprovision` dan
  /// tidak pernah membawa kredensial Wi-Fi.
  static Map<String, Object?> createDocument({
    required CommandType type,
    required Map<String, Object?> payload,
    required String? requestedBy,
  }) {
    return <String, Object?>{
      DeviceCommandFields.type: _writeType(type),
      DeviceCommandFields.payload: payload,
      DeviceCommandFields.status: DeviceCommandFields.statusPending,
      DeviceCommandFields.requestedBy: requestedBy,
      DeviceCommandFields.createdAt: FieldValue.serverTimestamp(),
    };
  }

  static CommandType _readType(Object? raw) {
    switch (raw) {
      case DeviceCommandFields.typeSpeakText:
        return CommandType.speakText;
      case DeviceCommandFields.typeSetVolume:
        return CommandType.setVolume;
      case DeviceCommandFields.typeRestart:
        return CommandType.restart;
      case DeviceCommandFields.typeReprovision:
        return CommandType.reprovision;
      case DeviceCommandFields.typeSyncNow:
      default:
        // Default `syncNow` untuk nilai tak dikenal supaya daftar tetap
        // tampil; nilai mentah tidak disimpan.
        return CommandType.syncNow;
    }
  }

  static String _writeType(CommandType type) {
    switch (type) {
      case CommandType.syncNow:
        return DeviceCommandFields.typeSyncNow;
      case CommandType.speakText:
        return DeviceCommandFields.typeSpeakText;
      case CommandType.setVolume:
        return DeviceCommandFields.typeSetVolume;
      case CommandType.restart:
        return DeviceCommandFields.typeRestart;
      case CommandType.reprovision:
        return DeviceCommandFields.typeReprovision;
    }
  }

  static CommandStatus _readStatus(Object? raw) {
    switch (raw) {
      case DeviceCommandFields.statusSent:
        return CommandStatus.sent;
      case DeviceCommandFields.statusAcked:
        return CommandStatus.acked;
      case DeviceCommandFields.statusDone:
        return CommandStatus.done;
      case DeviceCommandFields.statusFailed:
        return CommandStatus.failed;
      case DeviceCommandFields.statusPending:
      default:
        return CommandStatus.pending;
    }
  }

  static Map<String, Object?> _readPayload(Object? raw) {
    if (raw is! Map) return const <String, Object?>{};
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is String) result[key] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(result);
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
