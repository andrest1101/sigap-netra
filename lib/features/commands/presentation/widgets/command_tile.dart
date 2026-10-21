import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device_command.dart';
import 'command_presentation.dart';

/// Tile perintah bersama: dipakai layar Kontrol jarak jauh dan tab Perintah
/// di Log koneksi sehingga tampilan dan bahasa keduanya identik.
///
/// Baris kedua memakai [commandTimeLine] (pending → "Menunggu alat · …");
/// ringkasan payload (teks/level) ditampilkan sebagai baris ketiga bila ada.
class CommandTile extends StatelessWidget {
  const CommandTile({
    required this.command,
    required this.now,
    super.key,
    this.embedded = false,
  });

  final DeviceCommand command;
  final DateTime now;

  /// Bila true, tile tidak menggambar kartu sendiri dan dipakai sebagai anak
  /// [SectionCard] (Riwayat perintah). Varian bawaan tetap kartu mandiri untuk
  /// tab Perintah di Log koneksi.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final payloadSummary = commandPayloadSummary(command, l10n);
    final icon = Container(
      padding: const EdgeInsets.all(DesignTokens.spaceSm),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerHigh,
        shape: const CircleBorder(),
      ),
      child: Icon(commandIcon(command.type), size: 20),
    );
    final title = Text(
      commandTitle(command.type, l10n),
      style: textTheme.bodyMedium,
    );
    final timeLine = Text(
      commandTimeLine(command, now, l10n),
      style: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      // Riwayat memakai lebar penuh (status pindah ke baris judul), jadi
      // catatan hasil yang panjang tidak perlu dipotong di 2 baris.
      maxLines: embedded ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
    final payload = payloadSummary == null
        ? null
        : Text(
            payloadSummary,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
    final status = StatusChip(
      label: commandStatusLabel(command.status, l10n),
      tone: commandStatusTone(command.status),
      isDense: true,
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: DesignTokens.spaceSm),
                      status,
                    ],
                  ),
                  const SizedBox(height: 2),
                  timeLine,
                  if (payload != null) ...[
                    const SizedBox(height: DesignTokens.spaceXs),
                    payload,
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                timeLine,
                if (payload != null) ...[
                  const SizedBox(height: DesignTokens.spaceXs),
                  payload,
                ],
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          status,
        ],
      ),
    );
  }
}
