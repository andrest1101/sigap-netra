import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/bento_tile.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../core/widgets/logo_mark.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../devices/domain/entities/device.dart';
import '../../devices/presentation/providers/devices_providers.dart';
import '../../devices/presentation/widgets/device_connectivity_display.dart';
import '../../monitoring/domain/entities/detection.dart';
import '../../monitoring/presentation/providers/monitoring_providers.dart';
import '../../settings/presentation/widgets/settings_avatar_button.dart';
import '../../settings/presentation/widgets/simulation_badge.dart';
import '../../validation/presentation/providers/validation_providers.dart';

/// Layar Beranda — identitas visual v3.
///
/// Komposisi murni: Hero perangkat + bento ringkasan + aktivitas terbaru.
/// Tidak ada query Firestore di file ini, semuanya lewat provider.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final devices = ref.watch(myDevicesProvider);

    return LargeTitleScaffold(
      title: l10n.homeTitle,
      // Konteks "perangkat mana" (pola yang sama dengan tab Perangkat):
      // nama perangkat primer sebagai subjudul saat data ada.
      subtitle: devices.maybeWhen(
        data: (list) => list.isEmpty ? null : list.first.name,
        orElse: () => null,
      ),
      actions: const [SimulationBadge(), SettingsAvatarButton()],
      body: devices.when(
        loading: () => const _HomeLoading(),
        error: (error, _) => ErrorView(
          message: _messageFor(context, error),
          onRetry: () => ref.invalidate(myDevicesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _NoDeviceState(l10n: l10n);
          }
          final device = list.first;
          final now = ref.watch(nowProvider)();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacePage,
                  DesignTokens.spaceSm,
                  DesignTokens.spacePage,
                  0,
                ),
                child: DeviceHeroCard(device: device, now: now),
              ),
              _HomeBento(devices: list, now: now),
              const _RecentActivitySection(),
              const SizedBox(height: DesignTokens.spaceSection),
            ],
          );
        },
      ),
    );
  }

  String _messageFor(BuildContext context, Object error) =>
      _failureText(context, error);
}

/// Pesan error siap tampil untuk widget mana pun di file ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}

/// Kartu Hero perangkat: identitas + stats strip + aksi bertingkat.
///
/// Berlapis agar tidak datar: baris identitas (avatar + nama + chevron),
/// strip 3 stat (status, baterai, sinkron terakhir), lalu tombol primer
/// full-width + tombol sekunder. Ring baterai besar dihapus dari Hero —
/// baterai tampil sebagai stat ringkas; satu-satunya ring besar tetap di
/// tab Perangkat agar tidak ada dua signature yang bersaing.
class DeviceHeroCard extends ConsumerWidget {
  const DeviceHeroCard({required this.device, required this.now, super.key});

  final Device device;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pill = device.connectivity.toPillData(l10n);
    final isOnline = device.connectivity == DeviceConnectivity.online;

