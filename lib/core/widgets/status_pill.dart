import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/status_colors.dart';

/// Semantik status yang dipakai seluruh aplikasi.
///
/// Warna ditentukan di satu tempat agar tidak pernah berbeda antar layar:
/// hijau untuk online/Cocok, merah untuk terputus/Tidak cocok/error,
/// amber untuk menunggu/peringatan, abu untuk Belum/tidak diketahui.
enum AppStatusTone { success, error, warning, neutral, info }

/// Pilihan label yang sering dipakai bersama nada status tertentu.
enum StatusLabelStyle {
  /// Green: online / Cocok.
  online,

  /// Red: offline-terputus / Tidak cocok / error.
  offline,

  /// Amber: warning / menunggu.
  waiting,

  /// Grey: Belum / unknown.
  unknown,
}

/// Badge kecil berisi teks status dengan warna yang konsisten.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.tone,
    super.key,
    this.icon,
    this.isDense = false,
  });

  /// Label online dengan nada hijau.
  factory StatusPill.online(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.success,
        isDense: isDense,
      );

  /// Label terputus dengan nada merah.
  factory StatusPill.offline(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.error,
        icon: Icons.cloud_off,
        isDense: isDense,
      );

  /// Label menunggu dengan nada amber.
  factory StatusPill.waiting(String label, {Key? key, bool isDense = false}) =>
      StatusPill(
        key: key,
        label: label,
        tone: AppStatusTone.warning,
        isDense: isDense,
      );

  /// Label belum/tidak diketahui dengan nada abu.
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
      AppStatusTone.success => palette.success,
      AppStatusTone.error => palette.error,
      AppStatusTone.warning => palette.warning,
      AppStatusTone.neutral => palette.neutral,
      AppStatusTone.info => palette.info,
    };

    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: background.content,
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
          color: background.container,
          borderRadius: BorderRadius.circular(DesignTokens.radiusBadge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 12 : 14, color: background.content),
              SizedBox(width: isDense ? 4 : DesignTokens.spaceXs),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}
