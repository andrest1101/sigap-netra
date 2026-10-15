import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/data/datasources/fake_device_data_source.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/home/presentation/home_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../helpers/fake_app_graph.dart';

/// Regresi P0 presentasi, sekaligus membuktikan perilaku simulasi aslinya
/// (`lib/`, bukan helper test): selama belum ada pengguna, provider pengguna
/// sudah terbaca lewat rantai daftar perangkat (root `app.dart` memantau untuk
/// cache nama). `currentUserProvider` yang tidak reaktif membuat `null`
/// ter-cache selamanya sehingga Beranda tetap "Belum ada perangkat" meski
/// login berhasil. Test ini menuntut perangkat demo muncul untuk semua akun —
/// email maupun tamu — supaya demo tanpa hardware aman.
void main() {
  testWidgets('login email dan tamu memunculkan perangkat demo di Beranda', (
    tester,
  ) async {
    final graph = FakeAppGraph();
    final authDataSource = FakeAuthDataSource();
    final deviceDataSource = FakeDeviceDataSource();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepositoryImpl(authDataSource),
          ),
          deviceRepositoryProvider.overrideWithValue(
            FakeDeviceRepositoryImpl(deviceDataSource),
          ),
          ...graph.overrides,
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: HomeScreen(),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    // Sebelum login: state kosong (bukan error).
    await _pumpFlush(tester);
    expect(find.text('Belum ada perangkat'), findsOneWidget);

    // Login email (simulasi memakai UID demo) → perangkat demo muncul.
    await container
        .read(authRepositoryProvider)
        .signInWithEmail(
          email: 'presentasi@sigapnetra.local',
          password: 'kacamata-cerdas',
        );
    await _pumpFlush(tester);
    expect(find.text('Kacamata Cerdas'), findsWidgets);
    expect(find.text('Belum ada perangkat'), findsNothing);

    // Keluar → kembali ke state kosong.
    await container.read(authRepositoryProvider).signOut();
    await _pumpFlush(tester);
    expect(find.text('Belum ada perangkat'), findsOneWidget);

    // Tamu → perangkat demo tetap terlihat (keputusan cakupan presentasi).
    await container.read(authRepositoryProvider).signInAnonymously();
    await _pumpFlush(tester);
    expect(find.text('Kacamata Cerdas'), findsWidgets);

    // Timer detak simulasi tidak terikat siklus hidup provider: matikan di
    // dalam badan test supaya tidak tertinggal saat finalisasi tree.
    deviceDataSource.dispose();
    authDataSource.dispose();
  });
}

/// Memompa transisi stream + rebuild, lalu melewati satu detak konektivitas
/// 15 detik supaya timer periodiknya tercatat pernah fire (pola yang sama
/// dengan widget test Beranda lain).
Future<void> _pumpFlush(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(seconds: 16));
}
