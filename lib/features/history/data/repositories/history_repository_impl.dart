import '../../domain/entities/detection_filter.dart';
import '../../domain/entities/detection_page.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_data_source.dart';

/// Implementasi [HistoryRepository] di atas kontrak [HistoryDataSource].
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._dataSource, {required this.deviceNameOf});

  final HistoryDataSource _dataSource;

  /// Menyelesaikan nama tampilan perangkat untuk join client-side.
  final String Function(String deviceId) deviceNameOf;

  @override
  Future<DetectionPage> getDetectionsPage({
    required DetectionFilter filter,
    int limit = 25,
    DetectionPageCursor? startAfter,
  }) {
    final deviceId = filter.deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      throw ArgumentError(
        'DetectionFilter.deviceId wajib diisi: riwayat selalu per perangkat.',
      );
    }
    return _dataSource.getDetectionsPage(
      filter: filter,
      deviceName: deviceNameOf(deviceId),
      limit: limit,
      startAfter: startAfter,
    );
  }

  @override
  Future<void> deleteDetection({
    required String deviceId,
    required String detectionId,
    required String? thumbnailId,
  }) {
    return _dataSource.deleteDetection(
      deviceId: deviceId,
      detectionId: detectionId,
      thumbnailId: thumbnailId,
    );
  }

  @override
  Future<void> resetValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) {
    return _dataSource.resetValidation(
      deviceId: deviceId,
      detectionId: detectionId,
      validatedBy: validatedBy,
    );
  }

  @override
  Future<void> resetAllValidations({
    required String deviceId,
    required String? validatedBy,
  }) {
    return _dataSource.resetAllValidations(
      deviceId: deviceId,
      validatedBy: validatedBy,
    );
  }
}
