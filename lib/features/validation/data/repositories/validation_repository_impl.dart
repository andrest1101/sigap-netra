import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/repositories/validation_repository.dart';
import '../../domain/repositories/validation_summary.dart';
import '../datasources/validation_data_source.dart';

/// Implementasi [ValidationRepository] di atas kontrak [ValidationDataSource].
class ValidationRepositoryImpl implements ValidationRepository {
  ValidationRepositoryImpl(this._dataSource, {required this.deviceNameOf});

  final ValidationDataSource _dataSource;

  /// Menyelesaikan nama tampilan perangkat untuk join client-side.
  final String Function(String deviceId) deviceNameOf;

  @override
  Stream<List<Detection>> watchPendingDetections({
    required String deviceId,
    int limit = 20,
  }) {
    return _dataSource.watchPendingDetections(
      deviceId: deviceId,
      deviceName: deviceNameOf(deviceId),
      limit: limit,
    );
  }

  @override
  Future<ValidationSummary> getValidationSummary({required String deviceId}) {
    return _dataSource.getValidationSummary(deviceId: deviceId);
  }

  @override
  Future<void> submitValidation({
    required String deviceId,
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  }) {
    return _dataSource.submitValidation(
      deviceId: deviceId,
      detectionId: detectionId,
      status: status,
      validatedBy: validatedBy,
    );
  }

  @override
  Future<void> undoValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) {
    return _dataSource.undoValidation(
      deviceId: deviceId,
      detectionId: detectionId,
      validatedBy: validatedBy,
    );
  }
}
