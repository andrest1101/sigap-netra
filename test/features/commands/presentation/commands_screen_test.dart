import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/commands/domain/entities/device_command.dart';
import 'package:sigap_netra_app/features/commands/presentation/screens/commands_screen.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

void main() {
  Future<FakeAppGraph> pumpCommands(WidgetTester tester) async {
    final graph = FakeAppGraph();
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          ...graph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const CommandsScreen(deviceId: kDemoDeviceId),
        ),
      ),
    );
    return graph;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('perintah baru memakai bahasa jujur "Menunggu alat"', (
    tester,
  ) async {
    final graph = await pumpCommands(tester);
    await settle(tester);
    final before = graph.commands.itemsForTest.length;

    // `FilledButton.tonalIcon` menghasilkan subclass privat, jadi finder
    // berbasis tipe generik tidak cukup — cari lewat labelnya.
    final syncButton = find
        .ancestor(
          of: find.text('Sinkronkan sekarang'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        )
        .first;
    await tester.ensureVisible(syncButton);
    await tester.tap(syncButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(graph.commands.itemsForTest.length, before + 1);
    expect(find.text('Perintah dikirim.'), findsOneWidget);
    // Bukan "kedaluwarsa"/"gagal": perintah masih menunggu alat.
    expect(find.textContaining('Menunggu alat'), findsWidgets);

    // Habiskan timer simulasi device (1 dtk ack, 2 dtk done) + snackbar.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('sheet volume mengirim level yang dikonfirmasi', (tester) async {
    final graph = await pumpCommands(tester);
    await settle(tester);

    await tester.tap(find.text('Atur volume'));
    await tester.pumpAndSettle();

    // Slider sheet mulai dari 70 (default yang tampil).
    expect(find.text('Volume: 70'), findsOneWidget);
    // Geser slider sedikit lalu konfirmasi.
    await tester.drag(find.byType(Slider), const Offset(-120, 0));
    await tester.pump();
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    final newest = graph.commands.itemsForTest.first;
    expect(newest.type, CommandType.setVolume);
    expect(newest.payload['level'], isA<int>());
    expect(newest.payload['level'], lessThan(70));

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('sheet ucapkan teks mengirim teks + ringkasan payload', (
    tester,
  ) async {
    final graph = await pumpCommands(tester);
    await settle(tester);

    await tester.tap(find.text('Ucapkan teks'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo dunia');
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    final newest = graph.commands.itemsForTest.first;
    expect(newest.type, CommandType.speakText);
    expect(newest.payload['text'], 'Halo dunia');
    // Ringkasan payload tampil di tile bersama (bukan hanya di payload).
    expect(find.textContaining('Teks:'), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
  });
}
