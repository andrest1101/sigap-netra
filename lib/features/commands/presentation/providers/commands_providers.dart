import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device_command.dart';

/// Riwayat perintah jarak jauh untuk demo UI.
final commandsProvider =
    NotifierProvider<CommandsController, List<DeviceCommand>>(
      CommandsController.new,
    );

class CommandsController extends Notifier<List<DeviceCommand>> {
  /// Contoh UI sementara, bukan antrean Firestore.
  @override
  List<DeviceCommand> build() => _initial();

  void add(DeviceCommand command) {
    state = [command, ...state];
  }

  void updateStatus(String id, CommandStatus status, {String? resultNote}) {
    state = [
      for (final command in state)
        if (command.id == id)
          command.copyWith(status: status, resultNote: resultNote)
        else
          command,
    ];
  }
}

List<DeviceCommand> _initial() {
  final now = DateTime.now();
  return [
    DeviceCommand(
      id: 'cmd-sync-1',
      deviceId: 'simulasi-maixcam-1',
      type: CommandType.syncNow,
      status: CommandStatus.done,
      createdAt: now.subtract(const Duration(minutes: 6)),
      requestedBy: 'simulasi-user-1',
      resultNote: 'Sinkronisasi selesai.',
    ),
    DeviceCommand(
      id: 'cmd-restart-1',
      deviceId: 'simulasi-maixcam-1',
      type: CommandType.restart,
      status: CommandStatus.failed,
      createdAt: now.subtract(const Duration(minutes: 2)),
      requestedBy: 'simulasi-user-1',
      resultNote: 'Perangkat tidak merespons.',
    ),
  ];
}
