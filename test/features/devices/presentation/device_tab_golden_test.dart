import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/time/now_provider.dart';
import 'package:sigap_netra_app/core/widgets/battery_ring.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/commands/domain/entities/device_command.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/screens/device_list_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/app_fonts.dart';
import '../../../helpers/fake_app_graph.dart';
import '../../../helpers/golden_clock.dart';

/// Repository tiruan: satu perangkat online + baterai 82.
class _FakeDeviceRepository implements DeviceRepository {
  _FakeDeviceRepository();

  final StreamController<List<Device>> _controller =
      StreamController<List<Device>>.broadcast();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) {
    return Stream<List<Device>>.multi((controller) {
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<Device?> watchDevice(String deviceId) => _controller.stream.map(
    (devices) => devices.where((d) => d.deviceId == deviceId).firstOrNull,
  );

  void emit(List<Device> devices) => _controller.add(devices);

  Future<void> close() => _controller.close();
}

/// Golden test tab Perangkat: memotret hasil render AKTUAL (terang-saja).
///
/// File PNG tersimpan di `test/features/devices/goldens/` dan diinspeksi
/// manual sebelum presentasi — bukan tebakan dari membaca kode.
void main() {
  late _FakeDeviceRepository repository;

  setUpAll(loadAppFonts);
  setUp(() => repository = _FakeDeviceRepository());
  tearDown(() => repository.close());

  Future<FakeAppGraph> pumpDevices(
    WidgetTester tester, {
    Size surface = const Size(800, 1400),
  }) async {
    final graph = FakeAppGraph(now: goldenNow);
    // Tinggi 1400 px untuk golden halaman penuh; golden ponsel memakai
    // 390x844 agar kepadatan nyata ikut terbukti.
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => goldenNow),
          deviceRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          ...graph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: const DeviceListScreen(),
        ),
      ),
    );
    return graph;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  Device device() => Device(
    deviceId: kDemoDeviceId,
    name: 'Kacamata Cerdas',
    connectivity: DeviceConnectivity.online,
    lastSeen: goldenNow,
    model: 'MaixCAM',
    firmwareVersion: 'simulasi-1.0.0',
    batteryPct: 82,
  );

  group('Golden tab Perangkat', () {
    testWidgets('light: render aktual', (tester) async {
      await pumpDevices(tester);
      repository.emit([device()]);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      // Caption "Baterai" dihapus: ring + angka saja.
      expect(find.text('Baterai'), findsNothing);

      await expectLater(
        find.byType(DeviceListScreen),
        matchesGoldenFile('../goldens/device_tab_light.png'),
      );
    });

    testWidgets('light: ponsel 390x844', (tester) async {
      await pumpDevices(tester, surface: const Size(390, 844));
      repository.emit([device()]);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);
      expect(find.byType(BatteryRing), findsOneWidget);

      await expectLater(
        find.byType(DeviceListScreen),
        matchesGoldenFile('../goldens/device_tab_phone_light.png'),
      );
    });

    testWidgets('BatteryRing Perangkat identik dengan Beranda', (tester) async {
      await pumpDevices(tester);
      repository.emit([device()]);
      await settle(tester);

      // Regression: ring baterai Beranda dan Perangkat pernah divergen
      // (cincin abu rusak vs cincin hijau). Keduanya wajib memakai widget
      // bersama BatteryRing dengan ukuran sama (56, tanpa caption).
      final rings = tester.widgetList<BatteryRing>(find.byType(BatteryRing));
      expect(rings, isNotEmpty);
      for (final ring in rings) {
        expect(ring.diameter, 56);
        expect(ring.batteryPct, 82);
      }
      // Angka tengah memakai warna angka default tema (bukan putih paksa).
      expect(find.text('82'), findsOneWidget);
    });

    testWidgets('chip Kontrol + status berteks gelap di kartu terang', (
      tester,
    ) async {
      await pumpDevices(tester);
      repository.emit([device()]);
      await settle(tester);

      // Regression: teks chip pernah putih (onPrimary dipakai untuk semua
      // chip). `Text.style` chip selalu null — warna efektif datang dari
      // `DefaultTextStyle` chip (hasil `chipTheme.labelStyle`).
      for (final label in [
        'Sinkronkan sekarang',
        'Volume',
        'Ucapkan teks',
        'Mulai ulang',
        'Kejadian terakhir',
        'Perintah terakhir',
        'Info',
        'Peringatan',
        'Gangguan',
      ]) {
        final finder = find.text(label);
        if (finder.evaluate().isEmpty) continue;
        final text = tester.widget<Text>(finder.first);
        final element = tester.element(finder.first);
        final raw =
            text.style?.color ?? DefaultTextStyle.of(element).style.color;
        expect(raw, isNotNull, reason: 'label "$label" tanpa warna efektif');
        final color = raw is WidgetStateColor
            ? raw.resolve(const <WidgetState>{})
            : raw!;
        expect(
          color.computeLuminance() < 0.5,
          isTrue,
          reason: 'teks chip "$label" terlalu terang ($color)',
        );
      }
    });

    testWidgets('dua seksi timeline terpisah: kejadian vs perintah', (
      tester,
    ) async {
      await pumpDevices(tester);
      repository.emit([device()]);
      await settle(tester);

      // Versi lama mencampur event dan perintah dalam satu daftar tanpa
      // label; sekarang masing-masing punya seksi sendiri.
      expect(find.text('Kejadian terakhir'), findsOneWidget);
      expect(find.text('Perintah terakhir'), findsOneWidget);
      expect(find.text('Perangkat selesai booting.'), findsOneWidget);
      expect(find.textContaining('Sinkronisasi selesai.'), findsOneWidget);

      // Saringan severity tidak lagi menumpang di kartu ringkasan: filter
      // menyeluruh ada di Log koneksi. Chip status per baris tetap tampil.
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Lihat semua'), findsNWidgets(2));

      // Kode mentah (wlan_disconnected, command_failed) diganti kategori
      // manusiawi di kartu; kode asli tetap tersedia di Log koneksi.
      expect(find.textContaining('· Jaringan'), findsOneWidget);
      expect(find.textContaining('· Perintah'), findsOneWidget);
      expect(find.textContaining('· Sistem'), findsOneWidget);
      expect(find.textContaining('wlan_disconnected'), findsNothing);
      expect(find.textContaining('command_failed'), findsNothing);
    });

    testWidgets('tombol Sinkronkan benar-benar mengirim perintah', (
      tester,
    ) async {
      final graph = await pumpDevices(tester);
      repository.emit([device()]);
      await settle(tester);
      final before = graph.commands.itemsForTest.length;

      // `FilledButton.tonalIcon` menghasilkan subclass privat, jadi finder
      // berbasis tipe generik tidak cukup — cari lewat labelnya.
      final button = find
          .ancestor(
            of: find.text('Sinkronkan sekarang'),
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          )
          .first;
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(graph.commands.itemsForTest.length, before + 1);
      expect(graph.commands.itemsForTest.first.status, CommandStatus.pending);
      expect(find.text('Perintah dikirim.'), findsOneWidget);
      // Bahasa jujur saat perintah masih menunggu alat.
      expect(find.textContaining('Menunggu alat'), findsWidgets);

      // Habiskan timer simulasi device (1 dtk ack, 2 dtk done) + snackbar.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('slider volume mengirim perintah setVolume', (tester) async {
      final graph = await pumpDevices(tester);
      repository.emit([device()]);
      await settle(tester);
      final before = graph.commands.itemsForTest.length;

      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      await tester.pump();
      await tester.drag(slider, const Offset(-160, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(graph.commands.itemsForTest.length, before + 1);
      final newest = graph.commands.itemsForTest.first;
      expect(newest.type, CommandType.setVolume);
      expect(newest.payload['level'], isA<int>());

      await tester.pump(const Duration(seconds: 5));
    });
  });

  // matchesGoldenFile() resolusinya relatif file test; Directory() relatif cwd.
  test('golden dir tersedia', () {
    const dir = 'test/features/devices/goldens';
    expect(Directory(dir).existsSync(), isTrue);
    expect(File('$dir/device_tab_light.png').existsSync(), isTrue);
  });
}
