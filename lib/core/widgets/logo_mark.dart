import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Mark logo SIGAP-NETRA (mata + gelombang sinyal) dalam bentuk bulat.
///
/// Dipakai untuk identitas merek (splash, layar masuk) dan avatar perangkat
/// "kacamata cerdas" (Hero Beranda, kepala tab Perangkat, detail perangkat) —
/// satu sumber, jangan menyalin `Image.asset` di layar.
///
/// Aset `logo_mark.png` sudah dipangkas dari sumber (`assets/images/logo.jpeg`)
/// dan memuat latar putih sebagai bagian desain: mark tampil sebagai cakram
/// putih di tema terang maupun gelap (pola ikon aplikasi).
///
/// `cacheWidth` sengaja TIDAK dipakai: satu dekode 512×512 (±1 MB) dipakai
/// bersama semua pemanggil karena kunci image-cache-nya `AssetImage` polos —
/// itu juga yang membuat precache di test (lihat `precacheLogoMark`) berlaku
/// untuk semua ukuran tampil.
class LogoMark extends StatelessWidget {
  const LogoMark({required this.size, super.key, this.semanticsLabel});

  /// Diameter cakram logo.
  final double size;

  /// Label untuk screen reader. Bila null, gambar dianggap dekoratif.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.asset(
          kLogoMarkAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          semanticLabel: semanticsLabel,
          excludeFromSemantics: semanticsLabel == null,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
