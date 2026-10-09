import 'package:flutter/material.dart';

/// Token desain numerik, warna brand, dan durasi.
///
/// Nilai diambil dari `ui_spec.md` v3 (identitas visual baru SIGAP-NETRA).
/// Ubah token di satu tempat; jangan menulis angka spasi, radius, atau warna
/// brand secara harfiah di widget.
abstract final class DesignTokens {
  // Skala spasi: kelipatan 4, padding halaman 20, antar-seksi 24.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spacePage = 20;
  static const double spaceSection = 24;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;

  // Radius v3: hero 28, kartu 20, thumbnail 14, input 14, sheet atas 28.
  // Tombol utama dan chip memakai bentuk pil (stadium) — lihat
  // [radiusPill] yang dipakai bersama `StadiumBorder`.
  static const double radiusBadge = 8;
  static const double radiusButton = 12;
  static const double radiusThumbnail = 14;
  static const double radiusInput = 14;
  static const double radiusCard = 20;
  static const double radiusSheet = 28;
  static const double radiusHero = 28;
  static const double radiusBottomNav = 24;

  // Ukuran target sentuh minimum (accessibility).
  static const double minTouchTarget = 48;

  // Ukuran avatar/status.
  static const double statusPillHeight = 32;
  static const double deviceAvatarSize = 56;
  static const double thumbnailSize = 56;
  static const double lensRingStroke = 10;

  // Lebar maksimum konten agar tetap terbaca di tablet.
  static const double maxContentWidth = 640;

  // Durasi animasi v3: 200-300 ms, `Curves.easeOutCubic`.
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 300);

  /// Kurva gerak standar v3.
  static const Curve motionCurve = Curves.easeOutCubic;
}

/// Warna brand SIGAP-NETRA (identitas visual v3).
///
/// Satu-satunya tempat seed warna brand berada; mengganti identitas warna =
/// mengubah konstanta ini. Jangan memakai warna mentah di widget.
abstract final class BrandColors {
  /// Netra Indigo — warna utama. Dipakai sebagai seed `ColorScheme.fromSeed`.
  static const Color seed = Color(0xFF4A47D6);

  /// Lensa Amber — aksen, dipakai sebagai `tertiary`.
  static const Color accent = Color(0xFFF5A524);

  /// Lensa Amber untuk tema gelap.
  static const Color accentDark = Color(0xFFFFC15A);

  /// Latar aplikasi.
  static const Color backgroundLight = Color(0xFFF6F6FB);
  static const Color backgroundDark = Color(0xFF0E0F1A);
}
