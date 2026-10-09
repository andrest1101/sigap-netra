import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/bento_tile.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../devices/domain/entities/device.dart';
import '../../devices/presentation/providers/devices_providers.dart';
import '../../devices/presentation/widgets/device_connectivity_display.dart';
import '../../monitoring/presentation/providers/monitoring_providers.dart';
import '../../validation/domain/usecases/validation_usecases.dart';

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
      avatar: _SettingsAvatar(ref: ref),
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
          final now = DateTime.now();
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

  String _messageFor(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is AppFailure) return failureMessage(error, l10n);
    return l10n.stateErrorBody;
  }
}

/// Avatar Pengaturan di kanan app bar (arsitektur informasi v3).
class _SettingsAvatar extends ConsumerWidget {
  const _SettingsAvatar({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Semantics(
      button: true,
      label: l10n.settingsOpenTitle,
      child: InkWell(
        onTap: () => const SettingsPath().go(context),
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            initial,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu Hero perangkat: status, baterai (Lens Ring), aksi Sinkronkan + QR.
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

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacePage),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: ShapeDecoration(
                      color: colorScheme.surface,
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      Icons.visibility_rounded,
                      size: 32,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: StatusDot(
                      tone: isOnline ? AppStatusTone.ok : AppStatusTone.bad,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: textTheme.titleLarge),
                    const SizedBox(height: DesignTokens.spaceXs),
                    StatusChip(
                      label:
                          '${pill.label} · ${RelativeTime.format(device.lastSeen, now, l10n: l10n)}',
                      tone: pill.tone,
                      icon: pill.icon,
                      isDense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              _BatteryRing(device: device),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Row(
            children: [
              Expanded(child: _SyncButton(device: device)),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => DeviceWifiPath(device.deviceId).go(context),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: Text(l10n.homeWifiQrAction),
                ),
              ),
            ],
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

/// Lens Ring baterai: angka di tengah, "–" bila tidak tersedia.
class _BatteryRing extends StatelessWidget {
  const _BatteryRing({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final battery = device.batteryPct;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LensRing(
          diameter: 64,
          value: battery == null ? null : battery / 100,
          semanticsLabel: battery == null
              ? l10n.homeBatteryUnavailable
              : '${l10n.homeBatteryLabel} $battery persen',
          center: Text(
            battery == null ? '–' : '$battery',
            style: textTheme.titleMedium?.copyWith(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.homeBatteryLabel,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

/// Tombol Sinkronkan: mengirim `sync_now` lewat CommandsScreen terdekat.
///
/// Beranda tidak mengirim perintah langsung; ia membuka layar perintah
/// perangkat dengan aksi sinkron yang sudah dipilih.
class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: () => DeviceCommandsPath(device.deviceId).go(context),
      icon: const Icon(Icons.sync_rounded),
      label: Text(l10n.homeSyncNow),
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

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeOfflineSetupTitle,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
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
                      color: colorScheme.onPrimaryContainer,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
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
    final pending = ref.watch(pendingDetectionsProvider).length;
    final decided = ref.watch(detectionsProvider);
    final accuracy = calculateValidationAccuracy(decided);
    final accuracyText = accuracy.isNaN ? '–' : '${(accuracy * 100).round()}%';
    final todayCount = decided
        .where(
          (d) =>
              d.createdAt.year == now.year &&
              d.createdAt.month == now.month &&
              d.createdAt.day == now.day,
        )
        .length;

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
          Row(
            children: [
              Expanded(
                child: BentoTile(
                  label: l10n.homePendingLabel,
                  action: FilledButton.tonal(
                    onPressed: () => const ValidationPath().go(context),
                    child: Text(l10n.homePendingReview),
                  ),
                  child: BentoNumber('$pending'),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: BentoTile(
                  label: l10n.homeAccuracyLabel,
                  child: Row(
                    children: [
                      LensRing(
                        diameter: 56,
                        value: accuracy.isNaN ? null : accuracy,
                        progressColor: StatusColors.of(context).ok.solid,
                        semanticsLabel: accuracy.isNaN
                            ? l10n.homeAccuracyLabel
                            : l10n.homeAccuracySemantic(accuracyText),
                        center: Text(
                          accuracyText,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: BentoTile.small(
                  label: l10n.homeSyncedLabel,
                  value: RelativeTime.format(
                    devices.first.lastSeen,
                    now,
                    l10n: l10n,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: BentoTile.small(
                  label: l10n.homeTodayLabel,
                  value: l10n.homeReadingsToday(todayCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lima aktivitas terbaru + "Lihat semua" ke Riwayat.
class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(pendingDetectionsProvider).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeRecentActivity,
          action: TextButton(
            onPressed: () => const HistoryPath().go(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacePage,
            ),
            child: Text(
              l10n.validationAllDoneTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            _ActivityRow(
              index: i,
              deviceName: items[i].deviceName,
              label: items[i].displayLabel,
              time: RelativeTime.format(
                items[i].createdAt,
                DateTime.now(),
                l10n: l10n,
              ),
            ),
            if (i < items.length - 1) const Divider(height: 1, indent: 20),
          ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.index,
    required this.deviceName,
    required this.label,
    required this.time,
  });

  final int index;
  final String deviceName;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => const HistoryPath().go(context),
      child: Padding(
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
                Icons.receipt_long_rounded,
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
                    label,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$deviceName · $time',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StatusChip(
              label: '#${index + 1}',
              tone: AppStatusTone.neutral,
              isDense: true,
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
            ),
            child: Column(
              children: [
                Text(
                  l10n.homeNoDeviceHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(
                  l10n.homeNoDeviceHeroBody,
                  style: Theme.of(context).textTheme.bodyMedium,
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
