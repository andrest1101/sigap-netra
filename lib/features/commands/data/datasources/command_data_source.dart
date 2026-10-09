import '../../domain/entities/device_command.dart';

/// Kontrak sumber data perintah pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
///
/// App hanya membuat dokumen baru dengan status `pending`; transisi status
/// ditulis device (`docs/firestore_schema.md` bagian 1).
abstract interface class CommandDataSource {
  Stream<List<DeviceCommand>> watchCommands({
    required String deviceId,
    int limit = 20,
  });

  Stream<DeviceCommand?> watchCommand({
    required String deviceId,
    required String commandId,
  });

  Future<String> sendCommand({
    required String deviceId,
    required CommandType type,
    required Map<String, Object?> payload,
    required String? requestedBy,
  });
}
