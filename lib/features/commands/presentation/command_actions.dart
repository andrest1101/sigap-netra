/// Aksi perintah bersama untuk Kontrol (tab Perangkat) dan layar Kontrol
/// jarak jauh.
///
/// Semua jalur kirim perintah melewati file ini supaya snackbar sukses/gagal,
/// payload sah (`DeviceCommand.buildPayload`), dan alur konfirmasi restart
/// konsisten di seluruh aplikasi. Perintah tetap boleh dikirim saat alat
/// offline: device menjalankannya begitu tersambung kembali (status
/// "Menunggu alat").
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/entities/device_command.dart';
import 'providers/commands_providers.dart';

/// Mengirim satu perintah dan menampilkan umpan balik yang jujur.
Future<void> sendCommandAction(
  BuildContext context,
  WidgetRef ref, {
  required String deviceId,
  required CommandType type,
  Map<String, Object?> payload = const <String, Object?>{},
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await ref
        .read(sendCommandProvider)
        .call(
          deviceId: deviceId,
          type: type,
          payload: payload,
          requestedBy: ref.read(currentUserProvider)?.uid,
        );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.commandsSendFailed)));
    }
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.commandsSent)));
  }
}

/// Restart dengan konfirmasi eksplisit (kacamata berhenti sejenak).
Future<void> sendRestartAction(
  BuildContext context,
  WidgetRef ref, {
  required String deviceId,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await ConfirmSheet.show(
    context,
    title: l10n.commandsConfirmRestartTitle,
    message: l10n.commandsConfirmRestartBody,
    confirmLabel: l10n.commandsRestart,
    icon: Icons.restart_alt_rounded,
  );
  if (confirmed && context.mounted) {
    await sendCommandAction(
      context,
      ref,
      deviceId: deviceId,
      type: CommandType.restart,
    );
  }
}

/// Sheet "Ucapkan teks": teks diketik pengguna, dipotong di batas skema
/// (`kSpeakTextMaxLength`) oleh [DeviceCommand.buildPayload].
Future<void> sendSpeakTextAction(
  BuildContext context,
  WidgetRef ref, {
  required String deviceId,
}) async {
  final text = await showModalBottomSheet<String>(
    context: context,
    // Keyboard tidak boleh memaksa sheet jadi tinggi minimum.
    isScrollControlled: true,
    builder: (context) => const _SpeakTextSheet(),
  );
  if (text == null || text.isEmpty || !context.mounted) return;
  await sendCommandAction(
    context,
    ref,
    deviceId: deviceId,
    type: CommandType.speakText,
    payload: DeviceCommand.buildPayload(CommandType.speakText, text: text),
  );
}

/// Sheet "Ucapkan teks" dengan controller miliknya sendiri.
///
/// Controller di-dispose oleh `State.dispose()` — yaitu saat route benar-benar
/// dilepas — bukan segera setelah `pop()`, karena field masih ikut dirender
/// selama animasi keluar.
class _SpeakTextSheet extends StatefulWidget {
  const _SpeakTextSheet();

  @override
  State<_SpeakTextSheet> createState() => _SpeakTextSheetState();
}

class _SpeakTextSheetState extends State<_SpeakTextSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        // Ruang aman saat keyboard terbuka.
        padding: EdgeInsets.fromLTRB(
          DesignTokens.spacePage,
          DesignTokens.spaceMd,
          DesignTokens.spacePage,
          DesignTokens.spacePage + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
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
                controller: _controller,
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
                    Navigator.of(context).pop(_controller.text.trim()),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet "Atur volume": slider 0-100, satu perintah dikirim saat dikonfirmasi.
Future<void> sendVolumeAction(
  BuildContext context,
  WidgetRef ref, {
  required String deviceId,
  int initialLevel = 70,
}) async {
  final l10n = AppLocalizations.of(context);
  var level = initialLevel.clamp(0, 100);
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
    await sendCommandAction(
      context,
      ref,
      deviceId: deviceId,
      type: CommandType.setVolume,
      payload: DeviceCommand.buildPayload(CommandType.setVolume, level: level),
    );
  }
}
