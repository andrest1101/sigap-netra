import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/status_colors.dart';
import 'status_pill.dart';

/// Titik status kecil: indikator warna + ikon untuk hero dan baris ringkas.
///
/// Warna tidak pernah berdiri sendiri — selalu dipasangkan dengan label teks
/// di pemanggil.
class StatusDot extends StatelessWidget {
  const StatusDot({required this.tone, super.key, this.size = 10});

  final AppStatusTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = StatusColors.of(context);
    final color = switch (tone) {
      AppStatusTone.ok => palette.ok.solid,
      AppStatusTone.bad => palette.bad.solid,
      AppStatusTone.warn => palette.warn.solid,
      AppStatusTone.neutral => palette.neutral.solid,
      AppStatusTone.info => Theme.of(context).colorScheme.tertiary,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Chip status v3: pil berisi ikon + label dengan warna nada status.
///
/// Pengganti gaya badge lama; bentuk selalu pil (`StadiumBorder`).
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    super.key,
    this.icon,
    this.isDense = false,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final palette = StatusColors.of(context);
    final background = switch (tone) {
      AppStatusTone.ok => palette.ok,
      AppStatusTone.bad => palette.bad,
      AppStatusTone.warn => palette.warn,
      AppStatusTone.neutral => palette.neutral,
      AppStatusTone.info => null,
    };

    final colorScheme = Theme.of(context).colorScheme;
    final container = background?.container ?? colorScheme.tertiaryContainer;
    final content = background?.content ?? colorScheme.onTertiaryContainer;

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDense ? DesignTokens.spaceSm : DesignTokens.spaceMd,
          vertical: isDense ? 2 : DesignTokens.spaceXs,
        ),
        decoration: ShapeDecoration(
          color: container,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 12 : 16, color: content),
              SizedBox(width: isDense ? 4 : DesignTokens.spaceXs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: content,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip metrik kecil: ikon + nilai, mis. Confidence `0,96` atau Jarak `35 cm`.
///
/// Netral secara visual (permukaan tonal), bukan warna status — angka bukan
/// status.
class MetricChip extends StatelessWidget {
  const MetricChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceXs,
      ),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: DesignTokens.spaceXs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
