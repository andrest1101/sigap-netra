import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device_command.dart';
import '../providers/commands_providers.dart';

/// Kontrol perintah jarak jauh untuk demo.
class CommandsScreen extends ConsumerWidget {
  const CommandsScreen({this.deviceId, super.key});

  final String? deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final commands = ref.watch(commandsProvider);
    final items = [
      for (final command in commands)
        if (deviceId == null || command.deviceId == deviceId) command,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();
    final currentDeviceId = deviceId ?? 'simulasi-maixcam-1';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commandsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Wrap(
              spacing: DesignTokens.spaceSm,
              runSpacing: DesignTokens.spaceSm,
              children: [
                FilledButton.tonal(
                  onPressed: () async => _send(
                    context,
                    ref,
                    CommandType.syncNow,
                    currentDeviceId,
                    l10n,
                  ),
                  child: Text(l10n.commandsSyncNow),
                ),
                OutlinedButton(
                  onPressed: () => _stub(context, l10n.commandsSpeakText),
                  child: Text(l10n.commandsSpeakText),
                ),
                OutlinedButton(
                  onPressed: () => _stub(context, l10n.commandsSetVolume),
                  child: Text(l10n.commandsSetVolume),
                ),
                OutlinedButton(
                  onPressed: () async => _send(
                    context,
                    ref,
                    CommandType.restart,
                    currentDeviceId,
                    l10n,
                  ),
                  child: Text(l10n.commandsRestart),
                ),
                OutlinedButton(
                  onPressed: () async => _send(
                    context,
                    ref,
                    CommandType.reprovision,
                    currentDeviceId,
                    l10n,
                  ),
                  child: Text(l10n.commandsReprovision),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      l10n.eventsEmptyBody,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceMd),
                    itemBuilder: (context, index) {
                      final command = items[index];
                      return ListTile(
                        tileColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusCard,
                          ),
                        ),
                        leading: Icon(_iconFor(command.type)),
                        title: Text(_titleFor(command.type, l10n)),
                        subtitle: Text(
                          '${RelativeTime.format(command.createdAt, now, l10n: l10n)} - ${_statusLabel(command.status, l10n)}',
                        ),
                        trailing: StatusPill(
                          label: _statusLabel(command.status, l10n),
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
          ),
        ],
      ),
    );
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    CommandType type,
    String deviceId,
    AppLocalizations l10n,
  ) async {
    final confirmed =
        type != CommandType.restart ||
        await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.commandsConfirmRestartTitle),
                content: Text(l10n.commandsConfirmRestartBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.commonConfirm),
                  ),
                ],
              ),
            ) ==
            true;

    if (!confirmed || !context.mounted) return;

    final commands = ref.read(commandsProvider);
    final newCommand = DeviceCommand(
      id: 'cmd-${commands.length + 1}',
      deviceId: deviceId,
      type: type,
      status: CommandStatus.sent,
      createdAt: DateTime.now(),
      requestedBy: 'demo@sigapnetra.local',
      resultNote: type == CommandType.restart
          ? l10n.commandsConfirmRestartBody
          : null,
    );
    ref.read(commandsProvider.notifier).add(newCommand);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.commandsSent)));
  }

  void _stub(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }
}

IconData _iconFor(CommandType type) {
  return switch (type) {
    CommandType.syncNow => Icons.sync_alt,
    CommandType.speakText => Icons.record_voice_over_outlined,
    CommandType.setVolume => Icons.volume_up_outlined,
    CommandType.restart => Icons.restart_alt,
    CommandType.reprovision => Icons.qr_code_2,
  };
}

String _titleFor(CommandType type, AppLocalizations l10n) {
  return switch (type) {
    CommandType.syncNow => l10n.commandsSyncNow,
    CommandType.speakText => l10n.commandsSpeakText,
    CommandType.setVolume => l10n.commandsSetVolume,
    CommandType.restart => l10n.commandsRestart,
    CommandType.reprovision => l10n.commandsReprovision,
  };
}

String _statusLabel(CommandStatus status, AppLocalizations l10n) {
  return switch (status) {
    CommandStatus.pending => l10n.commandsStatusPending,
    CommandStatus.sent => l10n.commandsStatusSent,
    CommandStatus.acked => l10n.commandsStatusAcked,
    CommandStatus.done => l10n.commandsStatusDone,
    CommandStatus.failed => l10n.commandsStatusFailed,
  };
}
