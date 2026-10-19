import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Golden segmen Statistik Riwayat (terang-saja).
///
/// Jendela 7 hari dipilih karena angkanya **selalu sama**: sampel demo
/// dibangkitkan relatif ke hari ini, jadi total/akurasi tidak berubah
/// antartanggal — hanya urutan nama hari yang berotasi, dan font test
/// merender setiap huruf sebagai kotak berukuran sama sehingga gambar tetap
/// stabil. (Jendela 4 minggu memakai label tanggal "1 Okt"/"22 Sep" yang
/// panjangnya berubah, jadi tidak dijadikan golden.)
void main() {
  Future<void> pumpStats(WidgetTester tester) async {
    final graph = FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
          ...graph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: const HistoryScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));

    await tester.tap(find.text('Statistik'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  group('Golden panel Statistik Riwayat', () {
    testWidgets('7 hari — ring akurasi, grafik, komposisi (terang)', (
      tester,
    ) async {
      // Tinggi ekstra supaya seluruh panel terekam, bukan hanya hero.
      await tester.binding.setSurfaceSize(const Size(800, 1180));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStats(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('91%'), findsOneWidget);
      await expectLater(
        find.byType(HistoryScreen),
        matchesGoldenFile('../goldens/history_stats_light.png'),
      );
    });
  });
}
