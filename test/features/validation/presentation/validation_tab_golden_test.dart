import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/validation/presentation/screens/validation_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Golden tab Validasi (terang + gelap).
///
/// Mengunci: tumpukan kartu + tepi dua kartu samar di belakang (tone
/// `surfaceContainerHigh` + hairline), tombol "Tidak cocok" outlined `bad`
/// / "Cocok" filled `ok` (ui_spec §5.2), progres "1 dari 2", dan baris
/// `MetricChip`. Warna/palet dari `StatusColors` theme extension ikut
/// terverifikasi lewat PNG — bukan hanya "tidak error".
void main() {
  Future<void> pumpValidation(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
  }) async {
    final graph = FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
          // Antrean butuh UID pengguna (filter keanggotaan), jadi test
          // mem-pump sebagai pengguna yang sudah masuk.
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
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const ValidationScreen(),
        ),
      ),
    );
  }

  // Antrean demo memakai animasi + timer; pompa eksplisit secukupnya.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Golden tab Validasi', () {
    testWidgets('light: tumpukan kartu + aksi status ok/bad', (tester) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('1 dari 2'), findsOneWidget);
      expect(find.textContaining('100.000'), findsWidgets);
      expect(find.text('Cocok'), findsOneWidget);
      expect(find.text('Tidak cocok'), findsOneWidget);

      await expectLater(
        find.byType(ValidationScreen),
        matchesGoldenFile('../goldens/validation_tab_light.png'),
      );
    });

    testWidgets('dark: tone kartu + tombol tetap terbaca', (tester) async {
      await pumpValidation(tester, mode: ThemeMode.dark);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('100.000'), findsWidgets);

      await expectLater(
        find.byType(ValidationScreen),
        matchesGoldenFile('../goldens/validation_tab_dark.png'),
      );
    });

    testWidgets('light: petunjuk geser "Tidak cocok" tampil di latar bad', (
      tester,
    ) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      // Tahan setengah geseran ke kanan: kartu tergeser, latar petunjuk
      // `bad.container` + ikon/tulisan `bad.content` terlihat di belakang.
      // Dua langkah: gerakan pertama habis untuk melewati touch slop
      // (belum menggeser kartu), gerakan kedua baru menggeser.
      final gesture = await tester.startGesture(
        tester.getCenter(find.textContaining('100.000').first),
      );
      await gesture.moveBy(const Offset(80, 0));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      // Label "Tidak cocok" kini muncul dua kali: di tombol DAN di latar
      // geseran — bukti petunjuk benar-benar terlihat.
      expect(find.text('Tidak cocok'), findsNWidgets(2));

      await expectLater(
        find.byType(ValidationScreen),
        matchesGoldenFile('../goldens/validation_swipe_light.png'),
      );

      // Lepas di bawah ambang dismiss → kartu kembali, tidak ada keputusan.
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Urungkan'), findsNothing);
    });
  });
}
