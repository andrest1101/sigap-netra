import 'dart:async';

import 'device_data_source.dart';

import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';

/// Sumber data perangkat simulasi untuk mode pengembang.
///
/// Menghasilkan satu perangkat yang bergerak terhadap waktu nyata sehingga
/// status online/terputus benar-benar berubah tanpa perlu perangkat keras.
/// Data disimpan in-memory dan hilang saat aplikasi ditutup, sesuai sifat
/// simulasi.
class FakeDeviceDataSource implements DeviceDataSource {
  // ID perangkat demo lokal. Bukan format `deviceId` Firestore final dan
  // tidak boleh dipakai sebagai sumber kebenaran pairing.
  static const String _deviceId = 'simulasi-maixcam-1';
  static const String _deviceName = 'Kacamata Kamar';
  static const String _deviceModel = 'MaixCAM';

  final StreamController<List<Device>> _devicesController =
      StreamController<List<Device>>.broadcast();

  final StreamController<Device?> _deviceController =
      StreamController<Device?>.broadcast();

  Timer? _heartbeatTimer;

  DateTime _lastSeen = DateTime.now();

  /// `_lastSeen` bergerak maju tiap heartbeat sehingga ambang 90 detik
  /// benar-benar teruji selama pengembangan.
  void start({Duration interval = const Duration(seconds: 30)}) {
    if (_heartbeatTimer != null) return;
    _heartbeatTimer = Timer.periodic(interval, (_) {
      _lastSeen = DateTime.now();
      _emit();
    });
  }

  void _emit() {
    final now = DateTime.now();
    final device = _build(now);
    _devicesController.add([device]);
    _deviceController.add(device);
  }

  Device _build(DateTime now) {
    return Device(
      deviceId: _deviceId,
      name: _deviceName,
      model: _deviceModel,
      firmwareVersion: 'simulasi-1.0.0',
      wifiSsid: 'Jaringan-Rumah',
      lastSeen: _lastSeen,
      bootCount: 42,
      settings: const DeviceSettings(uploadThumbnails: false, uploadText: true),
      connectivity: deriveConnectivity(lastSeen: _lastSeen, now: now),
    );
  }

  @override
  Stream<List<Device>> watchMyDevices() {
    start();
    final now = DateTime.now();
    return Stream<List<Device>>.multi((controller) {
      controller.add([_build(now)]);
      final subscription = _devicesController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<Device?> watchDevice(String deviceId) {
    if (deviceId != _deviceId) {
      return Stream<Device?>.value(null);
    }
    start();
    final now = DateTime.now();
    return Stream<Device?>.multi((controller) {
      controller.add(_build(now));
      final subscription = _deviceController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _devicesController.close();
    _deviceController.close();
  }
}

/// Implementasi [DeviceRepository] untuk data simulasi.
class FakeDeviceRepositoryImpl implements DeviceRepository {
  FakeDeviceRepositoryImpl(this._dataSource);

  final FakeDeviceDataSource _dataSource;

  @override
  Stream<List<Device>> watchMyDevices() => _dataSource.watchMyDevices();

  @override
  Stream<Device?> watchDevice(String deviceId) =>
      _dataSource.watchDevice(deviceId);
}
