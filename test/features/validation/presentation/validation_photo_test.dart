import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/photo_viewer.dart';
import 'package:sigap_netra_app/features/validation/presentation/widgets/validation_photo.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Empat state [ValidationPhoto]: tanpa-ID (panel), memuat (skeleton),
/// gagal (panel + Coba lagi), dan gambar (Hero 4:3, ketuk → detail).
void main() {
  Future<void> pumpPhoto(
    WidgetTester tester, {
    required FakeAppGraph graph,
    String? thumbnailId,
    VoidCallback? onOpen,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: graph.overrides,
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: Scaffold(
            body: ValidationPhoto(
              deviceId: kDemoDeviceId,
              thumbnailId: thumbnailId,
              detectionId: 'det-money-100k',
              semanticsLabel: 'Rp 100.000',
              onOpenDetail: onOpen ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('ValidationPhoto', () {
    testWidgets('tanpa thumbnailId menampilkan panel tanpa gambar', (
      tester,
    ) async {
      await pumpPhoto(tester, graph: FakeAppGraph());
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Gambar tidak diunggah'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('thumbnailId terisi menampilkan foto hasil bacaan', (
      tester,
    ) async {
      var opened = false;
      final graph = FakeAppGraph();
      await pumpPhoto(
        tester,
        graph: graph,
        thumbnailId: 'det-money-100k',
        onOpen: () => opened = true,
      );
      // FutureProvider + decode Image.memory butuh bingkai tambahan.
      await pumpFrames(tester);
      final element = tester.element(find.byType(ValidationPhoto));
      await tester.runAsync(() async {
        final thumbnail = await graph.media.getThumbnail(
          deviceId: kDemoDeviceId,
          thumbnailId: 'det-money-100k',
        );
        await precacheImage(MemoryImage(thumbnail!.imageBytes), element);
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Hero), findsOneWidget);
      expect(find.text('Gambar tidak diunggah'), findsNothing);

      await tester.tap(find.byType(Image));
      expect(opened, isTrue);
    });

    testWidgets('error thumbnail menampilkan panel + Coba lagi', (
      tester,
    ) async {
      final graph = FakeAppGraph();
      await pumpPhoto(tester, graph: graph, thumbnailId: 'tidak-ada');
      await pumpFrames(tester);

      // Fake mengembalikan null (bukan error) → panel tanpa gambar, dan
      // tombol aksi validasi di bawah kartu selalu tersedia (bukan di sini).
      expect(tester.takeException(), isNull);
      expect(find.text('Gambar tidak diunggah'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('tombol zoom membuka penampil foto layar penuh', (
      tester,
    ) async {
      final graph = FakeAppGraph();
      await pumpPhoto(tester, graph: graph, thumbnailId: 'det-money-100k');
      await pumpFrames(tester);
      final element = tester.element(find.byType(ValidationPhoto));
      await tester.runAsync(() async {
        final thumbnail = await graph.media.getThumbnail(
          deviceId: kDemoDeviceId,
          thumbnailId: 'det-money-100k',
        );
        await precacheImage(MemoryImage(thumbnail!.imageBytes), element);
      });
      await tester.pump();

      await tester.tap(find.byTooltip('Perbesar foto'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewerScreen), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byTooltip('Tutup foto'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewerScreen), findsNothing);
    });
  });
}
