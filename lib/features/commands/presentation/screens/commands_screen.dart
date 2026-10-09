import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../domain/entities/device_command.dart';
import '../providers/commands_providers.dart';

/// Kontrol perintah jarak jauh — identitas visual v3.
///
/// Lima tipe yang dikenal firmware (syncNow/speakText/setVolume/restart/
/// reprovision). `speakText`/`setVolume` memakai sheet input dengan payload
/// sah (`DeviceCommand.buildPayload`); restart memakai konfirmasi.
/// Status: pending=warn, sent/acked=info, done=ok, failed=bad.
class CommandsScreen extends ConsumerWidget {
  const CommandsScreen({this.deviceId, super.key});

  final String? deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myDevices = ref
        .watch(myDevicesProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <Device>[]);
    final resolvedId =
        deviceId ?? (myDevices.isEmpty ? null : myDevices.first.deviceId);
    final all = ref.watch(commandsProvider);
    final items = [
      for (final command in all)
        if (resolvedId == null || command.deviceId == resolvedId) command,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commandsTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceSm,
              DesignTokens.spacePage,
              0,
            ),
            child: Wrap(
              spacing: DesignTokens.spaceSm,
              runSpacing: DesignTokens.spaceSm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: resolvedId == null
                      ? null
                      : () => _send(
                          context,
                          ref,
                          CommandType.syncNow,
                          resolvedId,
                        ),
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(l10n.commandsSyncNow),
                ),
                ActionChip(
                  avatar: const Icon(Icons.record_voice_over_rounded, size: 18),
                  label: Text(l10n.commandsSpeakText),
                  onPressed: resolvedId == null
                      ? null
                      : () => _sendSpeak(context, ref, resolvedId),
                ),
                ActionChip(
                  avatar: const Icon(Icons.volume_up_rounded, size: 18),
                  label: Text(l10n.commandsSetVolume),
                  onPressed: resolvedId == null
                      ? null
                      : () => _sendVolume(context, ref, resolvedId),
                ),
                ActionChip(
                  avatar: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(l10n.commandsRestart),
                  onPressed: resolvedId == null
                      ? null
                      : () => _sendRestart(context, ref, resolvedId),
                ),
                ActionChip(
                  avatar: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text(l10n.commandsReprovision),
                  onPressed: resolvedId == null
                      ? null
                      : () => DeviceWifiPath(resolvedId).go(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyView(
                    title: l10n.commandsTitle,
                    message: l10n.eventsEmptyBody,
                    icon: Icons.terminal_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(DesignTokens.spacePage),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceSm),
                    itemBuilder: (context, index) {
                      final command = items[index];
                      return _CommandTile(command: command, now: now);
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
    String targetDeviceId, {
    Map<String, Object?> payload = const {},
  }) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(currentUserProvider)?.uid;
    final newCommand = DeviceCommand(
      id: 'cmd-${DateTime.now().millisecondsSinceEpoch}',
      deviceId: targetDeviceId,
      type: type,
      status: CommandStatus.pending,
      createdAt: DateTime.now(),
      payload: payload,
      requestedBy: uid,
    );
    ref.read(commandsProvider.notifier).add(newCommand);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.commandsSent)));
    }
  }

  Future<void> _sendRestart(
    BuildContext context,
    WidgetRef ref,
    String targetDeviceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await ConfirmSheet.show(
      context,
      title: l10n.commandsConfirmRestartTitle,
      message: l10n.commandsConfirmRestartBody,
      confirmLabel: l10n.commandsRestart,
      icon: Icons.restart_alt_rounded,
    );
    if (confirmed && context.mounted) {
      await _send(context, ref, CommandType.restart, targetDeviceId);
    }
  }

  Future<void> _sendSpeak(
    BuildContext context,
    WidgetRef ref,
    String targetDeviceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    try {
      final text = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceMd,
              DesignTokens.spacePage,
              DesignTokens.spacePage,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.commandsSpeakTextLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: kSpeakTextMaxLength,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l10n.commandsSpeakTextLabel,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text.trim()),
                  child: Text(l10n.commonConfirm),
                ),
              ],
            ),
          ),
        ),
      );
      if (text == null || text.isEmpty || !context.mounted) return;
      await _send(
        context,
        ref,
        CommandType.speakText,
        targetDeviceId,
        payload: DeviceCommand.buildPayload(CommandType.speakText, text: text),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _sendVolume(
    BuildContext context,
    WidgetRef ref,
    String targetDeviceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    var level = 70;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceMd,
              DesignTokens.spacePage,
              DesignTokens.spacePage,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${l10n.commandsVolumeLabel}: $level',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Slider(
                  value: level.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$level',
                  onChanged: (value) =>
                      setSheetState(() => level = value.round()),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.commonConfirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await _send(
        context,
        ref,
        CommandType.setVolume,
        targetDeviceId,
        payload: DeviceCommand.buildPayload(
          CommandType.setVolume,
          level: level,
        ),
      );
    }
  }
}

/// Tile perintah: ikon + judul + waktu + chip status dengan nada benar.
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            decoration: ShapeDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: const CircleBorder(),
            ),
            child: Icon(_iconFor(command.type), size: 20),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(command.type, l10n),
                  style: textTheme.bodyMedium,
                ),
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
            label: _statusLabel(command.status, l10n),
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

IconData _iconFor(CommandType type) {
  return switch (type) {
    CommandType.syncNow => Icons.sync_rounded,
    CommandType.speakText => Icons.record_voice_over_rounded,
    CommandType.setVolume => Icons.volume_up_rounded,
    CommandType.restart => Icons.restart_alt_rounded,
    CommandType.reprovision => Icons.qr_code_rounded,
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
