import '../../domain/entities/device_command.dart';
import '../../domain/repositories/command_repository.dart';
import '../datasources/command_data_source.dart';

/// Implementasi [CommandRepository] di atas kontrak [CommandDataSource].
class CommandRepositoryImpl implements CommandRepository {
  CommandRepositoryImpl(this._dataSource);

  final CommandDataSource _dataSource;

  @override
  Stream<List<DeviceCommand>> watchCommands({
    required String deviceId,
    int limit = 20,
  }) {
    return _dataSource.watchCommands(deviceId: deviceId, limit: limit);
  }

  @override
  Stream<DeviceCommand?> watchCommand({
    required String deviceId,
    required String commandId,
  }) {
    return _dataSource.watchCommand(deviceId: deviceId, commandId: commandId);
  }

  @override
  Future<String> sendCommand({
    required String deviceId,
    required CommandType type,
    required Map<String, Object?> payload,
    required String? requestedBy,
  }) {
    return _dataSource.sendCommand(
      deviceId: deviceId,
      type: type,
      payload: payload,
      requestedBy: requestedBy,
    );
  }
}
