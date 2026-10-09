import '../../domain/entities/detection_filter.dart';
import '../../domain/entities/detection_page.dart';

/// Kontrak sumber data riwayat pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
///
/// Halaman memakai [DetectionPageCursor] supaya domain tetap bebas Firestore;
/// implementasi Firestore memetakannya ke `startAfter([createdAt])`.
abstract interface class HistoryDataSource {
  Future<DetectionPage> getDetectionsPage({
    required DetectionFilter filter,
    required String deviceName,
    int limit = 25,
    DetectionPageCursor? startAfter,
  });

  Future<void> deleteDetection({
    required String deviceId,
    required String detectionId,
    required String? thumbnailId,
  });

  Future<void> resetValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  });

  Future<void> resetAllValidations({
    required String deviceId,
    required String? validatedBy,
  });
}
