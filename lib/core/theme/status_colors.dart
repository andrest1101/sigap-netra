import 'package:flutter/material.dart';

/// Semantik status yang dipakai seluruh aplikasi.
///
/// Nada mengikuti `ui_spec.md` v3: ok = Terhubung/Cocok, bad =
/// Terputus/Tidak cocok/error, warn = Menunggu/peringatan,
/// neutral = Belum/tidak diketahui. `info` memakai `tertiary` skema
/// (Lensa Amber) untuk informasi netral seperti perintah terkirim.
enum AppStatusTone { ok, bad, warn, neutral, info }

/// Warna status dengan makna yang sudah pasti di seluruh aplikasi.
///
/// Shades mengikuti `ui_spec.md` v3 (identitas visual baru SIGAP-NETRA).
/// Makna tetap: ok = Terhubung/Cocok, bad = Terputus/Tidak cocok/error,
/// warn = Menunggu/Peringatan, neutral = Belum/tidak tersedia.
///
/// Didefinisikan sebagai `ThemeExtension` agar selalu dibaca lewat satu pintu
/// `StatusColors.of(context)` (aplikasi terang-saja, keputusan 2026-10-18).
/// Jangan memakai warna mentah di widget. Warna tidak boleh menjadi
/// satu-satunya pembawa makna: selalu sertakan ikon atau label.
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

  /// Palet status aplikasi (terang-saja).
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

  /// Mengambil palet status dari tema aktif.
  ///
  /// Fallback ke [light] bila ekstensi belum terpasang (mis. widget test
  /// dengan `ThemeData` polos).
  static StatusColors of(BuildContext context) {
    return Theme.of(context).extension<StatusColors>() ?? light;
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
