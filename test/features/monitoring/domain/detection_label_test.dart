import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';

/// Regression: label uang pernah ganda ("Rp 100000 - Nominal 100.000") —
/// nominal mentah tanpa format + label sampel mengulang nominal yang sama.
void main() {
  Detection money({int? amount, String? label}) => Detection(
    id: 'm',
    deviceId: 'd',
    deviceName: 'Kacamata Cerdas',
    type: DetectionType.money,
    createdAt: DateTime(2026, 10, 11, 12),
    amount: amount,
    label: label,
  );

  Detection text(String? ocr) => Detection(
    id: 't',
    deviceId: 'd',
    deviceName: 'Kacamata Cerdas',
    type: DetectionType.text,
    createdAt: DateTime(2026, 10, 11, 12),
    ocrText: ocr,
  );

  group('displayLabel uang', () {
    test('hanya nominal berformat titik, tanpa ganda', () {
      expect(money(amount: 100000).displayLabel, 'Rp 100.000');
      expect(money(amount: 50000).displayLabel, 'Rp 50.000');
      expect(money(amount: 10000).displayLabel, 'Rp 10.000');
    });

    test('label sampel tidak diulang', () {
      expect(
        money(amount: 100000, label: 'Nominal 100.000').displayLabel,
        'Rp 100.000',
      );
    });

    test('amount null menjadi strip', () {
      expect(money().displayLabel, '-');
    });
  });

  group('displayLabel teks', () {
    test('newline dinormalisasi ke satu baris', () {
      expect(
        text('AYAM GORENG — Rp15.000').displayLabel,
        'AYAM GORENG — Rp15.000',
      );
      expect(
        text('BARIS SATU\nBARIS DUA\nBARIS TIGA').displayLabel,
        'BARIS SATU · BARIS DUA · BARIS TIGA',
      );
    });

    test('dipotong 80 karakter dengan elipsis', () {
      final long = List.filled(100, 'A').join();
      expect(text(long).displayLabel, '${List.filled(80, 'A').join()}...');
    });

    test('null menjadi strip', () {
      expect(text(null).displayLabel, '-');
    });
  });
}
