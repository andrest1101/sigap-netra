import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/large_title_scaffold.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    String? subtitle = '25+ pembacaan dimuat',
    TextScaler textScaler = const TextScaler.linear(1.0),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: LargeTitleScaffold(
              title: 'Riwayat',
              subtitle: subtitle,
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
              body: const SizedBox(height: 2000),
            ),
          ),
        ),
      ),
    );
  }

  group('LargeTitleScaffold', () {
    testWidgets('judul dan aksi sebaris di app bar atas, bukan header turun', (
      tester,
    ) async {
      await pumpHeader(tester);

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.text('Riwayat'));
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(find.text('25+ pembacaan dimuat'), findsOneWidget);

      // Judul harus berada di toolbar atas (56 dp), bukan di bawah baris aksi.
      final titleTop = tester.getTopLeft(find.text('Riwayat')).dy;
      expect(titleTop, lessThan(80));

      // Ikon aksi dan judul berbagi baris yang sama.
      final titleCenter = tester.getCenter(find.text('Riwayat')).dy;
      final actionCenter = tester
          .getCenter(find.byIcon(Icons.more_vert_rounded))
          .dy;
      expect((titleCenter - actionCenter).abs(), lessThan(12));

      // Subjudul berada di bawah judul, bukan di atasnya.
      final subtitleTop = tester
          .getTopLeft(find.text('25+ pembacaan dimuat'))
          .dy;
      expect(subtitleTop, greaterThan(titleCenter));
    });

    testWidgets('header tetap menempel di atas saat konten digulir', (
      tester,
    ) async {
      await pumpHeader(tester);
      final before = tester.getTopLeft(find.text('Riwayat')).dy;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final after = tester.getTopLeft(find.text('Riwayat')).dy;
      expect((after - before).abs(), lessThan(1));
      expect(find.text('Riwayat'), findsOneWidget);
    });

    testWidgets('tanpa subjudul tetap lapang dan tidak overflow', (
      tester,
    ) async {
      await pumpHeader(tester, subtitle: null);
      expect(tester.takeException(), isNull);
      expect(find.text('Riwayat'), findsOneWidget);
    });

    testWidgets('360x800 teks 1,3x tidak memotong judul atau aksi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpHeader(tester, textScaler: const TextScaler.linear(1.3));

      expect(tester.takeException(), isNull);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });
  });
}
