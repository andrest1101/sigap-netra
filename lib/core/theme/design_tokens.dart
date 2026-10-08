/// Token desain numerik dan durasi.
///
/// Nilai diambil dari `docs/ui_spec.md`. Ubah token di satu tempat; jangan
/// menulis angka spasi atau radius secara harfiah di widget.
abstract final class DesignTokens {
  // Skala spasi: kelipatan 4.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;

  // Radius.
  static const double radiusBadge = 8;
  static const double radiusButton = 12;
  static const double radiusCard = 16;
  static const double radiusBottomNav = 24;

  // Ukuran target sentuh minimum (accessibility).
  static const double minTouchTarget = 48;

  // Ukuran avatar/status pill.
  static const double statusPillHeight = 32;
  static const double deviceAvatarSize = 56;

  // Lebar maksimum konten agar tetap terbaca di tablet.
  static const double maxContentWidth = 640;

  // Durasi animasi.
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);
}
