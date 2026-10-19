import 'package:flutter/material.dart';

import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device_command.dart';

/// Pemetaan perintah → teks/ikon/nada di satu tempat.
///
/// Dipakai tile bersama (`CommandTile`), baris ringkas timeline Perangkat,
/// dan widget pintasan supaya label tidak pernah berbeda antar layar.
String commandTitle(CommandType type, AppLocalizations l10n) {
  return switch (type) {
    CommandType.syncNow => l10n.commandsSyncNow,
    CommandType.speakText => l10n.commandsSpeakText,
    CommandType.setVolume => l10n.commandsSetVolume,
    CommandType.restart => l10n.commandsRestart,
    CommandType.reprovision => l10n.commandsReprovision,
  };
}

/// Ikon stabil per jenis perintah (sama di tile, timeline, dan pintasan).
IconData commandIcon(CommandType type) {
  return switch (type) {
    CommandType.syncNow => Icons.sync_rounded,
    CommandType.speakText => Icons.record_voice_over_rounded,
    CommandType.setVolume => Icons.volume_up_rounded,
    CommandType.restart => Icons.restart_alt_rounded,
    CommandType.reprovision => Icons.qr_code_rounded,
  };
}

/// Label status perintah (ditulis device, app tidak pernah mengubah).
String commandStatusLabel(CommandStatus status, AppLocalizations l10n) {
  return switch (status) {
    CommandStatus.pending => l10n.commandsStatusPending,
    CommandStatus.sent => l10n.commandsStatusSent,
    CommandStatus.acked => l10n.commandsStatusAcked,
    CommandStatus.done => l10n.commandsStatusDone,
    CommandStatus.failed => l10n.commandsStatusFailed,
  };
}

/// Nada status: pending=warn, sent/acked=info, done=ok, failed=bad.
AppStatusTone commandStatusTone(CommandStatus status) {
  return switch (status) {
    CommandStatus.pending => AppStatusTone.warn,
    CommandStatus.sent || CommandStatus.acked => AppStatusTone.info,
    CommandStatus.done => AppStatusTone.ok,
    CommandStatus.failed => AppStatusTone.bad,
  };
}

/// Baris waktu perintah.
///
/// Status `pending` memakai bahasa jujur "Menunggu alat · …" — perintah yang
/// dikirim saat alat offline tetap dieksekusi begitu alat tersambung kembali,
/// jadi tidak pernah diklaim "kedaluwarsa" atau "gagal" oleh app.
String commandTimeLine(
  DeviceCommand command,
  DateTime now,
  AppLocalizations l10n,
) {
  final time = RelativeTime.format(command.createdAt, now, l10n: l10n);
  if (command.status == CommandStatus.pending) {
    return l10n.commandsWaitingForDevice(time);
  }
  final note = command.resultNote;
  return note == null || note.isEmpty ? time : '$time · $note';
}

/// Ringkasan payload yang aman ditampilkan: teks yang diucapkan atau level
/// volume yang diminta. Tidak pernah menyentuh kredensial Wi-Fi.
String? commandPayloadSummary(DeviceCommand command, AppLocalizations l10n) {
  switch (command.type) {
    case CommandType.setVolume:
      final level = command.payload['level'];
      return level is int ? l10n.commandsVolumeValue(level) : null;
    case CommandType.speakText:
      final text = command.payload['text'];
      if (text is! String || text.isEmpty) return null;
      final display = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      return l10n.commandsDetailSpeakText(display);
    case CommandType.syncNow:
    case CommandType.restart:
    case CommandType.reprovision:
      return null;
  }
}
