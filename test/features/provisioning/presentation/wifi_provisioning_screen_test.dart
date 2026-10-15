import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sigap_netra_app/features/provisioning/presentation/screens/wifi_provisioning_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Smoke: langkah QR benar-benar merender kode dari isi form — bukan hanya
/// shell kosong. Payload yang dirender wajib sama dengan format aplikasi lama.
void main() {
  testWidgets('langkah QR merender QrImageView dari kredensial form', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: WifiProvisioningScreen(deviceId: 'simulasi-maixcam-1'),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Hotspot-Andre');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia123');

    // Stepper menyimpan konten semua langkah di tree (crossfade), jadi
    // "Lanjut" milik langkah Jaringan adalah yang pertama.
    final next = find.text('Lanjut').first;
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Kode benar-benar dirender (QrImageView.data privat di qr_flutter 4.x;
    // isi payload diuji di build_wifi_qr_payload_test).
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.size, 220);
    expect(find.textContaining('WIFI:T:WPA;S:…;P:…;;'), findsOneWidget);

    // Pembungkus Semantics untuk pembaca layar ikut terpasang pada kode QR.
    final wrappers = tester.widgetList<Semantics>(find.byType(Semantics));
    expect(
      wrappers.any(
        (s) =>
            s.properties.image == true && s.properties.label == 'Tampilkan QR',
      ),
      isTrue,
    );
  });
}
