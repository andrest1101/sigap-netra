import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/validation/data/datasources/fake_validation_data_source.dart';

Detection _detection({
  required String id,
  required ValidationStatus status,
  String? validatedBy,
}) {
  return Detection(
    id: id,
    deviceId: kDemoDeviceId,
    deviceName: kDemoDeviceName,
    type: DetectionType.money,
    createdAt: DateTime(2026, 10, 8, 12),
    amount: 10000,
    validationStatus: status,
    validatedBy: validatedBy,
    validatedAt: validatedBy == null ? null : DateTime(2026, 10, 8, 12),
  );
}

void main() {
  late FakeDetectionDataSource detections;
  late FakeValidationDataSource source;

  setUp(() {
    detections = FakeDetectionDataSource();
    source = FakeValidationDataSource(detections);
    detections.replaceAll([
      _detection(id: 'det-pending', status: ValidationStatus.pending),
      _detection(
        id: 'det-match',
        status: ValidationStatus.match,
        validatedBy: kDemoUserId,
      ),
      _detection(
        id: 'det-mismatch',
        status: ValidationStatus.mismatch,
        validatedBy: kDemoUserId,
      ),
    ]);
  });

  tearDown(() => detections.dispose());

  group('FakeValidationDataSource', () {
    test('antrean pending hanya berisi status pending', () async {
      final pending = await source
          .watchPendingDetections(
            deviceId: kDemoDeviceId,
            deviceName: kDemoDeviceName,
          )
          .first;

      expect(pending.map((e) => e.id), ['det-pending']);
    });

    test('device lain tidak melihat antrean demo', () async {
      final pending = await source
          .watchPendingDetections(deviceId: 'dev-asing', deviceName: 'Asing')
          .first;

      expect(pending, isEmpty);
    });

    test('ringkasan menghitung match/mismatch/pending', () async {
      final summary = await source.getValidationSummary(
        deviceId: kDemoDeviceId,
      );

      expect(summary.matches, 1);
      expect(summary.mismatches, 1);
      expect(summary.pending, 1);
      expect(summary.accuracy, 0.5);
    });

    test('submit menyimpan validatedBy', () async {
      await source.submitValidation(
        deviceId: kDemoDeviceId,
        detectionId: 'det-pending',
        status: ValidationStatus.match,
        validatedBy: kDemoUserId,
      );

      final item = detections.itemsForTest.firstWhere(
        (e) => e.id == 'det-pending',
      );
      expect(item.validationStatus, ValidationStatus.match);
      expect(item.validatedBy, kDemoUserId);
      expect(item.validatedAt, isNotNull);
    });

    test('undo menyimpan jejak pembatalan, tidak dikosongkan', () async {
      await source.undoValidation(
        deviceId: kDemoDeviceId,
        detectionId: 'det-match',
        validatedBy: kDemoUserId,
      );

      final item = detections.itemsForTest.firstWhere(
        (e) => e.id == 'det-match',
      );
      expect(item.validationStatus, ValidationStatus.pending);
      // Skema 4.2: jejak pembatalan tetap terlihat.
      expect(item.validatedBy, kDemoUserId);
      expect(item.validatedAt, isNotNull);
    });
  });
}
