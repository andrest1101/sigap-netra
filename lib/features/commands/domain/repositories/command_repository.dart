import '../../../commands/domain/entities/device_command.dart';

/// Kontrak repository perintah pada domain.
///
/// Firestore repository belum diimplementasikan karena payload command,
/// peran pengirim, dan security masih berstatus `[PERLU KONFIRMASI]`.
abstract interface class CommandRepository {
  /// Memantau status perintah satu perangkat atau semua perangkat.
  Stream<List<DeviceCommand>> watchCommands({String? deviceId, int limit = 20});

  /// Mengirim perintah baru dengan status awal `pending`.
  Future<void> sendCommand({
    required String deviceId,
    required CommandType type,
    required String? requestedBy,
  });
}
