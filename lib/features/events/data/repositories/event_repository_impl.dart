import '../../domain/entities/device_event.dart';
import '../../domain/entities/event_page.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_data_source.dart';

/// Implementasi [EventRepository] di atas kontrak [EventDataSource].
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._dataSource);

  final EventDataSource _dataSource;

  @override
  Stream<List<DeviceEvent>> watchEvents({String? deviceId, int limit = 50}) {
    return _dataSource.watchEvents(deviceId: deviceId, limit: limit);
  }

  @override
  Future<EventPage> getEventsPage({
    String? deviceId,
    EventSeverity? severity,
    int limit = 50,
    EventPageCursor? startAfter,
  }) {
    return _dataSource.getEventsPage(
      deviceId: deviceId,
      severity: severity,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
