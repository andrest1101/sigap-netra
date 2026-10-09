import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/theme_providers.dart';

/// Layar Pengaturan — identitas visual v3.
///
/// Dibuka lewat avatar (bukan tab). Seksi: Tampilan (segmen tema),
/// Privasi & data (consent eksplisit), Lanjutan (mode pengembang +
/// sumber data), Akun, Tentang (versi dinamis).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacePage,
          DesignTokens.spaceSm,
          DesignTokens.spacePage,
          DesignTokens.spaceSection,
        ),
        children: const [
          _AppearanceSection(),
          _PrivacySection(),
          _AdvancedSection(),
          _AccountSection(),
          _AboutSection(),
        ],
      ),
    );
  }
}

/// Judul seksi kecil dengan gaya v3.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        DesignTokens.spaceSection,
        0,
        DesignTokens.spaceSm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(appThemePreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.settingsDisplayTitle),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppThemePreference>(
            segments: [
              ButtonSegment(
                value: AppThemePreference.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: AppThemePreference.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: AppThemePreference.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.settings_suggest_outlined, size: 18),
              ),
            ],
            selected: {theme},
            onSelectionChanged: (selected) => ref
                .read(appThemePreferenceProvider.notifier)
                .set(selected.single),
            showSelectedIcon: false,
            style: const ButtonStyle(
              shape: WidgetStatePropertyAll(StadiumBorder()),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final uploads = ref.watch(uploadThumbnailsPrivacyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.settingsPrivacyTitle),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsUploadThumbnails),
          subtitle: Text(l10n.settingsUploadThumbnailsBody),
          value: uploads,
          onChanged: (value) async {
            if (value) {
              final accepted = await ConsentSheet.show(
                context,
                title: l10n.settingsUploadThumbnailsConsentTitle,
                message: l10n.settingsUploadThumbnailsConsentBody,
                acceptLabel: l10n.commonYes,
              );
              if (accepted) {
                await ref
                    .read(uploadThumbnailsPrivacyProvider.notifier)
                    .set(true);
              }
            } else {
              await ref
                  .read(uploadThumbnailsPrivacyProvider.notifier)
                  .set(false);
            }
          },
        ),
        Text(
          l10n.settingsRetentionBody,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AdvancedSection extends ConsumerWidget {
  const _AdvancedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final developerMode = ref.watch(developerModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.settingsAdvancedTitle),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.science_outlined),
          title: Text(l10n.settingsDeveloperMode),
          subtitle: Text(
            '${l10n.settingsDeveloperModeBody}\n${l10n.settingsAppliesAfterRestart}',
          ),
          value: developerMode,
          onChanged: (_) => ref.read(developerModeProvider.notifier).toggle(),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storage_outlined),
          title: Text(l10n.settingsSourceTitle),
          subtitle: Text(
            developerMode
                ? l10n.settingsDataSourceSimulation
                : l10n.settingsDataSourceFirebase,
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.settingsAccountTitle),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.person_outline_rounded),
          ),
          title: Text(l10n.settingsSignedInAs),
          subtitle: Text(
            currentUser == null
                ? l10n.settingsSignedOutAsGuest
                : currentUser.email != null && currentUser.email!.isNotEmpty
                ? maskEmail(currentUser.email!)
                : currentUser.uid,
          ),
          trailing: currentUser == null
              ? null
              : TextButton(
                  onPressed: () async {
                    final confirmed = await ConfirmSheet.show(
                      context,
                      title: l10n.settingsSignOutConfirmTitle,
                      message: l10n.settingsSignOutConfirmBody,
                      confirmLabel: l10n.loginSignOut,
                    );
                    if (confirmed) {
                      await ref.read(signOutProvider).call();
                    }
                  },
                  child: Text(l10n.loginSignOut),
                ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.settingsAboutTitle),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(l10n.settingsVersion),
          // Satu-satunya sumber versi tampil. Disarankan `package_info_plus`
          // agar selalu sinkron dengan pubspec (perlu persetujuan penambahan
          // package sesuai AGENTS.md).
          subtitle: const Text(kAppVersionDisplay),
        ),
      ],
    );
  }
}

/// Menampilkan email dalam bentuk tersamar.
///
/// Privasi: UI tidak pernah menampilkan alamat penuh.
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
    return email;
  }

  final local = parts.first;
  final domain = parts.last;
  final visible = local.length <= 2 ? local : local.substring(0, 2);
  return '$visible***@$domain';
}
