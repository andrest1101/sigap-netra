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
  const CommandTile({required this.command, required this.now, super.key});

  final DeviceCommand command;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final payloadSummary = commandPayloadSummary(command, l10n);

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
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            decoration: ShapeDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: const CircleBorder(),
            ),
            child: Icon(commandIcon(command.type), size: 20),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commandTitle(command.type, l10n),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  commandTimeLine(command, now, l10n),
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (payloadSummary != null) ...[
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    payloadSummary,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          StatusChip(
            label: commandStatusLabel(command.status, l10n),
            tone: commandStatusTone(command.status),
            isDense: true,
          ),
        ],
      ),
    );
  }
}
