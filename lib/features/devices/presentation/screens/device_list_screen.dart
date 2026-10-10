import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/battery_ring.dart';
import '../../../../core/widgets/bento_tile.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/settings_gear_button.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
import '../../../events/domain/entities/device_event.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_providers.dart';
import '../widgets/device_connectivity_display.dart';

/// Tab Perangkat — identitas visual v3.
///
/// Hub gabungan: kepala ringkasan status + kartu Hubungkan (QR Wi-Fi) +
/// Kontrol + timeline Aktivitas & error. Pengaturan pindah ke avatar.
class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final devices = ref.watch(myDevicesProvider);
    final now = DateTime.now();

    return LargeTitleScaffold(
      title: l10n.devicesTitle,
      subtitle: devices.maybeWhen(
        data: (list) => list.isEmpty
            ? null
            : '${list.length} ${l10n.devicesTitle.toLowerCase()}',
        orElse: () => null,
      ),
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(myDevicesProvider),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: l10n.commonRefresh,
        ),
        const SettingsGearButton(),
      ],
      body: devices.when(
        loading: () => const _DevicesLoading(),
        error: (error, _) => ErrorView(
          message: error is AppFailure ? failureMessage(error, l10n) : null,
          onRetry: () => ref.invalidate(myDevicesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              title: l10n.devicesEmptyTitle,
              message: l10n.devicesEmptyBody,
              icon: Icons.devices_other_outlined,
              action: FilledButton.icon(
                onPressed: () => const ValidationPath().go(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.deviceAdd),
              ),
            );
          }
          final device = list.first;
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
                child: _DeviceHead(device: device, now: now),
              ),
              _ConnectCard(device: device),
              _ControlCard(device: device),
              _ActivityTimeline(deviceId: device.deviceId),
              const SizedBox(height: DesignTokens.spaceSection),
            ],
          );
        },
      ),
    );
  }
}

/// Kepala ringkasan: titik status, baterai, firmware/model, terakhir terlihat.
class _DeviceHead extends StatelessWidget {
  const _DeviceHead({required this.device, required this.now});

  final Device device;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pill = device.connectivity.toPillData(l10n);
    final battery = device.batteryPct;

