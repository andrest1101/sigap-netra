import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../domain/entities/device_event.dart';
import '../providers/events_providers.dart';

/// Log koneksi/sinkronisasi dan perintah perangkat — identitas visual v3.
///
/// Label tab benar (Event/Perintah), tiap tab punya empty state, filter
/// severity untuk event, waktu absolut untuk screen reader.
class ConnectionLogsScreen extends ConsumerStatefulWidget {
  const ConnectionLogsScreen({this.deviceId, super.key});

  final String? deviceId;

  @override
  ConsumerState<ConnectionLogsScreen> createState() =>
      _ConnectionLogsScreenState();
}

class _ConnectionLogsScreenState extends ConsumerState<ConnectionLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventSeverity? _severity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Layar ini juga bisa dibuka tanpa konteks perangkat (dari Pengaturan).
    // Tanpa perangkat eksplisit kita jatuh ke perangkat utama: schema tidak
    // mengizinkan query lintas perangkat.
    final deviceId = widget.deviceId ?? ref.watch(primaryDeviceIdProvider);
    final eventsAsync = deviceId == null
        ? null
        : ref.watch(eventsProvider(deviceId));
    final commandsAsync = ref.watch(commandsProvider(deviceId));
    final events = eventsAsync?.value ?? const <DeviceEvent>[];
    final commands = commandsAsync.value ?? const <DeviceCommand>[];
    final filteredEvents = _severity == null
        ? events
        : events.where((e) => e.severity == _severity).toList();
    final now = DateTime.now();

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.eventsTitle),
        fallbackRoute: AppRoutes.devices,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.eventsTitle),
            Tab(text: l10n.commandsTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacePage,
                  DesignTokens.spaceMd,
                  DesignTokens.spacePage,
                  0,
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
              Expanded(
                child: _AsyncLogBody(
                  async: eventsAsync,
                  isEmpty: filteredEvents.isEmpty,
                  emptyTitle: l10n.eventsEmptyTitle,
                  emptyBody: l10n.eventsEmptyBody,
                  emptyIcon: Icons.hub_outlined,
                  onRetry: deviceId == null
                      ? null
                      : () => ref.invalidate(eventsProvider(deviceId)),
                  builder: (context) => ListView.separated(
                    padding: const EdgeInsets.all(DesignTokens.spacePage),
                    itemCount: filteredEvents.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceSm),
                    itemBuilder: (context, index) =>
                        _EventTile(event: filteredEvents[index], now: now),
                  ),
                ),
              ),
            ],
          ),
          _AsyncLogBody(
            async: commandsAsync,
            isEmpty: commands.isEmpty,
            emptyTitle: l10n.commandsTitle,
            emptyBody: l10n.eventsEmptyBody,
            emptyIcon: Icons.terminal_rounded,
            onRetry: deviceId == null
                ? null
                : () => ref.invalidate(commandsProvider(deviceId)),
            builder: (context) => ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.spacePage),
              itemCount: commands.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.spaceSm),
              itemBuilder: (context, index) =>
                  _CommandTile(command: commands[index], now: now),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.now});

  final DeviceEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label:
          '${_severitySpoken(event.severity, l10n)}: ${event.message}, ${RelativeTime.date(event.createdAt)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: _severityLabel(event.severity, l10n),
              tone: _severityTone(event.severity),
              isDense: true,
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.message, style: textTheme.bodyMedium),
                  Text(
                    '${RelativeTime.format(event.createdAt, now, l10n: l10n)} · ${event.type}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.command, required this.now});

  final DeviceCommand command;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_commandTitle(command, l10n), style: textTheme.bodyMedium),
                Text(
                  '${RelativeTime.format(command.createdAt, now, l10n: l10n)}${command.resultNote == null || command.resultNote!.isEmpty ? '' : ' · ${command.resultNote}'}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          StatusChip(
            label: _commandStatusLabel(command.status, l10n),
            tone: switch (command.status) {
              CommandStatus.pending => AppStatusTone.warn,
              CommandStatus.sent || CommandStatus.acked => AppStatusTone.info,
              CommandStatus.done => AppStatusTone.ok,
              CommandStatus.failed => AppStatusTone.bad,
            },
            isDense: true,
          ),
        ],
      ),
    );
  }
}

String _severityLabel(EventSeverity severity, AppLocalizations l10n) {
  return switch (severity) {
    EventSeverity.info => l10n.eventsSeverityInfo,
    EventSeverity.warning => l10n.eventsSeverityWarning,
    EventSeverity.error => l10n.eventsSeverityError,
  };
}

String _severitySpoken(EventSeverity severity, AppLocalizations l10n) {
  return switch (severity) {
    EventSeverity.info => l10n.eventsSeverityInfo,
    EventSeverity.warning => l10n.statusWarning,
    EventSeverity.error => l10n.statusError,
  };
}

AppStatusTone _severityTone(EventSeverity severity) {
  return switch (severity) {
    EventSeverity.info => AppStatusTone.neutral,
    EventSeverity.warning => AppStatusTone.warn,
    EventSeverity.error => AppStatusTone.bad,
  };
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

/// Body satu tab log: membedakan loading / error / kosong / data.
///
/// [async] null berarti tidak ada perangkat terpilih — tampil sebagai kosong,
/// bukan error, karena memang tidak ada yang bisa dimuat.
class _AsyncLogBody<T> extends StatelessWidget {
  const _AsyncLogBody({
    required this.async,
    required this.isEmpty,
    required this.emptyTitle,
    required this.emptyBody,
    required this.emptyIcon,
    required this.builder,
    this.onRetry,
  });

  final AsyncValue<List<T>>? async;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyBody;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final value = async;
    if (value != null && value.hasError && !value.hasValue) {
      return ErrorView(
        message: _failureText(context, value.error!),
        onRetry: onRetry,
      );
    }
    if (value != null && value.isLoading && !value.hasValue) {
      return const LoadingView();
    }
    if (value == null || isEmpty) {
      return EmptyView(title: emptyTitle, message: emptyBody, icon: emptyIcon);
    }
    return builder(context);
  }
}

/// Pesan error siap tampil untuk widget mana pun di file ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}
