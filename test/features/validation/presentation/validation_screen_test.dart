import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/monitoring/presentation/providers/monitoring_providers.dart';
import 'package:sigap_netra_app/features/validation/presentation/screens/validation_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

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

/// Regression test: tab Validasi pernah gagal render total karena `Expanded`
/// di dalam sliver tanpa batas tinggi. Test ini memastikan kartu antrean
/// tampil dan tombol aksi tersedia.
void main() {
  Future<void> pumpValidation(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(const _StubAuthRepository()),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ValidationScreen(),
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

      // Progres awal "1 dari 5".
      expect(find.text('1 dari 5'), findsOneWidget);

      await tapMatch(tester);
      // Setelah 1 dari 5 divalidasi: progres "1 dari 4". `ensureVisible`
      // di tapMatch men-scroll subtitle keluar viewport, jadi cari dengan
      // `skipOffstage: false`.
      expect(find.text('1 dari 4', skipOffstage: false), findsOneWidget);

      final undo = find.text('Urungkan');
      expect(undo, findsOneWidget);
      await tester.tap(undo.first);
      await pumpFrames(tester);

      // Kartu kembali: progres "1 dari 5" lagi.
      expect(find.text('1 dari 5', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // Memastikan contoh demo hanya berisi uang dan teks OCR.
  test('sampel demo hanya uang dan teks', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final items = container.read(detectionsProvider);

    expect(items, isNotEmpty);
    for (final item in items) {
      expect(
        item.type,
        anyOf(DetectionType.money, DetectionType.text),
        reason: 'deteksi ${item.id} bukan uang/teks',
      );
    }
  });
}
