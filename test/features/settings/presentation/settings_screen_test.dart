import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/settings/domain/entities/data_source.dart';
import 'package:sigap_netra_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:sigap_netra_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

void main() {
  Future<SharedPreferences> pumpSettings(
    WidgetTester tester, {
    DataSourceSelection selection = const DataSourceSelection.firebase(),
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          dataSourceSelectionProvider.overrideWithValue(selection),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    return preferences;
  }

  SwitchListTile switchTileOf(WidgetTester tester, String title) {
    return tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text(title),
        matching: find.byType(SwitchListTile),
      ),
    );
  }

  group('Pengaturan — privasi & data', () {
    testWidgets('catatan retensi jujur, tanpa klaim 30 hari aktif', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(
        find.text(
          'Pembacaan dan thumbnail dapat dihapus kapan saja dari Riwayat. '
          'Penghapusan otomatis 30 hari belum aktif.',
        ),
        findsOneWidget,
      );
      // Klaim lama tidak boleh kembali tanpa mekanisme yang menegakkannya.
      expect(
        find.text('Pembacaan dan thumbnail disimpan maksimal 30 hari.'),
        findsNothing,
      );
      // Kunci mati era mode gelap/bahasa tidak lagi dirender.
      expect(find.text('Bahasa'), findsNothing);
    });

    testWidgets('saklar thumbnail: Batal tidak mengubah preferensi', (
      tester,
    ) async {
      final preferences = await pumpSettings(tester);

      expect(switchTileOf(tester, 'Kirim thumbnail pembacaan').value, isFalse);

      await tester.tap(find.text('Kirim thumbnail pembacaan'));
      await tester.pumpAndSettle();
      expect(find.text('Izinkan pengiriman thumbnail?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(switchTileOf(tester, 'Kirim thumbnail pembacaan').value, isFalse);
      expect(preferences.getBool('upload_thumbnails_privacy'), isNot(true));
    });

    testWidgets('saklar thumbnail: Ya menyimpan consent', (tester) async {
      final preferences = await pumpSettings(tester);

      await tester.tap(find.text('Kirim thumbnail pembacaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya'));
      await tester.pumpAndSettle();

      expect(switchTileOf(tester, 'Kirim thumbnail pembacaan').value, isTrue);
      expect(preferences.getBool('upload_thumbnails_privacy'), isTrue);
    });
  });

  group('Pengaturan — lanjutan & tentang', () {
    testWidgets('mode pengembang menulis preferensi', (tester) async {
      final preferences = await pumpSettings(tester);

      expect(switchTileOf(tester, 'Mode pengembang').value, isFalse);

      await tester.tap(find.text('Mode pengembang'));
      await tester.pump();

      expect(switchTileOf(tester, 'Mode pengembang').value, isTrue);
      expect(preferences.getBool('developer_mode'), isTrue);
    });

    testWidgets('sumber data menampilkan kenyataan, bukan niat toggle', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        selection: const DataSourceSelection.simulation(
          SimulationReason.firebaseUnavailable,
        ),
      );

      // Toggle memang mati (pengguna tidak memilih simulasi) …
      expect(switchTileOf(tester, 'Mode pengembang').value, isFalse);
      // … tetapi aplikasi tetap harus jujur bahwa datanya simulasi.
      expect(
        find.text('Simulasi — Firebase belum tersedia pada build ini.'),
        findsOneWidget,
      );
      expect(find.text('Firebase — data tersinkron ke cloud.'), findsNothing);
    });

    testWidgets('data live menyebut Firebase sebagai sumber aktif', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.text('Firebase — data tersinkron ke cloud.'), findsOneWidget);
    });

    testWidgets('versi tampil sinkron dengan konstanta bersama', (
      tester,
    ) async {
      await pumpSettings(tester);

      // Satu sumber versi: `kAppVersionDisplay` di app_constants.dart,
      // dijaga sinkron dengan pubspec (1.0.0+1).
      expect(find.text('1.0.0+1'), findsOneWidget);
    });
  });
}
