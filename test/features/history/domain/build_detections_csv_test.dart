import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/history/domain/usecases/build_detections_csv.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';

Detection _detection({
  String id = 'det-1',
  DetectionType type = DetectionType.money,
  DateTime? createdAt,
  int? amount = 50000,
  String currency = 'IDR',
  String? label,
  double? confidence = 0.92,
  int? distanceCm = 84,
  String? ocrText,
  ValidationStatus status = ValidationStatus.pending,
}) {
  return Detection(
    id: id,
    deviceId: 'dev-1',
    deviceName: 'SIGAP-01',
    type: type,
    createdAt: createdAt ?? DateTime(2026, 10, 18, 14, 30, 5),
    amount: amount,
    currency: currency,
    label: label,
    confidence: confidence,
    distanceCm: distanceCm,
    ocrText: ocrText,
    validationStatus: status,
  );
}

void main() {
  group('buildDetectionsCsv', () {
    test('memuat BOM + header titik-koma', () {
      final csv = buildDetectionsCsv([_detection()]);
      expect(
        csv.startsWith(
          '\uFEFFwaktu;jenis;nilai;mata_uang;teks;keyakinan;jarak_cm;status'
          '\r\n',
        ),
        isTrue,
      );
      // Baris diakhiri CRLF supaya rapi di Excel/editor Windows.
      expect(csv.endsWith('\r\n'), isTrue);
    });

    test(
      'baris uang: waktu lokal, nominal polos, koma desimal, kata status',
      () {
        final csv = buildDetectionsCsv([
          _detection(status: ValidationStatus.match),
        ]);
        final rows = csv.split('\r\n');
        expect(rows[1], '2026-10-18 14:30:05;uang;50000;IDR;;0,92;84;Cocok');
      },
    );

    test(
      'teks: nilai & mata uang kosong, jarak kosong, dinormalkan 1 baris',
      () {
        final csv = buildDetectionsCsv([
          _detection(
            type: DetectionType.text,
            amount: null,
            confidence: 0.87,
            distanceCm: null,
            ocrText: 'Total: Rp 25.000;\nTerima kasih "Anda"',
          ),
        ]);
        final rows = csv.split('\r\n');
        // Sebaris, kutip ganda di-escape RFC 4180, pemisah dalam teks aman.
        expect(
          rows[1],
          '2026-10-18 14:30:05;teks;;;'
          '"Total: Rp 25.000; · Terima kasih ""Anda""";0,87;;Menunggu',
        );
      },
    );

    test('teks tanpa OCR memakai label sebagai cadangan', () {
      final csv = buildDetectionsCsv([
        _detection(
          type: DetectionType.text,
          amount: null,
          label: 'Pintu keluar',
          confidence: null,
          distanceCm: null,
        ),
      ]);
      final rows = csv.split('\r\n');
      expect(rows[1], '2026-10-18 14:30:05;teks;;;Pintu keluar;;;Menunggu');
    });

    test('status mismatch ditulis dengan kata UI', () {
      final csv = buildDetectionsCsv([
        _detection(status: ValidationStatus.mismatch),
      ]);
      expect(csv.contains(';Tidak cocok\r\n'), isTrue);
    });

    test('daftar kosong hanya memuat header (tanpa baris palsu)', () {
      final csv = buildDetectionsCsv(const <Detection>[]);
      expect(
        csv,
        '\uFEFFwaktu;jenis;nilai;mata_uang;teks;keyakinan;jarak_cm;status\r\n',
      );
    });

    test('CRLF di dalam teks OCR juga dinormalkan ke satu baris', () {
      final csv = buildDetectionsCsv([
        _detection(
          type: DetectionType.text,
          amount: null,
          ocrText: 'Baris satu\r\nBaris dua\rBaris tiga',
        ),
      ]);
      expect(csv.contains('Baris satu · Baris dua · Baris tiga'), isTrue);
    });
  });
}
