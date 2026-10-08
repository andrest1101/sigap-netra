import '../entities/device.dart';
import '../repositories/device_repository.dart';

/// Memantau daftar perangkat milik pengguna untuk Beranda dan Perangkat.
class WatchMyDevices {
  const WatchMyDevices(this._repository);

  final DeviceRepository _repository;

  Stream<List<Device>> call() => _repository.watchMyDevices();
}

/// Memantau satu perangkat untuk layar detail.
class WatchDevice {
  const WatchDevice(this._repository);

  final DeviceRepository _repository;

  Stream<Device?> call(String deviceId) => _repository.watchDevice(deviceId);
}
