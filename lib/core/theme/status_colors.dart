import 'package:flutter/material.dart';

/// Warna status dengan makna yang sudah pasti di seluruh aplikasi.
///
/// Shades mengikuti `ui_spec.md` v3 (identitas visual baru SIGAP-NETRA).
/// Makna tetap: ok = Terhubung/Cocok, bad = Terputus/Tidak cocok/error,
/// warn = Menunggu/Peringatan, neutral = Belum/tidak tersedia.
///
/// Didefinisikan sebagai `ThemeExtension` supaya mengikuti tema light/dark
/// secara otomatis. Jangan memakai warna mentah di widget; selalu baca lewat
/// `StatusColors.of(context)`. Warna tidak boleh menjadi satu-satunya pembawa
/// makna: selalu sertakan ikon atau label.
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

  StatusPalette copyWith({Color? solid, Color? container, Color? content}) {
    return StatusPalette(
      solid: solid ?? this.solid,
      container: container ?? this.container,
      content: content ?? this.content,
    );
  }

  StatusPalette lerp(StatusPalette? other, double t) {
    if (other == null) return this;
    return StatusPalette(
      solid: Color.lerp(solid, other.solid, t)!,
      container: Color.lerp(container, other.container, t)!,
      content: Color.lerp(content, other.content, t)!,
    );
  }
}

/// Kumpulan palet status sebagai `ThemeExtension`.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.ok,
    required this.bad,
    required this.warn,
    required this.neutral,
  });

  /// Terhubung, Cocok, berhasil.
  final StatusPalette ok;

  /// Terputus, Tidak cocok, error.
  final StatusPalette bad;

  /// Menunggu, peringatan.
  final StatusPalette warn;

  /// Belum, tidak diketahui.
  final StatusPalette neutral;

  /// Palet status untuk tema terang.
  static const StatusColors light = StatusColors(
    ok: StatusPalette(
      solid: Color(0xFF1E9E63),
      container: Color(0xFFDFF5E9),
      content: Color(0xFF0C5C36),
    ),
    bad: StatusPalette(
      solid: Color(0xFFD64550),
      container: Color(0xFFFBE3E6),
      content: Color(0xFF8C1D28),
    ),
    warn: StatusPalette(
      solid: Color(0xFFE5A00D),
      container: Color(0xFFFFF1D1),
      content: Color(0xFF7A5200),
    ),
    neutral: StatusPalette(
      solid: Color(0xFF6B6F80),
      container: Color(0xFFE9EAF0),
      content: Color(0xFF41454F),
    ),
  );

  /// Palet status untuk tema gelap.
  static const StatusColors dark = StatusColors(
    ok: StatusPalette(
      solid: Color(0xFF5FD39A),
      container: Color(0xFF123626),
      content: Color(0xFFA9E8C6),
    ),
    bad: StatusPalette(
      solid: Color(0xFFFF8A92),
      container: Color(0xFF3D151B),
      content: Color(0xFFFFB3B9),
    ),
    warn: StatusPalette(
      solid: Color(0xFFFFC857),
      container: Color(0xFF3A2C0E),
      content: Color(0xFFFFDD94),
    ),
    neutral: StatusPalette(
      solid: Color(0xFF9EA3B5),
      container: Color(0xFF23262F),
      content: Color(0xFFC6CAD6),
    ),
  );

  /// Mengambil palet dari tema aktif.
  ///
  /// Dipertahankan sebagai accessor kompatibel: pemanggil lama
  /// `StatusColors.of(context)` tetap jalan tanpa perubahan.
  static StatusColors of(BuildContext context) {
    return Theme.of(context).extension<StatusColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  StatusColors copyWith({
    StatusPalette? ok,
    StatusPalette? bad,
    StatusPalette? warn,
    StatusPalette? neutral,
  }) {
    return StatusColors(
      ok: ok ?? this.ok,
      bad: bad ?? this.bad,
      warn: warn ?? this.warn,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      ok: ok.lerp(other.ok, t),
      bad: bad.lerp(other.bad, t),
      warn: warn.lerp(other.warn, t),
      neutral: neutral.lerp(other.neutral, t),
    );
  }
}
