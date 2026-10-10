import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/settings_gear_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/thumbnail_tile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';

/// Riwayat — identitas visual v3.
///
/// Segmen Daftar | Statistik. Daftar: chip kategori + sheet filter status,
/// dikelompokkan per hari (header lengket), baris thumbnail 56/radius 14,
/// geser-hapus + Urungkan 5 dtk, menu ⋯ (Reset…, Ekspor CSV, Bagikan).
enum _HistoryTab { list, stats }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryTab _tab = _HistoryTab.list;
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

    return LargeTitleScaffold(
      title: l10n.historyTitle,
      subtitle: '${l10n.historySummaryTitle} · ${items.length}',
      actions: [
        const SettingsGearButton(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) => _onMenu(value),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'reset', child: Text(l10n.historyResetMenu)),
            PopupMenuItem(value: 'csv', child: Text(l10n.historyExportCsv)),
            PopupMenuItem(
              value: 'share',
              child: Text(l10n.historyShareSummary),
            ),
          ],
        ),
      ],
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
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_HistoryTab>(
                segments: [
                  ButtonSegment(
                    value: _HistoryTab.list,
                    label: Text(l10n.historyListTab),
                    icon: const Icon(Icons.list_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: _HistoryTab.stats,
                    label: Text(l10n.historyStatsTab),
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selected) =>
                    setState(() => _tab = selected.single),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  shape: WidgetStatePropertyAll(StadiumBorder()),
                ),
              ),
            ),
          ),
          if (_tab == _HistoryTab.stats)
            _StatsComingSoon(l10n: l10n)
          else
            _HistoryList(
              items: items,
              type: _type,
              onTypeChanged: (value) => setState(() => _type = value),
              onFilterPressed: () => _openStatusSheet(),
            ),
        ],
      ),
    );
  }

  Future<void> _onMenu(String value) async {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'reset':
        final confirmed = await ConfirmSheet.show(
          context,
          title: l10n.validationResetAllConfirmTitle,
          message: l10n.validationResetAllConfirmBody,
          confirmLabel: l10n.validationResetAll,
          icon: Icons.restart_alt_rounded,
        );
        if (confirmed && mounted) {
          HapticFeedback.mediumImpact();
          final detections = ref.read(detectionsProvider);
          for (final d in detections) {
            ref.read(detectionsProvider.notifier).reset(d.id);
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.validationUndoDone)));
          }
        }
      case 'csv':
      case 'share':
        if (mounted) {
          final message = value == 'csv'
              ? l10n.historyExportComingSoon
              : l10n.sharingEmpty;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
    }
  }

  Future<void> _openStatusSheet() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<ValidationStatus?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.historyFilterAll),
              leading: _status == null
                  ? const Icon(Icons.check_rounded)
                  : const SizedBox(width: 24),
              onTap: () => Navigator.of(context).pop(null),
            ),
            for (final status in ValidationStatus.values)
              ListTile(
                title: Text(_statusLabel(status, l10n)),
                leading: _status == status
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
                onTap: () => Navigator.of(context).pop(status),
              ),
            const SizedBox(height: DesignTokens.spaceSm),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _status = selected);
  }
}

String _statusLabel(ValidationStatus status, AppLocalizations l10n) {
  return switch (status) {
    ValidationStatus.pending => l10n.historyFilterPending,
    ValidationStatus.match => l10n.historyFilterMatch,
    ValidationStatus.mismatch => l10n.historyFilterMismatch,
  };
}

