import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/lens_ring.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/home/presentation/home_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';
import '../../../helpers/precache_logo.dart';

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

  Future<void> pumpHome(WidgetTester tester) async {
    // Hero memuat mark merek (aset) — precache agar golden menampilkan logo.
    await precacheLogoMark(tester);
    final graph = FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    deviceId: kDemoDeviceId,
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
      // Nama muncul 2x: subjudul app bar + Hero.
      expect(find.text('Kacamata Cerdas'), findsWidgets);
      // Hero baru: strip stats menampilkan persen (tanpa ring besar).
      expect(find.text('82%'), findsOneWidget);

      // Satu-satunya ring besar di Beranda = akurasi bento (78).
      // Ring baterai besar hanya di tab Perangkat — tidak ada dua
      // signature yang bersaing.
      final lensRings = tester.widgetList<LensRing>(find.byType(LensRing));
      final diameters = lensRings.map((r) => r.diameter).toSet();
      expect(diameters, equals({78}));

      // Bento informatif: jam absolut + breakdown kategori + footer akurasi.
      expect(find.textContaining('·'), findsWidgets);
      expect(find.textContaining('uang ·'), findsOneWidget);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('../goldens/home_tab_light.png'),
      );
    });
  });
}
