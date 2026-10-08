import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
import '../../domain/entities/device_event.dart';
import '../providers/events_providers.dart';

/// Log koneksi/sinkronisasi dan perintah perangkat.
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
    final commandItems =
        commands.where((command) => matchDevice(command.deviceId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.eventsSeverityError),
            Tab(text: l10n.commandsTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            itemCount: eventItems.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: DesignTokens.spaceMd),
            itemBuilder: (context, index) {
              final event = eventItems[index];
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                ),
                leading: StatusPill(
                  label: _severityLabel(event.severity, l10n),
                  tone: _severityTone(event.severity),
                ),
                title: Text(event.message),
                subtitle: Text(
                  '${RelativeTime.format(event.createdAt, now, l10n: l10n)} - ${event.type}',
                ),
              );
            },
          ),
          ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            itemCount: commandItems.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: DesignTokens.spaceMd),
            itemBuilder: (context, index) {
              final command = commandItems[index];
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                ),
                title: Text(_commandTitle(command, l10n)),
                subtitle: Text(
                  '${RelativeTime.format(command.createdAt, now, l10n: l10n)} - ${command.resultNote ?? '-'}',
                ),
                trailing: StatusPill(
                  label: _commandStatusLabel(command.status, l10n),
                  tone: switch (command.status) {
                    CommandStatus.pending => AppStatusTone.warning,
                    CommandStatus.sent ||
                    CommandStatus.acked ||
                    CommandStatus.done => AppStatusTone.success,
                    CommandStatus.failed => AppStatusTone.error,
                  },
                ),
              );
            },
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

AppStatusTone _severityTone(EventSeverity severity) {
  return switch (severity) {
    EventSeverity.info => AppStatusTone.neutral,
    EventSeverity.warning => AppStatusTone.warning,
    EventSeverity.error => AppStatusTone.error,
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
