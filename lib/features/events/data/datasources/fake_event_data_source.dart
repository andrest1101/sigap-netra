import '../../../../core/constants/demo_ids.dart';
import '../../domain/entities/device_event.dart';
import '../../domain/entities/event_page.dart';
import '../../domain/repositories/event_repository.dart';
import '../repositories/event_repository_impl.dart';
import 'event_data_source.dart';

/// Sumber data event simulasi untuk mode pengembang.
///
/// Data disimpan in-memory dan hilang saat aplikasi ditutup, sesuai sifat
/// simulasi.
class FakeEventDataSource implements EventDataSource {
  List<DeviceEvent> _items = _sample();

  /// Isi saat ini, dipakai test dan demo reset.
  List<DeviceEvent> get itemsForTest => List<DeviceEvent>.unmodifiable(_items);

  /// Mengganti seluruh isi simulasi, dipakai test dan demo reset.
  void replaceAll(List<DeviceEvent> items) {
    _items = List<DeviceEvent>.of(items);
  }

  @override
  Stream<List<DeviceEvent>> watchEvents({
    String? deviceId,
    int limit = 50,
  }) async* {
    yield _sorted()
        .where((item) => deviceId == null || item.deviceId == deviceId)
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<EventPage> getEventsPage({
    String? deviceId,
    EventSeverity? severity,
    int limit = 50,
    EventPageCursor? startAfter,
  }) async {
    final matched = _sorted()
        .where((item) => deviceId == null || item.deviceId == deviceId)
        .where((item) => severity == null || item.severity == severity)
        .toList(growable: false);

    var startIndex = 0;
    if (startAfter != null) {
      final found = matched.indexWhere(
        (item) =>
            item.createdAt.isAtSameMomentAs(startAfter.createdAt) &&
            item.id == startAfter.id,
      );
      if (found < 0) {
        return const EventPage(items: <DeviceEvent>[]);
      }
      startIndex = found + 1;
    }
    if (startIndex >= matched.length) {
      return const EventPage(items: <DeviceEvent>[]);
    }
    final endIndex = (startIndex + limit + 1).clamp(0, matched.length);
    final slice = matched.sublist(startIndex, endIndex);
    final hasMore = slice.length > limit;
    final items = hasMore ? slice.sublist(0, limit) : slice;
    return EventPage(
      items: items,
      nextCursor: hasMore && items.isNotEmpty
          ? EventPageCursor.fromEvent(items.last)
          : null,
    );
  }

  List<DeviceEvent> _sorted() {
    final sorted = List<DeviceEvent>.of(_items);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}

List<DeviceEvent> _sample() {
  final now = DateTime.now();
  return [
    DeviceEvent(
      id: 'evt-boot',
      deviceId: kDemoDeviceId,
      type: 'boot',
      severity: EventSeverity.info,
      message: 'Perangkat selesai booting.',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    DeviceEvent(
      id: 'evt-wifi-disconnect',
      deviceId: kDemoDeviceId,
      type: 'wlan_disconnected',
      severity: EventSeverity.warning,
      message: 'Koneksi Wi-Fi terputus sebentar.',
      createdAt: now.subtract(const Duration(minutes: 18)),
    ),
    DeviceEvent(
      id: 'evt-command-failed',
      deviceId: kDemoDeviceId,
      type: 'command_failed',
      severity: EventSeverity.error,
      message: 'Perintah restart gagal dieksekusi.',
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
  ];
}

/// Implementasi [EventRepository] untuk data simulasi.
class FakeEventRepositoryImpl extends EventRepositoryImpl {
  FakeEventRepositoryImpl(super.dataSource);
}
