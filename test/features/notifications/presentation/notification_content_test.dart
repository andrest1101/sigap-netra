import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/notifications/presentation/notification_content.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

Detection _detection({
  required DetectionType type,
  int? amount,
  String? ocrText,
}) {
  return Detection(
    id: 'det-1',
    deviceId: 'dev-1',
    deviceName: 'Kacamata Cerdas',
    type: type,
    createdAt: DateTime(2026, 10, 26, 10),
    amount: amount,
    ocrText: ocrText,
  );
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('id'));

  group('buildDetectionNotificationContent', () {
    test('uang menampilkan nominal dan nama perangkat', () {
      final content = buildDetectionNotificationContent(
        _detection(type: DetectionType.money, amount: 20000),
        l10n,
      );

      expect(content.title, 'Pembacaan uang baru');
      expect(content.body, contains('Rp 20.000'));
      expect(content.body, contains('Kacamata Cerdas'));
    });

    test('uang tanpa nominal memakai pesan jujur', () {
      final content = buildDetectionNotificationContent(
        _detection(type: DetectionType.money),
        l10n,
      );

      expect(content.body, contains('Nominal belum terbaca'));
      expect(content.body, contains('Kacamata Cerdas'));
    });

    test('teks TIDAK membocorkan isi OCR', () {
      final content = buildDetectionNotificationContent(
        _detection(
          type: DetectionType.text,
          ocrText: 'PESAN PRIBADI YANG TIDAK BOLEH TAMPIL',
        ),
        l10n,
      );

      expect(content.title, 'Pembacaan teks baru');
      expect(content.body, isNot(contains('PESAN PRIBADI')));
      expect(content.body, contains('Kacamata Cerdas'));
      expect(content.body, contains('Buka aplikasi'));
    });
  });
}
