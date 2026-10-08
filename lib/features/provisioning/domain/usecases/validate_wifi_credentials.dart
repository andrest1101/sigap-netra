import '../entities/wifi_credentials.dart';

/// Validasi form kredensial Wi-Fi tanpa membangun payload QR.
///
/// `BuildWifiQrPayload` belum diimplementasikan karena format payload final
/// masih berstatus `[PERLU KONFIRMASI]` dan harus diekstrak dari aplikasi
/// Kotlin lama/firmware.
class ValidateWifiCredentials {
  const ValidateWifiCredentials();

  /// Mengembalikan pesan error validasi atau null bila valid.
  String? call({
    required WifiCredentials credentials,
    required String emptySsidMessage,
    required String shortPasswordMessage,
    int minimumPasswordLength = 8,
  }) {
    if (credentials.ssid.trim().isEmpty) return emptySsidMessage;
    if (credentials.password.length < minimumPasswordLength) {
      return shortPasswordMessage;
    }
    return null;
  }
}
