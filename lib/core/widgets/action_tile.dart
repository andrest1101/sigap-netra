import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Baris aksi dengan ikon, judul, dan keterangan singkat.
///
/// Dipakai untuk kelompok aksi di Detail perangkat dan Kontrol jarak jauh.
/// Seluruh baris adalah target sentuh (bukan chip kecil): ikon 40 dp, judul
/// 14/SemiBold, keterangan 12/Regular, dan chevron. Saat [onTap] null baris
/// tampil nonaktif dengan ikon kunci — alasan nonaktif tetap wajib dijelaskan
/// oleh pemanggil di dekat kelompok aksi.
class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final disabledColor = colorScheme.onSurface.withValues(alpha: 0.38);
    final titleColor = _enabled ? colorScheme.onSurface : disabledColor;
    final subtitleColor = _enabled
        ? colorScheme.onSurfaceVariant
        : disabledColor;
    final iconTint = _enabled
        ? (iconColor ?? colorScheme.primary)
        : disabledColor;
    final label = subtitle == null ? title : '$title. $subtitle';

    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceLg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _enabled
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignTokens.spaceMd),
                ),
                child: Icon(icon, size: 20, color: iconTint),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(color: titleColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              trailing ??
                  Icon(
                    _enabled
                        ? Icons.chevron_right_rounded
                        : Icons.lock_outline_rounded,
                    size: 20,
                    color: _enabled
                        ? colorScheme.onSurfaceVariant
                        : disabledColor,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
