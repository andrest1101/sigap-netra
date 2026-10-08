import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_providers.dart';

/// Detail satu perangkat.
class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final device = ref.watch(deviceProvider(deviceId));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceDetailTitle)),
      body: device.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

          final connectivity = device.connectivity;
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: const Icon(Icons.visibility_outlined),
                      ),
                      const SizedBox(width: DesignTokens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: DesignTokens.spaceXs),
                            Text(switch (connectivity) {
                              DeviceConnectivity.online => l10n.statusOnline,
                              DeviceConnectivity.offline => l10n.statusOffline,
                              DeviceConnectivity.unknown => l10n.commonUnknown,
                            }),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: switch (connectivity) {
                          DeviceConnectivity.online => l10n.statusOnline,
                          DeviceConnectivity.offline => l10n.statusOffline,
                          DeviceConnectivity.unknown => l10n.commonUnknown,
                        },
                        tone: switch (connectivity) {
                          DeviceConnectivity.online => AppStatusTone.success,
                          DeviceConnectivity.offline => AppStatusTone.error,
                          DeviceConnectivity.unknown => AppStatusTone.neutral,
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                l10n.deviceDetailTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              _InfoRow(
                label: l10n.homeLastSeenLabel,
                value: RelativeTime.format(device.lastSeen, now, l10n: l10n),
              ),
              _InfoRow(
                label: l10n.deviceModelLabel,
                value: device.model ?? '-',
              ),
              _InfoRow(
                label: l10n.deviceFirmwareLabel,
                value: device.firmwareVersion ?? '-',
              ),
              _InfoRow(
                label: l10n.deviceWifiLabel,
                value: device.wifiSsid ?? '-',
              ),
              _InfoRow(
                label: l10n.deviceBootCountLabel,
                value: device.bootCount?.toString() ?? '-',
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                l10n.settingsPrivacy,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              _InfoRow(
                label: l10n.settingsUploadThumbnails,
                value: device.settings.uploadThumbnails
                    ? l10n.deviceThumbnailOn
                    : l10n.deviceThumbnailOff,
              ),
              _InfoRow(
                label: l10n.settingsDeveloperMode,
                value: device.settings.uploadText
                    ? l10n.deviceLocalActive
                    : l10n.deviceLocalInactive,
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                l10n.deviceRemoteControl,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              _ActionTile(
                icon: Icons.qr_code_2,
                label: l10n.provisioningTitle,
                onTap: () => context.push('/perangkat/$deviceId/wifi'),
              ),
              _ActionTile(
                icon: Icons.settings_remote,
                label: l10n.deviceRemoteControl,
                onTap: () => context.push('/perangkat/$deviceId/perintah'),
              ),
              _ActionTile(
                icon: Icons.sync_alt,
                label: l10n.eventsTitle,
                onTap: () => context.push('/pengaturan/koneksi/$deviceId'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
