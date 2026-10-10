import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';

/// Detail satu pembacaan — identitas visual v3.
///
/// Gambar besar via `Hero`, metadata sebagai `MetricChip`, ubah status
/// validasi, aksi Bagikan (dengan consent OCR).
class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({required this.detectionId, super.key});

  final String detectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detections = ref.watch(detectionsProvider);
    final matches = detections.where((item) => item.id == detectionId);
    final detection = matches.isEmpty ? null : matches.first;

    if (detection == null) {
      return Scaffold(
        appBar: BackAppBar(
          title: Text(l10n.historyDetailTitle),
          fallbackRoute: AppRoutes.history,
        ),
        body: EmptyView(
          title: l10n.stateErrorNotFound,
          message: l10n.historyEmptyBody,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.historyDetailTitle),
        fallbackRoute: AppRoutes.history,
        actions: [
          IconButton(
            onPressed: () => _share(context, ref, detection),
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.sharingAction,
          ),
          IconButton(
            onPressed: () => _delete(context, ref, detection),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.commonDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacePage,
          DesignTokens.spaceSm,
          DesignTokens.spacePage,
          DesignTokens.spaceSection,
        ),
        children: [
          _DetailImage(detection: detection),
          const SizedBox(height: DesignTokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  detection.displayLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: DesignTokens.displayLabelSize,
                  ),
                  maxLines: DesignTokens.displayLabelMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              StatusChip(
                label: switch (detection.validationStatus) {
                  ValidationStatus.pending => l10n.statusPending,
                  ValidationStatus.match => l10n.statusMatch,
                  ValidationStatus.mismatch => l10n.statusMismatch,
                },
                tone: switch (detection.validationStatus) {
                  ValidationStatus.pending => AppStatusTone.warn,
                  ValidationStatus.match => AppStatusTone.ok,
                  ValidationStatus.mismatch => AppStatusTone.bad,
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          _OcrCard(detection: detection),
          const SizedBox(height: DesignTokens.spaceMd),
          Wrap(
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceSm,
            children: [
              MetricChip(
                icon: detection.type == DetectionType.money
                    ? Icons.payments_rounded
                    : Icons.document_scanner_rounded,
                label: detection.type == DetectionType.money
                    ? l10n.historyTypeMoney
                    : l10n.historyTypeText,
              ),
              MetricChip(
                icon: Icons.speed_rounded,
                label: detection.confidence == null
                    ? l10n.validationConfidenceNoValue
                    : NumberFormatId.percentWithSign(
                        detection.confidence! * 100,
                      ),
              ),
              if (detection.distanceCm != null)
                MetricChip(
                  icon: Icons.straighten_rounded,
                  label: '${detection.distanceCm} cm',
                ),
              MetricChip(
                icon: Icons.schedule_rounded,
                label: RelativeTime.format(
                  detection.createdAt,
                  DateTime.now(),
                  l10n: l10n,
                ),
              ),
              MetricChip(
                icon: Icons.devices_other_outlined,
                label: detection.deviceName,
              ),
            ],
          ),
          if (detection.validatedBy != null) ...[
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              '${l10n.settingsSignedInUid}: ${detection.validatedBy}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.spaceSection),
          _ValidationActions(detection: detection),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Detection detection,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await ConfirmSheet.show(
      context,
      title: l10n.historyDeleteTitle,
      message: l10n.historyDeleteBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed && context.mounted) {
      HapticFeedback.mediumImpact();
      ref.read(detectionsProvider.notifier).removeForUndo(detection.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyDeleted)));
    }
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    Detection detection,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasOcr = detection.ocrText != null && detection.ocrText!.isNotEmpty;
    var includeOcr = false;
    if (hasOcr) {
      includeOcr = await ConsentSheet.show(
        context,
        title: l10n.sharingConsentTitle,
        message: l10n.sharingConsentBody,
        acceptLabel: l10n.sharingAction,
      );
      if (!context.mounted) return;
      if (!includeOcr && detection.ocrText != null) {
        // Pengguna menolak OCR: bagikan ringkasan tanpa kutipan teks.
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.sharingEmpty)));
  }
}

/// Gambar besar dengan Hero; panel informatif bila tanpa gambar.
class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (detection.thumbnailId == null) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacePage),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        ),
        child: Row(
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.validationNoImageTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    l10n.validationNoImageBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Hero(
      tag: 'detection-${detection.id}',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          ),
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
            semanticLabel: l10n.historyRecognitionResult,
          ),
        ),
      ),
    );
  }
}

/// Kartu OCR: teks penuh (bisa scroll) + salin.
class _OcrCard extends StatefulWidget {
  const _OcrCard({required this.detection});

  final Detection detection;

  @override
  State<_OcrCard> createState() => _OcrCardState();
}

class _OcrCardState extends State<_OcrCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final raw = widget.detection.ocrText ?? widget.detection.label ?? '–';
    final needsFold = raw.length > 500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.historyRecognitionResult,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: DesignTokens.letterSpacingLabel,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: raw));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.commonSave)));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: l10n.historyRecognitionResult,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXs),
          SelectableText(
            _expanded || !needsFold ? raw : '${raw.substring(0, 500)}…',
            style: textTheme.bodyLarge,
          ),
          if (needsFold)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? l10n.commonClose : l10n.commonSeeDetail),
            ),
        ],
      ),
    );
  }
}

/// Aksi ubah status validasi dari detail.
class _ValidationActions extends ConsumerWidget {
  const _ValidationActions({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (detection.validationStatus != ValidationStatus.pending) {
      return OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          ref.read(detectionsProvider.notifier).reset(detection.id);
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.undo_rounded),
        label: Text(l10n.validationUndo),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(detectionsProvider.notifier)
                  .markValidated(
                    id: detection.id,
                    status: ValidationStatus.mismatch,
                    validatedBy: ref.read(currentUserProvider)?.uid,
                  );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.validationMarkMismatch),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(detectionsProvider.notifier)
                  .markValidated(
                    id: detection.id,
                    status: ValidationStatus.match,
                    validatedBy: ref.read(currentUserProvider)?.uid,
                  );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.validationMarkMatch),
          ),
        ),
      ],
    );
  }
}
