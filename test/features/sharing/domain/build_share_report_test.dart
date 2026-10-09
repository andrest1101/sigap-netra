import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/sharing/domain/entities/share_report.dart';
import 'package:sigap_netra_app/features/sharing/domain/usecases/build_share_report.dart';

void main() {
  group('buildShareText', () {
    test('menggabung judul, baris, dan kutipan', () {
      const report = ShareReport(
        title: 'Hasil pembacaan uang',
        lines: ['Nominal Rp 50.000', 'Keyakinan 92%'],
        ocrExcerpt: 'Teks menu',
      );

      final text = buildShareText(report);

      expect(text, contains('Hasil pembacaan uang'));
      expect(text, contains('Nominal Rp 50.000'));
      expect(text, contains('Teks menu'));
      expect(text, isNot(contains('simulasi-maixcam-1')));
    });

    test('tanpa kutipan bila null', () {
      const report = ShareReport(title: 'Judul', lines: ['Baris 1']);

      expect(buildShareText(report), 'Judul\nBaris 1');
    });
  });

  group('buildShareReport', () {
    Detection detection({String? ocrText}) {
      return Detection(
        id: 'det-1',
        deviceId: 'simulasi-maixcam-1',
        deviceName: 'Kacamata Cerdas',
        type: DetectionType.text,
        createdAt: DateTime(2026, 10, 8, 12),
        ocrText: ocrText,
      );
    }

    test('tanpa OCR bila consent ditolak', () {
      final report = buildShareReport(
        detection(ocrText: 'Rahasia pribadi'),
        title: 'Judul',
        lines: const ['Baris'],
        includeOcrText: false,
      );

      expect(report.ocrExcerpt, isNull);
    });

    test('OCR disertakan bila consent diberikan', () {
      final report = buildShareReport(
        detection(ocrText: 'Menu makan siang'),
        title: 'Judul',
        lines: const ['Baris'],
        includeOcrText: true,
      );

      expect(report.ocrExcerpt, 'Menu makan siang');
    });

    test('OCR panjang dipotong 500 karakter', () {
      final report = buildShareReport(
        detection(ocrText: 'z' * 600),
        title: 'Judul',
        lines: const ['Baris'],
        includeOcrText: true,
      );

      expect(report.ocrExcerpt, hasLength(500));
    });
  });
}
