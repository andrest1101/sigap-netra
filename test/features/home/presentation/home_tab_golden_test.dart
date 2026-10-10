import 'dart:async';

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
import 'package:sigap_netra_app/features/home/presentation/home_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Repository tiruan: satu perangkat online, baterai 82.
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

/// Golden tab Beranda (terang): Hero + widget bersama [BatteryRing].
///
/// Regression: ring baterai Beranda pernah dibuat terpisah dari ring
/// tab Perangkat sehingga gaya/rasio divergen.
void main() {
  late _FakeDeviceRepository repository;

  setUp(() => repository = _FakeDeviceRepository());
  tearDown(() => repository.close());

  Future<void> pumpHome(
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
          home: const HomeScreen(),
        ),
      ),
    );
  }

  Future<void> pumpFrames(WidgetTester tester) async {
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
    batteryPct: 82,
  );

  group('Golden tab Beranda', () {
    testWidgets('light: render aktual + ring baterai konsisten', (
      tester,
    ) async {
      await pumpHome(tester);
      repository.emit([device()]);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      // Caption "Baterai" dihapus: ring + angka saja.
      expect(find.text('Baterai'), findsNothing);

      // Widget yang sama dengan tab Perangkat: ukuran + data identik.
      final rings = tester.widgetList<BatteryRing>(find.byType(BatteryRing));
      expect(rings, hasLength(1));
      expect(rings.first.diameter, 56);
      expect(rings.first.batteryPct, 82);
      // Satu-satunya beda yang sah: warna diangka menyesuaikan konteks
      // Hero `primaryContainer` (bukan putih paksa).
      final scheme = Theme.of(
        tester.element(find.byType(HomeScreen)),
      ).colorScheme;
      expect(rings.first.numberColor, scheme.onPrimaryContainer);

      // Bento informatif: jam absolut + breakdown kategori + footer akurasi.
      expect(find.textContaining('·'), findsWidgets);
      expect(find.textContaining('uang ·'), findsOneWidget);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('../goldens/home_tab_light.png'),
      );
    });

    testWidgets('dark: render aktual tanpa error', (tester) async {
      await pumpHome(tester, mode: ThemeMode.dark);
      repository.emit([device()]);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);
    });
  });
}