    // Hero ber-background `primaryContainer`: seluruh teks langsung di sini
    // wajib `onPrimaryContainer`. Hairline `outlineVariant` menegaskan batas
    // kartu di atas scaffold terang (bukan shadow).
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area info bisa di-tap → detail perangkat (konsisten dengan
          // kepala tab Perangkat). Tombol aksi di bawah tetap terpisah.
          InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
            onTap: () => DeviceDetailPath(device.deviceId).push(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    // Avatar kacamata cerdas memakai mark merek — satu
                    // identitas dengan detail perangkat & layar masuk.
                    const LogoMark(size: DesignTokens.deviceAvatarSize),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      // Aksesori visual: status berlabel sudah diumumkan
                      // StatusChip di strip — dot tidak diumumkan ganda.
                      child: ExcludeSemantics(
                        child: StatusDot(
                          tone: isOnline ? AppStatusTone.ok : AppStatusTone.bad,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Text(
                    device.name,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceXs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          _HeroStatsStrip(device: device, now: now, pill: pill),
          const SizedBox(height: DesignTokens.spaceMd),
          // Aksi bertingkat: primer full-width + sekunder full-width.
          // Dua tombol berdampingan selalu sempit (138dp @360px) dan
          // rawan wrap/ellipsis; susunan vertikal memberi ruang label
          // penuh + target sentuh 48. Saat offline QR menjadi primer.
          SizedBox(
            width: double.infinity,
            child: isOnline
                ? FilledButton.icon(
                    onPressed: () =>
                        DeviceCommandsPath(device.deviceId).push(context),
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(l10n.homeSyncNow),
                  )
                : FilledButton.icon(
                    onPressed: () =>
                        DeviceWifiPath(device.deviceId).push(context),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: Text(l10n.homeWifiQrAction),
                  ),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          SizedBox(
            width: double.infinity,
            child: isOnline
                ? FilledButton.tonalIcon(
                    onPressed: () =>
                        DeviceWifiPath(device.deviceId).push(context),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: Text(l10n.homeWifiQrAction),
                  )
                : FilledButton.tonalIcon(
                    onPressed: () =>
                        DeviceCommandsPath(device.deviceId).push(context),
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(l10n.homeSyncShort, maxLines: 1),
                  ),
          ),
          if (!isOnline) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            _OfflineSteps(l10n: l10n),
          ],
        ],
      ),
    );
  }
}

/// Strip 3 stat Hero: status + baterai + sinkron terakhir.
///
/// Baterai tampil sebagai nilai ringkas (ikon + persen, bukan ring besar):
/// satu-satunya ring baterai besar tetap di tab Perangkat agar tidak ada
/// dua signature yang bersaing. Sel di-tap menuju layar terkait.
class _HeroStatsStrip extends StatelessWidget {
  const _HeroStatsStrip({
    required this.device,
    required this.now,
    required this.pill,
  });

