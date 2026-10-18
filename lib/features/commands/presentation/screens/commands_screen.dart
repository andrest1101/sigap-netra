import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../domain/entities/device_command.dart';
import '../command_actions.dart';
import '../providers/commands_providers.dart';
import '../widgets/command_tile.dart';

/// Kontrol perintah jarak jauh — identitas visual v3.
///
/// Lima tipe yang dikenal firmware (syncNow/speakText/setVolume/restart/
/// reprovision). Aksi kirim/sheet/konfirmasi memakai `command_actions.dart`
/// yang sama dengan pintasan Kontrol di tab Perangkat; tile memakai
/// `CommandTile` bersama sehingga bahasa statusnya identik dengan Log koneksi.
/// Status `pending` dibahas jujur "Menunggu alat · …" karena perintah yang
/// dikirim saat alat offline tetap dieksekusi saat alat tersambung kembali.
class CommandsScreen extends ConsumerWidget {
  const CommandsScreen({this.deviceId, super.key});

  final String? deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final resolvedId = deviceId ?? ref.watch(primaryDeviceIdProvider);
    final commandsAsync = ref.watch(commandsProvider(resolvedId));
    final items = commandsAsync.value ?? const <DeviceCommand>[];
    final now = DateTime.now();

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.commandsTitle),
        fallbackRoute: AppRoutes.devices,
      ),
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
                      : () => sendCommandAction(
                          context,
                          ref,
                          deviceId: resolvedId,
                          type: CommandType.syncNow,
                        ),
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(l10n.commandsSyncNow),
                ),
                ActionChip(
                  avatar: const Icon(Icons.record_voice_over_rounded, size: 18),
                  label: Text(l10n.commandsSpeakText),
                  onPressed: resolvedId == null
                      ? null
                      : () => sendSpeakTextAction(
                          context,
                          ref,
                          deviceId: resolvedId,
                        ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.volume_up_rounded, size: 18),
                  label: Text(l10n.commandsSetVolume),
                  onPressed: resolvedId == null
                      ? null
                      : () => sendVolumeAction(
                          context,
                          ref,
                          deviceId: resolvedId,
                        ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(l10n.commandsRestart),
                  onPressed: resolvedId == null
                      ? null
                      : () => sendRestartAction(
                          context,
                          ref,
                          deviceId: resolvedId,
                        ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text(l10n.commandsReprovision),
                  onPressed: resolvedId == null
                      ? null
                      : () => DeviceWifiPath(resolvedId).push(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: commandsAsync.hasError && !commandsAsync.hasValue
                ? ErrorView(
                    message: _failureText(context, commandsAsync.error!),
                    onRetry: () => ref.invalidate(commandsProvider(resolvedId)),
                  )
                : commandsAsync.isLoading && !commandsAsync.hasValue
                ? const LoadingView()
                : items.isEmpty
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
                    itemBuilder: (context, index) =>
                        CommandTile(command: items[index], now: now),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pesan error siap tampil untuk widget mana pun di file ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}
