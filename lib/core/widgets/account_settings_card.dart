import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../router/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../utils/mask_email.dart';

/// Kartu "Akun & Pengaturan" di dalam body tiap tab.
///
/// Pengganti avatar menggantung di app bar: kartu ini selalu terlihat di bawah
/// konten utama, menampilkan inisial + email tersamar + tombol pil
/// "Pengaturan". Route `/pengaturan` tidak berubah.
class AccountSettingsCard extends ConsumerWidget {
  const AccountSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final subtitle = user == null
        ? l10n.settingsSignedOutAsGuest
        : email.isNotEmpty
        ? maskEmail(email)
        : user.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceSection,
        DesignTokens.spacePage,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initial,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsAccountTitle,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            FilledButton.tonalIcon(
              onPressed: () => const SettingsPath().go(context),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(l10n.settingsTitle),
            ),
          ],
        ),
      ),
    );
  }
}
