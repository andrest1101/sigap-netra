import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/battery_ring.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/screens/device_list_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

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

/// Golden test tab Perangkat: memotret hasil render AKTUAL (light + dark).
///
/// File PNG tersimpan di `test/goldens/` dan diinspeksi manual sebelum
/// presentasi — bukan tebakan dari membaca kode.
void main() {
  late _FakeDeviceRepository repository;

  setUp(() => repository = _FakeDeviceRepository());
  tearDown(() => repository.close());

  Future<void> pumpDevices(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const DeviceListScreen(),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  Device device() => Device(
    deviceId: 'dev-1',
    name: 'Kacamata Cerdas',
    connectivity: DeviceConnectivity.online,
    lastSeen: DateTime.now(),
    model: 'MaixCAM',
    firmwareVersion: 'simulasi-1.0.0',
    batteryPct: 82,
  );

  group('Golden tab Perangkat', () {
    testWidgets('light: render aktual', (tester) async {
      await pumpDevices(tester, mode: ThemeMode.light);
      repository.emit([device()]);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      expect(find.text('Baterai'), findsWidgets);

      await expectLater(
        find.byType(DeviceListScreen),
        matchesGoldenFile('../goldens/device_tab_light.png'),
      );
    });

    testWidgets('dark: render aktual', (tester) async {
      await pumpDevices(tester, mode: ThemeMode.dark);
      repository.emit([device()]);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);

      await expectLater(
        find.byType(DeviceListScreen),
        matchesGoldenFile('../goldens/device_tab_dark.png'),
      );
    });

    testWidgets('BatteryRing Perangkat identik dengan Beranda', (tester) async {
      await pumpDevices(tester, mode: ThemeMode.light);
      repository.emit([device()]);
      await settle(tester);

      // Regression: ring baterai Beranda dan Perangkat pernah divergen
      // (cincin abu rusak vs cincin hijau). Keduanya wajib memakai widget
      // bersama BatteryRing dengan diameter sama.
      final rings = tester.widgetList<BatteryRing>(find.byType(BatteryRing));
      expect(rings, isNotEmpty);
      for (final ring in rings) {
        expect(ring.diameter, 64);
        expect(ring.batteryPct, 82);
      }
      // Angka tengah memakai warna angka default tema (bukan putih paksa).
      expect(find.text('82'), findsOneWidget);
    });

    testWidgets('chip Kontrol + Severity berteks gelap di kartu terang', (
      tester,
    ) async {
      await pumpDevices(tester, mode: ThemeMode.light);
      repository.emit([device()]);
      await settle(tester);

      // Regression: teks chip pernah putih (onPrimary dipakai untuk semua
      // chip). `Text.style` chip selalu null — warna efektif datang dari
      // `DefaultTextStyle` chip (hasil `chipTheme.labelStyle`).
      for (final label in [
        'Sinkronkan sekarang',
        'Atur volume',
        'Ucapkan teks',
        'Mulai ulang',
        'Semua',
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
  });

  // matchesGoldenFile() resolusinya relatif file test; Directory() relatif cwd.
  test('golden dir tersedia', () {
    const dir = 'test/features/devices/goldens';
    expect(Directory(dir).existsSync(), isTrue);
    expect(File('$dir/device_tab_light.png').existsSync(), isTrue);
    expect(File('$dir/device_tab_dark.png').existsSync(), isTrue);
  });
}
