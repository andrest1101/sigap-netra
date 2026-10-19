import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/router/app_router.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/theme/status_colors.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_detail_screen.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Router minimal untuk layar detail (butuh GoRouter untuk push/pop).

void main() {
  Future<void> pumpDetail(
    WidgetTester tester, {
    FakeAppGraph? graph,
    String detectionId = 'det-money-50k',
    // Bila true, mulai dari halaman daftar dummy lalu push ke detail —
    // mensimulasikan alur nyata sehingga `pop` (undo/submit) punya stack
    // tujuan dan tidak crash di router test.
    bool fromHome = false,
  }) async {
    final appGraph = graph ?? FakeAppGraph();
    final router = GoRouter(
      initialLocation: fromHome ? '/' : '/riwayat/$detectionId',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => HistoryDetailPath(detectionId).push(context),
                child: const Text('Buka detail'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/riwayat/:id',
          builder: (context, state) =>
              HistoryDetailScreen(detectionId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
          ...appGraph.overrides,
        ],
        child: MaterialApp.router(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  group('Detail Riwayat R1', () {
    testWidgets('menampilkan label + chip status + tombol validasi', (
      tester,
    ) async {
      // det-money-50k: sudah Cocok → tombol Urungkan, bukan Cocok.
      await pumpDetail(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Foto 4:3 mendorong konten bawah keluar viewport test 800px —
      // scroll dulu, baru assert + cari tanpa skip offstage.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      expect(find.textContaining('50.000', skipOffstage: false), findsWidgets);
      expect(find.text('Cocok', skipOffstage: false), findsWidgets);
      expect(
        find.text('Batalkan validasi', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('item pending menampilkan pasangan ok/bad', (tester) async {
      // det-money-100k: pending → Cocok (filled ok) + Tidak cocok (outlined).
      await pumpDetail(tester, detectionId: 'det-money-100k');
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      expect(find.text('Tidak cocok', skipOffstage: false), findsOneWidget);

      final matchButton = tester.widget<FilledButton>(
        find
            .ancestor(
              of: find.text('Cocok', skipOffstage: false),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            )
            .first,
      );
      expect(
        matchButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        StatusColors.light.ok.solid,
      );
    });

    testWidgets('validatedBy tampil sebagai UID + waktu, bukan label ID', (
      tester,
    ) async {
      await pumpDetail(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Format jujur: "Divalidasi oleh <uid> · <waktu>".
      expect(
        find.textContaining('Divalidasi oleh', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.textContaining('ID pengguna:'), findsNothing);
    });

    testWidgets('salin teks memakai snackbar "disalin"', (tester) async {
      await pumpDetail(
        tester,
        detectionId: 'det-text-menu',
        graph: FakeAppGraph(),
      );
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Tombol salin di kartu OCR (bawah foto) — scroll sampai terlihat.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      final copy = find.byTooltip('Salin teks');
      expect(copy, findsOneWidget);
      await tester.tap(copy);
      await tester.pump();

      expect(find.text('Teks disalin.'), findsOneWidget);
      // Bukan label tombol simpan yang menyesatkan.
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('Undo memicu tulis ulang tanpa crash', (tester) async {
      final graph = FakeAppGraph();
      await pumpDetail(tester, graph: graph, fromHome: true);
      await pumpFrames(tester);
      expect(find.text('Buka detail'), findsOneWidget);
      await tester.tap(find.text('Buka detail'));
      await pumpFrames(tester);
      expect(find.byType(HistoryDetailScreen), findsOneWidget);

      // Tombol validasi di bawah foto 4:3 — scroll sampai terlihat lalu tap.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      await tester.tap(find.text('Batalkan validasi'));
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Undo berhasil + pop kembali ke halaman awal.
      expect(find.text('Buka detail'), findsOneWidget);
      final pending = graph.detections.itemsForTest
          .where((d) => d.id == 'det-money-50k')
          .single
          .validationStatus;
      expect(pending, ValidationStatus.pending);
    });
  });

  test('display label uang memakai format rupiah', () {
    final detection = Detection(
      id: 'x',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.money,
      createdAt: DateTime(2026, 10, 8, 12),
      amount: 100000,
    );
    expect(detection.displayLabel, 'Rp 100.000');
  });
}
