import '../../../events/domain/entities/device_event.dart';
import '../repositories/event_repository.dart';

/// Kontrak pemantauan event.
class WatchEvents {
  const WatchEvents(this._repository);

  final EventRepository _repository;

  Stream<List<DeviceEvent>> call({String? deviceId, int limit = 50}) {
    return _repository.watchEvents(deviceId: deviceId, limit: limit);
  }
}
