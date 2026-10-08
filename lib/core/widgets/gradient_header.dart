import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/status_colors.dart';

/// Header dengan latar gradien teal.
///
/// Dipakai di layar yang butuh penanda kuat seperti Beranda, Validasi, Riwayat,
/// Perangkat, dan Pengaturan. Judul dan aksi passed lewat [title], [subtitle],
/// dan [actions] agar widget tetap bebas dari logika.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.gradientStart, BrandColors.gradientEnd],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusBottomNav),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceLg,
        DesignTokens.spaceLg,
        DesignTokens.spaceLg,
        DesignTokens.spaceXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        subtitle!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              ...actions,
            ],
          ),
        ],
      ),
    );
  }
}
