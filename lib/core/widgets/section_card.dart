import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Kartu seksi tonal: satu wadah untuk sekelompok baris yang saling terkait.
///
/// Warna `surfaceContainerLow` + hairline `outlineVariant` (bukan shadow)
/// mengikuti identitas v3. [divide] menambahkan divider inset 16 dp di antara
/// anak agar baris tetap terbaca sebagai satu kelompok, bukan tumpukan kartu
/// terpisah. Semua jarak baris diserahkan kepada anak (12/16 dp).
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.children,
    super.key,
    this.padding = EdgeInsets.zero,
    this.divide = false,
    this.dividerIndent = DesignTokens.spaceLg,
    this.backgroundColor,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool divide;
  final double dividerIndent;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(DesignTokens.radiusCard);

    return Material(
      color: backgroundColor ?? colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (divide && index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent,
                  endIndent: dividerIndent,
                  color: colorScheme.outlineVariant,
                ),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}
