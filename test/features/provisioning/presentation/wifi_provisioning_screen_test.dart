import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/provisioning/presentation/screens/wifi_provisioning_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Repository perangkat tiruan dengan `lastSeen` yang hanya bergerak saat test
/// memintanya — meniru heartbeat device baru setelah QR dipindai.
class _FakeDeviceRepository implements DeviceRepository {
  static const String deviceId = 'simulasi-maixcam-1';

  /// `lastSeen` patokan (data terakhir sebelum QR dipindai).
  static final DateTime baseline = DateTime(2026, 10, 18, 12);

  final StreamController<Device?> _controller =
      StreamController<Device?>.broadcast();

  Device device({DateTime? lastSeen}) => Device(
    deviceId: deviceId,
    name: 'Kacamata Cerdas',
    model: 'MaixCAM',
    connectivity: DeviceConnectivity.online,
    lastSeen: lastSeen ?? baseline,
  );

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) => _controller
      .stream
      .map((device) => device == null ? <Device>[] : [device]);

  @override
  Stream<Device?> watchDevice(String id) => _controller.stream.map(
    (device) => device?.deviceId == id ? device : null,
  );

  void emit(Device value) => _controller.add(value);

  Future<void> close() => _controller.close();
}

void main() {
  late _FakeDeviceRepository repository;

  setUp(() => repository = _FakeDeviceRepository());
  tearDown(() => repository.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deviceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: WifiProvisioningScreen(
            deviceId: _FakeDeviceRepository.deviceId,
          ),
        ),
      ),
    );
  }

  /// Isi form lalu jalan sampai langkah "Menunggu alat" (indeks 2).
  Future<void> goToWaitingStep(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'Hotspot-Andre');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia123');

    // Stepper menyimpan konten semua langkah di tree (crossfade), jadi
    // "Lanjut" milik langkah Jaringan adalah yang pertama.
    final next = find.text('Lanjut').first;
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // "Lanjut" kedua = tombol panel QR menuju langkah menunggu.
    final startWaiting = find.text('Lanjut').last;
    await tester.ensureVisible(startWaiting);
    await tester.pump();
    await tester.tap(startWaiting);
    await tester.pump();
  }

  testWidgets('langkah QR merender QrImageView dari kredensial form', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Hotspot-Andre');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia123');

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

  testWidgets('detak baru setelah QR dipindai menampilkan "terhubung"', (
    tester,
  ) async {
    await pumpScreen(tester);
    // Data perangkat terakhir sebelum pemindaian.
    repository.emit(repository.device());
    await tester.pump();

    await goToWaitingStep(tester);
    expect(find.text('120'), findsOneWidget);
    expect(find.textContaining('Menunggu 120 dtk'), findsOneWidget);

    // Belum ada detak baru: tetap menunggu (bukan klaim sukses kosong).
    repository.emit(repository.device());
    await tester.pump();
    expect(find.text('Perangkat berhasil terhubung.'), findsNothing);

    // Detak baru: `lastSeen` maju melewati patokan → terhubung.
    repository.emit(
      repository.device(
        lastSeen: _FakeDeviceRepository.baseline.add(
          const Duration(seconds: 30),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Perangkat berhasil terhubung.'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Belum tersambung'), findsNothing);

    // Hitung mundur tidak lagi berjalan: lewati jauh dari 120 dtk dan state
    // sukses wajib bertahan (timer sudah dibatalkan saat terhubung).
    await tester.pump(const Duration(seconds: 130));
    expect(find.text('Perangkat berhasil terhubung.'), findsOneWidget);
    expect(find.text('Belum tersambung'), findsNothing);
  });

  testWidgets(
    'hitung mundur habis tanpa detak → "Belum tersambung" + coba lagi',
    (tester) async {
      await pumpScreen(tester);
      repository.emit(repository.device());
      await tester.pump();

      await goToWaitingStep(tester);
      expect(find.text('120'), findsOneWidget);

      // Lewati 2 menit penuh tanpa detak baru.
      await tester.pump(const Duration(seconds: 121));

      expect(find.text('Belum tersambung'), findsOneWidget);
      expect(find.textContaining('belum mengirim detak'), findsOneWidget);
      expect(find.text('Perangkat berhasil terhubung.'), findsNothing);

      // "Coba lagi" mengulang hitung mundur dari awal.
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(find.text('Belum tersambung'), findsNothing);
      expect(find.text('120'), findsOneWidget);
    },
  );
}
