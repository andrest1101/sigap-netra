import '../../domain/entities/detection.dart';
import '../../domain/repositories/detection_repository.dart';
import '../datasources/detection_data_source.dart';

/// Implementasi [DetectionRepository] di atas kontrak [DetectionDataSource].
class DetectionRepositoryImpl implements DetectionRepository {
  DetectionRepositoryImpl(this._dataSource, {required this.deviceNameOf});

  final DetectionDataSource _dataSource;

  /// Menyelesaikan nama tampilan perangkat untuk join client-side.
  ///
  /// Dokumen deteksi tidak menyimpan nama perangkat, jadi repository meminta
  /// nama dari pemanggil (mis. dari `DeviceRepository`) sebelum meneruskan
  /// ke data source.
  final String Function(String deviceId) deviceNameOf;

  @override
  Stream<List<Detection>> watchLatestDetections({
    required String deviceId,
    int limit = 10,
  }) {
    return _dataSource.watchLatestDetections(
      deviceId: deviceId,
      deviceName: deviceNameOf(deviceId),
      limit: limit,
    );
  }

  @override
  Stream<Detection?> watchDetection({
    required String deviceId,
    required String detectionId,
  }) {
    return _dataSource.watchDetection(
      deviceId: deviceId,
      deviceName: deviceNameOf(deviceId),
      detectionId: detectionId,
    );
  }
}
