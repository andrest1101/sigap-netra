import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/events/domain/entities/device_event.dart';
import 'package:sigap_netra_app/features/events/presentation/screens/connection_logs_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

void main() {
  Future<FakeAppGraph> pumpLogs(
    WidgetTester tester, {
    FakeAppGraph? graph,
  }) async {
    final g = graph ?? FakeAppGraph();
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
          ...g.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ConnectionLogsScreen(deviceId: kDemoDeviceId),
        ),
      ),
    );
    return g;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder listScrollable() => find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );

  testWidgets('tanpa saringan: realtime + catatan batas 50 terbaru', (
    tester,
  ) async {
    await pumpLogs(tester);
    await settle(tester);

    // Streaming realtime punya batas yang harus diakui terang-terangan.
    expect(find.textContaining('kejadian terbaru'), findsOneWidget);
    expect(find.text('Perangkat selesai booting.'), findsOneWidget);
  });

  testWidgets('saringan Gangguan memakai query server + catatan selesai', (
    tester,
  ) async {
    await pumpLogs(tester);
    await settle(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Gangguan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Hanya kejadian error yang tampil (halaman server, bukan filter lokal
    // atas 50 terbaru) dan catatan "sudah dimuat" muncul karena halaman
    // pertama sudah habis.
    expect(find.text('Perintah restart gagal dieksekusi.'), findsOneWidget);
    expect(find.text('Perangkat selesai booting.'), findsNothing);
    expect(find.textContaining('sudah dimuat'), findsOneWidget);
  });

  testWidgets('"Muat lagi" memuat halaman berikutnya', (tester) async {
    final graph = FakeAppGraph();
    final base = DateTime(2026, 10, 18, 12);
    graph.events.replaceAll([
      for (var i = 1; i <= 30; i++)
        DeviceEvent(
          id: 'evt-uji-$i',
          deviceId: kDemoDeviceId,
          type: 'sync',
          severity: EventSeverity.warning,
          message: 'Kejadian uji $i',
          createdAt: base.subtract(Duration(minutes: i)),
        ),
    ]);
    await pumpLogs(tester, graph: graph);
    await settle(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Peringatan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Halaman pertama berisi 25 kejadian terbaru.
    expect(find.text('Kejadian uji 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Muat lagi'),
      300,
      scrollable: listScrollable(),
    );
    await tester.tap(find.text('Muat lagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Halaman kedua: kejadian tertua + catatan semua sudah dimuat.
    await tester.scrollUntilVisible(
      find.text('Kejadian uji 30'),
      300,
      scrollable: listScrollable(),
    );
    expect(find.text('Kejadian uji 30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Semua kejadian pada saringan ini sudah dimuat.'),
      300,
      scrollable: listScrollable(),
    );
    expect(
      find.text('Semua kejadian pada saringan ini sudah dimuat.'),
      findsOneWidget,
    );
  });

  testWidgets('tab Perintah memakai tile bersama dengan resultNote', (
    tester,
  ) async {
    await pumpLogs(tester);
    await settle(tester);

    await tester.tap(find.text('Kontrol jarak jauh'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sinkronisasi selesai.'), findsOneWidget);
    expect(find.textContaining('Perangkat tidak merespons.'), findsOneWidget);
  });
}
