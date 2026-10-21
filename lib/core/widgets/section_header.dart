import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Kepala seksi tunggal untuk seluruh aplikasi.
///
/// Dua varian jarak:
/// - [SectionHeader] (halaman): padding horizontal 20 dp untuk layar yang
///   isinya belum punya padding sendiri (mis. tab Perangkat).
/// - [SectionHeader.inset]: tanpa padding horizontal karena sudah berada di
///   dalam `ListView` ber-padding 20 (Pengaturan, Detail perangkat, Kontrol).
///
/// Varian [dense] memakai jarak atas 12 dp untuk seksi pertama tepat di bawah
/// app bar. Jangan membuat header seksi privat baru: satu bahasa visual untuk
/// semua layar.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.action,
    this.dense = false,
  }) : inset = false;

  const SectionHeader.inset({
    required this.title,
    super.key,
    this.action,
    this.dense = false,
  }) : inset = true;

  final String title;
  final Widget? action;
  final bool inset;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset ? 0 : DesignTokens.spacePage,
        dense ? DesignTokens.spaceMd : DesignTokens.spaceSection,
        inset ? 0 : DesignTokens.spacePage,
        DesignTokens.spaceSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
