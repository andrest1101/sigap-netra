import '../entities/device_command.dart';
import '../repositories/command_repository.dart';

/// Kontrak pemantauan perintah satu perangkat.
class WatchCommands {
  const WatchCommands(this._repository);

  final CommandRepository _repository;

  Stream<List<DeviceCommand>> call({required String deviceId, int limit = 20}) {
    return _repository.watchCommands(deviceId: deviceId, limit: limit);
  }
}

/// Kontrak pemantauan satu perintah.
class WatchCommand {
  const WatchCommand(this._repository);

  final CommandRepository _repository;

  Stream<DeviceCommand?> call({
    required String deviceId,
    required String commandId,
  }) {
    return _repository.watchCommand(deviceId: deviceId, commandId: commandId);
  }
}

/// Kontrak pengiriman perintah baru dengan status awal `pending`.
///
/// Mengembalikan ID dokumen perintah yang dibuat.
class SendCommand {
  const SendCommand(this._repository);

  final CommandRepository _repository;

  Future<String> call({
    required String deviceId,
    required CommandType type,
    Map<String, Object?> payload = const {},
    required String? requestedBy,
  }) {
    return _repository.sendCommand(
      deviceId: deviceId,
      type: type,
      payload: payload,
      requestedBy: requestedBy,
    );
  }
}
