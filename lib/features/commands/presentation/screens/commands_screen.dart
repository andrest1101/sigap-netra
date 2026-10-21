import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/widgets/action_tile.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../domain/entities/device_command.dart';
import '../command_actions.dart';
import '../providers/commands_providers.dart';
import '../widgets/command_presentation.dart';
import '../widgets/command_tile.dart';

/// Kontrol perintah jarak jauh — identitas visual v3.
///
/// Lima tipe yang dikenal firmware (syncNow/speakText/setVolume/restart/
/// reprovision). Aksi cepat dikelompokkan dalam kartu berisi baris sentuh
/// berikon; riwayat perintah memakai satu kartu dengan divider inset. Saat
/// belum ada perangkat, alasan ditampilkan jelas dan semua aksi nonaktif.
///
/// Aksi kirim/sheet/konfirmasi tetap memakai `command_actions.dart` yang sama
/// dengan pintasan Kontrol di tab Perangkat. Status `pending` dibahas jujur
/// "Menunggu alat · …" karena perintah yang dikirim saat alat offline tetap
/// dieksekusi saat alat tersambung kembali.
class CommandsScreen extends ConsumerWidget {
  const CommandsScreen({this.deviceId, super.key});

  final String? deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final resolvedId = deviceId ?? ref.watch(primaryDeviceIdProvider);
    final commandsAsync = ref.watch(commandsProvider(resolvedId));
    final items = commandsAsync.value ?? const <DeviceCommand>[];
    final now = ref.watch(nowProvider)();

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.commandsTitle),
        fallbackRoute: AppRoutes.devices,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacePage,
          DesignTokens.spaceSm,
          DesignTokens.spacePage,
          DesignTokens.spaceSection,
        ),
        children: [
          SectionHeader.inset(title: l10n.commandsQuickActions, dense: true),
          if (resolvedId == null) ...[
            const _NoDeviceNotice(),
            const SizedBox(height: DesignTokens.spaceMd),
          ],
          SectionCard(
            divide: true,
            dividerIndent: DesignTokens.spaceLg,
            children: [
              _actionTile(
                context,
                ref,
                l10n,
                resolvedId,
                CommandType.syncNow,
                l10n.commandsSyncNowBody,
              ),
              _actionTile(
                context,
                ref,
                l10n,
                resolvedId,
                CommandType.speakText,
                l10n.commandsSpeakTextBody,
              ),
              _actionTile(
                context,
                ref,
                l10n,
                resolvedId,
                CommandType.setVolume,
                l10n.commandsSetVolumeBody,
              ),
              _actionTile(
                context,
                ref,
                l10n,
                resolvedId,
                CommandType.restart,
                l10n.commandsRestartBody,
              ),
              _actionTile(
                context,
                ref,
                l10n,
                resolvedId,
                CommandType.reprovision,
                l10n.commandsReprovisionBody,
              ),
            ],
          ),
          SectionHeader.inset(title: l10n.commandsHistoryTitle),
          _CommandsHistory(
            async: commandsAsync,
            items: items,
            now: now,
            onRetry: () => ref.invalidate(commandsProvider(resolvedId)),
          ),
        ],
      ),
    );
  }

  ActionTile _actionTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String? deviceId,
    CommandType type,
    String subtitle,
  ) {
    return ActionTile(
      icon: commandIcon(type),
      title: commandTitle(type, l10n),
      subtitle: subtitle,
      onTap: deviceId == null
          ? null
          : () {
              switch (type) {
                case CommandType.syncNow:
                  sendCommandAction(
                    context,
                    ref,
                    deviceId: deviceId,
                    type: CommandType.syncNow,
                  );
                case CommandType.speakText:
                  sendSpeakTextAction(context, ref, deviceId: deviceId);
                case CommandType.setVolume:
                  sendVolumeAction(context, ref, deviceId: deviceId);
                case CommandType.restart:
                  sendRestartAction(context, ref, deviceId: deviceId);
                case CommandType.reprovision:
                  DeviceWifiPath(deviceId).push(context);
              }
            },
    );
  }
}

/// Penjelasan tindakan saat belum ada perangkat terpilih.
class _NoDeviceNotice extends StatelessWidget {
  const _NoDeviceNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      backgroundColor: colorScheme.surfaceContainerHigh,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.spaceMd),
              ),
              child: Icon(
                Icons.devices_other_rounded,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.commandsNoDeviceTitle, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    l10n.commandsNoDeviceBody,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () => const DevicesPath().go(context),
            icon: const Icon(Icons.devices_other_rounded, size: 18),
            label: Text(l10n.commandsOpenDevices),
          ),
        ),
      ],
    );
  }
}

/// Riwayat perintah: loading, kosong, gagal, atau daftar dalam satu kartu.
class _CommandsHistory extends StatelessWidget {
  const _CommandsHistory({
    required this.async,
    required this.items,
    required this.now,
    required this.onRetry,
  });

  final AsyncValue<List<DeviceCommand>> async;
  final List<DeviceCommand> items;
  final DateTime now;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (async.hasError && !async.hasValue) {
      return SectionCard(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          _HistoryError(
            message: _failureText(context, async.error!),
            onRetry: onRetry,
          ),
        ],
      );
    }
    if (async.isLoading && !async.hasValue) {
      return const SectionCard(
        padding: EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          Skeleton.line(),
          SizedBox(height: DesignTokens.spaceMd),
          Skeleton.line(),
          SizedBox(height: DesignTokens.spaceMd),
          Skeleton.line(),
        ],
      );
    }
    if (items.isEmpty) {
      return SectionCard(
        padding: const EdgeInsets.all(DesignTokens.spaceXl),
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(DesignTokens.spaceMd),
                ),
                child: Icon(
                  Icons.terminal_rounded,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              Text(
                l10n.commandsEmptyTitle,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceXs),
              Text(
                l10n.commandsEmptyBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
    }

    return SectionCard(
      divide: true,
      dividerIndent: DesignTokens.spaceLg,
      children: [
        for (final command in items)
          CommandTile(command: command, now: now, embedded: true),
      ],
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 20, color: colorScheme.error),
        const SizedBox(width: DesignTokens.spaceSm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
      ],
    );
  }
}

/// Pesan error siap tampil untuk widget mana pun di file ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}
