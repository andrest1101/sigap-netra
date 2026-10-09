import '../entities/device.dart';

/// Kontrak pembacaan data perangkat.
abstract interface class DeviceRepository {
  /// Memantau perangkat milik pengguna secara berkelanjutan.
  ///
  /// [uid] adalah UID pengguna: hanya perangkat dengan `members` mencakup
  /// UID tersebut yang dikembalikan.
  Stream<List<Device>> watchMyDevices({required String uid});

  /// Memantau satu perangkat secara berkelanjutan.
  Stream<Device?> watchDevice(String deviceId);
}
