import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_providers.dart';

/// Detail satu perangkat — identitas visual v3.
///
/// Kepala tonal (avatar + nama + chip status, tanpa teks status ganda),
/// info teknis ringkas, privasi dengan label yang benar, dan aksi
/// (QR Wi-Fi, Kontrol, Koneksi) sebagai pil.
class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final device = ref.watch(deviceProvider(deviceId));
    final now = DateTime.now();

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
    final connectivity = device.connectivity;
    final pillTone = switch (connectivity) {
      DeviceConnectivity.online => AppStatusTone.ok,
      DeviceConnectivity.offline => AppStatusTone.bad,
      DeviceConnectivity.unknown => AppStatusTone.neutral,
    };
    final pillLabel = switch (connectivity) {
      DeviceConnectivity.online => l10n.statusOnline,
      DeviceConnectivity.offline => l10n.statusOffline,
      DeviceConnectivity.unknown => l10n.commonUnknown,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceSm,
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
            children: [
              Container(
                width: DesignTokens.deviceAvatarSize,
                height: DesignTokens.deviceAvatarSize,
                decoration: ShapeDecoration(
                  color: colorScheme.primaryContainer,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
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
                          '$pillLabel · ${RelativeTime.format(device.lastSeen, now, l10n: l10n)}',
                      tone: pillTone,
                      isDense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSection),
        _SectionLabel(text: l10n.deviceDetailTitle),
        _InfoRow(
          label: l10n.deviceModelLabel,
          value: device.model ?? l10n.commonUnknown,
        ),
        _InfoRow(
          label: l10n.deviceFirmwareLabel,
          value: device.firmwareVersion ?? l10n.commonUnknown,
        ),
        _InfoRow(
          label: l10n.deviceWifiLabel,
          value: device.wifiSsid ?? l10n.commonUnknown,
        ),
        _InfoRow(
          label: l10n.deviceBootCountLabel,
          value: device.bootCount?.toString() ?? l10n.commonUnknown,
        ),
        const SizedBox(height: DesignTokens.spaceLg),
        _SectionLabel(text: l10n.settingsPrivacyTitle),
        _InfoRow(
          label: l10n.settingsUploadThumbnails,
          value: device.settings.uploadThumbnails
              ? l10n.deviceThumbnailOn
              : l10n.deviceThumbnailOff,
        ),
        const SizedBox(height: DesignTokens.spaceLg),
        _SectionLabel(text: l10n.deviceRemoteControl),
        Wrap(
          spacing: DesignTokens.spaceSm,
          runSpacing: DesignTokens.spaceSm,
          children: [
            ActionChip(
              avatar: const Icon(Icons.qr_code_rounded, size: 18),
              label: Text(l10n.provisioningTitle),
              onPressed: () => DeviceWifiPath(device.deviceId).push(context),
            ),
            ActionChip(
              avatar: const Icon(Icons.settings_remote_rounded, size: 18),
              label: Text(l10n.deviceRemoteControl),
              onPressed: () =>
                  DeviceCommandsPath(device.deviceId).push(context),
            ),
            ActionChip(
              avatar: const Icon(Icons.hub_outlined, size: 18),
              label: Text(l10n.eventsTitle),
              onPressed: () =>
                  context.push('/pengaturan/koneksi/${device.deviceId}'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
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
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
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
