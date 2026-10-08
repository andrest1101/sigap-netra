import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/devices/data/datasources/device_data_source.dart';
import 'package:sigap_netra_app/features/devices/data/repositories/device_repository_impl.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';

void main() {
  group('DeviceRepositoryImpl', () {
    test('meneruskan daftar perangkat dari data source', () async {
      final source = _ControlledDeviceDataSource()
        ..addDevices([
          Device(
            deviceId: 'dev-1',
            name: 'Kacamata Kamar',
            connectivity: DeviceConnectivity.online,
            lastSeen: DateTime(2026, 10, 8, 12),
          ),
        ]);
      final repository = DeviceRepositoryImpl(source);

      final devices = await repository.watchMyDevices().first;

      expect(devices, hasLength(1));
      expect(devices.single.deviceId, 'dev-1');
      expect(devices.single.name, 'Kacamata Kamar');
    });

    test('meneruskan detail perangkat yang ditemukan', () async {
      final source = _ControlledDeviceDataSource()
        ..addDevices([
          Device(
            deviceId: 'dev-1',
            name: 'Kacamata Kamar',
            connectivity: DeviceConnectivity.offline,
            lastSeen: DateTime(2026, 10, 8, 6),
          ),
        ]);
      final repository = DeviceRepositoryImpl(source);

      final device = await repository.watchDevice('dev-1').first;

      expect(device, isNotNull);
      expect(device?.deviceId, 'dev-1');
      expect(device?.connectivity, DeviceConnectivity.offline);
    });

    test('stream data yang langmut memuat nilai terbaru', () async {
      final source = _ControlledDeviceDataSource();
      final repository = DeviceRepositoryImpl(source);

      expect(await repository.watchMyDevices().first, isEmpty);

      source.addDevices([
        Device(
          deviceId: 'dev-2',
          name: 'Kacamata Dapur',
          connectivity: DeviceConnectivity.online,
          lastSeen: DateTime(2026, 10, 8, 12),
        ),
      ]);

      final updated = await repository.watchMyDevices().first;
      expect(updated.single.deviceId, 'dev-2');
    });
  });
}

class _ControlledDeviceDataSource implements DeviceDataSource {
  final List<Device> _devices = <Device>[];

  final StreamController<List<Device>> _updates =
      StreamController<List<Device>>.broadcast();

  void addDevices(List<Device> devices) {
    _devices
      ..clear()
      ..addAll(devices);
    _updates.add(List<Device>.unmodifiable(_devices));
  }

  @override
  Stream<List<Device>> watchMyDevices() async* {
    yield List<Device>.unmodifiable(_devices);
    yield* _updates.stream;
  }

  @override
  Stream<Device?> watchDevice(String deviceId) async* {
    Device? currentDevice() {
      for (final device in _devices) {
        if (device.deviceId == deviceId) return device;
      }
      return null;
    }

    yield currentDevice();
    yield* _updates.stream.map((_) => currentDevice());
  }
}
