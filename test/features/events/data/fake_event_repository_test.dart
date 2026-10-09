import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/events/data/datasources/fake_event_data_source.dart';
import 'package:sigap_netra_app/features/events/domain/entities/device_event.dart';

void main() {
  late FakeEventDataSource source;

  setUp(() => source = FakeEventDataSource());

  group('FakeEventDataSource', () {
    test('watchEvents terbaru dulu', () async {
      final events = await source.watchEvents(deviceId: kDemoDeviceId).first;

      expect(events, hasLength(3));
      for (var i = 0; i < events.length - 1; i++) {
        expect(events[i].createdAt.isAfter(events[i + 1].createdAt), isTrue);
      }
    });

    test('filter severity error', () async {
      final page = await source.getEventsPage(
        deviceId: kDemoDeviceId,
        severity: EventSeverity.error,
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.severity, EventSeverity.error);
    });

    test('paginasi dua halaman lalu habis', () async {
      final first = await source.getEventsPage(
        deviceId: kDemoDeviceId,
        limit: 2,
      );
      expect(first.items, hasLength(2));
      expect(first.nextCursor, isNotNull);

      final second = await source.getEventsPage(
        deviceId: kDemoDeviceId,
        limit: 2,
        startAfter: first.nextCursor,
      );
      expect(second.items, hasLength(1));
      expect(second.nextCursor, isNull);
    });

    test('device asing tidak melihat event demo', () async {
      final page = await source.getEventsPage(deviceId: 'dev-asing');

      expect(page.items, isEmpty);
    });
  });
}
