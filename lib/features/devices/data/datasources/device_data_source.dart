import '../../domain/entities/device.dart';

/// Kontrak sumber data perangkat pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
abstract interface class DeviceDataSource {
  Stream<List<Device>> watchMyDevices();

  Stream<Device?> watchDevice(String deviceId);
}
