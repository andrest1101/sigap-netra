import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';

/// Layar sementara untuk fitur yang domain-nya belum dikerjakan.
///
/// Menggantikan layar kosong tanpa pesan sehingga struktur navigasi dan bottom
/// nav dapat dicoba sekarang. Layar ini akan dihapus satu per satu mengikuti
/// `progress.md`; jangan jadikan ini tempat menaruh logika fitur.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.screenKey,
    required this.icon,
    super.key,
    this.titleKey,
  });

  /// Pengenal layar, dipakai untuk membedakan layar saat debug dan test.
  final String screenKey;

  final IconData icon;

  /// Key l10n untuk judul. Null memakai teks "Fitur sedang dikerjakan".
  final String? titleKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final title = titleKey == null
        ? 'Fitur sedang dikerjakan'
        : _resolveTitle(l10n, titleKey!);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: colorScheme.primary),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                'Layar ini belum diimplementasikan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolusi judul dari key l10n yang diberikan di [titleKey].
  static String _resolveTitle(AppLocalizations l10n, String key) =>
      switch (key) {
        'loginTitle' => l10n.loginTitle,
        'validationTitle' => l10n.validationTitle,
        'historyTitle' => l10n.historyTitle,
        'historyDetailTitle' => l10n.historyDetailTitle,
        'devicesTitle' => l10n.devicesTitle,
        'deviceDetailTitle' => l10n.deviceDetailTitle,
        'provisioningTitle' => l10n.provisioningTitle,
        'commandsTitle' => l10n.commandsTitle,
        'settingsTitle' => l10n.settingsTitle,
        'eventsTitle' => l10n.eventsTitle,
        _ => l10n.appTitle,
      };
}
