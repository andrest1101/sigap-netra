import '../entities/device.dart';

/// Kontrak pembacaan data perangkat.
abstract interface class DeviceRepository {
  /// Memantau perangkat milik pengguna secara berkelanjutan.
  Stream<List<Device>> watchMyDevices();

  /// Memantau satu perangkat secara berkelanjutan.
  Stream<Device?> watchDevice(String deviceId);
}
