import '../entities/device_event.dart';
import '../entities/event_page.dart';
import '../repositories/event_repository.dart';

/// Kontrak pemantauan event.
class WatchEvents {
  const WatchEvents(this._repository);

  final EventRepository _repository;

  Stream<List<DeviceEvent>> call({String? deviceId, int limit = 50}) {
    return _repository.watchEvents(deviceId: deviceId, limit: limit);
  }
}

/// Kontrak pengambilan halaman event dengan filter severity.
class GetEventsPage {
  const GetEventsPage(this._repository);

  final EventRepository _repository;

  Future<EventPage> call({
    String? deviceId,
    EventSeverity? severity,
    int limit = 50,
    EventPageCursor? startAfter,
  }) {
    return _repository.getEventsPage(
      deviceId: deviceId,
      severity: severity,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
