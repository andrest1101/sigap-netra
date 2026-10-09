import '../entities/detection.dart';
import '../repositories/detection_repository.dart';

/// Memantau pembacaan terbaru satu perangkat untuk Beranda dan aktivitas.
class WatchLatestDetections {
  const WatchLatestDetections(this._repository);

  final DetectionRepository _repository;

  Stream<List<Detection>> call({required String deviceId, int limit = 10}) {
    return _repository.watchLatestDetections(deviceId: deviceId, limit: limit);
  }
}
