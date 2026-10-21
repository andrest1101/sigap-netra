import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('layar anak memakai judul 18/SemiBold', () {
      final style = AppTheme.light().appBarTheme.titleTextStyle;

      expect(style?.fontSize, 18);
      expect(style?.fontWeight, FontWeight.w600);
      expect(style?.fontFamily, AppTheme.fontFamily);
    });

    test('semua peran teks memakai Plus Jakarta Sans', () {
      final textTheme = AppTheme.light().textTheme;
      final roles = <String, TextStyle?>{
        'displayLarge': textTheme.displayLarge,
        'displayMedium': textTheme.displayMedium,
        'displaySmall': textTheme.displaySmall,
        'headlineLarge': textTheme.headlineLarge,
        'headlineMedium': textTheme.headlineMedium,
        'headlineSmall': textTheme.headlineSmall,
        'titleLarge': textTheme.titleLarge,
        'titleMedium': textTheme.titleMedium,
        'titleSmall': textTheme.titleSmall,
        'bodyLarge': textTheme.bodyLarge,
        'bodyMedium': textTheme.bodyMedium,
        'bodySmall': textTheme.bodySmall,
        'labelLarge': textTheme.labelLarge,
        'labelMedium': textTheme.labelMedium,
        'labelSmall': textTheme.labelSmall,
      };

      for (final entry in roles.entries) {
        expect(
          entry.value?.fontFamily,
          AppTheme.fontFamily,
          reason: '${entry.key} harus memakai font aplikasi',
        );
      }
    });

    test('tombol, chip, dan navigation bar memakai font aplikasi', () {
      final theme = AppTheme.light();

      expect(
        theme.filledButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
      expect(
        theme.outlinedButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
      expect(
        theme.textButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
      expect(theme.chipTheme.labelStyle?.fontFamily, AppTheme.fontFamily);
      expect(
        theme.navigationBarTheme.labelTextStyle?.resolve({})?.fontFamily,
        AppTheme.fontFamily,
      );
    });
  });
}
