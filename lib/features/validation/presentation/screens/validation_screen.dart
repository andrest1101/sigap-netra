import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../providers/validation_providers.dart';
import '../widgets/validation_photo.dart';

/// Antrean validasi — identitas visual v3.
///
/// App bar large-title + progres "1 dari N" + SegmentedButton
/// Gabungan/Uang/Menu-Teks. Kartu teratas + dua kartu samar di belakang
/// (terlihat sebagai tumpukan 12 px di bawah kartu utama), aksi bawah
/// Tidak cocok (outlined `bad`) / Cocok (filled `ok`) sesuai `ui_spec.md`
/// §5.2, snackbar Urungkan 5 detik. Tombol selalu ada sebagai pasangan aksi
/// geser. Pergantian kartu dianimasikan (fade + slide
/// [DesignTokens.animationMedium]), dan area antrean punya tiga empty state
/// jujur: belum ada perangkat, antrean habis, atau filter sedang kosong.
enum _ValidationFilter { all, money, text }

class ValidationScreen extends ConsumerStatefulWidget {
  const ValidationScreen({super.key});

  @override
  ConsumerState<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends ConsumerState<ValidationScreen> {
  _ValidationFilter _filter = _ValidationFilter.all;
  int _index = 0;
  bool _deciding = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceId = ref.watch(primaryDeviceIdProvider);
    final pendingAsync = deviceId == null
        ? AsyncData<List<Detection>>(const <Detection>[])
        : ref.watch(pendingDetectionsProvider(deviceId));
    final pending = pendingAsync.value ?? const <Detection>[];
    final filtered = _applyFilter(pending);
    final clamped = filtered.isEmpty ? 0 : _index.clamp(0, filtered.length - 1);
    // Urutan state: loading/error dulu (data belum pasti), lalu "belum ada
    // perangkat", baru antrean — supaya pesan "semua selesai" tidak pernah
    // muncul sebelum data termuat atau saat perangkat belum terhubung.
    final hasData = pendingAsync.hasValue;

    return LargeTitleScaffold(
      title: l10n.validationTitle,
      subtitle: !hasData || filtered.isEmpty
          ? null
          : l10n.validationProgressValue(clamped + 1, filtered.length),
      actions: const [SettingsGearButton()],
      // Body memakai `Expanded` (tumpukan kartu mengisi sisa layar), jadi
      // wajib `fillRemaining` agar constraint vertikal terbatas.
      fillRemaining: true,
      body: !hasData
          ? pendingAsync.hasError
                ? ErrorView(
                    message: _messageFor(context, pendingAsync.error!),
                    onRetry: () =>
                        ref.invalidate(pendingDetectionsProvider(deviceId!)),
                  )
                : const LoadingView()
          : deviceId == null
          ? _NoDeviceQueue(l10n: l10n)
          : Column(
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
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusBadge,
                      ),
                      child: LinearProgressIndicator(
                        value: (clamped + 1) / filtered.length,
                        minHeight: 6,
                      ),
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: DesignTokens.animationMedium,
                    switchInCurve: DesignTokens.motionCurve,
                    switchOutCurve: DesignTokens.motionCurve,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _buildQueue(
                      l10n: l10n,
                      pending: pending,
                      filtered: filtered,
                      clamped: clamped,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Isi area antrean: tumpukan kartu atau salah satu empty state. Semua
  /// cabang diberi key agar [AnimatedSwitcher] menganimasikan pergantian.
  Widget _buildQueue({
    required AppLocalizations l10n,
    required List<Detection> pending,
    required List<Detection> filtered,
    required int clamped,
  }) {
    if (filtered.isNotEmpty) {
      final detection = filtered[clamped];
      return _ValidationStack(
        key: ValueKey('stack-${_filter.name}-${detection.id}'),
        detection: detection,
        queueBehind: filtered.skip(clamped + 1).take(2).toList(),
        onMatch: () => _decide(detection, ValidationStatus.match),
        onMismatch: () => _decide(detection, ValidationStatus.mismatch),
      );
    }
    // Antrean benar-benar habis → ajakan melihat Riwayat.
    if (pending.isEmpty) {
      return _EmptyQueue(key: const ValueKey('empty-done'), l10n: l10n);
    }
    // Masih ada antrean, tapi tidak ada yang cocok dengan filter aktif.
    return _FilteredEmptyQueue(
      key: const ValueKey('empty-filtered'),
      l10n: l10n,
      waitingElsewhere: pending.length,
      onShowAll: () => setState(() {
        _filter = _ValidationFilter.all;
        _index = 0;
      }),
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

  Future<void> _decide(Detection detection, ValidationStatus status) async {
    // Guard ganda-tap: satu keputusan diproses sampai selesai sebelum yang
    // berikutnya, supaya tidak ada dua tulis untuk satu pembacaan.
    if (_deciding) return;
    _deciding = true;
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(currentUserProvider)?.uid;
    HapticFeedback.lightImpact();

    try {
      await ref
          .read(submitValidationProvider)
          .call(
            deviceId: detection.deviceId,
            detectionId: detection.id,
            status: status,
            validatedBy: uid,
          );
    } catch (_) {
      _deciding = false;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.validationSaveFailed)));
      }
      return;
    }
    _deciding = false;
    if (!mounted) return;

    showUndoSnackbar(
      context,
      message: l10n.validationSaved,
      actionLabel: l10n.validationUndoAction,
      onUndo: () async {
        try {
          await ref
              .read(undoValidationProvider)
              .call(
                deviceId: detection.deviceId,
                detectionId: detection.id,
                validatedBy: uid,
              );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.validationUndoFailed)));
          }
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.validationUndoDone)));
        }
      },
    );
  }

  String _messageFor(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is AppFailure) return failureMessage(error, l10n);
    return l10n.stateErrorBody;
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
    final statusColors = StatusColors.of(context);

    // Hanya area kartu yang di-Dismissible: saat digeser, tombol aksi dan
    // seluruh kerangka layar tetap diam — yang bergerak hanya tumpukan kartu.
    return LayoutBuilder(
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
                Dismissible(
                  key: ValueKey('swipe-${detection.id}'),
                  direction: DismissDirection.horizontal,
                  background: _SwipeHint(
                    alignment: Alignment.centerLeft,
                    icon: Icons.close_rounded,
                    label: l10n.validationMarkMismatch,
                    palette: statusColors.bad,
                  ),
                  secondaryBackground: _SwipeHint(
                    alignment: Alignment.centerRight,
                    icon: Icons.check_rounded,
                    label: l10n.validationMarkMatch,
                    palette: statusColors.ok,
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      onMismatch();
                    } else {
                      onMatch();
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      // Dua kartu samar di belakang: masing-masing terdorong
                      // 12 px ke bawah + menyempit, dan kartu depan diberi
                      // ruang bawah (Padding) supaya tepi kartu belakang
                      // benar-benar terlihat sebagai tumpukan — versi lama
                      // menaruhnya di belakang kartu opak sehingga tak
                      // pernah tampak.
                      for (var i = queueBehind.length - 1; i >= 0; i--)
                        Positioned(
                          top: 12.0 * (i + 1),
                          left: 12.0 * (i + 1),
                          right: 12.0 * (i + 1),
                          bottom: 12.0 * (queueBehind.length - 1 - i),
                          child: Opacity(
                            opacity: 0.85 - 0.3 * i,
                            child: const _GhostCard(),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 12.0 * queueBehind.length,
                        ),
                        child: _ValidationCard(detection: detection),
                      ),
                    ],
                  ),
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
                            foregroundColor: statusColors.bad.solid,
                            side: BorderSide(color: statusColors.bad.solid),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceMd),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onMatch,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l10n.validationMarkMatch),
                          // Spec §5.2: "Cocok" memakai warna status `ok`
                          // (bukan primary) agar berpasangan dengan
                          // "Tidak cocok" warna `bad`.
                          style: FilledButton.styleFrom(
                            backgroundColor: statusColors.ok.solid,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                          ),
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
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.palette,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final StatusPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceSection,
      ),
      decoration: BoxDecoration(
        color: palette.container,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: palette.content),
          const SizedBox(width: DesignTokens.spaceSm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: palette.content),
          ),
        ],
      ),
    );
  }
}

