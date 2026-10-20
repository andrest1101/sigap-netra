import '../../../../l10n/generated/app_localizations.dart';

/// Kategori manusiawi untuk kode `type` event perangkat.
///
/// Kode mentah tetap tampil di Log koneksi (untuk diagnosis), sedangkan kartu
/// ringkasan Perangkat hanya menampilkan kategori agar tidak terbaca seperti
/// log teknis. Pemetaan berbasis prefiks dan selalu punya fallback: firmware
/// boleh menambah tipe baru tanpa membuat kartu menampilkan kode asing.
String eventCategoryLabel(String type, AppLocalizations l10n) {
  final normalized = type.trim().toLowerCase();
  if (normalized.isEmpty) return l10n.eventsCategoryGeneral;
  if (normalized.startsWith('wlan') ||
      normalized.startsWith('wifi') ||
      normalized.startsWith('network')) {
    return l10n.eventsCategoryNetwork;
  }
  if (normalized.startsWith('command')) return l10n.eventsCategoryCommand;
  if (normalized.startsWith('boot') ||
      normalized.startsWith('system') ||
      normalized.startsWith('heartbeat') ||
      normalized.startsWith('power') ||
      normalized.startsWith('config') ||
      normalized.startsWith('storage') ||
      normalized.startsWith('battery') ||
      normalized.startsWith('auth')) {
    return l10n.eventsCategorySystem;
  }
  if (normalized.startsWith('detection') ||
      normalized.startsWith('camera') ||
      normalized.startsWith('lidar') ||
      normalized.startsWith('sensor') ||
      normalized.startsWith('ocr') ||
      normalized.startsWith('yolo')) {
    return l10n.eventsCategoryReading;
  }
  return l10n.eventsCategoryGeneral;
}
