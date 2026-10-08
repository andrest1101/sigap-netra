import '../../../commands/domain/entities/device_command.dart';
import '../repositories/command_repository.dart';

/// Kontrak pemantauan perintah.
class WatchCommands {
  const WatchCommands(this._repository);

  final CommandRepository _repository;

  Stream<List<DeviceCommand>> call({String? deviceId, int limit = 20}) {
    return _repository.watchCommands(deviceId: deviceId, limit: limit);
  }
}

/// Kontrak pengiriman perintah baru.
class SendCommand {
  const SendCommand(this._repository);

  final CommandRepository _repository;

  Future<void> call({
    required String deviceId,
    required CommandType type,
    required String? requestedBy,
  }) {
    return _repository.sendCommand(
      deviceId: deviceId,
      type: type,
      requestedBy: requestedBy,
    );
  }
}
