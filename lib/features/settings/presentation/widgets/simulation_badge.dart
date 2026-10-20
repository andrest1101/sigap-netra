import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/data_source.dart';
import '../providers/settings_providers.dart';

/// Label kenapa data simulasi dipakai, dalam bahasa manusia.
String simulationReasonLabel(AppLocalizations l10n, SimulationReason? reason) {
  return switch (reason) {
    SimulationReason.developerMode => l10n.simulationReasonDeveloperMode,
    SimulationReason.firebaseUnavailable =>
      l10n.simulationReasonFirebaseUnavailable,
    null => '',
  };
}

/// Pil kecil "SIMULASI" di app bar tab — penanda permanen, bukan hiasan.
///
/// Selalu membaca [dataSourceSelectionProvider] (kenyataan hasil resolusi di
/// `main.dart`), bukan preferensi `developer_mode`. Saat data live, widget ini
/// nol ukuran sehingga tidak menggeser app bar maupun golden test.
class SimulationBadge extends ConsumerWidget {
  const SimulationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(dataSourceSelectionProvider);
    if (!selection.isSimulation) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final status = StatusColors.of(context).warn;
    final label = l10n.simulationBadgeLabel;

    return Semantics(
      container: true,
      label: l10n.simulationBadgeSemantics,
      excludeSemantics: true,
      child: Container(
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXs),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
        decoration: ShapeDecoration(
          color: status.container,
          shape: StadiumBorder(
            side: BorderSide(color: status.solid.withValues(alpha: 0.45)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded, size: 14, color: status.content),
            const SizedBox(width: DesignTokens.spaceXs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: status.content,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keterangan mode simulasi satu blok — dipakai di layar masuk.
///
/// Berbeda dari [SimulationBadge] yang hanya menandai, blok ini menjelaskan
/// **apa artinya** bagi pengguna: data demo, tidak ada cloud, dan (di layar
/// masuk) akun apa pun diterima. Nol ukuran saat data live.
class SimulationNotice extends ConsumerWidget {
  const SimulationNotice({
    super.key,
    this.margin = EdgeInsets.zero,
    this.showLoginHint = false,
  });

  final EdgeInsetsGeometry margin;

  /// Tambahkan catatan khusus layar masuk: kredensial apa pun diterima.
  final bool showLoginHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(dataSourceSelectionProvider);
    if (!selection.isSimulation) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final status = StatusColors.of(context).warn;

    return Padding(
      padding: margin,
      child: Semantics(
        container: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          decoration: BoxDecoration(
            color: status.container,
            borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
            border: Border.all(color: status.solid.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: ShapeDecoration(
                  color: status.solid.withValues(alpha: 0.16),
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: 17,
                  color: status.content,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.simulationNoticeTitle,
                      style: textTheme.labelLarge?.copyWith(
                        color: status.content,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      l10n.simulationNoticeBody,
                      style: textTheme.bodySmall?.copyWith(
                        color: status.content,
                        height: 1.35,
                      ),
                    ),
                    if (showLoginHint) ...[
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        l10n.simulationLoginHint,
                        style: textTheme.bodySmall?.copyWith(
                          color: status.content,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      simulationReasonLabel(l10n, selection.simulationReason),
                      style: textTheme.labelSmall?.copyWith(
                        color: status.content,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
