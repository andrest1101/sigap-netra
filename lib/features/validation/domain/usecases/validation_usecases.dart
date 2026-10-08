import '../../../monitoring/domain/entities/detection.dart';
import '../repositories/validation_repository.dart';

/// Menghitung akurasi validasi manusia dalam domain.
double calculateValidationAccuracy(List<Detection> detections) {
  final matches = detections
      .where((item) => item.validationStatus == ValidationStatus.match)
      .length;
  final mismatches = detections
      .where((item) => item.validationStatus == ValidationStatus.mismatch)
      .length;

  if (matches + mismatches == 0) return double.nan;
  return matches / (matches + mismatches);
}

/// Kontrak use case validasi.
class WatchPendingDetections {
  const WatchPendingDetections(this._repository);

  final ValidationRepository _repository;

  Stream<List<Detection>> call({int limit = 20}) {
    return _repository.watchPendingDetections(limit: limit);
  }
}

/// Kontrak pengajuan validasi manusia.
class SubmitValidation {
  const SubmitValidation(this._repository);

  final ValidationRepository _repository;

  Future<void> call({
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  }) {
    return _repository.submitValidation(
      detectionId: detectionId,
      status: status,
      validatedBy: validatedBy,
    );
  }
}

/// Kontrak pembatalan validasi manusia.
class UndoValidation {
  const UndoValidation(this._repository);

  final ValidationRepository _repository;

  Future<void> call({required String detectionId}) {
    return _repository.undoValidation(detectionId: detectionId);
  }
}

/// Kontrak perhitungan akurasi manusia.
class GetAccuracy {
  const GetAccuracy(this._repository);

  final ValidationRepository _repository;

  Future<double?> call({int limit = 1000}) {
    return _repository.getValidationAccuracy(limit: limit);
  }
}
