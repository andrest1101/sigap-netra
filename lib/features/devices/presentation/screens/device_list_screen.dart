import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/battery_ring.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/large_title_scaffold.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/command_actions.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
import '../../../commands/presentation/widgets/command_presentation.dart';
import '../../../events/domain/entities/device_event.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../../../events/presentation/widgets/event_presentation.dart';
import '../../../settings/presentation/widgets/settings_avatar_button.dart';
import '../../../settings/presentation/widgets/simulation_badge.dart';
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
    final now = ref.watch(nowProvider)();

    return LargeTitleScaffold(
      title: l10n.devicesTitle,
      subtitle: devices.maybeWhen(
        data: (list) => list.isEmpty
            ? null
            : '${list.length} ${l10n.devicesTitle.toLowerCase()}',
        orElse: () => null,
      ),
      actions: [
        const SimulationBadge(),
        IconButton(
          onPressed: () => ref.invalidate(myDevicesProvider),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: l10n.commonRefresh,
        ),
        const SettingsAvatarButton(),
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
        SectionHeader(title: l10n.deviceControlTitle),
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

/// Dua kartu ringkasan aktivitas: "Kejadian terakhir" dan "Perintah terakhir".
///
/// Masing-masing punya container sendiri agar baris tidak lagi mengambang di
/// antara kartu Kontrol dan tepi layar. Saringan severity sengaja tidak
/// ditampilkan di sini: kartu hanya memuat beberapa kejadian terbaru,
/// sedangkan saringan menyeluruh (query server + paginasi) ada di Log koneksi.
class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EventsSection(deviceId: deviceId),
        _CommandsSection(deviceId: deviceId),
        const SizedBox(height: DesignTokens.spaceSection),
      ],
    );
  }
}

class _EventsSection extends ConsumerWidget {
  const _EventsSection({required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eventsProvider(deviceId));
    final items = (async.value ?? const <DeviceEvent>[])
        .take(4)
        .toList(growable: false);
    final now = ref.watch(nowProvider)();

    final Widget content;
    if (async.isLoading && !async.hasValue) {
      content = const _ActivityCardSkeleton(lines: 2);
    } else if (async.hasError && !async.hasValue) {
      content = _ActivityError(
        error: async.error,
        onRetry: () => ref.invalidate(eventsProvider(deviceId)),
      );
    } else if (items.isEmpty) {
      content = _ActivityEmpty(message: l10n.eventsEmptyBody);
    } else {
      content = Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _EventRow(
              event: items[i],
              time: RelativeTime.format(items[i].createdAt, now, l10n: l10n),
            ),
            if (i < items.length - 1) const _ActivityDivider(),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.deviceEventsTitle,
          action: TextButton(
            onPressed: () => const ConnectionLogsPath().push(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        _ActivityCard(child: content),
      ],
    );
  }
}

class _CommandsSection extends ConsumerWidget {
  const _CommandsSection({required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(commandsProvider(deviceId));
    final items = (async.value ?? const <DeviceCommand>[])
        .take(3)
        .toList(growable: false);
    final now = ref.watch(nowProvider)();

    final Widget content;
    if (async.isLoading && !async.hasValue) {
      content = const _ActivityCardSkeleton(lines: 2);
    } else if (async.hasError && !async.hasValue) {
      content = _ActivityError(
        error: async.error,
        onRetry: () => ref.invalidate(commandsProvider(deviceId)),
      );
    } else if (items.isEmpty) {
      content = _ActivityEmpty(message: l10n.deviceCommandsEmpty);
    } else {
      content = Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _CommandRow(command: items[i], now: now),
            if (i < items.length - 1) const _ActivityDivider(),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.deviceCommandsTitle,
          action: TextButton(
            onPressed: () => DeviceCommandsPath(deviceId).push(context),
            child: Text(l10n.commonSeeAll),
          ),
        ),
        _ActivityCard(child: content),
      ],
    );
  }
}

/// Kartu tonal yang membungkus daftar ringkasan aktivitas.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacePage),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _ActivityDivider extends StatelessWidget {
  const _ActivityDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: DesignTokens.spaceLg,
      endIndent: DesignTokens.spaceLg,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _ActivityCardSkeleton extends StatelessWidget {
  const _ActivityCardSkeleton({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines; i++) ...[
            const Skeleton.line(),
            if (i < lines - 1) const SizedBox(height: DesignTokens.spaceMd),
          ],
        ],
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Baris error ringkas di dalam kartu: pesan + aksi coba lagi.
class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.error, required this.onRetry});

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
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
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
  const _EventRow({required this.event, required this.time});

  final DeviceEvent event;
  final String time;

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
    final palette = _tonePalette(context, tone);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceMd,
      ),
      child: Row(
        children: [
          _ActivityIcon(icon: icon, palette: palette),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.message,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$time · ${eventCategoryLabel(event.type, l10n)}',
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
    final tone = commandStatusTone(command.status);
    final palette = _tonePalette(context, tone);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceMd,
      ),
      child: Row(
        children: [
          _ActivityIcon(icon: commandIcon(command.type), palette: palette),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commandTitle(command.type, l10n),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
            tone: tone,
            isDense: true,
          ),
        ],
      ),
    );
  }
}

/// Ikon leading 40 dp dengan latar tonal sesuai tingkat kepentingan.
class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.icon, required this.palette});

  final IconData icon;
  final StatusPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: palette.container,
        shape: const CircleBorder(),
      ),
      child: Icon(icon, size: 20, color: palette.content),
    );
  }
}

/// Palet status untuk leading icon. `info` memakai pasangan tertiary karena
/// `StatusColors` hanya menyimpan nada status tetap (ok/bad/warn/neutral).
StatusPalette _tonePalette(BuildContext context, AppStatusTone tone) {
  final palette = StatusColors.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  return switch (tone) {
    AppStatusTone.ok => palette.ok,
    AppStatusTone.bad => palette.bad,
    AppStatusTone.warn => palette.warn,
    AppStatusTone.neutral => palette.neutral,
    AppStatusTone.info => StatusPalette(
      solid: colorScheme.tertiary,
      container: colorScheme.tertiaryContainer,
      content: colorScheme.onTertiaryContainer,
    ),
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
