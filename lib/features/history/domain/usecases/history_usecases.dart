import '../../../monitoring/domain/entities/detection.dart';
import '../entities/detection_filter.dart';
import '../repositories/history_repository.dart';

/// Kontrak pengambilan halaman riwayat.
class GetDetectionsPage {
  const GetDetectionsPage(this._repository);

  final HistoryRepository _repository;

  Future<List<Detection>> call({
    required DetectionFilter filter,
    int limit = 25,
    Detection? startAfter,
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

  Future<void> call({required Detection detection}) {
    return _repository.deleteDetection(detection: detection);
  }
}

/// Kontrak pembatalan validasi dari riwayat.
class ResetValidation {
  const ResetValidation(this._repository);

  final HistoryRepository _repository;

  Future<void> call({required String detectionId}) {
    return _repository.resetValidation(detectionId: detectionId);
  }
}
