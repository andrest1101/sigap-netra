import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
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
    final events = ref.watch(eventsProvider);
    final commands = ref.watch(commandsProvider);

    bool matchDevice(String? id) =>
        widget.deviceId == null || id == widget.deviceId;

    final eventItems =
        events.where((event) => matchDevice(event.deviceId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filteredEvents = _severity == null
        ? eventItems
        : eventItems.where((e) => e.severity == _severity).toList();
    final commandItems =
        commands.where((command) => matchDevice(command.deviceId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
                child: Wrap(
                  spacing: DesignTokens.spaceSm,
                  runSpacing: DesignTokens.spaceSm,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.historyFilterAll),
                      selected: _severity == null,
                      onSelected: (_) => setState(() => _severity = null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.eventsSeverityWarning),
                      selected: _severity == EventSeverity.warning,
                      onSelected: (_) =>
                          setState(() => _severity = EventSeverity.warning),
                    ),
                    ChoiceChip(
                      label: Text(l10n.eventsSeverityError),
                      selected: _severity == EventSeverity.error,
                      onSelected: (_) =>
                          setState(() => _severity = EventSeverity.error),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredEvents.isEmpty
                    ? EmptyView(
                        title: l10n.eventsEmptyTitle,
                        message: l10n.eventsEmptyBody,
                        icon: Icons.hub_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(DesignTokens.spacePage),
                        itemCount: filteredEvents.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: DesignTokens.spaceSm),
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return _EventTile(event: event, now: now);
                        },
                      ),
              ),
            ],
          ),
          commandItems.isEmpty
              ? EmptyView(
                  title: l10n.commandsTitle,
                  message: l10n.eventsEmptyBody,
                  icon: Icons.terminal_rounded,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(DesignTokens.spacePage),
                  itemCount: commandItems.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.spaceSm),
                  itemBuilder: (context, index) {
                    final command = commandItems[index];
                    return _CommandTile(command: command, now: now);
                  },
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
