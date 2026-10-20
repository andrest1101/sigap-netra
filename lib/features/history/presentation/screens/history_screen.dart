import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
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
import '../../../../core/widgets/thumbnail_tile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../../media/presentation/providers/media_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../sharing/domain/entities/share_report.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/detection_filter.dart';
import '../../domain/usecases/build_detections_csv.dart';
import '../providers/history_providers.dart';
import '../widgets/history_stats_view.dart';

/// Riwayat — identitas visual v3.
///
/// Segmen **Daftar | Statistik**:
/// - Daftar: chip kategori + sheet filter status, grup per hari dengan
///   ringkasan jenis bacaan, baris thumbnail 48/radius 14 dengan pil
///   keyakinan & jarak, geser-hapus + konfirmasi, menu ⋯ (Reset…, Ekspor CSV,
///   Bagikan).
/// - Statistik: agregat jendela 7 hari/4 minggu dari `count()` server —
///   ring akurasi, grafik batang per hari/minggu, komposisi jenis & status
///   validasi (lihat `HistoryStatsView`).
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
    final id = deviceId;
    final pageKey = id == null
        ? null
        : HistoryPageKey(deviceId: id, type: _type, status: _status);
    final page = pageKey == null
        ? null
        : ref.watch(historyPageProvider(pageKey));
    final items = page?.value?.items ?? const <Detection>[];
    final hasMore = page?.value?.nextCursor != null;
    final hasError = page != null && page.hasError && !page.hasValue;
    final isLoadingFirstPage = page != null && page.isLoading && !page.hasValue;
    // Subjudul jujur: jumlah yang benar-benar dimuat, bukan total database.
    // Tanpa "+" pengguna mengira "6 pembacaan tersimpan" = seluruh database
    // padahal masih ada halaman berikut (bug klaim diam-diam).
    final subtitle = deviceId == null
        ? null
        : hasMore
        ? l10n.historyStoredCountMore(items.length)
        : l10n.historyStoredCount(items.length);

    return LargeTitleScaffold(
      title: l10n.historyTitle,
      subtitle: subtitle,
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
          if (deviceId == null)
            EmptyView(
              title: l10n.historyNoDeviceTitle,
              message: l10n.historyNoDeviceBody,
              icon: Icons.link_off_rounded,
              action: FilledButton.tonalIcon(
                onPressed: () => const DevicesPath().go(context),
                icon: const Icon(Icons.devices_other_rounded),
                label: Text(l10n.historyNoDeviceAction),
              ),
            )
          else if (_tab == _HistoryTab.stats)
            HistoryStatsView(deviceId: deviceId)
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
              status: _status,
              hasMore: hasMore,
              // Cabang deviceId null sudah kembali via EmptyView di atas,
              // jadi pageKey di sini selalu non-null.
              // ignore: cast_nullable_to_non_nullable
              pageKey: pageKey as HistoryPageKey,
              onLoadMore: () =>
                  ref.read(historyLimitProvider.notifier).increase(),
              onTypeChanged: (value) {
                setState(() => _type = value);
                ref.read(historyLimitProvider.notifier).reset();
              },
              onFilterPressed: () => _openStatusSheet(),
              onClearFilters: () {
                setState(() {
                  _type = null;
                  _status = null;
                });
                ref.read(historyLimitProvider.notifier).reset();
              },
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
        await _exportCsv(l10n);
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
      // Angka panel Statistik ikut berubah setelah reset (semua validasi
      // kembali "Menunggu") — tanpa ini panel menunjukkan angka lama.
      ref.invalidate(historyInsightsProvider);
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

  /// Ekspor CSV: consent dulu, satu query maksimal [kDetectionCsvMaxRows]
  /// baris sesuai filter aktif, tulis berkas sementara, lalu buka share sheet.
  ///
  /// Tidak ada apa pun yang diunggah ke cloud: berkas dibuat di perangkat
  /// pengguna dan hanya pengguna yang menentukan tujuannya. Bila masih ada
  /// baris di luar batas, pengguna diberi tahu hasilnya terpotong.
  Future<void> _exportCsv(AppLocalizations l10n) async {
    final consented = await ConsentSheet.show(
      context,
      title: l10n.historyExportConsentTitle,
      message: l10n.historyExportConsentBody,
      acceptLabel: l10n.historyExportConsentAccept,
    );
    if (!consented || !mounted) return;
    final deviceId = ref.read(primaryDeviceIdProvider);
    if (deviceId == null) return;
    _snack(l10n.historyExportPreparing);
    try {
      final page = await ref
          .read(getDetectionsPageProvider)
          .call(
            filter: DetectionFilter(
              deviceId: deviceId,
              type: _type,
              status: _status,
            ),
            limit: kDetectionCsvMaxRows,
          );
      if (!mounted) return;
      if (page.items.isEmpty) {
        _snack(l10n.historyExportEmpty);
        return;
      }
      await ref
          .read(shareCsvProvider)
          .call(
            content: buildDetectionsCsv(page.items),
            fileName:
                'sigap-netra-riwayat-'
                '${_csvFileNameFormat.format(DateTime.now())}.csv',
          );
      // Diberitahukan setelah share sheet ditutup: selama sheet terbuka
      // snackbar tidak terlihat, jadi jangan menumpuk pesan di belakangnya.
      if (page.nextCursor != null) {
        _snack(l10n.historyExportTruncated(kDetectionCsvMaxRows));
      }
    } catch (_) {
      if (mounted) _snack(l10n.historyExportFailed);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    // Satu pesan pada satu waktu: pesan lama disembunyikan supaya pesan baru
    // (mis. hasil ekspor) tidak mengantre di belakangnya.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openStatusSheet() async {
    final l10n = AppLocalizations.of(context);
    // "Semua" vs tutup-sheet (swipe/batal) keduanya null bila memakai
    // `ValidationStatus?` langsung — filter aktif ikut ter-reset diam-diam
    // saat pengguna hanya menutup sheet. Marker khusus membedakannya:
    // null = dibatalkan (filter dipertahankan), marker = reset ke Semua.
    final selected = await showModalBottomSheet<Object?>(
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
              onTap: () => Navigator.of(context).pop(_kAllStatusFilter),
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
    if (!mounted || selected == null) return;
    setState(
      () => _status = selected == _kAllStatusFilter
          ? null
          : selected as ValidationStatus,
    );
    ref.read(historyLimitProvider.notifier).reset();
  }
}

/// Marker "Semua" untuk sheet filter status (lihat [_HistoryScreenState]).
const Object _kAllStatusFilter = Object();

/// Jam baris riwayat ("14.32") — 24 jam gaya Indonesia, tanpa AM/PM.
final DateFormat _rowTimeFormat = DateFormat('HH.mm');

/// Cap waktu nama berkas ekspor CSV ("20261018-143005"), waktu lokal.
final DateFormat _csvFileNameFormat = DateFormat('yyyyMMdd-HHmmss');

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
    required this.status,
    required this.hasMore,
    required this.pageKey,
    required this.onLoadMore,
    required this.onTypeChanged,
    required this.onFilterPressed,
    required this.onClearFilters,
  });

  final List<Detection> items;
  final DetectionType? type;
  final ValidationStatus? status;
  final bool hasMore;

  /// Kunci halaman yang sedang tampil — dipakai invalidate tepat setelah
  /// hapus/reset. Tanpa kunci, `ref.invalidate(historyPageProvider)` tanpa
  /// argumen tidak menyentuh instance family yang tampil sehingga baris yang
  /// dihapus tetap terlihat (bug basi).
  final HistoryPageKey pageKey;
  final VoidCallback onLoadMore;
  final ValueChanged<DetectionType?> onTypeChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onClearFilters;

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
          // Jujur seperti Validasi: filter aktif yang kosong bukan berarti
          // "belum ada pembacaan sama sekali" — beri jalan keluar satu ketuk.
          if (type != null || status != null)
            EmptyView(
              title: l10n.historyFilterEmptyTitle,
              message: l10n.historyFilterEmptyBody,
              icon: Icons.filter_alt_off_rounded,
              action: FilledButton.tonalIcon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.visibility_rounded),
                label: Text(l10n.historyFilterShowAll),
              ),
            )
          else
            EmptyView(
              title: l10n.historyEmptyTitle,
              message: l10n.historyEmptyBody,
              icon: Icons.history_toggle_off_rounded,
            )
        else
          _DayGroupedList(
            items: items,
            hasMore: hasMore,
            pageKey: pageKey,
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
    required this.pageKey,
    required this.onLoadMore,
  });

  final List<Detection> items;
  final bool hasMore;
  final HistoryPageKey pageKey;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = _groupByDay(items);
    // Nomor urut global (bukan per hari): cocok dengan subjudul "#N".
    var number = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          _DayHeader(
            // Kunci per tanggal: elemen dipakai ulang dengan tepat saat "Muat
            // lagi" menambah baris ke grup hari yang sudah tampil.
            key: ValueKey('day-${groups[i].day.toIso8601String()}'),
            label: _dayLabel(groups[i].day, l10n),
            count: groups[i].items.length,
            money: groups[i].money,
            text: groups[i].text,
            // Grup terakhir terpotong bila masih ada halaman berikutnya:
            // jumlahnya "sekurangnya N" — ditandai "+" dan rincian jenis
            // disembunyikan supaya tidak mengklaim angka yang belum dimuat.
            partial: hasMore && i == groups.length - 1,
          ),
          for (final detection in groups[i].items)
            _HistoryRow(
              detection: detection,
              number: ++number,
              onDelete: () => _delete(context, ref, detection),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spacePage),
          child: hasMore
              ? Center(
                  child: FilledButton.tonalIcon(
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

  List<_DayGroup> _groupByDay(List<Detection> items) {
    final groups = <DateTime, List<Detection>>{};
    for (final item in items) {
      final day = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      groups.putIfAbsent(day, () => []).add(item);
    }
    return [
      for (final entry in groups.entries) _DayGroup(entry.key, entry.value),
    ];
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
  /// konfirmasi muncul sebelum penghapusan, bukan sesudah. Sukses memakai
  /// snackbar berlabel jelas (nama pembacaan ikut disebut), bukan dialog —
  /// dialog sukses akan menambah ketukan sia-sia setelah konfirmasi.
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
    try {
      await ref
          .read(deleteDetectionProvider)
          .call(
            deviceId: detection.deviceId,
            detectionId: detection.id,
            thumbnailId: detection.thumbnailId,
          );
      // Invalidate instance halaman yang tampil + thumbnail yang dihapus:
      // tanpa kunci family yang tepat, FutureProvider basi tetap dipakai dan
      // baris yang dihapus masih terlihat meski snackbar sudah muncul.
      ref.invalidate(historyPageProvider(pageKey));
      // Jumlah per hari/minggu di panel Statistik juga berkurang satu.
      ref.invalidate(historyInsightsProvider);
      final thumb = detection.thumbnailId;
      if (thumb != null && thumb.isNotEmpty) {
        ref.invalidate(
          thumbnailProvider(
            ThumbnailQuery(deviceId: detection.deviceId, thumbnailId: thumb),
          ),
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.historyDeletedNamed(detection.displayLabel)),
          ),
        );
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

/// Satu grup hari pada daftar riwayat.
class _DayGroup {
  _DayGroup(this.day, this.items);

  final DateTime day;
  final List<Detection> items;

  int get money => items.where((d) => d.type == DetectionType.money).length;

  int get text => items.length - money;
}

/// Header grup hari: label hari + ringkasan bacaan hari itu.
///
/// Ringkasan hanya menyebut angka yang benar-benar dimuat. Grup terakhir yang
/// masih terpotong halaman berikutnya ditandai "+" dan rincian jenisnya
/// disembunyikan (`partial`) — jangan mengklaim total yang belum diambil.
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.count,
    required this.money,
    required this.text,
    required this.partial,
    super.key,
  });

  final String label;
  final int count;
  final int money;
  final int text;
  final bool partial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stat = partial
        ? l10n.historyDayStatMore(count)
        : l10n.historyDayStat(count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceLg,
        DesignTokens.spacePage,
        DesignTokens.spaceSm,
      ),
      child: Semantics(
        header: true,
        child: Row(
          // Kedua sisi fleksibel & bisa dipotong dengan elipsis: di layar
          // sempit label hari menang, ringkasan angka menyusut — tidak ada
          // yang meluber keluar kartu.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            Flexible(
              child: Text(
                partial ? stat : '$stat · ${l10n.historyDayTypes(money, text)}',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
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
    final statusColors = StatusColors.of(context);
    final tone = switch (detection.validationStatus) {
      ValidationStatus.pending => AppStatusTone.warn,
      ValidationStatus.match => AppStatusTone.ok,
      ValidationStatus.mismatch => AppStatusTone.bad,
    };
    // Pil keyakinan: angka pendek (±95%), makna lengkap ada di semantik.
    final confidenceValue = detection.confidence;
    final confidence = confidenceValue == null
        ? null
        : NumberFormatId.percentWithSign(confidenceValue * 100);

    return Dismissible(
      key: ValueKey('history-${detection.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.spacePage),
        color: statusColors.bad.container,
        child: Icon(
          Icons.delete_outline_rounded,
          color: statusColors.bad.content,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: () => HistoryDetailPath(detection.id).push(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
            vertical: DesignTokens.spaceSm,
          ),
          child: Row(
            children: [
              // Thumbnail 48: foto asli bila ada, ikon kategori bila tanpa
              // gambar (opt-in mati / belum diunggah). Titik status menempel
              // — pola yang sama dengan aktivitas Beranda.
              _RowThumb(detection: detection, tone: tone),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detection.displayLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Baris meta: nomor & jam sebagai teks tenang, lalu pil
                    // keyakinan, jarak, dan status validasi. Semua ditaruh di
                    // dalam satu `Wrap` (bukan chip status yang dipaku di
                    // kanan) supaya di layar 360 dp isinya turun ke run
                    // berikutnya dengan rapi — tidak ada yang terpotong.
                    Wrap(
                      spacing: DesignTokens.spaceSm,
                      runSpacing: DesignTokens.spaceXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${l10n.historyReadNumber(number)} · '
                          '${_rowTimeFormat.format(detection.createdAt)}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (confidence != null)
                          Semantics(
                            label: l10n.historyConfidenceValue(confidence),
                            excludeSemantics: true,
                            child: MetricChip(
                              icon: Icons.center_focus_strong_rounded,
                              label: confidence,
                              isDense: true,
                            ),
                          ),
                        if (detection.distanceCm != null)
                          MetricChip(
                            icon: Icons.straighten_rounded,
                            label: l10n.historyDistanceValue(
                              detection.distanceCm!,
                            ),
                            isDense: true,
                          ),
                        StatusChip(
                          label: switch (detection.validationStatus) {
                            ValidationStatus.pending => l10n.statusPending,
                            ValidationStatus.match => l10n.statusMatch,
                            ValidationStatus.mismatch => l10n.statusMismatch,
                          },
                          tone: tone,
                          isDense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceXs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail 48 baris riwayat: foto bila ada, ikon kategori bila tanpa gambar.
class _RowThumb extends ConsumerWidget {
  const _RowThumb({required this.detection, required this.tone});

  final Detection detection;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMoney = detection.type == DetectionType.money;
    final placeholderIcon = isMoney
        ? Icons.payments_rounded
        : Icons.document_scanner_rounded;
    final semantics =
        '${detection.displayLabel}, ${RelativeTime.format(detection.createdAt, DateTime.now(), l10n: l10n)}';
    final id = detection.thumbnailId;

    Widget thumb;
    if (id == null || id.isEmpty) {
      thumb = ThumbnailTile.unavailable(
        semanticsLabel: semantics,
        icon: placeholderIcon,
      );
    } else {
      final async = ref.watch(
        thumbnailProvider(
          ThumbnailQuery(deviceId: detection.deviceId, thumbnailId: id),
        ),
      );
      thumb = async.when(
        loading: () => const ThumbnailTile.loading(),
        error: (_, _) => ThumbnailTile.unavailable(
          semanticsLabel: semantics,
          icon: placeholderIcon,
        ),
        data: (thumbnail) {
          final bytes = thumbnail?.imageBytes;
          if (bytes == null || bytes.isEmpty) {
            return ThumbnailTile.unavailable(
              semanticsLabel: semantics,
              icon: placeholderIcon,
            );
          }
          return ThumbnailTile.image(
            imageBytes: bytes,
            semanticsLabel: semantics,
            heroTag: 'detection-${detection.id}',
          );
        },
      );
    }

    return Stack(
      children: [
        thumb,
        Positioned(
          right: 2,
          bottom: 2,
          child: ExcludeSemantics(child: StatusDot(tone: tone, size: 12)),
        ),
      ],
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
