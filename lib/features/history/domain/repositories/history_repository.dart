import '../../../monitoring/domain/entities/detection.dart';
import '../entities/detection_filter.dart';

/// Kontrak repository riwayat pada domain.
///
/// Firestore repository belum diimplementasikan karena kontrak pagination,
/// retensi, dan security masih berstatus `[PERLU KONFIRMASI]`.
abstract interface class HistoryRepository {
  /// Mengambil satu halaman riwayat sesuai filter aktif.
  Future<List<Detection>> getDetectionsPage({
    required DetectionFilter filter,
    int limit = 25,
    Detection? startAfter,
  });

  /// Menghapus satu pembacaan beserta media terkait bila kebijakan hapus sudah
  /// dikonfirmasi.
  Future<void> deleteDetection({required Detection detection});

  /// Mereset validasi satu pembacaan bila kebijakan pembatalan sudah
  /// dikonfirmasi.
  Future<void> resetValidation({required String detectionId});
}
