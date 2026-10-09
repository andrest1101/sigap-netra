import '../entities/detection_filter.dart';
import '../entities/detection_page.dart';

/// Kontrak repository riwayat pada domain.
///
/// Paginasi memakai [DetectionPageCursor] (nilai `createdAt` + `id`) supaya
/// domain tetap bebas Firestore; data layer Firestore memetakannya ke
/// `startAfter([createdAt])` pada query `orderBy createdAt DESC` sesuai
/// `docs/firestore_schema.md` bagian 7.3.
abstract interface class HistoryRepository {
  /// Mengambil satu halaman riwayat sesuai filter aktif.
  ///
  /// [startAfter] null berarti halaman pertama. Mengembalikan [DetectionPage]
  /// yang membawa `nextCursor` untuk halaman berikutnya, atau null bila habis.
  Future<DetectionPage> getDetectionsPage({
    required DetectionFilter filter,
    int limit = 25,
    DetectionPageCursor? startAfter,
  });

  /// Menghapus satu pembacaan beserta dokumen `media` terkait.
  Future<void> deleteDetection({
    required String deviceId,
    required String detectionId,
    required String? thumbnailId,
  });

  /// Mereset validasi satu pembacaan ke `pending` dengan tetap menyimpan
  /// [validatedBy] sebagai jejak pembatalan (skema bagian 4.2).
  Future<void> resetValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  });

  /// Mereset seluruh validasi satu perangkat (batch + konfirmasi di UI),
  /// dengan [validatedBy] sebagai jejak pelaku batch.
  Future<void> resetAllValidations({
    required String deviceId,
    required String? validatedBy,
  });
}
