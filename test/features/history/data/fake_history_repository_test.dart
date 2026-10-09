import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/history/data/datasources/fake_history_data_source.dart';
import 'package:sigap_netra_app/features/history/domain/entities/detection_filter.dart';
import 'package:sigap_netra_app/features/history/domain/entities/detection_page.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';

Detection _detection({required String id, required int minutesAgo}) {
  return Detection(
    id: id,
    deviceId: kDemoDeviceId,
    deviceName: kDemoDeviceName,
    type: DetectionType.money,
    createdAt: DateTime(
      2026,
      10,
      8,
      12,
    ).subtract(Duration(minutes: minutesAgo)),
    amount: 10000,
  );
}

void main() {
  late FakeDetectionDataSource detections;
  late FakeHistoryDataSource source;

  setUp(() {
    detections = FakeDetectionDataSource();
    source = FakeHistoryDataSource(detections);
    detections.replaceAll([
      _detection(id: 'det-1', minutesAgo: 1),
      _detection(id: 'det-2', minutesAgo: 2),
      _detection(id: 'det-3', minutesAgo: 3),
    ]);
  });

  tearDown(() => detections.dispose());

  group('FakeHistoryDataSource pagination', () {
    test('halaman pertama terbaru dulu dengan kursor lanjut', () async {
      final page = await source.getDetectionsPage(
        filter: const DetectionFilter(deviceId: kDemoDeviceId),
        deviceName: kDemoDeviceName,
        limit: 2,
      );

      expect(page.items.map((e) => e.id), ['det-1', 'det-2']);
      expect(page.nextCursor, isNotNull);
    });

    test('halaman kedua memakai kursor dan kursor habis', () async {
      const filter = DetectionFilter(deviceId: kDemoDeviceId);
      final first = await source.getDetectionsPage(
        filter: filter,
        deviceName: kDemoDeviceName,
        limit: 2,
      );
      final second = await source.getDetectionsPage(
        filter: filter,
        deviceName: kDemoDeviceName,
        limit: 2,
        startAfter: first.nextCursor,
      );

      expect(second.items.map((e) => e.id), ['det-3']);
      expect(second.nextCursor, isNull);
    });

    test('kursor tak dikenal menghasilkan halaman kosong', () async {
      final page = await source.getDetectionsPage(
        filter: const DetectionFilter(deviceId: kDemoDeviceId),
        deviceName: kDemoDeviceName,
        limit: 2,
        startAfter: DetectionPageCursor(
          createdAt: DateTime(2020, 1, 1),
          id: 'tidak-ada',
        ),
      );

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('delete menghapus item', () async {
      await source.deleteDetection(
        deviceId: kDemoDeviceId,
        detectionId: 'det-2',
        thumbnailId: null,
      );

      final page = await source.getDetectionsPage(
        filter: const DetectionFilter(deviceId: kDemoDeviceId),
        deviceName: kDemoDeviceName,
        limit: 10,
      );
      expect(page.items.map((e) => e.id), ['det-1', 'det-3']);
    });

    test('resetAll mengembalikan semua ke pending dengan jejak', () async {
      await source.resetAllValidations(
        deviceId: kDemoDeviceId,
        validatedBy: kDemoUserId,
      );

      for (final item in detections.itemsForTest) {
        expect(item.validationStatus, ValidationStatus.pending);
      }
    });
  });
}