  final Device device;
  final DateTime now;
  final StatusPillData pill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onHero = Theme.of(context).colorScheme.onPrimaryContainer;
    final battery = device.batteryPct;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: onHero.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeroStatCell(
              icon: pill.icon ?? Icons.circle_rounded,
              iconTone: pill.tone,
              label: pill.label,
              onHero: onHero,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: onHero.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _HeroStatCell(
              icon: battery == null
                  ? Icons.battery_unknown_rounded
                  : battery >= 30
                  ? Icons.battery_full_rounded
                  : Icons.battery_alert_rounded,
              label: battery == null ? '–' : '$battery%',
              onHero: onHero,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: onHero.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _HeroStatCell(
              icon: Icons.sync_rounded,
              label: RelativeTime.timeAndDate(device.lastSeen, l10n: l10n),
              onHero: onHero,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatCell extends StatelessWidget {
  const _HeroStatCell({
    required this.icon,
    required this.label,
    required this.onHero,
    this.iconTone,
  });

  final IconData icon;
  final String label;
  final Color onHero;
  final AppStatusTone? iconTone;

  @override
  Widget build(BuildContext context) {
    final palette = StatusColors.of(context);
    final iconColor = switch (iconTone) {
      AppStatusTone.ok => palette.ok.solid,
      AppStatusTone.bad => palette.bad.solid,
      AppStatusTone.warn => palette.warn.solid,
      AppStatusTone.neutral => palette.neutral.solid,
      AppStatusTone.info => Theme.of(context).colorScheme.tertiary,
      null => onHero,
    };
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: DesignTokens.spaceXs),
        Flexible(
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: onHero,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Panel 3 langkah ringkas saat perangkat offline.
class _OfflineSteps extends StatelessWidget {
  const _OfflineSteps({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final steps = [
      l10n.homeOfflineStepOne,
      l10n.homeOfflineStepTwo,
      l10n.homeOfflineStepThree,
    ];

    // Panel di dalam Hero: background = `onPrimaryContainer` transparan,
    // teks = `onPrimaryContainer`. Pasangan konsisten di dua mode.
    final onHero = colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: onHero.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeOfflineSetupTitle,
            style: textTheme.labelMedium?.copyWith(color: onHero),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: onHero,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: textTheme.bodyMedium?.copyWith(color: onHero),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bento grid 2 kolom: Menunggu, Kecocokan, Sinkron terakhir, Hari ini.
class _HomeBento extends ConsumerWidget {
  const _HomeBento({required this.devices, required this.now});

  final List<Device> devices;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deviceId = devices.first.deviceId;
    final summary = ref.watch(validationSummaryProvider(deviceId)).value;
    final latest =
        ref
            .watch(latestDetectionsProvider((deviceId: deviceId, limit: 100)))
            .value ??
        const <Detection>[];
    final pending = summary?.pending;
    final accuracy = summary?.accuracy;
    final accuracyText = accuracy == null
        ? '–'
        : '${(accuracy * 100).round()}%';
    final decidedCount = summary?.decided ?? 0;
    final today = latest
        .where(
          (d) =>
              d.createdAt.year == now.year &&
              d.createdAt.month == now.month &&
              d.createdAt.day == now.day,
        )
        .toList();
    final todayMoney = today.where((d) => d.type == DetectionType.money).length;
    final todayText = today.length - todayMoney;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceSection,
        DesignTokens.spacePage,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tinggi disamakan: tile kanan tidak lagi melayang walau isinya
          // lebih pendek dari tile kiri (angka + tombol).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BentoTile(
                    label: l10n.homePendingLabel,
                    icon: Icons.fact_check_rounded,
                    iconColor: StatusColors.of(context).warn.solid,
                    action: FilledButton.tonal(
                      onPressed: () => const ValidationPath().go(context),
                      child: Text(l10n.homePendingReview),
                    ),
                    child: BentoNumber(pending == null ? '–' : '$pending'),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: BentoTile(
                    label: l10n.homeAccuracyLabel,
                    icon: Icons.verified_rounded,
                    iconColor: StatusColors.of(context).ok.solid,
                    footer: accuracy == null
                        ? l10n.homeNoValidation
                        : l10n.homeAccuracyFromCount(decidedCount),
                    child: LensRing(
                      // Satu-satunya ring besar di Beranda (ring baterai
                      // kini berupa stat di strip Hero): 78 agar sisa track
                      // terbaca sebagai jalur yang belum terisi, bukan
                      // lekukan kecil di tengah kartu.
                      diameter: 78,
                      value: accuracy,
                      progressColor: StatusColors.of(context).ok.solid,
                      semanticsLabel: accuracy == null
                          ? l10n.homeAccuracyLabel
                          : l10n.homeAccuracySemantic(accuracyText),
                      center: Text(
                        accuracyText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          // Baris kedua ikut memakai IntrinsicHeight + stretch: "Hari ini"
          // punya footer sedangkan "Sinkron terakhir" tidak — tanpa ini
          // kedua kotak tampil beda tinggi (regresi visual Beranda).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BentoTile.small(
                    label: l10n.homeSyncedLabel,
                    icon: Icons.sync_rounded,
                    // Jam absolut ("14.32 · 10 Okt"), bukan relatif: chip Hero
                    // sudah menampilkan hitungan relatif presisi.
                    value: RelativeTime.timeAndDate(
                      devices.first.lastSeen,
                      l10n: l10n,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: BentoTile.small(
                    label: l10n.homeTodayLabel,
                    icon: Icons.today_rounded,
                    value: l10n.homeReadingsToday(today.length),
                    footer: l10n.homeTodayBreakdown(todayMoney, todayText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lima pembacaan terbaru (semua status) + "Lihat semua" ke Riwayat.
///
/// Tiap baris memakai chip status validasi (Cocok/Tidak cocok/Belum) dan
/// ikon kategori (uang/teks) — bukan nomor urut generik. Tap baris membuka
/// detail pembacaan, bukan tab Riwayat.
class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deviceId = ref.watch(primaryDeviceIdProvider);
    final latest = deviceId == null
        ? null
        : ref.watch(latestDetectionsProvider((deviceId: deviceId, limit: 100)));
    final items = latest?.value?.take(5).toList() ?? const <Detection>[];
    final now = ref.watch(nowProvider)();
    final isLoading = latest != null && latest.isLoading && !latest.hasValue;
    final hasError = latest != null && latest.hasError && !latest.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Non-compact (top 24): ritme seksi sama dengan tab Perangkat.
        // Varian compact membuat Aktivitas "nempel" ke bento (celah 12).
        SectionHeader(
          title: l10n.homeRecentActivity,
          action: TextButton(
            onPressed: () => const HistoryPath().go(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        if (isLoading)
          const _ActivitySkeleton()
        else if (hasError)
          _ActivityError(
            message: _failureText(context, latest.error!),
            onRetry: () => ref.invalidate(
              latestDetectionsProvider((deviceId: deviceId!, limit: 100)),
            ),
          )
        else if (items.isEmpty)
          _EmptyActivity(l10n: l10n)
        else
          for (var i = 0; i < items.length; i++) ...[
            _ActivityRow(
              detection: items[i],
              time: RelativeTime.format(items[i].createdAt, now, l10n: l10n),
            ),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                indent: DesignTokens.spacePage,
                endIndent: DesignTokens.spacePage,
              ),
          ],
      ],
    );
  }
}

/// Skeleton tiga baris aktivitas saat stream pembacaan masih memuat.
class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacePage),
      child: Column(
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

/// Baris error ringkas untuk aktivitas terbaru: pesan + aksi coba lagi.
class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacePage,
        vertical: DesignTokens.spaceSm,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: colorScheme.error),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}

/// Empty khusus Beranda: ikon + ajakan ke antrean validasi.
class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacePage,
        vertical: DesignTokens.spaceMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: const CircleBorder(),
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeEmptyActivityTitle,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.homeEmptyActivityBody,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          // Kosong karena BELUM ADA data sama sekali: ajak memastikan
          // perangkat terhubung (bukan ke antrean Validasi yang juga kosong).
          FilledButton.tonal(
            onPressed: () => const DevicesPath().go(context),
            child: Text(l10n.deviceConnectTitle),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.detection, required this.time});

  final Detection detection;
  final String time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final meta = detection.confidence == null
        ? time
        : '${NumberFormatId.percentWithSign(detection.confidence! * 100)} · $time';

    final tone = switch (detection.validationStatus) {
      ValidationStatus.pending => AppStatusTone.warn,
      ValidationStatus.match => AppStatusTone.ok,
      ValidationStatus.mismatch => AppStatusTone.bad,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      onTap: () => HistoryDetailPath(detection.id).push(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacePage,
          vertical: DesignTokens.spaceMd,
        ),
        child: Row(
          children: [
            // Thumbnail 48: ikon kategori dalam kotak rounded (bukan
            // lingkaran generik) + titik status menempel — baris terbaca
            // sebagai kartu mini, bukan daftar pengaturan.
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusThumbnail,
                    ),
                  ),
                  child: Icon(
                    detection.type == DetectionType.money
                        ? Icons.payments_rounded
                        : Icons.document_scanner_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: ExcludeSemantics(
                    child: StatusDot(tone: tone, size: 12),
                  ),
                ),
              ],
            ),
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
                  // Satu perangkat primer: nama perangkat tidak diulang di
                  // tiap baris (sudah di subjudul app bar + Hero).
                  Text(
                    meta,
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
              tone: tone,
              isDense: true,
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
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(DesignTokens.spacePage),
      child: Column(
        children: [
          Skeleton.card(),
          SizedBox(height: DesignTokens.spaceMd),
          Skeleton.line(),
          SizedBox(height: DesignTokens.spaceSm),
          Skeleton.line(),
        ],
      ),
    );
  }
}

class _NoDeviceState extends StatelessWidget {
  const _NoDeviceState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacePage),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacePage),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n.homeNoDeviceHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(
                  l10n.homeNoDeviceHeroBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          EmptyView(
            title: l10n.homeNoDevicesTitle,
            message: l10n.homeNoDevicesBody,
            icon: Icons.devices_other_outlined,
            action: FilledButton.icon(
              onPressed: () => const DevicesPath().go(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.deviceAdd),
            ),
          ),
        ],
      ),
    );
  }
}
