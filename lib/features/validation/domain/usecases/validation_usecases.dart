import '../../../monitoring/domain/entities/detection.dart';
import '../repositories/validation_repository.dart';
import '../repositories/validation_summary.dart';

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

  Stream<List<Detection>> call({required String deviceId, int limit = 20}) {
    return _repository.watchPendingDetections(deviceId: deviceId, limit: limit);
  }
}

/// Kontrak pengajuan validasi manusia.
class SubmitValidation {
  const SubmitValidation(this._repository);

  final ValidationRepository _repository;

  Future<void> call({
    required String deviceId,
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  }) {
    return _repository.submitValidation(
      deviceId: deviceId,
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

  Future<void> call({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) {
    return _repository.undoValidation(
      deviceId: deviceId,
      detectionId: detectionId,
      validatedBy: validatedBy,
    );
  }
}

/// Kontrak ringkasan akurasi manusia (dihitung dari `count()`, bukan unduhan).
class GetValidationSummary {
  const GetValidationSummary(this._repository);

  final ValidationRepository _repository;

  Future<ValidationSummary> call({required String deviceId}) {
    return _repository.getValidationSummary(deviceId: deviceId);
  }
}
