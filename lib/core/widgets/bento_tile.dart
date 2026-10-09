import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Ubin bento: kartu tonal untuk ringkasan angka 2 kolom.
///
/// Angka besar 32-40/Bold dengan `tabularFigures` agar tidak bergeser saat
/// berubah. Varian [BentoTile.tall] untuk tile tinggi (mis. Menunggu +
/// tombol Periksa), [BentoTile.small] untuk tile ringkas sebaris.
class BentoTile extends StatelessWidget {
  const BentoTile({
    required this.label,
    required this.child,
    super.key,
    this.action,
    this.onTap,
  });

  /// Tile ringkas: label + nilai sebaris.
  BentoTile.small({
    required this.label,
    required String value,
    super.key,
    this.action,
    this.onTap,
  }) : child = _SmallValue(value: value);

  final String label;
  final Widget child;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tile = Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          child,
          if (action != null) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            action!,
          ],
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      child: tile,
    );
  }
}

class _SmallValue extends StatelessWidget {
  const _SmallValue({required this.value});

  static final _tabular = FontFeature.tabularFigures();

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontFeatures: [_tabular]),
    );
  }
}

/// Nilai angka besar bento (32-40/Bold, tabular).
class BentoNumber extends StatelessWidget {
  const BentoNumber(this.value, {super.key, this.fontSize = 36});

  static final _tabular = FontFeature.tabularFigures();

  final String value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontFeatures: [_tabular],
      ),
    );
  }
}

/// Kepala seksi: judul + aksi opsional di kanan.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceSection,
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
