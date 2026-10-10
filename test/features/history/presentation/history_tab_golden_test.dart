import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Golden tab Riwayat (terang): membuktikan label chip berwarna gelap
/// terbaca di atas daftar terang — bukan putih yang menyatu dengan latar.
void main() {
  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
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

  /// Warna efektif label chip: `Text.style` chip selalu null — warna
  /// diwariskan lewat `DefaultTextStyle` yang dipasang chip dari
  /// `chipTheme.labelStyle`. Keduanya dibaca, baru diukur luminance-nya.
  double labelLuminance(WidgetTester tester, Finder finder) {
    final text = tester.widget<Text>(finder.first);
    final element = tester.element(finder.first);
    final raw = text.style?.color ?? DefaultTextStyle.of(element).style.color;
    expect(
      raw,
      isNotNull,
      reason: 'label "${text.data}" tidak memakai warna efektif dari tema',
    );
    final color = raw!;
    final resolved = color is WidgetStateColor
        ? color.resolve(const <WidgetState>{})
        : color;
    return resolved.computeLuminance();
  }

  group('Golden tab Riwayat', () {
    testWidgets('chip kategori + filter berteks gelap (light)', (tester) async {
      await pumpHistory(tester);
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Riwayat'), findsWidgets);
      for (final label in ['Semua', 'Uang', 'Teks', 'Saring']) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: 'label chip "$label" hilang');
        expect(
          labelLuminance(tester, finder) < 0.5,
          isTrue,
          reason: 'teks chip "$label" terlalu terang di tema terang',
        );
      }

      await expectLater(
        find.byType(HistoryScreen),
        matchesGoldenFile('../goldens/history_tab_light.png'),
      );
    });

    testWidgets('render aktual dark tanpa error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(uid: 'user-1', email: 'user@example.com'),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const HistoryScreen(),
          ),
        ),
      );
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Riwayat'), findsWidgets);
    });
  });
}
