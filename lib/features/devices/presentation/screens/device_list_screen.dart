import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
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
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/command_actions.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
import '../../../commands/presentation/widgets/command_presentation.dart';
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
            // Tanpa aksi "Tambah": alur klaim perangkat belum ada di app
            // (P2). Tombol lama mengarah ke Validasi yang juga kosong —
            // menyesatkan, jadi dihapus sampai alur klaim diputuskan.
            return EmptyView(
              title: l10n.devicesEmptyTitle,
              message: l10n.devicesEmptyBody,
              icon: Icons.devices_other_outlined,
            );
          }
          final device = list.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (list.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacePage,
                    DesignTokens.spaceSm,
                    DesignTokens.spacePage,
                    0,
                  ),
                  child: _MultiDeviceNote(count: list.length),
                ),
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

/// Catatan jujur saat akun punya lebih dari satu perangkat.
///
/// Tab ini sengaja menampilkan satu perangkat utama (seluruh aplikasi
/// mengasumsikan satu kacamata aktif); catatan ini menjelaskan sisanya agar
/// tidak terkesan perangkat lain hilang.
class _MultiDeviceNote extends StatelessWidget {
  const _MultiDeviceNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Text(
              l10n.devicesMultipleNote(count),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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

/// Kartu Kontrol fungsional: volume, sinkron, ucapkan, mulai ulang.
///
/// Semua aksi benar-benar mengirim perintah lewat `command_actions.dart`
/// (bukan sekadar pintasan ke layar lain). Perintah tetap boleh dikirim saat
/// alat offline — device menjalankannya begitu tersambung kembali, dengan
/// catatan jujur di bawah tombol selama alat tidak tersambung.
class _ControlCard extends ConsumerStatefulWidget {
  const _ControlCard({required this.device});

  final Device device;

  @override
  ConsumerState<_ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends ConsumerState<_ControlCard> {
  int _volume = 70;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deviceId = widget.device.deviceId;
    final isOnline = widget.device.connectivity == DeviceConnectivity.online;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.deviceControlTitle,
          action: TextButton(
            onPressed: () => DeviceCommandsPath(deviceId).push(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(
                      child: Text(
                        l10n.commandsVolumeLabel,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$_volume',
                      style: textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _volume.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_volume',
                  onChanged: (value) => setState(() => _volume = value.round()),
                  // Satu perintah per penyesuaian selesai — bukan per geseran.
                  onChangeEnd: (value) => sendCommandAction(
                    context,
                    ref,
                    deviceId: deviceId,
                    type: CommandType.setVolume,
                    payload: DeviceCommand.buildPayload(
                      CommandType.setVolume,
                      level: value.round(),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Wrap(
                  spacing: DesignTokens.spaceSm,
                  runSpacing: DesignTokens.spaceSm,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => sendCommandAction(
                        context,
                        ref,
                        deviceId: deviceId,
                        type: CommandType.syncNow,
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(l10n.commandsSyncNow),
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.record_voice_over_rounded,
                        size: 18,
                      ),
                      label: Text(l10n.commandsSpeakText),
                      onPressed: () =>
                          sendSpeakTextAction(context, ref, deviceId: deviceId),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(l10n.commandsRestart),
                      onPressed: () =>
                          sendRestartAction(context, ref, deviceId: deviceId),
                    ),
                  ],
                ),
                if (!isOnline) ...[
                  const SizedBox(height: DesignTokens.spaceMd),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: Text(
                          l10n.deviceControlOfflineNote,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Timeline dua seksi: "Kejadian terakhir" (event + saringan severity) dan
/// "Perintah terakhir" (perintah yang dikirim dari aplikasi).
///
/// Dua seksi dipisah supaya "menunggu validasi" dan "perintah dikirim" tidak
/// pernah tercampur dalam satu daftar tanpa label seperti versi sebelumnya.
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
    final eventsAsync = ref.watch(eventsProvider(widget.deviceId));
    final events = eventsAsync.value ?? const <DeviceEvent>[];
    final filtered = _severity == null
        ? events
        : events.where((e) => e.severity == _severity).toList(growable: false);
    final items = filtered.take(8).toList(growable: false);
    final commandsAsync = ref.watch(commandsProvider(widget.deviceId));
    final commands = (commandsAsync.value ?? const <DeviceCommand>[])
        .take(3)
        .toList(growable: false);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.deviceEventsTitle,
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
        ..._eventRows(context, l10n, eventsAsync, items, events, now),
        const SizedBox(height: DesignTokens.spaceLg),
        SectionHeader(title: l10n.deviceCommandsTitle),
        ..._commandRows(context, l10n, commandsAsync, commands, now),
        const SizedBox(height: DesignTokens.spaceSection),
      ],
    );
  }

  List<Widget> _eventRows(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<DeviceEvent>> async,
    List<DeviceEvent> items,
    List<DeviceEvent> all,
    DateTime now,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    if (async.isLoading && !async.hasValue) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacePage),
          child: Skeleton.card(),
        ),
      ];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _TimelineError(
          error: async.error,
          onRetry: () => ref.invalidate(eventsProvider(widget.deviceId)),
        ),
      ];
    }
    if (items.isEmpty) {
      // Bedakan "belum ada kejadian" dan "saringan tidak menemukan apa-apa".
      final message = all.isEmpty
          ? l10n.eventsEmptyBody
          : l10n.historyFilterEmptyTitle;
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      for (var i = 0; i < items.length; i++)
        _EventRow(
          event: items[i],
          time: RelativeTime.format(items[i].createdAt, now, l10n: l10n),
          isLast: i == items.length - 1,
        ),
    ];
  }

  List<Widget> _commandRows(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<DeviceCommand>> async,
    List<DeviceCommand> commands,
    DateTime now,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    if (async.isLoading && !async.hasValue) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacePage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Skeleton.line(),
              SizedBox(height: DesignTokens.spaceSm),
              Skeleton.line(),
            ],
          ),
        ),
      ];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _TimelineError(
          error: async.error,
          onRetry: () => ref.invalidate(commandsProvider(widget.deviceId)),
        ),
      ];
    }
    if (commands.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: Text(
            l10n.deviceCommandsEmpty,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      for (final command in commands) _CommandRow(command: command, now: now),
    ];
  }
}

/// Baris error ringkas timeline: pesan + aksi coba lagi.
class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final err = error;
    final message = err is AppFailure
        ? failureMessage(err, l10n)
        : l10n.stateErrorBody;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacePage),
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
  const _CommandRow({required this.command, required this.now});

  final DeviceCommand command;
  final DateTime now;

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
            commandIcon(command.type),
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commandTitle(command.type, l10n),
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  commandTimeLine(command, now, l10n),
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
            label: commandStatusLabel(command.status, l10n),
            tone: commandStatusTone(command.status),
            isDense: true,
          ),
        ],
      ),
    );
  }
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