/// Daftar riwayat: chip kategori + tombol filter + grup per hari.
class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.items,
    required this.type,
    required this.onTypeChanged,
    required this.onFilterPressed,
  });

  final List<Detection> items;
  final DetectionType? type;
  final ValueChanged<DetectionType?> onTypeChanged;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacePage,
            DesignTokens.spaceMd,
            DesignTokens.spacePage,
            0,
          ),
          child: Wrap(
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceSm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l10n.historyFilterAll),
                selected: type == null,
                onSelected: (_) => onTypeChanged(null),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.payments_rounded, size: 16),
                label: Text(l10n.historyTypeMoney),
                selected: type == DetectionType.money,
                onSelected: (_) => onTypeChanged(DetectionType.money),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.document_scanner_rounded, size: 16),
                label: Text(l10n.historyTypeText),
                selected: type == DetectionType.text,
                onSelected: (_) => onTypeChanged(DetectionType.text),
              ),
              ActionChip(
                avatar: const Icon(Icons.tune_rounded, size: 16),
                label: Text(l10n.commonFilter),
                onPressed: onFilterPressed,
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          EmptyView(
            title: l10n.historyEmptyTitle,
            message: l10n.historyEmptyBody,
            icon: Icons.history_toggle_off_rounded,
          )
        else
          _DayGroupedList(items: items),
        const SizedBox(height: DesignTokens.spaceSection),
      ],
    );
  }
}

/// Daftar dikelompokkan per hari dengan header lengket.
class _DayGroupedList extends ConsumerWidget {
  const _DayGroupedList({required this.items});

  final List<Detection> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = _groupByDay(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          _DayHeader(label: _dayLabel(entry.key, l10n)),
          for (var i = 0; i < entry.value.length; i++)
            _HistoryRow(
              detection: entry.value[i],
              number: items.indexOf(entry.value[i]) + 1,
              onDelete: () => _deleteWithUndo(context, ref, entry.value[i]),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spacePage),
          child: Text(
            l10n.historyEndOfList,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Map<DateTime, List<Detection>> _groupByDay(List<Detection> items) {
    final groups = <DateTime, List<Detection>>{};
    for (final item in items) {
      final day = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      groups.putIfAbsent(day, () => []).add(item);
    }
    return groups;
  }

  String _dayLabel(DateTime day, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return l10n.historyToday;
    if (day == today.subtract(const Duration(days: 1))) {
      return l10n.historyYesterday;
    }
    return RelativeTime.date(day);
  }

  void _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    Detection detection,
  ) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(detectionsProvider.notifier);
    // Simpan salinan untuk undo: controller demo tidak punya hapus permanen,
    // jadi undo = kembalikan item (Fase 2 lanjutan memakai DeleteDetection).
    controller.removeForUndo(detection.id);
    showUndoSnackbar(
      context,
      message: l10n.historyDeleted,
      actionLabel: l10n.validationUndoAction,
      onUndo: () => controller.restoreForUndo(detection),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceLg,
        DesignTokens.spacePage,
        DesignTokens.spaceSm,
      ),
      child: Semantics(
        header: true,
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.detection,
    required this.number,
    required this.onDelete,
  });

  final Detection detection;
  final int number;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('history-${detection.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.spacePage),
        color: colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: () => context.push('/riwayat/${detection.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
            vertical: DesignTokens.spaceSm,
          ),
          child: Row(
            children: [
              detection.thumbnailId == null
                  ? ThumbnailTile.unavailable(
                      semanticsLabel: l10n.validationNoImage,
                    )
                  : ThumbnailTile.unavailable(
                      semanticsLabel:
                          '${detection.displayLabel}, ${RelativeTime.format(detection.createdAt, DateTime.now(), l10n: l10n)}',
                    ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detection.displayLabel,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${l10n.historyReadNumber(number)} · ${detection.confidence == null ? '–' : l10n.historyConfidenceValue(NumberFormatId.percentWithSign(detection.confidence! * 100))}${detection.distanceCm == null ? '' : ' · ${l10n.historyDistanceValue(detection.distanceCm!)}'}',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSm),
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
                isDense: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmen Statistik (P1): placeholder rapi, bukan layar kosong.
class _StatsComingSoon extends StatelessWidget {
  const _StatsComingSoon({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
        DesignTokens.spacePage,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceSection),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              l10n.historyStatsComingSoonTitle,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              l10n.historyStatsComingSoonBody,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