    // Tap kepala perangkat membuka Detail (push agar bisa kembali).
    // Seluruh konten kartu interaktif sekaligus: satu pintu ke detail.
    final borderRadius = BorderRadius.circular(DesignTokens.radiusCard);
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => DeviceDetailPath(device.deviceId).push(context),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacePage),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusDot(
                          tone: device.connectivity == DeviceConnectivity.online
                              ? AppStatusTone.ok
                              : AppStatusTone.bad,
                          size: 12,
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Expanded(
                          child: Text(
                            device.name,
                            style: textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      '${l10n.deviceLastSeenLabel}: ${RelativeTime.format(device.lastSeen, now, l10n: l10n)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (device.firmwareVersion != null ||
                        device.model != null) ...[
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        [
                          if (device.model != null)
                            l10n.deviceModelShort(device.model!),
                          if (device.firmwareVersion != null)
                            l10n.deviceFirmwareShort(device.firmwareVersion!),
                        ].join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spaceSm),
                    StatusChip(
                      label: pill.label,
                      tone: pill.tone,
                      icon: pill.icon,
                      isDense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              // Widget bersama yang sama dengan Hero Beranda (ukuran
              // default 56 di kedua tempat agar proporsinya identik).
              BatteryRing(batteryPct: battery),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu Hubungkan: tombol QR Wi-Fi + bantuan singkat.
class _ConnectCard extends StatelessWidget {
  const _ConnectCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.deviceConnectTitle),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.deviceConnectBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      DeviceWifiPath(device.deviceId).push(context),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: Text(l10n.deviceShowQr),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu Kontrol: pintasan ke perintah (volume, ucapkan, restart, sinkron).
class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.deviceControlTitle,
          action: TextButton(
            onPressed: () => DeviceCommandsPath(device.deviceId).push(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: Wrap(
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceSm,
            children: [
              _ControlChip(
                icon: Icons.sync_rounded,
                label: l10n.commandsSyncNow,
                onTap: () => DeviceCommandsPath(device.deviceId).push(context),
              ),
              _ControlChip(
                icon: Icons.volume_up_rounded,
                label: l10n.commandsSetVolume,
                onTap: () => DeviceCommandsPath(device.deviceId).push(context),
              ),
              _ControlChip(
                icon: Icons.record_voice_over_rounded,
                label: l10n.commandsSpeakText,
                onTap: () => DeviceCommandsPath(device.deviceId).push(context),
              ),
              _ControlChip(
                icon: Icons.restart_alt_rounded,
                label: l10n.commandsRestart,
                onTap: () => DeviceCommandsPath(device.deviceId).push(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// Timeline aktivitas & error: event + perintah terbaru, filter severity.
class _ActivityTimeline extends ConsumerStatefulWidget {
  const _ActivityTimeline({required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<_ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<_ActivityTimeline> {
  EventSeverity? _severity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final events = ref
        .watch(eventsProvider)
        .where((e) => e.deviceId == widget.deviceId);
    final filtered = _severity == null
        ? events.toList()
        : events.where((e) => e.severity == _severity).toList();
    final items = filtered.take(8).toList();
    final commands = ref
        .watch(commandsProvider)
        .where((c) => c.deviceId == widget.deviceId)
        .take(3)
        .toList();
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.deviceActivityTitle,
          action: TextButton(
            onPressed: () => const ConnectionLogsPath().push(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacePage,
            0,
            DesignTokens.spacePage,
            DesignTokens.spaceSm,
          ),
          child: FilterChipRow<EventSeverity>(
            selected: _severity,
            onChanged: (value) => setState(() => _severity = value),
            options: [
              (label: l10n.historyFilterAll, icon: null, value: null),
              (
                label: l10n.eventsSeverityInfo,
                icon: Icons.info_outline_rounded,
                value: EventSeverity.info,
              ),
              (
                label: l10n.eventsSeverityWarning,
                icon: Icons.warning_amber_rounded,
                value: EventSeverity.warning,
              ),
              (
                label: l10n.eventsSeverityError,
                icon: Icons.error_outline_rounded,
                value: EventSeverity.error,
              ),
            ],
          ),
        ),
        if (items.isEmpty && commands.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacePage,
            ),
            child: Text(
              l10n.eventsEmptyBody,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            _EventRow(
              event: items[i],
              time: RelativeTime.format(items[i].createdAt, now, l10n: l10n),
              isLast: i == items.length - 1 && commands.isEmpty,
            ),
        for (final command in commands)
          _CommandRow(
            command: command,
            time: RelativeTime.format(command.createdAt, now, l10n: l10n),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.time,
    required this.isLast,
  });

  final DeviceEvent event;
  final String time;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (icon, tone) = switch (event.severity) {
      EventSeverity.info => (Icons.info_outline_rounded, AppStatusTone.neutral),
      EventSeverity.warning => (
        Icons.warning_amber_rounded,
        AppStatusTone.warn,
      ),
      EventSeverity.error => (Icons.error_outline_rounded, AppStatusTone.bad),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacePage),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                decoration: ShapeDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: const CircleBorder(),
                ),
                child: Icon(icon, size: 16, color: colorScheme.onSurface),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: DesignTokens.spacePage,
                  color: colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.message,
                          style: textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceSm),
                      StatusChip(
                        label: switch (event.severity) {
                          EventSeverity.info => l10n.eventsSeverityInfo,
                          EventSeverity.warning => l10n.eventsSeverityWarning,
                          EventSeverity.error => l10n.eventsSeverityError,
                        },
                        tone: tone,
                        isDense: true,
                      ),
                    ],
                  ),
                  Text(
                    '$time · ${event.type}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({required this.command, required this.time});

  final DeviceCommand command;
  final String time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacePage,
        vertical: DesignTokens.spaceXs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.terminal_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Text(
              '${_commandTitle(command, l10n)} · $time',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusChip(
            label: _commandStatusLabel(command.status, l10n),
            tone: switch (command.status) {
              CommandStatus.pending => AppStatusTone.warn,
              CommandStatus.failed => AppStatusTone.bad,
              _ => AppStatusTone.ok,
            },
            isDense: true,
          ),
        ],
      ),
    );
  }
}

String _commandTitle(DeviceCommand command, AppLocalizations l10n) {
  return switch (command.type) {
    CommandType.syncNow => l10n.commandsSyncNow,
    CommandType.speakText => l10n.commandsSpeakText,
    CommandType.setVolume => l10n.commandsSetVolume,
    CommandType.restart => l10n.commandsRestart,
    CommandType.reprovision => l10n.commandsReprovision,
  };
}

String _commandStatusLabel(CommandStatus status, AppLocalizations l10n) {
  return switch (status) {
    CommandStatus.pending => l10n.commandsStatusPending,
    CommandStatus.sent => l10n.commandsStatusSent,
    CommandStatus.acked => l10n.commandsStatusAcked,
    CommandStatus.done => l10n.commandsStatusDone,
    CommandStatus.failed => l10n.commandsStatusFailed,
  };
}

class _DevicesLoading extends StatelessWidget {
  const _DevicesLoading();

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
