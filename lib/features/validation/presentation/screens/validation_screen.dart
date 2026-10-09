import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/thumbnail_tile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';

/// Antrean validasi — identitas visual v3.
///
/// App bar large-title + progres "1 dari N" + SegmentedButton
/// Gabungan/Uang/Menu-Teks. Kartu teratas + dua kartu samar di belakang,
/// aksi bawah Tidak cocok (outlined bad) / Cocok (filled ok), snackbar
/// Urungkan 5 detik. Tombol selalu ada sebagai pasangan aksi geser.
enum _ValidationFilter { all, money, text }

class ValidationScreen extends ConsumerStatefulWidget {
  const ValidationScreen({super.key});

  @override
  ConsumerState<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends ConsumerState<ValidationScreen> {
  _ValidationFilter _filter = _ValidationFilter.all;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(pendingDetectionsProvider);
    final filtered = _applyFilter(pending);
    final clamped = filtered.isEmpty ? 0 : _index.clamp(0, filtered.length - 1);

    return LargeTitleScaffold(
      title: l10n.validationTitle,
      subtitle: filtered.isEmpty
          ? null
          : l10n.validationProgressValue(clamped + 1, filtered.length),
      // Body memakai `Expanded` (tumpukan kartu mengisi sisa layar), jadi
      // wajib `fillRemaining` agar constraint vertikal terbatas.
      fillRemaining: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceSm,
              DesignTokens.spacePage,
              0,
            ),
            child: _FilterSegmented(
              filter: _filter,
              onChanged: (value) => setState(() {
                _filter = value;
                _index = 0;
              }),
            ),
          ),
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacePage,
                DesignTokens.spaceMd,
                DesignTokens.spacePage,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusBadge),
                child: LinearProgressIndicator(
                  value: (clamped + 1) / filtered.length,
                  minHeight: 6,
                ),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyQueue(l10n: l10n)
                : _ValidationStack(
                    key: ValueKey('${_filter.name}-$clamped'),
                    detection: filtered[clamped],
                    queueBehind: filtered.skip(clamped + 1).take(2).toList(),
                    onMatch: () =>
                        _decide(filtered[clamped], ValidationStatus.match),
                    onMismatch: () =>
                        _decide(filtered[clamped], ValidationStatus.mismatch),
                  ),
          ),
        ],
      ),
    );
  }

  List<Detection> _applyFilter(List<Detection> pending) {
    switch (_filter) {
      case _ValidationFilter.all:
        return pending;
      case _ValidationFilter.money:
        return pending
            .where((d) => d.type == DetectionType.money)
            .toList(growable: false);
      case _ValidationFilter.text:
        return pending
            .where((d) => d.type == DetectionType.text)
            .toList(growable: false);
    }
  }

  void _decide(Detection detection, ValidationStatus status) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    ref
        .read(detectionsProvider.notifier)
        .markValidated(
          id: detection.id,
          status: status,
          validatedBy: ref.read(currentUserProvider)?.uid,
        );
    setState(() {});
    showUndoSnackbar(
      context,
      message: l10n.validationSaved,
      actionLabel: l10n.validationUndoAction,
      onUndo: () {
        ref.read(detectionsProvider.notifier).reset(detection.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.validationUndoDone)));
        }
      },
    );
  }
}

class _FilterSegmented extends StatelessWidget {
  const _FilterSegmented({required this.filter, required this.onChanged});

  final _ValidationFilter filter;
  final ValueChanged<_ValidationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<_ValidationFilter>(
      segments: [
        ButtonSegment(
          value: _ValidationFilter.all,
          label: Text(l10n.validationFilterAll),
        ),
        ButtonSegment(
          value: _ValidationFilter.money,
          label: Text(l10n.validationFilterMoney),
        ),
        ButtonSegment(
          value: _ValidationFilter.text,
          label: Text(l10n.validationFilterText),
        ),
      ],
      selected: {filter},
      onSelectionChanged: (selected) => onChanged(selected.single),
      showSelectedIcon: false,
      style: const ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    );
  }
}

/// Tumpukan kartu validasi: kartu teratas interaktif + dua samar di belakang.
class _ValidationStack extends StatelessWidget {
  const _ValidationStack({
    required this.detection,
    required this.queueBehind,
    required this.onMatch,
    required this.onMismatch,
    super.key,
  });

  final Detection detection;
  final List<Detection> queueBehind;
  final VoidCallback onMatch;
  final VoidCallback onMismatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey('swipe-${detection.id}'),
      direction: DismissDirection.horizontal,
      background: _SwipeHint(
        alignment: Alignment.centerLeft,
        icon: Icons.close_rounded,
        label: l10n.validationMarkMismatch,
      ),
      secondaryBackground: _SwipeHint(
        alignment: Alignment.centerRight,
        icon: Icons.check_rounded,
        label: l10n.validationMarkMatch,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMismatch();
        } else {
          onMatch();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceMd,
              DesignTokens.spacePage,
              DesignTokens.spacePage,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - DesignTokens.spacePage * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      // Dua kartu samar di belakang.
                      for (var i = queueBehind.length - 1; i >= 0; i--)
                        Positioned.fill(
                          top: 12.0 * (i + 1),
                          child: Opacity(
                            opacity: 0.35 - 0.12 * i,
                            child: _GhostCard(detection: queueBehind[i]),
                          ),
                        ),
                      _ValidationCard(detection: detection),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: DesignTokens.spaceSection,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onMismatch,
                            icon: const Icon(Icons.close_rounded),
                            label: Text(l10n.validationMarkMismatch),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceMd),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onMatch,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(l10n.validationMarkMatch),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.alignment,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceSection,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: DesignTokens.spaceSm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: const SizedBox(height: 120),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMoney = detection.type == DetectionType.money;

    return Semantics(
      label: '${detection.displayLabel}, ${l10n.statusPending}',
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardImage(detection: detection),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusChip(
                        label: isMoney
                            ? l10n.validationFilterMoney
                            : l10n.validationFilterText,
                        tone: AppStatusTone.info,
                        icon: isMoney
                            ? Icons.payments_rounded
                            : Icons.document_scanner_rounded,
                        isDense: true,
                      ),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: Text(
                          detection.deviceName,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Text(
                    l10n.validationReadAs,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    detection.displayLabel,
                    style: textTheme.headlineSmall?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Wrap(
                    spacing: DesignTokens.spaceSm,
                    runSpacing: DesignTokens.spaceSm,
                    children: [
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Area gambar 4:3, atau panel informatif bila gambar tidak diunggah.
class _CardImage extends StatelessWidget {
  const _CardImage({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasImage = detection.thumbnailId != null;

    if (!hasImage) {
      return Container(
        color: colorScheme.surfaceContainerHigh,
        padding: const EdgeInsets.all(DesignTokens.spacePage),
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
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    l10n.validationNoImageBody,
                    style: textTheme.bodySmall?.copyWith(
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

    // Thumbnail dimuat di Fase 2 lanjutan (media lookup per thumbnailId);
    // untuk presentasi tampilkan placeholder rasio 4:3 yang rapi.
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: colorScheme.surfaceContainerHigh,
        child: Center(
          child: ThumbnailTile.unavailable(
            semanticsLabel: l10n.validationNoImage,
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: l10n.validationAllDoneTitle,
      message: l10n.validationAllDoneBody,
      icon: Icons.task_alt_rounded,
      action: FilledButton.tonalIcon(
        onPressed: () => const HistoryPath().go(context),
        icon: const Icon(Icons.history_rounded),
        label: Text(l10n.validationGoHistory),
      ),
    );
  }
}
