import '../../domain/entities/device_event.dart';
import '../../domain/entities/event_page.dart';

/// Kontrak sumber data event pada data layer.
///
/// Implementasi produksi memakai Firestore; implementasi simulasi dan test
/// dapat dibuat tanpa koneksi jaringan atau perangkat keras.
///
/// Read-only dari sisi aplikasi: aplikasi tidak pernah membuat, mengubah, atau
/// menghapus event (`docs/firestore_schema.md` bagian 1).
abstract interface class EventDataSource {
  Stream<List<DeviceEvent>> watchEvents({String? deviceId, int limit = 50});

  Future<EventPage> getEventsPage({
    String? deviceId,
    EventSeverity? severity,
    int limit = 50,
    EventPageCursor? startAfter,
  });
}