/// Kartu samar di belakang antrean — hanya tepinya yang terlihat.
class _GhostCard extends StatelessWidget {
  const _GhostCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
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
            ValidationPhoto(
              deviceId: detection.deviceId,
              thumbnailId: detection.thumbnailId,
              detectionId: detection.id,
              semanticsLabel: detection.displayLabel,
              onOpenDetail: () => HistoryDetailPath(detection.id).push(context),
            ),
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
                      letterSpacing: DesignTokens.letterSpacingLabel,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    detection.displayLabel,
                    style: textTheme.headlineSmall?.copyWith(
                      fontSize: DesignTokens.displayLabelSize,
                    ),
                    maxLines: DesignTokens.displayLabelMaxLines,
                    overflow: TextOverflow.ellipsis,
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

/// Antrean benar-benar habis — semua pembacaan sudah diperiksa.
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.l10n, super.key});

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

/// Filter aktif kosong padahal kategori lain masih menunggu — pesan harus
/// jujur ("semua sudah selesai" di sini adalah bug lama), plus jalan keluar
/// satu ketuk: kembali ke Gabungan.
class _FilteredEmptyQueue extends StatelessWidget {
  const _FilteredEmptyQueue({
    required this.l10n,
    required this.waitingElsewhere,
    required this.onShowAll,
    super.key,
  });

  final AppLocalizations l10n;
  final int waitingElsewhere;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: l10n.validationFilterEmptyTitle,
      message: l10n.validationFilterEmptyBody(waitingElsewhere),
      icon: Icons.filter_alt_off_rounded,
      action: FilledButton.tonalIcon(
        onPressed: onShowAll,
        icon: const Icon(Icons.visibility_rounded),
        label: Text(l10n.validationFilterShowAll),
      ),
    );
  }
}

/// Belum ada perangkat terhubung — tab Validasi tidak bisa mulai bekerja.
class _NoDeviceQueue extends StatelessWidget {
  const _NoDeviceQueue({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: l10n.validationNoDeviceTitle,
      message: l10n.validationNoDeviceBody,
      icon: Icons.link_off_rounded,
      action: FilledButton.tonalIcon(
        onPressed: () => const DevicesPath().go(context),
        icon: const Icon(Icons.devices_other_rounded),
        label: Text(l10n.validationNoDeviceAction),
      ),
    );
  }
}
