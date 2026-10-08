import 'package:equatable/equatable.dart';

enum EventSeverity { info, warning, error }

class DeviceEvent extends Equatable {
  const DeviceEvent({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String deviceId;
  final String type;
  final EventSeverity severity;
  final String message;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, deviceId, type, severity, message, createdAt];
}
