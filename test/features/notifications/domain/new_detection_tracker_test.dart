import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/notifications/domain/usecases/new_detection_tracker.dart';

Detection _detection(
  String id, {
  DateTime? createdAt,
  ValidationStatus validationStatus = ValidationStatus.pending,
}) {
  return Detection(
    id: id,
    deviceId: 'dev-1',
    deviceName: 'Kacamata',
    type: DetectionType.money,
    createdAt: createdAt ?? DateTime(2026, 10, 26, 10),
    amount: 10000,
    validationStatus: validationStatus,
  );
}

void main() {
  group('NewDetectionTracker', () {
    test('emisi pertama hanya primes, tidak ada notifikasi', () {
      final tracker = NewDetectionTracker();

      final result = tracker.track([_detection('a'), _detection('b')]);

      expect(result, isEmpty);
      expect(tracker.isPrimed, isTrue);
    });

    test('emisi berikutnya hanya mengembalikan ID baru', () {
      final tracker = NewDetectionTracker();
      tracker.track([_detection('a'), _detection('b')]);

      final result = tracker.track([
        _detection('c'),
        _detection('a'),
        _detection('b'),
      ]);

      expect(result.map((detection) => detection.id), ['c']);
    });

    test('daftar yang sama berulang tidak memicu notifikasi', () {
      final tracker = NewDetectionTracker();
      tracker.track([_detection('a')]);

      expect(tracker.track([_detection('a')]), isEmpty);
      expect(tracker.track([_detection('a')]), isEmpty);
    });

    test('perubahan status validasi bukan pembacaan baru', () {
      final tracker = NewDetectionTracker();
      tracker.track([_detection('a')]);

      final result = tracker.track([
        _detection('a', validationStatus: ValidationStatus.match),
      ]);

      expect(result, isEmpty);
    });

    test('reset membuat emisi berikutnya menjadi primes lagi', () {
      final tracker = NewDetectionTracker();
      tracker.track([_detection('a')]);

      tracker.reset();
      expect(tracker.isPrimed, isFalse);
      expect(tracker.track([_detection('b')]), isEmpty);
      expect(tracker.track([_detection('b'), _detection('c')]).single.id, 'c');
    });

    test('ID lama yang keluar dari jendela tidak muncul lagi', () {
      final tracker = NewDetectionTracker(maxRememberedIds: 2);
      tracker.track([_detection('a'), _detection('b')]);
      tracker.track([_detection('c'), _detection('d')]);

      // 'a' dan 'b' terbuang dari memori, tetapi jendela query nyata tidak
      // pernah menghadirkan kembali dokumen yang sudah lewat.
      expect(tracker.track([_detection('a')]).single.id, 'a');
    });
  });
}
