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

  /// Memantau satu dokumen pembacaan untuk layar detail.
  ///
  /// Mengembalikan null bila dokumen tidak ada (atau sudah terhapus), bukan
  /// error — layar detail merendernya sebagai state "tidak ditemukan".
  Stream<Detection?> watchDetection({
    required String deviceId,
    required String deviceName,
    required String detectionId,
  });
}
