import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';

/// Antrean pembacaan yang perlu dinilai cocok/tidak cocok.
class ValidationScreen extends ConsumerWidget {
  const ValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(pendingDetectionsProvider);
    final now = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: l10n.validationTitle,
            subtitle: '${pending.length} ${l10n.homePendingLabel}',
          ),
          Expanded(
            child: pending.isEmpty
                ? EmptyView(
                    title: l10n.validationEmptyTitle,
                    message: l10n.validationEmptyBody,
                    icon: Icons.task_alt_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    itemCount: pending.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceMd),
                    itemBuilder: (context, index) {
                      final detection = pending[index];
                      return _ValidationCard(
                        detection: detection,
                        now: now,
                        onMatch: () => ref
                            .read(detectionsProvider.notifier)
                            .markValidated(
                              id: detection.id,
                              status: ValidationStatus.match,
                              validatedBy: ref.read(currentUserProvider)?.uid,
                            ),
                        onMismatch: () => ref
                            .read(detectionsProvider.notifier)
                            .markValidated(
                              id: detection.id,
                              status: ValidationStatus.mismatch,
                              validatedBy: ref.read(currentUserProvider)?.uid,
                            ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({
    required this.detection,
    required this.now,
    required this.onMatch,
    required this.onMismatch,
  });

  final Detection detection;
  final DateTime now;
  final VoidCallback onMatch;
  final VoidCallback onMismatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMoney = detection.type == DetectionType.money;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMoney
                      ? Icons.payments_outlined
                      : Icons.document_scanner_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spaceSm),
                Expanded(
                  child: Text(
                    detection.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusPill(
                  label: l10n.statusPending,
                  tone: AppStatusTone.warning,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              detection.deviceName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (detection.distanceCm != null)
              Text(
                '${l10n.validationDistanceLabel}: ${detection.distanceCm} cm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              RelativeTime.format(detection.createdAt, now, l10n: l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              isMoney
                  ? (detection.confidence == null
                        ? l10n.validationConfidenceNoValue
                        : l10n.validationConfidenceValue(
                            (detection.confidence! * 100).toStringAsFixed(0),
                          ))
                  : (detection.ocrText ?? l10n.validationNoImage),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onMatch,
                    child: Text(l10n.validationMarkMatch),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMismatch,
                    child: Text(l10n.validationMarkMismatch),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
