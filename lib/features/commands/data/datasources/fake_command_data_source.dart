import 'dart:async';

import '../../../../core/constants/demo_ids.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/repositories/command_repository.dart';
import '../repositories/command_repository_impl.dart';
import 'command_data_source.dart';

/// Sumber data perintah simulasi untuk mode pengembang.
///
/// Data disimpan in-memory dan hilang saat aplikasi ditutup, sesuai sifat
/// simulasi. Simulasi meniru alur device: perintah baru berstatus `pending`
/// lalu otomatis maju ke `done` supaya UI status bisa diuji end-to-end
/// tanpa hardware.
class FakeCommandDataSource implements CommandDataSource {
  final StreamController<List<DeviceCommand>> _controller =
      StreamController<List<DeviceCommand>>.broadcast();

  List<DeviceCommand> _items = _sample();

  int _counter = 0;

  void _emit() {
    _controller.add(List<DeviceCommand>.unmodifiable(_sorted()));
  }

  List<DeviceCommand> _sorted() {
    final sorted = List<DeviceCommand>.of(_items);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Isi saat ini, dipakai test dan demo reset.
  List<DeviceCommand> get itemsForTest =>
      List<DeviceCommand>.unmodifiable(_sorted());

  @override
  Stream<List<DeviceCommand>> watchCommands({
    required String deviceId,
    int limit = 20,
  }) {
    if (deviceId != kDemoDeviceId) {
      return Stream<List<DeviceCommand>>.value(const <DeviceCommand>[]);
    }
    final initial = _sorted().take(limit).toList(growable: false);
    return Stream<List<DeviceCommand>>.multi((controller) {
      controller.add(initial);
      final subscription = _controller.stream.listen((_) {
        controller.add(_sorted().take(limit).toList(growable: false));
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<DeviceCommand?> watchCommand({
    required String deviceId,
    required String commandId,
  }) {
    DeviceCommand? current() {
      for (final item in _items) {
        if (item.id == commandId) return item;
      }
      return null;
    }

    return Stream<DeviceCommand?>.multi((controller) {
      controller.add(current());
      final subscription = _controller.stream.listen((_) {
        controller.add(current());
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<String> sendCommand({
    required String deviceId,
    required CommandType type,
    required Map<String, Object?> payload,
    required String? requestedBy,
  }) async {
    final id = 'cmd-simulasi-${++_counter}';
    _items = [
      DeviceCommand(
        id: id,
        deviceId: deviceId,
        type: type,
        status: CommandStatus.pending,
        createdAt: DateTime.now(),
        payload: payload,
        requestedBy: requestedBy,
      ),
      ..._items,
    ];
    _emit();
    // Tiru device: ack lalu selesai shortly after.
    Timer(const Duration(seconds: 1), () => _advance(id, CommandStatus.acked));
    Timer(const Duration(seconds: 2), () => _advance(id, CommandStatus.done));
    return id;
  }

  void _advance(String id, CommandStatus status) {
    _items = [
      for (final item in _items)
        if (item.id == id) item.copyWith(status: status) else item,
    ];
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}

List<DeviceCommand> _sample() {
  final now = DateTime.now();
  return [
    DeviceCommand(
      id: 'cmd-sync-1',
      deviceId: kDemoDeviceId,
      type: CommandType.syncNow,
      status: CommandStatus.done,
      createdAt: now.subtract(const Duration(minutes: 6)),
      requestedBy: kDemoUserId,
      resultNote: 'Sinkronisasi selesai.',
    ),
    DeviceCommand(
      id: 'cmd-restart-1',
      deviceId: kDemoDeviceId,
      type: CommandType.restart,
      status: CommandStatus.failed,
      createdAt: now.subtract(const Duration(minutes: 2)),
      requestedBy: kDemoUserId,
      resultNote: 'Perangkat tidak merespons.',
    ),
  ];
}

/// Implementasi [CommandRepository] untuk data simulasi.
class FakeCommandRepositoryImpl extends CommandRepositoryImpl {
  FakeCommandRepositoryImpl(super.dataSource);
}
