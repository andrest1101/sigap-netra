import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/device.dart';

/// Pemetaan dokumen Firestore ke entity domain [Device].
///
/// Hanya file ini yang boleh tahu nama field Firestore. Selain `lastSeen`,
/// semua field boleh null karena perangkat yang baru menyala atau firmware lama
/// bisa belum mengisinya.
abstract final class DeviceModel {
  /// Konversi snapshot perangkat menjadi entity domain.
  ///
  /// [now] dioper masuk supaya pemetaan deterministik dan bisa diuji.
  static Device fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required DateTime now,
  }) {
    return fromData(data: snapshot.data(), deviceId: snapshot.id, now: now);
  }

  /// Konversi map mentah menjadi entity domain.
  ///
  /// Dipisah dari [fromDocument] agar pemetaan bisa diuji tanpa Firestore.
  /// [data] boleh null untuk dokumen yang belum punya field apa pun.
  static Device fromData({
    required Map<String, dynamic>? data,
    required String deviceId,
    required DateTime now,
  }) {
    final fields = data ?? const <String, dynamic>{};
    final lastSeen = _readTimestamp(fields['lastSeen']);
    final rawName = fields['name'];

    return Device(
      deviceId: deviceId,
      // Nama kosong harus jatuh ke deviceId agar UI tidak pernah menampilkan
      // string kosong di header.
      name: rawName is String && rawName.isNotEmpty ? rawName : deviceId,
      connectivity: deriveConnectivity(lastSeen: lastSeen, now: now),
      model: _readString(fields['model']),
      firmwareVersion: _readString(fields['firmwareVersion']),
      wifiSsid: _readString(fields['wifiSsid']),
      lastSeen: lastSeen,
      bootCount: _readInt(fields['bootCount']),
      settings: _readSettings(fields['settings']),
    );
  }

  static DeviceSettings _readSettings(Object? raw) {
    if (raw is! Map) return const DeviceSettings();
    return DeviceSettings(
      uploadThumbnails: raw['uploadThumbnails'] == true,
      uploadText: raw['uploadText'] == true,
    );
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

  /// Path dokumen perangkat, dipakai ulang agar sinkron dengan
  /// `firestore_paths.dart`.
  static String docPath(String deviceId) => deviceDocPath(deviceId);
}
