import '../entities/wifi_credentials.dart';

/// Tipe keamanan Wi-Fi pada payload QR.
const String kWifiSecurityWpa = 'WPA';

/// Karakter yang wajib di-escape pada payload QR Wi-Fi (spesifikasi ZXing).
const Set<String> _specialChars = {r'\', ';', ',', ':', '"'};

/// Fungsi murni: membangun payload QR Wi-Fi sesuai format aplikasi lama.
///
/// Bentuk payload (format standar ZXing yang juga dipakai aplikasi Kotlin
/// lama / firmware): `WIFI:T:WPA;S:<ssid>;P:<password>;;`
///
/// Karakter `\`, `;`, `,`, `:` dan `"` di-escape dengan `\` agar SSID dan
/// kata sandi yang memuatnya tetap terbaca utuh oleh pemindai. Kata sandi
/// kosong menghilangkan bagian `P:` (bukan `P:;`), sesuai perilaku pemindai
/// umum untuk jaringan terbuka.
///
/// PRIVASI: hasil hanya hidup di layar QR selama proses provisioning — kata
/// sandi tidak pernah disimpan ke preferensi, log, atau Firestore.
String buildWifiQrPayload(
  WifiCredentials credentials, {
  String security = kWifiSecurityWpa,
  bool hidden = false,
}) {
  final parts = <String>['T:$security', 'S:${_escape(credentials.ssid)}'];
  if (credentials.password.isNotEmpty) {
    parts.add('P:${_escape(credentials.password)}');
  }
  if (hidden) {
    parts.add('H:true');
  }
  return 'WIFI:${parts.join(';')};;';
}

/// Menambahkan backslash di depan karakter khusus ZXing.
String _escape(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    if (_specialChars.contains(char)) buffer.write(r'\');
    buffer.write(char);
  }
  return buffer.toString();
}
