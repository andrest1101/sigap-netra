import '../entities/device_command.dart';

/// Kontrak repository perintah pada domain.
///
/// App hanya boleh membuat dokumen perintah dengan status awal `pending`
/// (`docs/firestore_schema.md` bagian 1). `payload` wajib kosong untuk
/// `sync_now`/`restart`/`reprovision` dan tidak pernah membawa kredensial
/// Wi-Fi (lihat [DeviceCommand.buildPayload]).
abstract interface class CommandRepository {
  /// Memantau status perintah terbaru satu perangkat, terbaru dulu.
  Stream<List<DeviceCommand>> watchCommands({
    required String deviceId,
    int limit = 20,
  });

  /// Memantau satu perintah untuk layar status pengiriman.
  Stream<DeviceCommand?> watchCommand({
    required String deviceId,
    required String commandId,
  });

  /// Mengirim perintah baru dengan status awal `pending`.
  ///
  /// [payload] mengikuti tabel skema bagian 4.5; gunakan
  /// [DeviceCommand.buildPayload] untuk membangunnya dengan aman.
  Future<String> sendCommand({
    required String deviceId,
    required CommandType type,
    required Map<String, Object?> payload,
    required String? requestedBy,
  });
}
