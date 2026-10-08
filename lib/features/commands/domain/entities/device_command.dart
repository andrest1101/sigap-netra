import 'package:equatable/equatable.dart';

enum CommandType { syncNow, speakText, setVolume, restart, reprovision }

enum CommandStatus { pending, sent, acked, done, failed }

class DeviceCommand extends Equatable {
  const DeviceCommand({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.requestedBy,
    this.resultNote,
  });

  final String id;
  final String deviceId;
  final CommandType type;
  final CommandStatus status;
  final DateTime createdAt;
  final String? requestedBy;
  final String? resultNote;

  DeviceCommand copyWith({CommandStatus? status, String? resultNote}) {
    return DeviceCommand(
      id: id,
      deviceId: deviceId,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      requestedBy: requestedBy,
      resultNote: resultNote,
    );
  }

  @override
  List<Object?> get props => [
    id,
    deviceId,
    type,
    status,
    createdAt,
    requestedBy,
    resultNote,
  ];
}
