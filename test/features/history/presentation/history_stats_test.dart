import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/history/data/datasources/fake_history_data_source.dart';
import 'package:sigap_netra_app/features/history/domain/entities/detection_filter.dart';
import 'package:sigap_netra_app/features/history/domain/entities/history_insights.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_screen.dart';
import 'package:sigap_netra_app/features/history/presentation/widgets/daily_readings_chart.dart';
import 'package:sigap_netra_app/features/history/presentation/widgets/history_stats_view.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Repository riwayat yang gagal menghitung (mis. `unavailable`).
///
/// Panel Statistik harus memperlihatkan ErrorView + "Coba lagi", bukan deretan
/// nol yang terbaca seolah "tidak ada pembacaan".
class _FailingCountRepository extends FakeHistoryRepositoryImpl {
  _FailingCountRepository(super.dataSource);

  @override
  Future<int> countDetections({required DetectionFilter filter}) {
    throw Exception('kuota baca habis');
  }
}

void main() {
  Future<FakeAppGraph> pumpHistory(
    WidgetTester tester, {
    FakeAppGraph? graph,
  }) async {
    final target = graph ?? FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
          ...target.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: const HistoryScreen(),
        ),
      ),
    );
    return target;
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  /// Pindah ke segmen Statistik lalu tunggu agregat `count()` selesai.
  Future<void> openStats(WidgetTester tester) async {
    await tester.tap(find.text('Statistik'));
    await pumpFrames(tester);
  }

  group('Statistik Riwayat — 7 hari', () {
    testWidgets('ring akurasi + angka kunci dari agregat count()', (
      tester,
    ) async {
      await pumpHistory(tester);
      await pumpFrames(tester);
      await openStats(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Akurasi bacaan'), findsOneWidget);
      // 31 cocok dari 34 validasi manusia pada jendela 7 hari (2 menunggu
      // TIDAK dihitung benar — integritas validasi).
      expect(find.text('91%'), findsOneWidget);
      expect(find.text('dari 34 validasi'), findsOneWidget);

      expect(find.text('Total pembacaan'), findsOneWidget);
      expect(find.text('36'), findsOneWidget);
      expect(find.text('Per hari'), findsOneWidget);
      expect(find.text('≈5'), findsOneWidget);
      expect(find.text('Menunggu validasi'), findsOneWidget);
    });

    testWidgets('semua segmen berwarna punya ukuran nyata (regresi 0 px)', (
      tester,
    ) async {
      await pumpHistory(tester);
      await pumpFrames(tester);
      await openStats(tester);

      // Regresi: `ColoredBox` tanpa anak menyusut jadi 0 px saat sumbu
      // lintangnya longgar (tanpa `CrossAxisAlignment.stretch`) sehingga
      // batang grafik dan bar komposisi tak terlihat sama sekali.
      final segments = find
          .descendant(
            of: find.byType(HistoryStatsView),
            matching: find.byType(ColoredBox),
          )
          .evaluate()
          .toList();
      expect(segments, isNotEmpty);
      for (final element in segments) {
        final size = tester.getSize(find.byWidget(element.widget));
        // Ukuran nol = segmen tak terlihat (garis rambut 1 px tetap sah).
        expect(size.width, greaterThan(0), reason: 'segmen runtuh lebarnya');
        expect(size.height, greaterThan(0), reason: 'segmen runtuh tingginya');
      }
    });

    testWidgets('grafik batang harian + komposisi jenis & status', (
      tester,
    ) async {
      await pumpHistory(tester);
      await pumpFrames(tester);
      await openStats(tester);

      final chart = tester.widget<DailyReadingsChart>(
        find.byType(DailyReadingsChart),
      );
      expect(chart.insights.window, HistoryWindow.week);
      expect(
        chart.insights.buckets.map((b) => b.total),
        [8, 5, 0, 5, 6, 6, 6],
        reason: 'batang kiri→kanan: 6 hari lalu sampai hari ini',
      );

      // Legenda berangka: persen dibagi total jendela yang sama (36).
      expect(find.text('Uang · 26 · 72%'), findsOneWidget);
      expect(find.text('Teks · 10 · 28%'), findsOneWidget);
      expect(find.text('Cocok · 31 · 86%'), findsOneWidget);
      expect(find.text('Tidak cocok · 3 · 8%'), findsOneWidget);
      expect(find.text('Menunggu · 2 · 6%'), findsOneWidget);
    });
  });

  group('Statistik Riwayat — 4 minggu', () {
    testWidgets('ganti rentang: angka dan lebar batang ikut berubah', (
      tester,
    ) async {
      await pumpHistory(tester);
      await pumpFrames(tester);
      await openStats(tester);

      await tester.tap(find.text('4 minggu terakhir'));
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('dari 121 validasi'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.text('≈4'), findsOneWidget);
      expect(find.text('Uang · 93 · 76%'), findsOneWidget);
      expect(find.text('Teks · 30 · 24%'), findsOneWidget);
      expect(find.text('Cocok · 114 · 93%'), findsOneWidget);

      final chart = tester.widget<DailyReadingsChart>(
        find.byType(DailyReadingsChart),
      );
      expect(chart.insights.window, HistoryWindow.month);
      expect(
        chart.insights.buckets.map((b) => b.total),
        [19, 33, 35, 36],
        reason: '4 blok 7 hari, blok terakhir memuat hari ini',
      );
    });

    testWidgets('grafik mingguan diberi label tanggal, bukan nama hari', (
      tester,
    ) async {
      await pumpHistory(tester);
      await pumpFrames(tester);
      await openStats(tester);
      await tester.tap(find.text('4 minggu terakhir'));
      await pumpFrames(tester);

      // Label nama hari hanya ada di jendela harian: teks "Sen"…"Min" hilang
      // saat batang menjadi mingguan.
      for (final day in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']) {
        expect(
          find.text(day),
          findsNothing,
          reason: 'label harian "$day" masih tampil di grafik mingguan',
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Statistik Riwayat — daftar', () {
    testWidgets('header hari memuat jumlah + jenis bacaan', (tester) async {
      await pumpHistory(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Header "Hari ini" dibedakan lewat kunci tanggalnya — hari lain bisa
      // kebetulan punya komposisi sama (mis. kemarin juga 4 uang · 2 teks).
      final today = DateTime.now();
      final todayHeader = find.byKey(
        ValueKey(
          'day-${DateTime(today.year, today.month, today.day).toIso8601String()}',
        ),
      );
      expect(todayHeader, findsOneWidget);
      expect(
        find.descendant(of: todayHeader, matching: find.text('Hari ini')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: todayHeader,
          matching: find.text('6 pembacaan · 4 uang · 2 teks'),
        ),
        findsOneWidget,
      );
      // Baris: nomor bacaan + jam, plus pil keyakinan & jarak.
      expect(find.textContaining('No. 1 · '), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsWidgets);
      expect(find.byIcon(Icons.straighten_rounded), findsWidgets);
    });

    testWidgets('grup terpotong ditandai "+" dan tanpa rincian jenis', (
      tester,
    ) async {
      await pumpHistory(tester);
      await pumpFrames(tester);

      final partial = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^\d+\+ pembacaan$').hasMatch(widget.data!),
      );
      expect(partial, findsOneWidget);
      expect(find.textContaining('uang ·'), findsWidgets);
    });
  });

  group('Statistik Riwayat — state kosong & error', () {
    testWidgets('tanpa bacaan: empty state jujur + jalan keluar 4 minggu', (
      tester,
    ) async {
      final graph = FakeAppGraph();
      graph.detections.replaceAll(const <Detection>[]);
      await pumpHistory(tester, graph: graph);
      await pumpFrames(tester);
      await openStats(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Belum ada pembacaan pada rentang ini'), findsOneWidget);
      expect(find.byType(DailyReadingsChart), findsNothing);

      await tester.tap(find.text('Lihat 4 minggu terakhir'));
      await pumpFrames(tester);

      // Sudah di rentang terpanjang: tidak ada jalan keluar yang sia-sia.
      expect(find.text('Belum ada pembacaan pada rentang ini'), findsOneWidget);
      expect(find.text('Lihat 4 minggu terakhir'), findsNothing);
    });

    testWidgets('gagal menghitung: ErrorView + Coba lagi (bukan nol)', (
      tester,
    ) async {
      final graph = FakeAppGraph(
        historyRepositoryBuilder: (detections, _) =>
            _FailingCountRepository(FakeHistoryDataSource(detections)),
      );
      await pumpHistory(tester, graph: graph);
      await pumpFrames(tester);
      await openStats(tester);

      expect(find.text('Terjadi kesalahan'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Total pembacaan'), findsNothing);
    });
  });

  group('Statistik Riwayat — layar sempit', () {
    testWidgets('360 dp: daftar & statistik tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpHistory(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);

      await openStats(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('4 minggu terakhir'));
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
