import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Status konektivitas sebuah perangkat.
///
/// Selalu dihitung di sisi klien dari selisih `now - lastSeen`, tidak pernah
/// dipercaya dari field yang tersimpan di Firestore. Lihat
/// `deriveConnectivity()`.
enum DeviceConnectivity {
  /// `lastSeen` lebih baru dari 90 detik.
  online,

  /// Ada `lastSeen` tetapi sudah melewati ambang.
  offline,

  /// Perangkat pernah terlihat tetapi waktu saat ini belum diketahui, jadi
  /// status tidak boleh diklaim sebagai online maupun terputus.
  unknown,
}

/// Rumus status konektivitas yang dipakai seluruh aplikasi.
///
/// [lastSeen] boleh null: perangkat yang belum pernah mengirim heartbeat tidak
/// boleh ditampilkan sebagai online. Fungsi murni, jadi mudah diuji tanpa
/// Firestore maupun widget.
DeviceConnectivity deriveConnectivity({
  DateTime? lastSeen,
  required DateTime now,
  int thresholdSeconds = kDeviceOnlineThresholdSeconds,
}) {
  if (lastSeen == null) return DeviceConnectivity.unknown;

  final elapsed = now.difference(lastSeen);
  if (elapsed.isNegative) return DeviceConnectivity.online;

  return elapsed.inSeconds < thresholdSeconds
      ? DeviceConnectivity.online
      : DeviceConnectivity.offline;
}

/// Preferensi yang tersimpan pada dokumen perangkat.
///
/// `uploadThumbnails` bersifat opt-in dan default `false` karena thumbnail
/// adalah satu-satunya data gambar yang boleh keluar dari perangkat.
class DeviceSettings extends Equatable {
  const DeviceSettings({
    this.uploadThumbnails = false,
    this.uploadText = false,
  });

  final bool uploadThumbnails;
  final bool uploadText;

  DeviceSettings copyWith({bool? uploadThumbnails, bool? uploadText}) {
    return DeviceSettings(
      uploadThumbnails: uploadThumbnails ?? this.uploadThumbnails,
      uploadText: uploadText ?? this.uploadText,
    );
  }

  @override
  List<Object?> get props => [uploadThumbnails, uploadText];
}

/// Dokumen perangkat yang dibaca aplikasi.
///
/// Sepenuhnya read-only dari sisi aplikasi: aplikasi tidak pernah menulis
/// dokumen ini.
class Device extends Equatable {
  const Device({
    required this.deviceId,
    required this.name,
    required this.connectivity,
    this.model,
    this.firmwareVersion,
    this.wifiSsid,
    this.lastSeen,
    this.bootCount,
    this.batteryPct,
    this.members = const <String, String>{},
    this.createdAt,
    this.updatedAt,
    this.settings = const DeviceSettings(),
  });

  final String deviceId;
  final String name;
  final DeviceConnectivity connectivity;
  final String? model;
  final String? firmwareVersion;

  /// SSID tujuan yang tersimpan di perangkat. Bukan kata sandi: kata sandi
  /// tidak pernah disimpan di aplikasi maupun Firestore.
  final String? wifiSsid;

  final DateTime? lastSeen;
  final int? bootCount;

  /// Persentase baterai 0-100, atau null bila tidak ada sensor.
  ///
  /// [PERLU KONFIRMASI] Keberadaan baterai belum dikonfirmasi tim hardware
  /// (`docs/firestore_schema.md` bagian 4.1). Field ini opsional dan UI wajib
  /// menampilkan "-" bila null; jangan pernah memalsukan nilai.
  final int? batteryPct;

  /// Keanggotaan perangkat: map UID ke role.
  ///
  /// [PERLU KONFIRMASI] Daftar role final dan siapa yang menulis `members`
  /// belum diputuskan owner (`docs/firestore_schema.md` bagian 6). Sampai
  /// itu, kode aplikasi hanya memakai kunci (UID) untuk filter query, bukan
  /// nilai role sebagai sumber kebenaran otorisasi.
  final Map<String, String> members;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DeviceSettings settings;

  /// Menghitung ulang status konektivitas terhadap waktu [now].
  Device withConnectivity(DateTime now) => copyWith(
    connectivity: deriveConnectivity(lastSeen: lastSeen, now: now),
  );

  Device copyWith({
    String? name,
    DeviceConnectivity? connectivity,
    String? model,
    String? firmwareVersion,
    String? wifiSsid,
    DateTime? lastSeen,
    int? bootCount,
    int? batteryPct,
    Map<String, String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    DeviceSettings? settings,
  }) {
    return Device(
      deviceId: deviceId,
      name: name ?? this.name,
      connectivity: connectivity ?? this.connectivity,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      lastSeen: lastSeen ?? this.lastSeen,
      bootCount: bootCount ?? this.bootCount,
      batteryPct: batteryPct ?? this.batteryPct,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    name,
    connectivity,
    model,
    firmwareVersion,
    wifiSsid,
    lastSeen,
    bootCount,
    batteryPct,
    members,
    createdAt,
    updatedAt,
    settings,
  ];
}
