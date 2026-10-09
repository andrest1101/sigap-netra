import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/status_colors.dart';

/// Semantik status yang dipakai seluruh aplikasi.
///
/// Nada mengikuti `ui_spec.md` v3: ok = Terhubung/Cocok, bad =
/// Terputus/Tidak cocok/error, warn = Menunggu/peringatan,
/// neutral = Belum/tidak diketahui. `info` memakai `tertiary` skema
/// (Lensa Amber) untuk informasi netral seperti perintah terkirim.
enum AppStatusTone { ok, bad, warn, neutral, info }

/// Badge kecil berisi teks status dengan warna yang konsisten.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.tone,
    super.key,
    this.icon,
    this.isDense = false,
  });

  /// Label terhubung/Cocok dengan nada ok.
  factory StatusPill.online(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.ok,
        isDense: isDense,
      );

  /// Label terputus dengan nada bad.
  factory StatusPill.offline(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.bad,
        icon: Icons.cloud_off_rounded,
        isDense: isDense,
      );

  /// Label menunggu dengan nada warn.
  factory StatusPill.waiting(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.warn,
        isDense: isDense,
      );

  /// Label belum/tidak diketahui dengan nada neutral.
  factory StatusPill.unknown(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.neutral,
        isDense: isDense,
      );

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

    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: content,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDense ? DesignTokens.spaceSm : DesignTokens.spaceMd,
          vertical: isDense ? 2 : DesignTokens.spaceXs + 1,
        ),
        decoration: BoxDecoration(
          color: container,
          borderRadius: BorderRadius.circular(DesignTokens.radiusBadge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 12 : 14, color: content),
              SizedBox(width: isDense ? 4 : DesignTokens.spaceXs),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}
