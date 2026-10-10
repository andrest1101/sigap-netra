import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sigap_netra_app/features/auth/presentation/widgets/sign_up_sheet.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Widget test layar masuk baru: hero, validasi, sheet daftar, tamu.
void main() {
  late FakeAuthDataSource dataSource;

  setUp(() => dataSource = FakeAuthDataSource());
  tearDown(() => dataSource.dispose());

  Future<void> pumpLogin(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepositoryImpl(dataSource),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Konten login tinggi (hero + form + tombol) melebihi viewport test
  /// 800x600 — scroll dulu agar target terlihat sebelum di-tap.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(finder);
  }

  group('LoginScreen', () {
    testWidgets('menampilkan hero, form, Google, tamu, dan link daftar', (
      tester,
    ) async {
      await pumpLogin(tester);

      expect(find.text('SIGAP-NETRA'), findsOneWidget);
      expect(find.text('Selamat datang kembali'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata sandi'), findsOneWidget);
      expect(find.text('Masuk dengan email'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.text('Lanjutkan sebagai tamu'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('email salah format menampilkan error validasi', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(find.byType(TextField).first, 'bukan-email');
      await tester.enterText(find.byType(TextField).at(1), 'rahasia123');
      await tapVisible(tester, find.text('Masuk dengan email'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Format email tidak valid.'), findsOneWidget);
      expect(dataSource.currentUser, isNull);
    });

    testWidgets('link Daftar membuka sheet pendaftaran', (tester) async {
      await pumpLogin(tester);

      await tapVisible(tester, find.text('Daftar'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Buat akun'), findsWidgets);
      expect(find.text('Konfirmasi kata sandi'), findsOneWidget);
    });

    Finder sheetFields() => find.descendant(
      of: find.byType(SignUpSheet),
      matching: find.byType(TextField),
    );

    Future<void> fillSheet(WidgetTester tester, List<String> values) async {
      final fields = sheetFields();
      for (var i = 0; i < values.length; i++) {
        await tester.ensureVisible(fields.at(i));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(fields.at(i), values[i]);
      }
    }

    testWidgets('sheet menolak konfirmasi tidak cocok', (tester) async {
      await pumpLogin(tester);
      await tapVisible(tester, find.text('Daftar'));
      await tester.pump(const Duration(milliseconds: 500));

      await fillSheet(tester, [
        '',
        'baru@example.com',
        'rahasia123',
        'berbeda123',
      ]);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buat akun'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);
      expect(dataSource.currentUser, isNull);
    });

    testWidgets('sheet mendaftarkan akun valid', (tester) async {
      await pumpLogin(tester);
      await tapVisible(tester, find.text('Daftar'));
      await tester.pump(const Duration(milliseconds: 500));

      await fillSheet(tester, [
        'Budi',
        'budi@example.com',
        'rahasia123',
        'rahasia123',
      ]);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buat akun'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(dataSource.currentUser?.email, 'budi@example.com');
    });

    testWidgets('tamu masuk tanpa kredensial', (tester) async {
      await pumpLogin(tester);

      await tapVisible(tester, find.text('Lanjutkan sebagai tamu'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(dataSource.currentUser, isNotNull);
      expect(dataSource.currentUser?.email, isNull);
    });

    testWidgets('light: render aktual', (tester) async {
      await pumpLogin(tester, mode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('../goldens/login_light.png'),
      );
    });

    testWidgets('dark: render aktual', (tester) async {
      await pumpLogin(tester, mode: ThemeMode.dark);
      await tester.pump(const Duration(seconds: 16));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('../goldens/login_dark.png'),
      );
    });
  });
}
