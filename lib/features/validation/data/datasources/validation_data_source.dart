import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/repositories/validation_summary.dart';

/// Kontrak sumber data validasi pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
///
/// Tulis dibatasi pada tiga field: `validationStatus`, `validatedBy`,
/// `validatedAt` (`docs/firestore_schema.md` bagian 1).
abstract interface class ValidationDataSource {
  Stream<List<Detection>> watchPendingDetections({
    required String deviceId,
    required String deviceName,
    int limit = 20,
  });

  Future<ValidationSummary> getValidationSummary({required String deviceId});

  Future<void> submitValidation({
    required String deviceId,
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  });

  Future<void> undoValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  });
}
