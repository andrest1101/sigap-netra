import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';

/// Riwayat seluruh pembacaan dengan filter lokal untuk demo.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DetectionType? _type;
  ValidationStatus? _status;

  bool _matches(Detection detection) {
    final typeOk = _type == null || detection.type == _type;
    final statusOk = _status == null || detection.validationStatus == _status;
    return typeOk && statusOk;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detections = ref.watch(detectionsProvider);
    final items = detections.where(_matches).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceLg,
              DesignTokens.spaceXl,
              DesignTokens.spaceLg,
              DesignTokens.spaceLg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            width: double.infinity,
            child: Text(
              l10n.historyTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DetectionType?>(
                    value: _type,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterType,
                    ),
                    items: [
                      DropdownMenuItem<DetectionType?>(
                        value: null,
                        child: Text(l10n.commonNone),
                      ),
                      DropdownMenuItem<DetectionType?>(
                        value: DetectionType.money,
                        child: Text(l10n.historyTypeMoney),
                      ),
                      DropdownMenuItem<DetectionType?>(
                        value: DetectionType.text,
                        child: Text(l10n.historyTypeText),
                      ),
                    ],
                    onChanged: (value) => setState(() => _type = value),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: DropdownButtonFormField<ValidationStatus?>(
                    value: _status,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterStatus,
                    ),
                    items: [
                      DropdownMenuItem<ValidationStatus?>(
                        value: null,
                        child: Text(l10n.commonNone),
                      ),
                      DropdownMenuItem<ValidationStatus?>(
                        value: ValidationStatus.pending,
                        child: Text(l10n.statusPending),
                      ),
                      DropdownMenuItem<ValidationStatus?>(
                        value: ValidationStatus.match,
                        child: Text(l10n.statusMatch),
                      ),
                      DropdownMenuItem<ValidationStatus?>(
                        value: ValidationStatus.mismatch,
                        child: Text(l10n.statusMismatch),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyView(
                    title: l10n.historyEmptyTitle,
                    message: l10n.historyDeleteBody,
                    icon: Icons.history_toggle_off_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceSm),
                    itemBuilder: (context, index) {
                      final detection = items[index];
                      return ListTile(
                        tileColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusCard,
                          ),
                        ),
                        leading: CircleAvatar(
                          child: Icon(
                            detection.type == DetectionType.money
                                ? Icons.payments_outlined
                                : Icons.document_scanner_outlined,
                          ),
                        ),
                        title: Text(
                          detection.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${RelativeTime.format(detection.createdAt, now, l10n: l10n)} - ${detection.deviceName}',
                        ),
                        trailing: StatusPill(
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
                        onTap: () => context.push('/riwayat/${detection.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
