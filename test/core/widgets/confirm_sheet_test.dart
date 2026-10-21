import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/confirm_sheet.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Teks panjang sengaja melebihi 85% tinggi layar pada 360x640 + 1,3x.
final String _longMessage = List.filled(
  24,
  'Data pembacaan, thumbnail, dan validasi akan dihapus dari perangkat ini. '
  'Tindakan ini tidak dapat dibatalkan.',
).join('\n\n');

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required void Function(BuildContext context) onOpen,
    double textScale = 1.0,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => onOpen(context),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'ConfirmSheet: teks panjang 360x640 @1,3x menggulir, tombol tetap aman',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpHost(
        tester,
        textScale: 1.3,
        onOpen: (context) => ConfirmSheet.show(
          context,
          title: 'Hapus semua data perangkat?',
          message: _longMessage,
          confirmLabel: 'Hapus semua',
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConfirmSheet), findsOneWidget);
      // Batas 85% layar (544 dp) + toleransi pembulatan.
      expect(tester.getSize(find.byType(ConfirmSheet)).height, lessThan(546));
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus semua'), findsOneWidget);

      // Isi boleh tergulir, tetapi baris aksi tidak ikut hilang.
      final content = find.descendant(
        of: find.byType(ConfirmSheet),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(content, const Offset(0, -240));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Batal'), findsOneWidget);
    },
  );

  testWidgets(
    'ConsentSheet: teks panjang 360x640 @1,3x menggulir, tombol tetap aman',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpHost(
        tester,
        textScale: 1.3,
        onOpen: (context) => ConsentSheet.show(
          context,
          title: 'Izinkan pengiriman thumbnail?',
          message: _longMessage,
          acceptLabel: 'Izinkan',
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConsentSheet), findsOneWidget);
      expect(tester.getSize(find.byType(ConsentSheet)).height, lessThan(546));
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Izinkan'), findsOneWidget);

      final content = find.descendant(
        of: find.byType(ConsentSheet),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(content, const Offset(0, -240));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Izinkan'), findsOneWidget);
    },
  );
}
