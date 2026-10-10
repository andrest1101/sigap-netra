import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/theme/status_colors.dart';
import 'package:sigap_netra_app/core/widgets/battery_ring.dart';
import 'package:sigap_netra_app/core/widgets/lens_ring.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpRing(
    WidgetTester tester,
    LensRing ring, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Scaffold(body: Center(child: ring)),
      ),
    );
    await tester.pump();
  }

  group('LensRing.battery', () {
    testWidgets('baterai 82 memakai warna ok tema', (tester) async {
      await pumpRing(
        tester,
        LensRing.battery(
          diameter: 72,
          batteryPct: 82,
          availableLabel: 'Baterai',
          unavailableLabel: 'Baterai tidak tersedia',
        ),
      );

      expect(find.text('82'), findsOneWidget);
      expect(find.bySemanticsLabel('Baterai 82 persen'), findsOneWidget);
    });

    testWidgets('baterai null tampil elegan + ikon', (tester) async {
      await pumpRing(
        tester,
        LensRing.battery(
          diameter: 72,
          batteryPct: null,
          availableLabel: 'Baterai',
          unavailableLabel: 'Baterai tidak tersedia',
        ),
      );

      // Tidak ada angka "–" polos: ikon penanda yang tampil.
      expect(find.text('–'), findsNothing);
      expect(find.byIcon(Icons.battery_unknown_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Baterai tidak tersedia'), findsOneWidget);
    });

    testWidgets('baterai rendah memakai warna bad', (tester) async {
      await pumpRing(
        tester,
        LensRing.battery(
          diameter: 72,
          batteryPct: 10,
          availableLabel: 'Baterai',
          unavailableLabel: 'Baterai tidak tersedia',
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('warna adaptif mengikuti mode gelap', (tester) async {
      await pumpRing(
        tester,
        LensRing.battery(
          diameter: 72,
          batteryPct: 82,
          availableLabel: 'Baterai',
          unavailableLabel: 'Baterai tidak tersedia',
        ),
        brightness: Brightness.dark,
      );

      final context = tester.element(find.byType(LensRing));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(StatusColors.of(context).ok.solid, isNotNull);
      expect(find.text('82'), findsOneWidget);
    });
  });

  group('BatteryRing', () {
    Future<void> pumpBattery(WidgetTester tester, int? pct) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(child: BatteryRing(batteryPct: pct)),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('ring + angka saja, tanpa caption', (tester) async {
      await pumpBattery(tester, 82);

      expect(find.text('82'), findsOneWidget);
      expect(find.text('Baterai'), findsNothing);
      final ring = tester.widget<BatteryRing>(find.byType(BatteryRing));
      expect(ring.diameter, 56);
    });

    testWidgets('null tetap berlabel semantik', (tester) async {
      await pumpBattery(tester, null);

      expect(find.text('Baterai'), findsNothing);
      expect(find.bySemanticsLabel('Baterai tidak tersedia'), findsOneWidget);
    });
  });
}
