import '../../domain/entities/device.dart';

/// Kontrak sumber data perangkat pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
///
/// [uid] adalah UID pengguna yang sedang masuk: daftar hanya berisi perangkat
/// yang anggotanya mencakup UID tersebut (`members.<uid>`, skema bagian 3).
abstract interface class DeviceDataSource {
  Stream<List<Device>> watchMyDevices({required String uid});

  Stream<Device?> watchDevice(String deviceId);
}
