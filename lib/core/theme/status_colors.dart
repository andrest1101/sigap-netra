import 'package:flutter/material.dart';

/// Warna status dengan makna yang sudah pasti di seluruh aplikasi.
///
/// Aturan warna ini berasal dari `AGENTS.md` dan tidak boleh diubah per widget:
///
/// | Warna | Makna                                                                 |
/// | ----- | --------------------------------------------------------------------- |
/// | Hijau | Online / Cocok                                                     |
/// | Merah | Offline-terputus / Tidak cocok / error                              |
/// | Amber | Peringatan / menunggu                                              |
/// | Abu   | Belum / tidak diketahui                                            |
///
/// Setiap warna punya tiga varian agar kontrasnya tetap aman di light maupun
/// dark: `solid` untuk ikon/garis, `container` untuk latar, `content` untuk teks
/// di atas `container`.
@immutable
class StatusPalette {
  const StatusPalette({
    required this.solid,
    required this.container,
    required this.content,
  });

  final Color solid;
  final Color container;
  final Color content;
}

/// Kumpulan palet status yang sadar tema.
@immutable
class StatusColors {
  const StatusColors({
    required this.success,
    required this.error,
    required this.warning,
    required this.neutral,
    required this.info,
  });

  /// Hijau: perangkat online, pembacaan Cocok.
  final StatusPalette success;

  /// Merah: perangkat terputus, Tidak cocok, error.
  final StatusPalette error;

  /// Amber: menunggu, perlu perhatian.
  final StatusPalette warning;

  /// Abu: Belum, tidak diketahui.
  final StatusPalette neutral;

  /// Biru: informasi netral (perintah terkirim, sinkronisasi).
  final StatusPalette info;

  /// Palet status untuk tema terang.
  static const StatusColors light = StatusColors(
    success: StatusPalette(
      solid: Color(0xFF2E7D32),
      container: Color(0xFFE8F5E9),
      content: Color(0xFF1B5E20),
    ),
    error: StatusPalette(
      solid: Color(0xFFC62828),
      container: Color(0xFFFDECEA),
      content: Color(0xFFB71C1C),
    ),
    warning: StatusPalette(
      solid: Color(0xFFEF6C00),
      container: Color(0xFFFFF3E0),
      content: Color(0xFFE65100),
    ),
    neutral: StatusPalette(
      solid: Color(0xFF9E9E9E),
      container: Color(0xFFF5F5F5),
      content: Color(0xFF616161),
    ),
    info: StatusPalette(
      solid: Color(0xFF0277BD),
      container: Color(0xFFE1F5FE),
      content: Color(0xFF01579B),
    ),
  );

  /// Palet status untuk tema gelap.
  static const StatusColors dark = StatusColors(
    success: StatusPalette(
      solid: Color(0xFF66BB6A),
      container: Color(0xFF1B3A1E),
      content: Color(0xFFA5D6A7),
    ),
    error: StatusPalette(
      solid: Color(0xFFEF5350),
      container: Color(0xFF3E1C1C),
      content: Color(0xFFEF9A9A),
    ),
    warning: StatusPalette(
      solid: Color(0xFFFFB74D),
      container: Color(0xFF3D2E1A),
      content: Color(0xFFFFCC80),
    ),
    neutral: StatusPalette(
      solid: Color(0xFFBDBDBD),
      container: Color(0xFF2A2A2A),
      content: Color(0xFFE0E0E0),
    ),
    info: StatusPalette(
      solid: Color(0xFF4FC3F7),
      container: Color(0xFF17343F),
      content: Color(0xFF81D4FA),
    ),
  );

  /// Mengambil palet sesuai kecerahan tema saat ini.
  static StatusColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Warna seed dan gradien header yang konsisten di seluruh aplikasi.
abstract final class BrandColors {
  /// Warna seed Material 3.
  static const Color seed = Color(0xFF00897B);

  /// Awal gradien header.
  static const Color gradientStart = Color(0xFF009688);

  /// Akhir gradien header.
  static const Color gradientEnd = Color(0xFF00796B);
}
