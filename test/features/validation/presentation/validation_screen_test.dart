import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/status_colors.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/validation/presentation/screens/validation_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Auth stub: pengguna demo sudah masuk (untuk `validatedBy` UID).
class _StubAuthRepository implements AuthRepository {
  const _StubAuthRepository();

  @override
  AppUser? get currentUser =>
      const AppUser(uid: 'user-1', email: 'user@example.com');

  @override
  Stream<AuthState> watchAuthState() =>
      Stream<AuthState>.value(const AuthSignedOut());

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signInAnonymously() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

/// Repository tanpa perangkat — menguji empty state "belum ada perangkat".
class _EmptyDeviceRepository implements DeviceRepository {
  const _EmptyDeviceRepository();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) =>
      Stream<List<Device>>.value(const <Device>[]);

  @override
  Stream<Device?> watchDevice(String deviceId) => Stream<Device?>.value(null);
}

/// Regression test: tab Validasi pernah gagal render total karena `Expanded`
/// di dalam sliver tanpa batas tinggi. Test ini memastikan kartu antrean
/// tampil dan tombol aksi tersedia.
void main() {
  Future<void> pumpValidation(
    WidgetTester tester, {
    FakeAppGraph? graph,
    DeviceRepository? deviceRepository,
    double textScale = 1.0,
  }) async {
    final appGraph = graph ?? FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(const _StubAuthRepository()),
          deviceRepositoryProvider.overrideWithValue(
            deviceRepository ?? DemoDeviceRepository(),
          ),
          ...appGraph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: textScale == 1.0
              ? const ValidationScreen()
              // Text scale sistem 1,3x (batas dukungan spec) diuji lewat
              // MediaQuery override — bukan parameter test yang fiktif.
              : Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(textScale)),
                    child: const ValidationScreen(),
                  ),
                ),
        ),
      ),
    );
  }

  // Antrean demo memakai animasi + timer; pompa eksplisit secukupnya.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Validasi', () {
    testWidgets('menampilkan kartu antrean dan tombol aksi', (tester) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      // Sampel demo: uang 100rb terbaru + filter Gabungan aktif.
      expect(find.textContaining('100.000'), findsWidgets);
      expect(find.text('Cocok'), findsOneWidget);
      expect(find.text('Tidak cocok'), findsOneWidget);
      expect(find.text('Gabungan'), findsOneWidget);
    });

    testWidgets('filter Uang menyembunyikan sampel teks', (tester) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      // "Uang" muncul ganda (segmen di atas + chip kategori kartu): segmen
      // selalu di atas kartu dalam urutan tree, jadi targetkan yang pertama.
      final segment = find.text('Uang').first;
      await tester.ensureVisible(segment);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(segment);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Menu/Teks'), findsOneWidget);
    });

    // `FilledButton.icon` merender `_FilledButtonWithIcon` (bukan
    // `FilledButton`), jadi cari lewat teks yang unik di antrean.
    Future<void> tapMatch(WidgetTester tester) async {
      final match = find.text('Cocok');
      expect(match, findsOneWidget);
      await tester.ensureVisible(match.first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(match.first);
      await pumpFrames(tester);
    }

    testWidgets('menekan Cocok memajukan antrean + snackbar Urungkan', (
      tester,
    ) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      await tapMatch(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Urungkan'), findsOneWidget);
    });

    testWidgets('Urungkan mengembalikan kartu ke antrean', (tester) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      // Progres awal "1 dari 2" (dua item menunggu pada sampel demo).
      expect(find.text('1 dari 2'), findsOneWidget);

      await tapMatch(tester);
      // Setelah item pertama divalidasi: progres "1 dari 1". `ensureVisible`
      // di tapMatch men-scroll subtitle keluar viewport, jadi cari dengan
      // `skipOffstage: false`.
      expect(find.text('1 dari 1', skipOffstage: false), findsOneWidget);

      final undo = find.text('Urungkan');
      expect(undo, findsOneWidget);
      await tester.tap(undo.first);
      await pumpFrames(tester);

      // Kartu kembali: progres "1 dari 2" lagi.
      expect(find.text('1 dari 2', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa perangkat menampilkan ajakan hubungkan perangkat', (
      tester,
    ) async {
      await pumpValidation(
        tester,
        deviceRepository: const _EmptyDeviceRepository(),
      );
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Belum ada perangkat terhubung'), findsOneWidget);
      expect(find.text('Buka Perangkat'), findsOneWidget);
      // Bukan pesan "semua selesai" — tidak ada perangkat, bukan tuntas.
      expect(find.text('Semua pembacaan sudah diperiksa'), findsNothing);
    });

    testWidgets('filter kosong jujur, bukan "semua sudah diperiksa"', (
      tester,
    ) async {
      final graph = FakeAppGraph();
      // Hanya satu item menunggu, bertipe uang → filter Menu/Teks kosong
      // padahal antrean kategori lain masih ada.
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
      await pumpValidation(tester, graph: graph);
      await pumpFrames(tester);

      final segment = find.text('Menu/Teks').first;
      await tester.ensureVisible(segment);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(segment);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Tidak ada antrean di filter ini'), findsOneWidget);
      expect(find.textContaining('1 pembacaan menunggu'), findsOneWidget);
      expect(find.text('Semua pembacaan sudah diperiksa'), findsNothing);

      // "Tampilkan semua" mengembalikan antrean tanpa pindah tab.
      await tester.tap(find.text('Tampilkan semua'));
      await pumpFrames(tester);
      expect(find.textContaining('75.000'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol Cocok memakai warna status ok (ui_spec §5.2)', (
      tester,
    ) async {
      await pumpValidation(tester);
      await pumpFrames(tester);

      // `FilledButton.icon` merender subclass privat `FilledButton`, jadi
      // pencarian memakai predicate `w is FilledButton`.
      final matchButton = tester.widget<FilledButton>(
        find
            .ancestor(
              of: find.text('Cocok'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            )
            .first,
      );
      expect(
        matchButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        StatusColors.light.ok.solid,
      );
    });

    testWidgets('teks 1,3x tetap tanpa overflow di viewport ponsel', (
      tester,
    ) async {
      // 390x844 @3x — ukuran ponsel nyata; batas ketat untuk teks besar.
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await pumpValidation(tester, textScale: 1.3);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Cocok'), findsOneWidget);
      expect(find.text('Tidak cocok'), findsOneWidget);
    });
  });

  // Memastikan contoh demo hanya berisi uang dan teks OCR.
  test('sampel demo hanya uang dan teks', () {
    final items = FakeDetectionDataSource().itemsForTest;

    expect(items, isNotEmpty);
    for (final item in items) {
      expect(
        item.type,
        anyOf(DetectionType.money, DetectionType.text),
        reason: 'deteksi ${item.id} bukan uang/teks',
      );
    }
  });

  // Sampel teks harus jujur terhadap kapabilitas alat: teks posisi baca
  // (menu/sampul), bukan rambu jalan atau dokumen bebas.
  test('sampel teks bukan rambu atau dokumen bebas', () {
    final texts = FakeDetectionDataSource().itemsForTest.where(
      (item) => item.type == DetectionType.text,
    );

    expect(texts, isNotEmpty);
    const forbidden = ['PINTU KELUAR', 'MINIMARKET', 'RAMBU', 'REKLAME'];
    for (final item in texts) {
      final ocr = (item.ocrText ?? '').toUpperCase();
      for (final word in forbidden) {
        expect(
          ocr.contains(word),
          isFalse,
          reason: 'sampel ${item.id} menyiratkan OCR bebas ("$word")',
        );
      }
    }
  });
}
