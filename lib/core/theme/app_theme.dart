import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'status_colors.dart';

/// Tema Material 3 SIGAP-NETRA (identitas visual v3).
///
/// Seed Netra Indigo `#4A47D6`, aksen Lensa Amber sebagai `tertiary`, font
/// Plus Jakarta Sans (di-bundle), kartu tonal tanpa shadow, tombol & chip
/// bentuk pil, NavigationBar standar M3.
///
/// Terang-saja: mode gelap dihapus berdasarkan keputusan produk 2026-10-18
/// (satu identitas visual; tanpa pemilih tema di Pengaturan).
abstract final class AppTheme {
  /// Nama family font yang di-bundle di `assets/fonts/`.
  static const String fontFamily = 'PlusJakartaSans';

  /// Tema aplikasi (terang-saja).
  static ThemeData light() => _build(
    scaffold: BrandColors.background,
    accent: BrandColors.accent,
    status: StatusColors.light,
  );

  static ThemeData _build({
    required Color scaffold,
    required Color accent,
    required StatusColors status,
  }) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: Brightness.light,
    );
    // Aksen Lensa Amber sebagai tertiary sesuai identitas v3.
    colorScheme = colorScheme.copyWith(tertiary: accent, surface: scaffold);

    final textTheme = _textTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: fontFamily,
      textTheme: textTheme,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Header tab akar dan layar anak sama-sama memakai 18/SemiBold.
        // Header akar sengaja rapat agar konten tidak terdorong ke bawah;
        // hierarki navigasi dibedakan oleh tombol kembali dan isi layar.
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Kartu tonal v3: tanpa shadow, dengan hairline `outlineVariant` agar
      // batas kartu tetap terbaca di atas scaffold terang (bukan kartu putih
      // bershadow yang dilarang identitas v3).
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceXl,
            vertical: DesignTokens.spaceMd,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceXl,
            vertical: DesignTokens.spaceMd,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
        ),
      ),
      // Warna chip EKSPLISIT di tema (anti putih permanen).
      //
      // Latar: chip Material M3 mewarisi warna label dari `DefaultTextStyle`
      // internal bila `labelStyle.color` null — pada kasus kami itu jatuh ke
      // warna yang salah sehingga teks chip tampak putih di atas kartu terang.
      // Dengan warna eksplisit (termasuk varian selected/disabled via
      // `WidgetStateColor` yang di-resolve SDK di `chip.dart`), semua
      // ActionChip/ChoiceChip deterministik di light maupun dark.
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        checkmarkColor: colorScheme.onSecondaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSecondaryContainer;
            }
            return colorScheme.onSurfaceVariant;
          }),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 18),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSheet),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusBadge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: colorScheme.surfaceContainer,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: DesignTokens.spaceSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(DesignTokens.radiusCard),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  /// Tipografi v3: large-title 28/Bold, title 18/SemiBold, body 14,
  /// label/chip 12/SemiBold, angka besar 32-40/Bold tabular.
  ///
  /// `TextTheme.apply` penting: seluruh peran (termasuk `bodySmall` dan
  /// headline yang tidak di-override) wajib memakai Plus Jakarta Sans. Bila
  /// hanya sebagian di-`copyWith`, peran yang terlewat jatuh ke font fallback
  /// platform — terlihat jelas sebagai glyph kotak di golden test.
  static TextTheme _textTheme(TextTheme base) {
    final themed = base.apply(fontFamily: fontFamily);
    return themed.copyWith(
      displayLarge: themed.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: themed.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: themed.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: themed.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: themed.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: themed.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: themed.bodyMedium?.copyWith(fontSize: 14),
      labelLarge: themed.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: themed.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: themed.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
