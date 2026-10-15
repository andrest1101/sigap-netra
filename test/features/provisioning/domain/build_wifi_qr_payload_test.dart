import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/provisioning/domain/entities/wifi_credentials.dart';
import 'package:sigap_netra_app/features/provisioning/domain/usecases/build_wifi_qr_payload.dart';

/// Payload QR Wi-Fi harus identik dengan format aplikasi Kotlin lama
/// (`WIFI:T:WPA;S:<ssid>;P:<sandi>;;`) — jangan pernah mengubah bentuknya
/// tanpa mengekstrak format baru dari aplikasi lama / firmware.
void main() {
  group('buildWifiQrPayload', () {
    test('format dasar identik dengan aplikasi lama', () {
      expect(
        buildWifiQrPayload(
          const WifiCredentials(ssid: 'Hotspot-Andre', password: 'rahasia123'),
        ),
        'WIFI:T:WPA;S:Hotspot-Andre;P:rahasia123;;',
      );
    });

    test('meng-escape karakter khusus ZXing dengan backslash', () {
      expect(
        buildWifiQrPayload(
          const WifiCredentials(
            ssid: r'Netra;A,B:C\D"E',
            password: r'p;a,s:s\w"d',
          ),
        ),
        r'WIFI:T:WPA;S:Netra\;A\,B\:C\\D\"E;P:p\;a\,s\:s\\w\"d;;',
      );
    });

    test('kata sandi kosong menghilangkan bagian P', () {
      expect(
        buildWifiQrPayload(const WifiCredentials(ssid: 'Guest', password: '')),
        'WIFI:T:WPA;S:Guest;;',
      );
    });

    test('hidden menambahkan H:true sebelum terminator', () {
      expect(
        buildWifiQrPayload(
          const WifiCredentials(ssid: 'S', password: 'p'),
          hidden: true,
        ),
        'WIFI:T:WPA;S:S;P:p;H:true;;',
      );
    });

    test('tipe keamanan dapat diganti eksplisit', () {
      expect(
        buildWifiQrPayload(
          const WifiCredentials(ssid: 'S', password: 'p'),
          security: 'WEP',
        ),
        'WIFI:T:WEP;S:S;P:p;;',
      );
    });
  });
}
