import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/notifications/domain/usecases/select_notifiable_detections.dart';

Detection _detection(String id, DateTime createdAt) {
  return Detection(
    id: id,
    deviceId: 'dev-1',
    deviceName: 'Kacamata',
    type: DetectionType.money,
    createdAt: createdAt,
    amount: 10000,
  );
}

void main() {
  final now = DateTime(2026, 10, 26, 10, 0);

  group('selectNotifiableDetections', () {
    test('membuang pembacaan yang lebih tua dari batas', () {
      final result = selectNotifiableDetections([
        _detection('baru', now.subtract(const Duration(minutes: 2))),
        _detection('lama', now.subtract(const Duration(minutes: 11))),
      ], now: now);

      expect(result.map((detection) => detection.id), ['baru']);
    });

    test('tepat di batas umur masih diterima', () {
      final result = selectNotifiableDetections([
        _detection('batas', now.subtract(const Duration(minutes: 10))),
      ], now: now);

      expect(result.single.id, 'batas');
    });

    test('mengurutkan terbaru lebih dulu lalu membatasi jumlah', () {
      final result = selectNotifiableDetections([
        _detection('tua', now.subtract(const Duration(minutes: 4))),
        _detection('baru', now.subtract(const Duration(minutes: 1))),
        _detection('tengah', now.subtract(const Duration(minutes: 2))),
        _detection('paling-baru', now.subtract(const Duration(minutes: 0))),
      ], now: now);

      expect(result.map((detection) => detection.id), [
        'paling-baru',
        'baru',
        'tengah',
      ]);
    });

    test('batas nol menghasilkan daftar kosong', () {
      final result = selectNotifiableDetections(
        [_detection('baru', now)],
        now: now,
        maxCount: 0,
      );

      expect(result, isEmpty);
    });
  });
}
