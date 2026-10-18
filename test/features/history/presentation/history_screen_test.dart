import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/theme/status_colors.dart';
import 'package:sigap_netra_app/core/widgets/confirm_sheet.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_screen.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Repository tanpa perangkat — menguji empty state "belum ada perangkat".
class _EmptyDeviceRepository implements DeviceRepository {
  const _EmptyDeviceRepository();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) =>
      Stream<List<Device>>.value(const <Device>[]);

  @override
  Stream<Device?> watchDevice(String deviceId) => Stream<Device?>.value(null);
}

void main() {
  Future<void> pumpHistory(
    WidgetTester tester, {
    FakeAppGraph? graph,
    DeviceRepository? deviceRepository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          deviceRepositoryProvider.overrideWithValue(
            deviceRepository ?? DemoDeviceRepository(),
          ),
          ...(graph ?? FakeAppGraph()).overrides,
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
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  group('Riwayat R1', () {
    testWidgets('tanpa perangkat menampilkan ajakan hubungkan', (tester) async {
      await pumpHistory(
        tester,
        deviceRepository: const _EmptyDeviceRepository(),
      );
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Belum ada perangkat terhubung'), findsOneWidget);
      expect(find.text('Buka Perangkat'), findsOneWidget);
      // Bukan pesan "belum ada pembacaan" — tidak ada perangkat, bukan kosong.
      expect(find.text('Belum ada pembacaan'), findsNothing);
    });

    testWidgets('subjudul jujur: jumlah yang dimuat', (tester) async {
      await pumpHistory(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Sampel demo lebih dari satu halaman (123 bacaan, halaman 25 baris):
      // subjudul wajib memakai "+" supaya tidak mengklaim memuat semuanya.
      expect(find.text('25+ pembacaan dimuat'), findsOneWidget);
    });

    testWidgets('filter kosong jujur + Tampilkan semua', (tester) async {
      final graph = FakeAppGraph();
      // Hanya satu item uang → filter teks kosong padahal data ada.
      graph.detections.replaceAll([
        Detection(
          id: 'det-test-money',
          deviceId: kDemoDeviceId,
          deviceName: kDemoDeviceName,
          type: DetectionType.money,
          createdAt: DateTime.now(),
          amount: 75000,
          confidence: 0.9,
          distanceCm: 25,
        ),
      ]);
      await pumpHistory(tester, graph: graph);
      await pumpFrames(tester);

      final segment = find.text('Teks').first;
      await tester.ensureVisible(segment);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(segment);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Tidak ada hasil untuk filter ini'), findsOneWidget);
      expect(find.text('Belum ada pembacaan'), findsNothing);

      await tester.tap(find.text('Tampilkan semua'));
      await pumpFrames(tester);
      expect(find.textContaining('75.000'), findsWidgets);
    });

    testWidgets('baris memakai ikon kategori + chip status', (tester) async {
      await pumpHistory(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Chip status validasi hadir (campuran pending/cocok/tidak).
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Cocok'), findsWidgets);
      // Chevron tap ke detail hadir di tiap baris.
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });

    testWidgets('ikon hapus geser memakai warna status bad', (tester) async {
      await pumpHistory(tester);
      await pumpFrames(tester);

      // Latar hapus harus memakai palet status bad (bukan errorContainer
      // mentah) agar selaras dengan Validasi. Baris pertama digeser
      // parsial: latar muncul tanpa memicu sheet konfirmasi.
      final row = find
          .ancestor(
            of: find.textContaining('100.000'),
            matching: find.byType(Dismissible),
          )
          .first;
      await tester.drag(row, const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.textContaining('100.000').first);
      final bad = StatusColors.of(context).bad.container;
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.delete_outline_rounded),
              matching: find.byType(Container),
            )
            .first,
      );
      // Latar hapus memakai `color` langsung (bukan decoration).
      expect(container.color, bad);
    });

    testWidgets('hapus baris menghilangkan baris + snackbar berlabel', (
      tester,
    ) async {
      final graph = FakeAppGraph();
      await pumpHistory(tester, graph: graph);
      await pumpFrames(tester);

      expect(find.textContaining('100.000'), findsWidgets);

      // Geser penuh ke kiri → sheet konfirmasi (bukan langsung hapus).
      // confirmDismiss me-return false: Dismissible memanggil onDelete lalu
      // menahan kartu di tempat sampai sheet dijawab.
      final row = find
          .ancestor(
            of: find.textContaining('100.000'),
            matching: find.byType(Dismissible),
          )
          .first;
      await tester.drag(row, const Offset(-600, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Konfirmasi sheet: ketuk "Hapus" di dalam ConfirmSheet (bukan teks
      // "Hapus" lain — cari eksplisit di bawah judul sheet).
      expect(find.text('Hapus pembacaan ini?'), findsOneWidget);
      final confirm = find.descendant(
        of: find.byType(ConfirmSheet),
        matching: find.text('Hapus'),
      );
      expect(confirm, findsOneWidget);
      await tester.ensureVisible(confirm);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await pumpFrames(tester);

      // Regresi bug basi: baris harus hilang dari UI (invalidate kunci
      // family tepat), snackbar menyebut nama yang dihapus. Assert via key
      // baris (ValueKey history-<id>): snackbar sukses sendiri mengandung
      // "100.000" sehingga pencarian teks mentah salah sasaran.
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('history-det-money-100k')),
        findsNothing,
      );
      expect(find.text('Rp 100.000 dihapus dari riwayat.'), findsOneWidget);
      expect(
        graph.detections.itemsForTest.any((d) => d.id == 'det-money-100k'),
        isFalse,
      );
    });
  });

  test('sampel demo memakai fake bersama (tidak drift)', () {
    expect(FakeDetectionDataSource().itemsForTest, isNotEmpty);
  });
}
