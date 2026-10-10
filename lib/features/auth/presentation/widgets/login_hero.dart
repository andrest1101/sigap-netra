import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Kepala brand layar masuk: lensa + nama aplikasi + kartu 3 poin.
///
/// Menggantikan header polos (ikon + judul + satu baris subtitle): tiga poin
/// menjelaskan apa yang dilakukan aplikasi sebelum pengguna memasukkan
/// kredensial — pola aplikasi profesional (nilai dulu, form kemudian).
class LoginHero extends StatelessWidget {
  const LoginHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Semantics(
          header: true,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const LensRing(diameter: 88, mode: LensRingMode.focusing),
              Container(
                width: 52,
                height: 52,
                decoration: ShapeDecoration(
                  color: colorScheme.primaryContainer,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceLg),
        Text(
          l10n.appTitle,
          style: textTheme.headlineSmall?.copyWith(
            letterSpacing: DesignTokens.letterSpacingBrand,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          l10n.loginWelcomeSubtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceLg),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroPoint(
                icon: Icons.payments_rounded,
                text: l10n.loginHeroPointMoney,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              _HeroPoint(
                icon: Icons.fact_check_rounded,
                text: l10n.loginHeroPointValidate,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              _HeroPoint(
                icon: Icons.privacy_tip_outlined,
                text: l10n.loginHeroPointPrivate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceSm),
          decoration: ShapeDecoration(
            color: colorScheme.primaryContainer,
            shape: const CircleBorder(),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(child: Text(text, style: textTheme.bodyMedium)),
      ],
    );
  }
}

/// Pembatas "atau" dengan dua garis — dipakai antara tombol utama dan
/// tombol alternatif (Google, tamu).
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: Text(
            l10n.loginOrDivider,
            style: textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
