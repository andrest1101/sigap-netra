import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/settings_gear_button.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/thumbnail_tile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../sharing/domain/entities/share_report.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../providers/history_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceId = ref.watch(primaryDeviceIdProvider);
    final page = deviceId == null
        ? null
        : ref.watch(
            historyPageProvider(
              HistoryPageKey(deviceId: deviceId, type: _type, status: _status),
            ),
          );
    final items = page?.value?.items ?? const <Detection>[];
    final hasMore = page?.value?.nextCursor != null;
    final hasError = page != null && page.hasError && !page.hasValue;
    final isLoadingFirstPage = page != null && page.isLoading && !page.hasValue;

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
          else if (deviceId == null)
            EmptyView(
              title: l10n.historyEmptyTitle,
              message: l10n.historyEmptyBody,
              icon: Icons.history_toggle_off_rounded,
            )
          else if (hasError)
            ErrorView(
              message: _failureText(context, page.error!),
              onRetry: () => ref.invalidate(historyPageProvider),
            )
          else if (isLoadingFirstPage)
            const _HistorySkeleton()
          else
            _HistoryList(
              items: items,
              type: _type,
              hasMore: hasMore,
              onLoadMore: () =>
                  ref.read(historyLimitProvider.notifier).increase(),
              onTypeChanged: (value) {
                setState(() => _type = value);
                ref.read(historyLimitProvider.notifier).reset();
              },
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
        await _resetAllValidations(l10n);
      case 'csv':
        _snack(l10n.historyExportComingSoon);
      case 'share':
        await _shareSummary(l10n);
    }
  }

  Future<void> _resetAllValidations(AppLocalizations l10n) async {
    final confirmed = await ConfirmSheet.show(
      context,
      title: l10n.validationResetAllConfirmTitle,
      message: l10n.validationResetAllConfirmBody,
      confirmLabel: l10n.validationResetAll,
      icon: Icons.restart_alt_rounded,
    );
    if (!confirmed || !mounted) return;
    final deviceId = ref.read(primaryDeviceIdProvider);
    if (deviceId == null) return;
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(resetAllValidationsProvider)
          .call(
            deviceId: deviceId,
            validatedBy: ref.read(currentUserProvider)?.uid,
          );
      ref.invalidate(historyPageProvider);
    } catch (_) {
      if (mounted) _snack(l10n.historyActionFailed);
      return;
    }
    if (mounted) _snack(l10n.historyResetDone);
  }

  /// Membagikan ringkasan baris yang sedang dimuat — angka saja, tanpa OCR,
  /// tanpa ID perangkat, tanpa lokasi.
  Future<void> _shareSummary(AppLocalizations l10n) async {
    final deviceId = ref.read(primaryDeviceIdProvider);
    if (deviceId == null) return;
    final key = HistoryPageKey(
      deviceId: deviceId,
      type: _type,
      status: _status,
    );
    final items =
        ref.read(historyPageProvider(key)).value?.items ?? const <Detection>[];
    if (items.isEmpty) {
      _snack(l10n.sharingEmpty);
      return;
    }

    final money = items.where((d) => d.type == DetectionType.money).length;
    final text = items.length - money;
    final matched = items
        .where((d) => d.validationStatus == ValidationStatus.match)
        .length;
    final mismatch = items
        .where((d) => d.validationStatus == ValidationStatus.mismatch)
        .length;
    final decided = matched + mismatch;
    final accuracyText = decided == 0
        ? null
        : '${((matched / decided) * 100).round()}%';

    final report = ShareReport(
      title: l10n.sharingSummaryTitle,
      lines: [
        l10n.sharingSummaryTotal(items.length),
        l10n.sharingSummaryBreakdown(money, text),
        if (accuracyText != null)
          l10n.sharingSummaryAccuracy(accuracyText, decided),
      ],
    );
    try {
      await ref.read(shareReportProvider).call(report);
    } catch (_) {
      if (mounted) _snack(l10n.historyActionFailed);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    if (mounted) {
      setState(() => _status = selected);
      ref.read(historyLimitProvider.notifier).reset();
    }
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
    required this.hasMore,
    required this.onLoadMore,
    required this.onTypeChanged,
    required this.onFilterPressed,
  });

  final List<Detection> items;
  final DetectionType? type;
  final bool hasMore;
  final VoidCallback onLoadMore;
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
          _DayGroupedList(
            items: items,
            hasMore: hasMore,
            onLoadMore: onLoadMore,
          ),
        const SizedBox(height: DesignTokens.spaceSection),
      ],
    );
  }
}

/// Daftar dikelompokkan per hari dengan header lengket.
class _DayGroupedList extends ConsumerWidget {
  const _DayGroupedList({
    required this.items,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<Detection> items;
  final bool hasMore;
  final VoidCallback onLoadMore;

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
              onDelete: () => _delete(context, ref, entry.value[i]),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spacePage),
          child: hasMore
              ? Center(
                  child: OutlinedButton.icon(
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(l10n.historyLoadMore),
                  ),
                )
              : Text(
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

  /// Hapus permanen setelah konfirmasi: dokumen deteksi + `media` terkait.
  ///
  /// Tidak ada undo — Firestore tidak menyediakan pemulihan dokumen, dan app
  /// dilarang membuat ulang dokumen deteksi (skema bagian 1). Karena itu
  /// konfirmasi muncul sebelum penghapusan, bukan sesudah.
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
    try {
      await ref
          .read(deleteDetectionProvider)
          .call(
            deviceId: detection.deviceId,
            detectionId: detection.id,
            thumbnailId: detection.thumbnailId,
          );
      ref.invalidate(historyPageProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.historyDeleted)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.historyActionFailed)));
      }
    }
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

/// Skeleton daftar riwayat saat halaman pertama masih dimuat.
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
        DesignTokens.spacePage,
        0,
      ),
      child: Column(
        children: [
          Skeleton.card(),
          SizedBox(height: DesignTokens.spaceSm),
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
