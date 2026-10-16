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
  Future<FakeAppGraph> pumpValidation(
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
    return graph;
  }

  // Antrean demo memakai animasi + timer; pompa eksplisit secukupnya.
  // Thumbnail foto (FutureProvider + decode Image.memory) butuh bingkai
  // tambahan: Future selesai dalam 1-2 pump, decode gambar butuh beberapa
  // pump lagi sebelum capture golden.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Menunggu decode foto selesai sebelum capture golden.
  ///
  /// `Image.memory` decode asinkron: tanpa precache, golden menangkap bingkai
  /// kosong meski provider sudah `AsyncData`. Baca langsung dari fake data
  /// source — bukan `ref.read(provider.future)`: provider `autoDispose` tanpa
  /// listener langsung di-dispose sehingga future-nya menggantung selamanya.
  /// `precacheImage` wajib di dalam `runAsync`: decode gambar memakai
  /// real-async yang tidak pernah selesai di zona fake-async `tester.pump`.
  /// `MemoryImage` dibandingkan berdasar isi bytes, jadi cache hasil precache
  /// dipakai ulang oleh `Image.memory` di kartu; satu pump untuk repaint.
  Future<void> settleThumbnails(
    WidgetTester tester,
    FakeAppGraph graph,
    Finder scope,
  ) async {
    final element = tester.element(scope);
    await tester.runAsync(() async {
      for (final detection in graph.detections.itemsForTest) {
        final id = detection.thumbnailId;
        if (id == null || id.isEmpty) continue;
        final thumbnail = await graph.media.getThumbnail(
          deviceId: detection.deviceId,
          thumbnailId: id,
        );
        final bytes = thumbnail?.imageBytes;
        if (bytes == null || bytes.isEmpty) continue;
        await precacheImage(MemoryImage(bytes), element);
      }
    });
    await tester.pump();
  }

  group('Golden tab Validasi', () {
    testWidgets('light: tumpukan kartu + aksi status ok/bad', (tester) async {
      final graph = await pumpValidation(tester);
      await pumpFrames(tester);
      await settleThumbnails(tester, graph, find.byType(ValidationScreen));

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
      final graph = await pumpValidation(tester, mode: ThemeMode.dark);
      await pumpFrames(tester);
      await settleThumbnails(tester, graph, find.byType(ValidationScreen));

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
      final graph = await pumpValidation(tester);
      await pumpFrames(tester);
      await settleThumbnails(tester, graph, find.byType(ValidationScreen));

      // Kartu kini memuat foto 4:3: teks nominal jatuh di luar viewport
      // 800x600 sehingga tidak bisa jadi titik gesture. Mulai dari area atas
      // kartu (foto, selalu on-screen). Dua langkah: pertama untuk touch slop,
      // kedua menggeser.
      final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(Dismissible).first) +
            const Offset(200, 100),
      );
      await gesture.moveBy(const Offset(80, 0));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      // Label "Tidak cocok" kini muncul dua kali: di tombol DAN di latar
      // geseran — bukti petunjuk benar-benar terlihat. `skipOffstage: false`
      // karena kartu berfoto 4:3 mendorong tombol bawah keluar viewport
      // test 800x600 (tombol offstage, hint onstage).
      expect(find.text('Tidak cocok', skipOffstage: false), findsNWidgets(2));

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
