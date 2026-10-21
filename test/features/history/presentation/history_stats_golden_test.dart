import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/time/now_provider.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/app_fonts.dart';
import '../../../helpers/fake_app_graph.dart';
import '../../../helpers/golden_clock.dart';

/// Golden segmen Statistik Riwayat (terang-saja).
///
/// Jendela 7 hari dipilih karena angkanya **selalu sama** saat jam dipatok ke
/// [goldenNow]: sampel demo dan batas jendela memakai waktu tetap yang sama,
/// jadi total, akurasi, dan urutan nama hari tidak berubah antartanggal. Font
/// aplikasi dimuat agar label, lebar batang, dan line break diuji apa adanya.
/// (Jendela 4 minggu memakai label tanggal "1 Okt"/"22 Sep" yang panjangnya
/// berubah, jadi tidak dijadikan golden.)
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpStats(WidgetTester tester) async {
    final graph = FakeAppGraph(now: goldenNow);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => goldenNow),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          deviceRepositoryProvider.overrideWithValue(
            DemoDeviceRepository(now: goldenNow),
          ),
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
