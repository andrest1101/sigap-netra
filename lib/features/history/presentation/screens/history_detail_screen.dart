import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../../media/presentation/providers/media_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';
import '../../../sharing/domain/usecases/build_share_report.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../validation/presentation/providers/validation_providers.dart';
import '../providers/history_providers.dart';

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
    final deviceId = ref.watch(primaryDeviceIdProvider);
    final detectionAsync = deviceId == null
        ? null
        : ref.watch(
            detectionProvider((deviceId: deviceId, detectionId: detectionId)),
          );
    final detection = detectionAsync?.value;

    if (detection == null) {
      // Tiga kemungkinan dibedakan supaya jujur: belum ada perangkat, masih
      // memuat / gagal memuat, atau dokumen memang sudah tidak ada.
      final Widget body;
      if (detectionAsync == null || detectionAsync.hasValue) {
        body = EmptyView(
          title: l10n.stateErrorNotFound,
          message: l10n.historyEmptyBody,
          icon: Icons.receipt_long_outlined,
        );
      } else if (detectionAsync.hasError) {
        body = ErrorView(
          message: _failureText(context, detectionAsync.error!),
          onRetry: () => ref.invalidate(
            detectionProvider((deviceId: deviceId!, detectionId: detectionId)),
          ),
        );
      } else {
        body = const _DetailSkeleton();
      }
      return Scaffold(
        appBar: BackAppBar(
          title: Text(l10n.historyDetailTitle),
          fallbackRoute: AppRoutes.history,
        ),
        body: body,
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
              l10n.historyValidatedByAt(
                detection.validatedBy!,
                detection.validatedAt == null
                    ? l10n.timeNever
                    : RelativeTime.dateTime(detection.validatedAt!),
              ),
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
    if (!confirmed || !context.mounted) return;
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(deleteDetectionProvider)
          .call(
            deviceId: detection.deviceId,
            detectionId: detection.id,
            thumbnailId: detection.thumbnailId,
          );
      // Daftar di belakang harus segar saat kembali: buang semua instance
      // halaman family (filter boleh apa saja) + thumbnail yang dihapus.
      ref.invalidate(historyPageProvider);
      final thumb = detection.thumbnailId;
      if (thumb != null && thumb.isNotEmpty) {
        ref.invalidate(
          thumbnailProvider(
            ThumbnailQuery(deviceId: detection.deviceId, thumbnailId: thumb),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.historyActionFailed)));
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.historyDeletedNamed(detection.displayLabel))),
    );
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    Detection detection,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasOcr = detection.ocrText != null && detection.ocrText!.isNotEmpty;
    // Consent hanya relevan bila ada teks hasil pengenalan yang bisa memuat
    // informasi pribadi. Menolak consent = bagikan tanpa kutipan OCR.
    var includeOcr = false;
    if (hasOcr) {
      includeOcr = await ConsentSheet.show(
        context,
        title: l10n.sharingConsentTitle,
        message: l10n.sharingConsentBody,
        acceptLabel: l10n.sharingAction,
      );
      if (!context.mounted) return;
    }

    final report = buildShareReport(
      detection,
      title: l10n.sharingShareText,
      lines: [
        detection.displayLabel,
        RelativeTime.format(detection.createdAt, DateTime.now(), l10n: l10n),
        switch (detection.validationStatus) {
          ValidationStatus.pending => l10n.statusPending,
          ValidationStatus.match => l10n.statusMatch,
          ValidationStatus.mismatch => l10n.statusMismatch,
        },
        if (detection.confidence != null)
          l10n.historyConfidenceValue(
            NumberFormatId.percentWithSign(detection.confidence! * 100),
          ),
        if (detection.distanceCm != null)
          l10n.historyDistanceValue(detection.distanceCm!),
      ],
      includeOcrText: includeOcr,
    );
    try {
      await ref.read(shareReportProvider).call(report);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.historyActionFailed)));
      }
    }
  }
}

/// Skeleton detail saat dokumen sedang dimuat dari stream.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceSm,
        DesignTokens.spacePage,
        DesignTokens.spaceSection,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton.card(),
          SizedBox(height: DesignTokens.spaceSm),
          Skeleton.card(),
          SizedBox(height: DesignTokens.spaceSm),
          Skeleton.card(),
        ],
      ),
    );
  }
}

/// Pesan error siap tampil untuk widget mana pun di file ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}

/// Gambar besar dengan Hero; panel informatif bila tanpa gambar.
class _DetailImage extends ConsumerWidget {
  const _DetailImage({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final id = detection.thumbnailId;

    Widget panel() {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacePage),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        ),
        child: Row(
          children: [
            Icon(
              detection.type == DetectionType.money
                  ? Icons.payments_rounded
                  : Icons.document_scanner_rounded,
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

    if (id == null || id.isEmpty) return panel();

    final async = ref.watch(
      thumbnailProvider(
        ThumbnailQuery(deviceId: detection.deviceId, thumbnailId: id),
      ),
    );
    return async.when(
      loading: () => AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  DesignTokens.radiusThumbnail,
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => panel(),
      data: (thumbnail) {
        final bytes = thumbnail?.imageBytes;
        if (bytes == null || bytes.isEmpty) return panel();
        return Hero(
          tag: 'detection-${detection.id}',
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
              child: Container(
                color: colorScheme.surfaceContainerHigh,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  semanticLabel: l10n.historyRecognitionResult,
                  errorBuilder: (context, _, _) => Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                    semanticLabel: l10n.historyRecognitionResult,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                  ).showSnackBar(SnackBar(content: Text(l10n.historyCopied)));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: l10n.historyCopyAction,
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
///
/// Semua aksi menulis lewat repository validasi (hanya tiga field validasi),
/// lalu kembali ke layar sebelumnya setelah berhasil.
class _ValidationActions extends ConsumerWidget {
  const _ValidationActions({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusColors = StatusColors.of(context);

    if (detection.validationStatus != ValidationStatus.pending) {
      return OutlinedButton.icon(
        onPressed: () => _undo(context, ref),
        icon: const Icon(Icons.undo_rounded),
        label: Text(l10n.validationUndo),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _submit(context, ref, ValidationStatus.mismatch),
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.validationMarkMismatch),
            style: OutlinedButton.styleFrom(
              foregroundColor: statusColors.bad.solid,
              side: BorderSide(color: statusColors.bad.solid),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _submit(context, ref, ValidationStatus.match),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.validationMarkMatch),
            // Sama seperti Validasi (ui_spec §5.2): "Cocok" memakai `ok`,
            // bukan primary — berpasangan dengan "Tidak cocok" warna `bad`.
            style: FilledButton.styleFrom(
              backgroundColor: statusColors.ok.solid,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ValidationStatus status,
  ) async {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(submitValidationProvider)
          .call(
            deviceId: detection.deviceId,
            detectionId: detection.id,
            status: status,
            validatedBy: ref.read(currentUserProvider)?.uid,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.validationSaveFailed)));
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(undoValidationProvider)
          .call(
            deviceId: detection.deviceId,
            detectionId: detection.id,
            validatedBy: ref.read(currentUserProvider)?.uid,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.validationUndoFailed)));
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
