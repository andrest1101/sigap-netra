import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/mask_email.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/data_source.dart';
import '../providers/settings_providers.dart';

/// Layar Pengaturan — identitas visual v3.
///
/// Dibuka lewat avatar (bukan tab). Header akun tetap hero `primaryContainer`;
/// Privasi, Lanjutan, dan Tentang dikelompokkan menjadi kartu tonal dengan
/// divider inset agar tidak lagi terlihat seperti daftar `ListTile` polos.
/// Tidak ada pemilih tema: aplikasi terang-saja (keputusan produk 2026-10-18).
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
        children: [
          const _AccountHeader(),
          SectionHeader.inset(title: l10n.settingsPrivacyTitle),
          const _PrivacySection(),
          SectionHeader.inset(title: l10n.settingsAdvancedTitle),
          const _AdvancedSection(),
          SectionHeader.inset(title: l10n.settingsAboutTitle),
          const _AboutSection(),
        ],
      ),
    );
  }
}

/// Ikon leading berwarna tonal untuk baris Pengaturan.
///
/// Kotak 36 dp dengan radius 12 dp (bukan lingkaran generik) memberi bobot
/// visual yang sama dengan ikon aksi di Detail perangkat dan Kontrol.
class _SettingsLeading extends StatelessWidget {
  const _SettingsLeading({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.spaceMd),
      ),
      child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
    );
  }
}

const EdgeInsets _settingsTilePadding = EdgeInsets.symmetric(
  horizontal: DesignTokens.spaceLg,
  vertical: DesignTokens.spaceXs,
);

/// Catatan penjelas di dalam kartu seksi.
///
/// Sengaja bukan `ListTile` dan bukan subtitle saklar: teks penjelas panjang
/// mendapat lebar penuh agar tidak terhimpit oleh switch di kanan.
class _SettingsNoteLine extends StatelessWidget {
  const _SettingsNoteLine({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: DesignTokens.spaceSm),
        ],
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
    final uploads = ref.watch(uploadThumbnailsPrivacyProvider);

    return SectionCard(
      divide: true,
      dividerIndent: DesignTokens.spaceLg,
      children: [
        SwitchListTile(
          contentPadding: _settingsTilePadding,
          secondary: const _SettingsLeading(icon: Icons.photo_library_outlined),
          title: Text(l10n.settingsUploadThumbnails),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceLg,
            DesignTokens.spaceMd,
            DesignTokens.spaceLg,
            DesignTokens.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsNoteLine(text: l10n.settingsUploadThumbnailsBody),
              const SizedBox(height: DesignTokens.spaceMd),
              _SettingsNoteLine(
                icon: Icons.schedule_rounded,
                text: l10n.settingsRetentionBody,
              ),
            ],
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
    // Sumber data dibaca dari hasil resolusi `main.dart`, bukan disimpulkan
    // dari toggle: build tanpa Firebase tetap simulasi walau toggle mati.
    final selection = ref.watch(dataSourceSelectionProvider);

    return SectionCard(
      divide: true,
      dividerIndent: DesignTokens.spaceLg,
      children: [
        SwitchListTile(
          contentPadding: _settingsTilePadding,
          secondary: const _SettingsLeading(icon: Icons.science_outlined),
          title: Text(l10n.settingsDeveloperMode),
          value: developerMode,
          onChanged: (_) => ref.read(developerModeProvider.notifier).toggle(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceLg,
            DesignTokens.spaceMd,
            DesignTokens.spaceLg,
            DesignTokens.spaceLg,
          ),
          child: _SettingsNoteLine(
            icon: Icons.restart_alt_rounded,
            text:
                '${l10n.settingsDeveloperModeBody} · '
                '${l10n.settingsAppliesAfterRestart}',
          ),
        ),
        ListTile(
          contentPadding: _settingsTilePadding,
          leading: _SettingsLeading(
            icon: selection.isSimulation
                ? Icons.science_outlined
                : Icons.cloud_done_outlined,
          ),
          title: Text(l10n.settingsSourceTitle),
          subtitle: Text(switch (selection.simulationReason) {
            SimulationReason.developerMode =>
              l10n.settingsSourceSimulationDeveloperMode,
            SimulationReason.firebaseUnavailable =>
              l10n.settingsSourceSimulationFirebaseUnavailable,
            null => l10n.settingsSourceLive,
          }),
        ),
      ],
    );
  }
}

/// Header akun di puncak Pengaturan: avatar inisial + identitas + tombol Keluar.
///
/// Satu-satunya tempat info akun tampil — menggantikan kartu akun yang dulu
/// disebar di 3 tab. Tombol Keluar diletakkan di baris terpisah agar identitas
/// panjang dan text scale 1,3x tidak saling menghimpit.
class _AccountHeader extends ConsumerWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final email = currentUser?.email ?? '';
    final displayName = currentUser?.displayName?.trim() ?? '';
    // Identitas utama: nama tampilan bila ada (pendaftaran / Google),
    // lalu email tersamar, lalu UID untuk tamu anonim.
    final identity = displayName.isNotEmpty
        ? displayName
        : currentUser == null
        ? l10n.settingsSignedOutAsGuest
        : email.isNotEmpty
        ? maskEmail(email)
        : currentUser.uid;
    final secondary = displayName.isNotEmpty && email.isNotEmpty
        ? maskEmail(email)
        : null;
    final initialSource = displayName.isNotEmpty ? displayName : email;
    final initial = initialSource.isNotEmpty
        ? initialSource[0].toUpperCase()
        : '?';
    final onHero = colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: textTheme.labelMedium?.copyWith(color: onHero),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      identity,
                      style: textTheme.bodyLarge?.copyWith(
                        color: onHero,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        style: textTheme.bodySmall?.copyWith(
                          color: onHero.withValues(alpha: 0.78),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (currentUser != null) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Divider(height: 1, color: onHero.withValues(alpha: 0.18)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
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
                style: TextButton.styleFrom(foregroundColor: onHero),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.loginSignOut),
              ),
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

    return SectionCard(
      children: [
        ListTile(
          contentPadding: _settingsTilePadding,
          leading: const _SettingsLeading(icon: Icons.info_outline_rounded),
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
