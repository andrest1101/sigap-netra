import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/widgets/empty_view.dart';
import 'package:sigap_netra_app/core/widgets/error_view.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// EmptyView/ErrorView dipakai di Validasi, Riwayat, dan Perangkat. Test ini
/// memastikan CTA bersama tetap dapat dicapai pada 360x640 @1,3x — bukan
/// tersembunyi di bawah lipatan tanpa jalur gulir.
void main() {
  Future<void> pumpView(
    WidgetTester tester,
    Widget view, {
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
        home: Scaffold(body: view),
      ),
    );
    await tester.pump();
  }

  testWidgets('EmptyView 360x640 @1,3x: aksi dapat digulir dan disentuh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var tapped = false;
    await pumpView(
      tester,
      EmptyView(
        title: 'Belum ada perangkat terhubung',
        message:
            'Sambungkan kacamata pintar terlebih dahulu agar pembacaan dan '
            'validasi dapat tampil di sini. Pastikan perangkat berada di '
            'jaringan yang sama dengan ponsel pendamping.',
        action: FilledButton(
          onPressed: () => tapped = true,
          child: const Text('Buka Perangkat'),
        ),
      ),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    final action = find.text('Buka Perangkat');
    expect(action, findsOneWidget);
    await tester.ensureVisible(action);
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getRect(action).bottom, lessThanOrEqualTo(640));
    await tester.tap(action);
    expect(tapped, isTrue);
  });

  testWidgets('ErrorView 360x640 @1,3x: Coba lagi dapat dicapai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var retried = false;
    await pumpView(
      tester,
      ErrorView(
        message:
            'Layanan tidak dapat dihubungi saat ini. Periksa koneksi '
            'internet, lalu coba lagi. Jika masalah berlanjut, buka '
            'pengaturan jaringan perangkat Anda.',
        onRetry: () => retried = true,
      ),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    final retry = find.text('Coba lagi');
    expect(retry, findsOneWidget);
    await tester.ensureVisible(retry);
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getRect(retry).bottom, lessThanOrEqualTo(640));
    await tester.tap(retry);
    expect(retried, isTrue);
  });
}
