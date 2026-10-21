import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Ubin bento: kartu tonal untuk ringkasan angka 2 kolom.
///
/// Angka besar 32-40/Bold dengan `tabularFigures` agar tidak bergeser saat
/// berubah. Varian [BentoTile.tall] untuk tile tinggi (mis. Menunggu +
/// tombol Periksa), [BentoTile.small] untuk tile ringkas sebaris.
///
/// Tone `surfaceContainer` (satu langkah di atas kartu biasa
/// `surfaceContainerLow`): di atas scaffold terang `#F6F6FB`, tone Low nyaris
/// menyatu dengan halaman sehingga Beranda terbaca "putih rata". Hairline
/// `outlineVariant` tetap dipakai — identitas v3 kartu tonal tanpa shadow.
class BentoTile extends StatelessWidget {
  const BentoTile({
    required this.label,
    required this.child,
    super.key,
    this.action,
    this.onTap,
    this.footer,
    this.icon,
    this.iconColor,
  });

  /// Tile ringkas: label + nilai sebaris.
  BentoTile.small({
    required this.label,
    required String value,
    super.key,
    this.action,
    this.onTap,
    this.footer,
    this.icon,
    this.iconColor,
  }) : child = _SmallValue(value: value);

  final String label;
  final Widget child;
  final Widget? action;
  final VoidCallback? onTap;

  /// Teks mikro di bawah nilai (mis. "3 uang · 2 teks"): memberi konteks
  /// tanpa menambah tinggi tile secara berarti.
  final String? footer;

  /// Ikon header: lingkaran tonal di depan label agar tiap tile punya
  /// identitas visual (bukan 4 kartu abu identik). Warna via [iconColor],
  /// default `onSurfaceVariant`.
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tile = Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceXs),
                  // Highest, bukan High: bubble harus tetap 2 tingkat di atas
                  // tone tile (`surfaceContainer`) agar lingkarannya terbaca.
                  decoration: ShapeDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: iconColor ?? colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          child,
          if (footer != null) ...[
            const SizedBox(height: DesignTokens.spaceXs),
            Text(
              footer!,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    // Satu baris + ellipsis: dua tile kecil sejajar tingginya sama walau
    // nilainya panjang ("5 menit yang lalu").
    return Text(
      value,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontFeatures: [_tabular]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
