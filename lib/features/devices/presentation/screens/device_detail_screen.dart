import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/action_tile.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/logo_mark.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_providers.dart';

/// Detail satu perangkat — identitas visual v3.
///
/// Kepala tonal berisi identitas dan status. Informasi teknis, privasi, dan
/// aksi dikelompokkan menjadi tiga kartu seksi; aksi adalah baris sentuh
/// berikon + chevron, bukan `ActionChip` mengambang.
class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final device = ref.watch(deviceProvider(deviceId));
    final now = ref.watch(nowProvider)();

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.deviceDetailTitle),
        fallbackRoute: AppRoutes.devices,
      ),
      body: device.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(DesignTokens.spacePage),
          child: Column(
            children: [
              Skeleton.card(),
              SizedBox(height: DesignTokens.spaceMd),
              Skeleton.line(),
            ],
          ),
        ),
        error: (error, _) => ErrorView(
          message: error is AppFailure ? failureMessage(error, l10n) : null,
          onRetry: () => ref.invalidate(deviceProvider(deviceId)),
        ),
        data: (device) {
          if (device == null) {
            return EmptyView(
              title: l10n.stateErrorNotFound,
              message: l10n.deviceDetailTitle,
              icon: Icons.device_unknown_outlined,
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.devices),
                child: Text(l10n.commonBack),
              ),
            );
          }
          return _DeviceDetailBody(device: device, now: now);
        },
      ),
    );
  }
}

class _DeviceDetailBody extends StatelessWidget {
  const _DeviceDetailBody({required this.device, required this.now});

  final Device device;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final battery = device.batteryPct;
    final identityMeta = [
      if (device.model != null) l10n.deviceModelShort(device.model!),
      if (device.firmwareVersion != null)
        l10n.deviceFirmwareShort(device.firmwareVersion!),
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
        DesignTokens.spacePage,
        DesignTokens.spaceSection,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacePage),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mark merek kacamata cerdas (selaras Hero Beranda).
              const LogoMark(size: DesignTokens.deviceAvatarSize),
              const SizedBox(width: DesignTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: textTheme.titleLarge),
                    if (identityMeta.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        identityMeta,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spaceSm),
                    _ConnectivityChip(device: device, now: now, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionHeader.inset(title: l10n.deviceInfoTitle),
        SectionCard(
          divide: true,
          dividerIndent: DesignTokens.spaceLg,
          children: [
            _InfoRow(
              icon: Icons.memory_rounded,
              label: l10n.deviceModelLabel,
              value: device.model ?? l10n.commonUnknown,
            ),
            _InfoRow(
              icon: Icons.system_update_alt_rounded,
              label: l10n.deviceFirmwareLabel,
              value: device.firmwareVersion ?? l10n.commonUnknown,
            ),
            _InfoRow(
              icon: Icons.wifi_rounded,
              label: l10n.deviceWifiLabel,
              value: device.wifiSsid ?? l10n.commonUnknown,
            ),
            _InfoRow(
              icon: Icons.battery_full_rounded,
              label: l10n.homeBatteryLabel,
              value: battery == null ? '–' : '$battery%',
            ),
            _InfoRow(
              icon: Icons.restart_alt_rounded,
              label: l10n.deviceBootCountLabel,
              value: device.bootCount?.toString() ?? l10n.commonUnknown,
            ),
          ],
        ),
        SectionHeader.inset(title: l10n.settingsPrivacyTitle),
        SectionCard(
          divide: true,
          dividerIndent: DesignTokens.spaceLg,
          children: [
            _InfoRow(
              icon: Icons.photo_library_outlined,
              label: l10n.settingsUploadThumbnails,
              value: device.settings.uploadThumbnails
                  ? l10n.deviceThumbnailOn
                  : l10n.deviceThumbnailOff,
            ),
            _InfoNote(
              icon: Icons.lock_outline_rounded,
              text: l10n.settingsUploadsManageOnDevice,
            ),
          ],
        ),
        SectionHeader.inset(title: l10n.deviceActionsTitle),
        SectionCard(
          divide: true,
          dividerIndent: DesignTokens.spaceLg,
          children: [
            ActionTile(
              icon: Icons.qr_code_rounded,
              title: l10n.provisioningTitle,
              subtitle: l10n.deviceQrActionBody,
              onTap: () => DeviceWifiPath(device.deviceId).push(context),
            ),
            ActionTile(
              icon: Icons.settings_remote_rounded,
              title: l10n.deviceRemoteControl,
              subtitle: l10n.deviceControlActionBody,
              onTap: () => DeviceCommandsPath(device.deviceId).push(context),
            ),
            ActionTile(
              icon: Icons.hub_outlined,
              title: l10n.deviceLogActionTitle,
              subtitle: l10n.deviceLogActionBody,
              onTap: () =>
                  context.push('/pengaturan/koneksi/${device.deviceId}'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Chip status koneksi + waktu terakhir terlihat.
class _ConnectivityChip extends StatelessWidget {
  const _ConnectivityChip({
    required this.device,
    required this.now,
    required this.l10n,
  });

  final Device device;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final pill = switch (device.connectivity) {
      DeviceConnectivity.online => (
        label: l10n.statusOnline,
        tone: AppStatusTone.ok,
        icon: Icons.wifi_rounded,
      ),
      DeviceConnectivity.offline => (
        label: l10n.statusOffline,
        tone: AppStatusTone.bad,
        icon: Icons.wifi_off_rounded,
      ),
      DeviceConnectivity.unknown => (
        label: l10n.commonUnknown,
        tone: AppStatusTone.neutral,
        icon: Icons.help_outline_rounded,
      ),
    };

    return StatusChip(
      label:
          '${pill.label} · ${RelativeTime.format(device.lastSeen, now, l10n: l10n)}',
      tone: pill.tone,
      icon: pill.icon,
      isDense: true,
    );
  }
}

/// Baris informasi: label kecil di atas nilai, dengan ikon di kiri.
///
/// Susunan vertikal (bukan label kiri/nilai kanan) membuat SSID panjang dan
/// text scale 1,3x tetap terbaca tanpa saling menghimpit.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Catatan kecil di dalam kartu (bukan baris pengaturan yang bisa diubah).
class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
