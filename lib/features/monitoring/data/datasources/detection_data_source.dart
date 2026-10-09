import '../../domain/entities/detection.dart';

/// Kontrak sumber data pembacaan pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
abstract interface class DetectionDataSource {
  Stream<List<Detection>> watchLatestDetections({
    required String deviceId,
    required String deviceName,
    int limit = 10,
  });
}
