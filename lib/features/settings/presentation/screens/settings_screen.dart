import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/mask_email.dart';
import '../../../../core/widgets/back_app_bar.dart';
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
      appBar: BackAppBar(
        title: Text(l10n.settingsTitle),
        fallbackRoute: AppRoutes.home,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacePage,
          DesignTokens.spaceMd,
          DesignTokens.spacePage,
          DesignTokens.spaceSection,
        ),
        children: const [
          _AccountHeader(),
          _AppearanceSection(),
          _PrivacySection(),
          _AdvancedSection(),
          _AboutSection(),
        ],
      ),
    );
  }
}

/// Judul seksi kecil dengan gaya v3.
///
/// [isFirst]: seksi pertama setelah header akun — tanpa jarak atas agar
/// tidak dobel dengan padding ListView.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.isFirst = false});

  final String text;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        isFirst ? DesignTokens.spaceMd : DesignTokens.spaceSection,
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
        _SectionTitle(l10n.settingsDisplayTitle, isFirst: true),
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
          // Satu baris alir (bukan '\n' paksa): tinggi baris mengikuti
          // konten, tidak memaksa 3 baris kosong.
          subtitle: Text(
            '${l10n.settingsDeveloperModeBody} · ${l10n.settingsAppliesAfterRestart}',
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

/// Header akun di puncak Pengaturan: avatar inisial + email tersamar +
/// tombol Keluar.
///
/// Satu-satunya tempat info akun tampil — menggantikan kartu akun yang dulu
/// disebar di 3 tab. Tidak memakai judul seksi agar tidak dobel spasi atas.
class _AccountHeader extends ConsumerWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final email = currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final subtitle = currentUser == null
        ? l10n.settingsSignedOutAsGuest
        : email.isNotEmpty
        ? maskEmail(email)
        : currentUser.uid;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.surface,
            child: Text(
              initial,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
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
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                Text(
                  subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (currentUser != null) ...[
            const SizedBox(width: DesignTokens.spaceSm),
            TextButton(
              onPressed: () async {
                final confirmed = await ConfirmSheet.show(
                  context,
                  title: l10n.settingsSignOutConfirmTitle,
                  message: l10n.settingsSignOutConfirmBody,
                  confirmLabel: l10n.loginSignOut,
                );
                if (confirmed && context.mounted) {
                  await ref.read(signOutProvider).call();
                }
              },
              child: Text(l10n.loginSignOut),
            ),
          ],
        ],
      ),
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
