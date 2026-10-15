import '../entities/detection.dart';

/// Kontrak repository pembacaan pada domain.
///
/// Read-only dari sisi aplikasi: aplikasi tidak pernah membuat dokumen
/// deteksi (`docs/firestore_schema.md` bagian 1). Query selalu memakai
/// `orderBy createdAt DESC` + `limit` sesuai skema bagian 7.3.
abstract interface class DetectionRepository {
  /// Memantau pembacaan terbaru satu perangkat, terbaru dulu.
  Stream<List<Detection>> watchLatestDetections({
    required String deviceId,
    int limit = 10,
  });

  /// Memantau satu pembacaan untuk layar detail (satu dokumen, bukan daftar).
  ///
  /// Null berarti dokumen tidak ada / sudah terhapus.
  Stream<Detection?> watchDetection({
    required String deviceId,
    required String detectionId,
  });
}
