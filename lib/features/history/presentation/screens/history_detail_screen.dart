import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';

/// Detail satu pembacaan dari Riwayat.
class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({required this.detectionId, super.key});

  final String detectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detections = ref.watch(detectionsProvider);
    final now = DateTime.now();
    final matches = detections.where((item) => item.id == detectionId);
    final detection = matches.isEmpty ? null : matches.first;

    if (detection == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.historyDetailTitle)),
        body: EmptyView(
          title: l10n.stateErrorNotFound,
          message: l10n.historyDeleteBody,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(
                  detection.type == DetectionType.money
                      ? Icons.payments_outlined
                      : Icons.document_scanner_outlined,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Text(
                  detection.displayLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusPill(
                label: switch (detection.validationStatus) {
                  ValidationStatus.pending => l10n.statusPending,
                  ValidationStatus.match => l10n.statusMatch,
                  ValidationStatus.mismatch => l10n.statusMismatch,
                },
                tone: switch (detection.validationStatus) {
                  ValidationStatus.pending => AppStatusTone.warning,
                  ValidationStatus.match => AppStatusTone.success,
                  ValidationStatus.mismatch => AppStatusTone.error,
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          TextFormField(
            initialValue: detection.ocrText ?? detection.label ?? '',
            readOnly: true,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Hasil pengenalan'),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          _MetaRow(
            label: l10n.historyFilterType,
            value: detection.type == DetectionType.money
                ? l10n.historyTypeMoney
                : l10n.historyTypeText,
          ),
          _MetaRow(label: l10n.navDevices, value: detection.deviceName),
          _MetaRow(
            label: l10n.homeLastSeenLabel,
            value: RelativeTime.format(detection.createdAt, now, l10n: l10n),
          ),
          _MetaRow(
            label: l10n.validationConfidenceLabel,
            value: '${((detection.confidence ?? 0) * 100).toStringAsFixed(0)}%',
          ),
          if (detection.distanceCm != null)
            _MetaRow(
              label: l10n.validationDistanceLabel,
              value: '${detection.distanceCm} cm',
            ),
          if (detection.validationStatus != ValidationStatus.pending) ...[
            const SizedBox(height: DesignTokens.spaceLg),
            FilledButton.tonal(
              onPressed: () {
                ref.read(detectionsProvider.notifier).reset(detection.id);
                Navigator.of(context).pop();
              },
              child: Text(l10n.validationUndo),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value),
        ],
      ),
    );
  }
}
