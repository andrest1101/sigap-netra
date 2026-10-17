import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/history/data/datasources/fake_history_data_source.dart';
import 'package:sigap_netra_app/features/history/domain/entities/detection_filter.dart';
import 'package:sigap_netra_app/features/history/domain/entities/history_insights.dart';
import 'package:sigap_netra_app/features/history/domain/usecases/history_usecases.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';

/// `now` tetap supaya batas hari tidak bergantung jam test dijalankan.
final DateTime _now = DateTime(2026, 10, 15, 14, 30);

Detection _item({
  required String id,
  required DateTime createdAt,
  DetectionType type = DetectionType.money,
  ValidationStatus status = ValidationStatus.pending,
}) {
  return Detection(
    id: id,
    deviceId: kDemoDeviceId,
    deviceName: kDemoDeviceName,
    type: type,
    createdAt: createdAt,
    amount: type == DetectionType.money ? 10000 : null,
    ocrText: type == DetectionType.text ? 'SUSU KOTAK 250 ML' : null,
    validationStatus: status,
  );
}

void main() {
  group('insightWindowRanges', () {
    test('jendela 7 hari = 7 batang harian, berakhir besok tengah malam', () {
      final ranges = insightWindowRanges(now: _now, window: HistoryWindow.week);

      expect(ranges, hasLength(7));
      expect(ranges.first.start, DateTime(2026, 10, 9));
      expect(ranges.last.end, DateTime(2026, 10, 16));
      for (var i = 0; i < ranges.length; i++) {
        expect(
          ranges[i].start,
          DateTime(2026, 10, 9 + i),
          reason: 'batang $i mulai di tengah malam lokal',
        );
        expect(
          ranges[i].end.difference(ranges[i].start),
          const Duration(days: 1),
        );
      }
    });

    test('jendela 4 minggu = 4 batang mingguan, semua tujuh hari', () {
      final ranges = insightWindowRanges(
        now: _now,
        window: HistoryWindow.month,
      );

      expect(ranges, hasLength(4));
      expect(ranges.first.start, DateTime(2026, 9, 18));
      expect(ranges.last.end, DateTime(2026, 10, 16));
      for (final range in ranges) {
        expect(range.end.difference(range.start), const Duration(days: 7));
      }
      // Jendela 28 hari tepat habis dibagi 7 — tidak ada batang sisa.
      expect(
        ranges.first.start,
        ranges.last.start.subtract(const Duration(days: 21)),
      );
    });

    test('rentang memakai pagar setengah terbuka', () {
      final range = insightWindowRanges(
        now: _now,
        window: HistoryWindow.week,
      ).first;

      expect(range.contains(DateTime(2026, 10, 9)), isTrue);
      expect(range.contains(DateTime(2026, 10, 9, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 10)), isFalse);
      expect(range.contains(DateTime(2026, 10, 8, 23, 59, 59)), isFalse);
    });
  });

  group('GetHistoryInsights', () {
    late FakeDetectionDataSource detections;
    late GetHistoryInsights insights;

    setUp(() {
      detections = FakeDetectionDataSource();
      insights = GetHistoryInsights(
        FakeHistoryRepositoryImpl(FakeHistoryDataSource(detections)),
      );
      detections.replaceAll([
        // Hari ini.
        _item(
          id: 'today-cocok',
          createdAt: DateTime(2026, 10, 15, 9),
          status: ValidationStatus.match,
        ),
        _item(
          id: 'today-teks',
          createdAt: DateTime(2026, 10, 15, 10),
          type: DetectionType.text,
        ),
        // Kemarin: satu tidak cocok.
        _item(
          id: 'kemarin-salah',
          createdAt: DateTime(2026, 10, 14, 8),
          status: ValidationStatus.mismatch,
        ),
        // Batang paling tua: dua bacaan di hari yang sama.
        _item(
          id: 'awal-jendela-a',
          createdAt: DateTime(2026, 10, 9),
          status: ValidationStatus.match,
        ),
        _item(
          id: 'awal-jendela-b',
          createdAt: DateTime(2026, 10, 9, 23, 59, 59),
          status: ValidationStatus.match,
        ),
        // Di luar jendela 7 hari (hari ke-7 dan lebih tua).
        _item(id: 'terlalu-tua', createdAt: DateTime(2026, 10, 8, 23, 59)),
      ]);
    });

    tearDown(() => detections.dispose());

    test('menjumlahkan per batang, per jenis, dan per status', () async {
      final result = await insights.call(
        deviceId: kDemoDeviceId,
        window: HistoryWindow.week,
        now: _now,
      );

      expect(result.buckets, hasLength(7));
      expect(
        result.buckets.map((b) => b.total),
        [2, 0, 0, 0, 0, 1, 2],
        reason: 'batang urut lama → baru (kiri → kanan)',
      );
      expect(result.buckets.first.money, 2);
      expect(result.buckets.first.text, 0);
      expect(result.buckets.last.money, 1);
      expect(result.buckets.last.text, 1);

      // Bacaan di luar jendela tidak pernah ikut (pagar `createdAt`).
      expect(result.total, 5);
      expect(result.money, 4);
      expect(result.text, 1);

      expect(result.matched, 3);
      expect(result.mismatched, 1);
      expect(result.pending, 1);
      expect(result.decided, 4);
      expect(result.accuracyPercent, 75);
      expect(result.averagePerDay, closeTo(5 / 7, 0.0001));
      expect(result.isEmpty, isFalse);
    });

    test('jendela 4 minggu mengelompokkan tujuh hari per batang', () async {
      final result = await insights.call(
        deviceId: kDemoDeviceId,
        window: HistoryWindow.month,
        now: _now,
      );

      expect(result.buckets, hasLength(4));
      expect(
        result.buckets.map((b) => b.total),
        [0, 0, 1, 5],
        reason: 'batang = blok 7 hari yang berakhir hari ini (9–15 Okt)',
      );
      // Bacaan 8 Okt kini ikut (di dalam jendela 28 hari) — bukti jendela
      // benar-benar 28 hari, bukan 7 hari yang salah label.
      expect(result.total, 6);
      expect(result.buckets.last.range.start, DateTime(2026, 10, 9));
    });

    test('tanpa bacaan: nol, bukan pembagian nol', () async {
      detections.replaceAll(const <Detection>[]);
      final result = await insights.call(
        deviceId: kDemoDeviceId,
        window: HistoryWindow.week,
        now: _now,
      );

      expect(result.isEmpty, isTrue);
      expect(result.total, 0);
      expect(result.accuracyPercent, isNull);
      expect(result.averagePerDay, 0);
      expect(result.decided, 0);
    });
  });

  group('DetectionFilter rentang waktu', () {
    const filter = DetectionFilter(deviceId: kDemoDeviceId);

    test('since inklusif, before eksklusif', () {
      final ranged = DetectionFilter(
        deviceId: filter.deviceId,
        since: DateTime(2026, 10, 9),
        before: DateTime(2026, 10, 10),
      );

      expect(
        ranged.matches(_item(id: 'a', createdAt: DateTime(2026, 10, 9))),
        isTrue,
      );
      expect(
        ranged.matches(
          _item(id: 'b', createdAt: DateTime(2026, 10, 9, 23, 59, 59)),
        ),
        isTrue,
      );
      expect(
        ranged.matches(_item(id: 'c', createdAt: DateTime(2026, 10, 10))),
        isFalse,
      );
      expect(
        ranged.matches(_item(id: 'd', createdAt: DateTime(2026, 10, 8, 23))),
        isFalse,
      );
    });

    test('filter tanpa rentang tidak membatasi waktu', () {
      expect(filter.matches(_item(id: 'a', createdAt: DateTime(2020))), isTrue);
    });
  });
}
