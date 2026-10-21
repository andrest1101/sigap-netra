import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/photo_viewer.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../helpers/app_fonts.dart';

/// Penampil foto layar penuh: zoom, reset, dan rute tutup.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List bytes;

  setUpAll(loadAppFonts);

  setUpAll(() async {
    final data = await rootBundle.load('assets/images/demo_money_100k.jpg');
    bytes = data.buffer.asUint8List();
  });

  Widget app(Widget home) {
    return MaterialApp(
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      home: home,
    );
  }

  Widget viewer() {
    return app(
      PhotoViewerScreen(
        imageBytes: bytes,
        heroTag: 'test-photo',
        semanticsLabel: 'Rp 100.000',
      ),
    );
  }

  testWidgets('menampilkan foto, penampil interaktif, dan petunjuk', (
    tester,
  ) async {
    await tester.pumpWidget(viewer());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Hero), findsOneWidget);
    expect(find.byTooltip('Tutup foto'), findsOneWidget);
    expect(
      find.text('Cubit atau ketuk dua kali untuk memperbesar'),
      findsOneWidget,
    );
  });

  testWidgets('ketuk dua kali memperbesar lalu tombol reset mengembalikan', (
    tester,
  ) async {
    await tester.pumpWidget(viewer());
    await tester.pump();

    final interactive = find.byType(InteractiveViewer);
    AnimatedOpacity hintFade() => tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Cubit atau ketuk dua kali untuk memperbesar'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(hintFade().opacity, 1);

    await tester.tap(interactive);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(interactive);
    await tester.pumpAndSettle();

    var controller = tester
        .widget<InteractiveViewer>(interactive)
        .transformationController;
    expect(controller, isNotNull);
    expect(controller!.value.getMaxScaleOnAxis(), greaterThan(1.5));
    expect(hintFade().opacity, 0);
    expect(find.byTooltip('Kembalikan ukuran'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembalikan ukuran'));
    await tester.pumpAndSettle();

    controller = tester
        .widget<InteractiveViewer>(interactive)
        .transformationController;
    expect(controller!.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
    expect(find.byTooltip('Kembalikan ukuran'), findsNothing);
  });

  testWidgets('golden: penampil foto layar penuh', (tester) async {
    // Golden ponsel 390x844 @3x: ukuran target utama, termasuk petunjuk yang
    // boleh turun dua baris di layar sempit.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(viewer());
    await tester.pump();
    final element = tester.element(find.byType(PhotoViewerScreen));
    await tester.runAsync(() async {
      await precacheImage(MemoryImage(bytes), element);
    });
    await tester.pump();

    await expectLater(
      find.byType(PhotoViewerScreen),
      matchesGoldenFile('goldens/photo_viewer_light.png'),
    );
  });

  testWidgets('tombol tutup mengembalikan ke layar asal', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => PhotoViewerScreen.open(
                  context,
                  imageBytes: bytes,
                  heroTag: 'test-photo',
                  semanticsLabel: 'Rp 100.000',
                ),
                child: const Text('Buka foto'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka foto'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup foto'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsNothing);
    expect(find.text('Buka foto'), findsOneWidget);
  });
}
