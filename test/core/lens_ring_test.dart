import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/theme/status_colors.dart';
import 'package:sigap_netra_app/core/widgets/battery_ring.dart';
import 'package:sigap_netra_app/core/widgets/lens_ring.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpRing(WidgetTester tester, LensRing ring) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
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

    testWidgets('palet status tetap ada di tema polos (tanpa AppTheme)', (
      tester,
    ) async {
      // Regression: fallback `StatusColors.of` tidak boleh bergantung pada
      // tema gelap yang sudah dihapus — tema tanpa ekstensi memakai palet
      // terang.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                StatusColors.of(context).ok.solid,
                StatusColors.light.ok.solid,
              );
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );
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
