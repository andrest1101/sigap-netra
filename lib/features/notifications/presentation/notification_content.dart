import '../../../../core/utils/number_format_id.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../monitoring/domain/entities/detection.dart';

/// Judul dan isi satu notifikasi pembacaan.
class DetectionNotificationContent {
  const DetectionNotificationContent({required this.title, required this.body});

  final String title;
  final String body;
}

/// Menyusun notifikasi dari pembacaan tanpa membocorkan isi OCR.
///
/// Uang boleh menampilkan nominal. Teks hanya menyebut bahwa perangkat membaca
/// teks — isi `ocrText` dapat berisi informasi pribadi dan tetap hanya terlihat
/// setelah pengguna membuka aplikasi.
DetectionNotificationContent buildDetectionNotificationContent(
  Detection detection,
  AppLocalizations l10n,
) {
  switch (detection.type) {
    case DetectionType.money:
      final amount = detection.amount;
      return DetectionNotificationContent(
        title: l10n.notificationMoneyTitle,
        body: amount == null
            ? l10n.notificationMoneyUnknownBody(detection.deviceName)
            : l10n.notificationMoneyBody(
                NumberFormatId.rupiah(amount),
                detection.deviceName,
              ),
      );
    case DetectionType.text:
      return DetectionNotificationContent(
        title: l10n.notificationTextTitle,
        body: l10n.notificationTextBody(detection.deviceName),
      );
  }
}
