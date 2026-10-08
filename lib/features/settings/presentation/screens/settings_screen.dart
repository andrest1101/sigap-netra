import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/theme_providers.dart';

/// Layar Pengaturan.
///
/// Memanfaatkan preferensi lokal untuk demo; prinsip privasi soal thumbnail
/// tetap ditampilkan sebagai persetujuan eksplisit.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(appThemePreferenceProvider);
    final developerMode = ref.watch(developerModeProvider);
    final uploadThumbnails = ref.watch(uploadThumbnailsPrivacyProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(title: l10n.settingsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              children: [
                Text(
                  l10n.settingsAppearance,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                DropdownMenu<AppThemePreference>(
                  initialSelection: theme,
                  label: Text(l10n.settingsTitle),
                  expandedInsets: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value != null) {
                      ref.read(appThemePreferenceProvider.notifier).set(value);
                    }
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: AppThemePreference.system,
                      label: l10n.settingsThemeSystem,
                    ),
                    DropdownMenuEntry(
                      value: AppThemePreference.light,
                      label: l10n.settingsThemeLight,
                    ),
                    DropdownMenuEntry(
                      value: AppThemePreference.dark,
                      label: l10n.settingsThemeDark,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceXl),
                Text(
                  l10n.settingsPrivacy,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsUploadThumbnails),
                  subtitle: Text(l10n.settingsUploadThumbnailsBody),
                  value: uploadThumbnails,
                  onChanged: (value) async {
                    if (value) {
                      final accepted = await _showThumbnailConsent(context);
                      if (accepted) {
                        ref
                            .read(uploadThumbnailsPrivacyProvider.notifier)
                            .set(true);
                      }
                    } else {
                      ref
                          .read(uploadThumbnailsPrivacyProvider.notifier)
                          .set(false);
                    }
                  },
                ),
                const SizedBox(height: DesignTokens.spaceXl),
                Text(
                  l10n.settingsDeveloperMode,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsDeveloperMode),
                  subtitle: Text(l10n.settingsDeveloperModeBody),
                  value: developerMode,
                  onChanged: (_) =>
                      ref.read(developerModeProvider.notifier).toggle(),
                ),
                const SizedBox(height: DesignTokens.spaceXl),
                Text(
                  l10n.settingsAccount,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.settingsSignedInAs),
                  subtitle: Text(currentUser?.email ?? '-'),
                  trailing: TextButton(
                    onPressed: () async {
                      final confirmed = await _showSignOutConfirmation(context);
                      if (confirmed) {
                        await ref.read(signOutProvider).call();
                      }
                    },
                    child: Text(l10n.loginSignOut),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXl),
                Text(
                  l10n.settingsAbout,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsVersion),
                  subtitle: const Text('1.0.0+1'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showSignOutConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.settingsSignOutConfirmTitle),
            content: Text(l10n.settingsSignOutConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.loginSignOut),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showThumbnailConsent(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.settingsUploadThumbnailsConsentTitle),
            content: Text(l10n.settingsUploadThumbnailsConsentBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.commonYes),
              ),
            ],
          ),
        ) ??
        false;
  }
}
