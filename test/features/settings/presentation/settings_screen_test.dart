import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sigap_netra_app/features/settings/domain/entities/data_source.dart';
import 'package:sigap_netra_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:sigap_netra_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_notification_gateway.dart';

void main() {
  Future<SharedPreferences> pumpSettings(
    WidgetTester tester, {
    DataSourceSelection selection = const DataSourceSelection.firebase(),
    double textScale = 1.0,
    double bottomInset = 0,
    FakeNotificationGateway? notificationGateway,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final gateway = notificationGateway ?? FakeNotificationGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          dataSourceSelectionProvider.overrideWithValue(selection),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          notificationGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(textScale),
                  // Meniru navigation bar Android (edge-to-edge) pada
                  // pengujian layout bawah.
                  padding: media.padding.copyWith(bottom: bottomInset),
                  viewPadding: media.viewPadding.copyWith(bottom: bottomInset),
                ),
                child: const SettingsScreen(),
              );
            },
          ),
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

  group('Pengaturan — notifikasi', () {
    testWidgets('default mati; menyalakan meminta izin lalu menyimpan', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway();
      final preferences = await pumpSettings(
        tester,
        notificationGateway: gateway,
      );

      expect(switchTileOf(tester, 'Notifikasi pembacaan').value, isFalse);

      await tester.tap(find.text('Notifikasi pembacaan'));
      await tester.pumpAndSettle();

      expect(switchTileOf(tester, 'Notifikasi pembacaan').value, isTrue);
      expect(preferences.getBool('detection_notifications_enabled'), isTrue);
      expect(gateway.permissionRequests, 1);
    });

    testWidgets('izin ditolak: saklar tetap mati dan pengguna diberi tahu', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway(permissionGranted: false);
      final preferences = await pumpSettings(
        tester,
        notificationGateway: gateway,
      );

      await tester.tap(find.text('Notifikasi pembacaan'));
      await tester.pumpAndSettle();

      expect(switchTileOf(tester, 'Notifikasi pembacaan').value, isFalse);
      expect(
        preferences.getBool('detection_notifications_enabled'),
        isNot(true),
      );
      expect(find.textContaining('Izin notifikasi ditolak'), findsOneWidget);
      expect(gateway.permissionRequests, 1);
    });
  });

  group('Pengaturan — lanjutan & tentang', () {
    testWidgets('mode pengembang menulis preferensi', (tester) async {
      final preferences = await pumpSettings(tester);

      // Kartu Lanjutan kini berada di bawah lipatan karena ada seksi
      // Notifikasi di antaranya.
      await tester.scrollUntilVisible(find.text('Mode pengembang'), 300);
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
      await tester.scrollUntilVisible(find.text('Mode pengembang'), 300);
      expect(switchTileOf(tester, 'Mode pengembang').value, isFalse);
      // … tetapi aplikasi tetap harus jujur bahwa datanya simulasi.
      await tester.scrollUntilVisible(
        find.text('Simulasi — Firebase belum tersedia pada build ini.'),
        300,
      );
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

      await tester.scrollUntilVisible(
        find.text('Firebase — data tersinkron ke cloud.'),
        300,
      );
      expect(find.text('Firebase — data tersinkron ke cloud.'), findsOneWidget);
    });

    testWidgets('versi tampil sinkron dengan konstanta bersama', (
      tester,
    ) async {
      await pumpSettings(tester);

      // Tentang berada di bawah lipatan pada viewport default test.
      await tester.scrollUntilVisible(find.text('1.0.0+1'), 300);
      // Satu sumber versi: `kAppVersionDisplay` di app_constants.dart,
      // dijaga sinkron dengan pubspec (1.0.0+1).
      expect(find.text('1.0.0+1'), findsOneWidget);
    });
  });

  group('Pengaturan — tata letak', () {
    testWidgets('360x800 @1,3x: kartu seksi muat tanpa overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpSettings(tester, textScale: 1.3);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Privasi dan data'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Lanjutan'), 300);
      expect(tester.takeException(), isNull);
      expect(find.text('Lanjutan'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Tentang'), 300);
      expect(tester.takeException(), isNull);
      expect(find.text('Tentang'), findsOneWidget);
      expect(find.text('1.0.0+1'), findsOneWidget);
    });

    testWidgets(
      '360x800 @1,3x + navigation bar: versi Tentang tetap terlihat penuh',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Android edge-to-edge: navigation bar 48 dp menutupi bagian bawah
        // Scaffold bila body tidak memakai SafeArea.
        await pumpSettings(tester, textScale: 1.3, bottomInset: 48);
        await tester.pump();

        await tester.scrollUntilVisible(find.text('1.0.0+1'), 300);
        await tester.pump();

        expect(tester.takeException(), isNull);
        final versionRect = tester.getRect(find.text('1.0.0+1'));
        expect(
          versionRect.bottom,
          lessThanOrEqualTo(800 - 48),
          reason: 'baris versi tidak boleh masuk area navigation bar',
        );
        // Masih ada ruang gulir setelah kartu Tentang, bukan berhenti tepat
        // di tepi inset.
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.body, isA<SafeArea>());
      },
    );
  });
}
