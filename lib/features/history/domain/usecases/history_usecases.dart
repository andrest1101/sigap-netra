import '../entities/detection_filter.dart';
import '../entities/detection_page.dart';
import '../repositories/history_repository.dart';

/// Kontrak pengambilan halaman riwayat.
class GetDetectionsPage {
  const GetDetectionsPage(this._repository);

  final HistoryRepository _repository;

  Future<DetectionPage> call({
    required DetectionFilter filter,
    int limit = 25,
    DetectionPageCursor? startAfter,
  }) {
    return _repository.getDetectionsPage(
      filter: filter,
      limit: limit,
      startAfter: startAfter,
    );
  }
}

/// Kontrak penghapusan pembacaan beserta media terkait.
class DeleteDetection {
  const DeleteDetection(this._repository);

  final HistoryRepository _repository;

  Future<void> call({
    required String deviceId,
    required String detectionId,
    required String? thumbnailId,
  }) {
    return _repository.deleteDetection(
      deviceId: deviceId,
      detectionId: detectionId,
      thumbnailId: thumbnailId,
    );
  }
}

/// Kontrak pembatalan validasi dari riwayat.
class ResetValidation {
  const ResetValidation(this._repository);

  final HistoryRepository _repository;

  Future<void> call({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) {
    return _repository.resetValidation(
      deviceId: deviceId,
      detectionId: detectionId,
      validatedBy: validatedBy,
    );
  }
}

/// Kontrak reset seluruh validasi satu perangkat (batch + konfirmasi di UI).
class ResetAllValidations {
  const ResetAllValidations(this._repository);

  final HistoryRepository _repository;

  Future<void> call({required String deviceId, required String? validatedBy}) {
    return _repository.resetAllValidations(
      deviceId: deviceId,
      validatedBy: validatedBy,
    );
  }
}
