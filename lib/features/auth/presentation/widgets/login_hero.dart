import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../core/widgets/logo_mark.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Kepala brand layar masuk: lensa + nama aplikasi + kartu 3 poin.
///
/// Menggantikan header polos (ikon + judul + satu baris subtitle): tiga poin
/// menjelaskan apa yang dilakukan aplikasi sebelum pengguna memasukkan
/// kredensial — pola aplikasi profesional (nilai dulu, form kemudian).
class LoginHero extends StatelessWidget {
  const LoginHero({super.key, this.compact = false});

  /// Varian ringkas untuk layar pendek / teks 1,3x. Tetap mempertahankan
  /// tiga janji produk, tetapi cincin, jarak, dan padding kartu mengecil agar
  /// CTA dan tautan daftar tidak terdorong jauh ke bawah lipatan.
  final bool compact;

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
              LensRing(
                diameter: compact ? 64 : 88,
                mode: LensRingMode.focusing,
              ),
              // Mark merek di tengah cincin fokus — identitas SIGAP-NETRA,
              // bukan ikon lensa generik.
              LogoMark(size: compact ? 38 : 52),
            ],
          ),
        ),
        SizedBox(height: compact ? DesignTokens.spaceMd : DesignTokens.spaceLg),
        Text(
          l10n.appTitle,
          style: textTheme.headlineSmall?.copyWith(
            letterSpacing: DesignTokens.letterSpacingBrand,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? DesignTokens.spaceXs : DesignTokens.spaceSm),
        Text(
          l10n.loginWelcomeSubtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? DesignTokens.spaceMd : DesignTokens.spaceLg),
        Container(
          padding: EdgeInsets.all(
            compact ? DesignTokens.spaceMd : DesignTokens.spaceLg,
          ),
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
                compact: compact,
              ),
              SizedBox(
                height: compact ? DesignTokens.spaceXs : DesignTokens.spaceSm,
              ),
              _HeroPoint(
                icon: Icons.fact_check_rounded,
                text: l10n.loginHeroPointValidate,
                compact: compact,
              ),
              SizedBox(
                height: compact ? DesignTokens.spaceXs : DesignTokens.spaceSm,
              ),
              _HeroPoint(
                icon: Icons.privacy_tip_outlined,
                text: l10n.loginHeroPointPrivate,
                compact: compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({
    required this.icon,
    required this.text,
    required this.compact,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconPadding = compact ? DesignTokens.spaceXs : DesignTokens.spaceSm;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: ShapeDecoration(
            color: colorScheme.primaryContainer,
            shape: const CircleBorder(),
          ),
          child: Icon(
            icon,
            size: compact ? 14 : 16,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        SizedBox(width: compact ? DesignTokens.spaceSm : DesignTokens.spaceMd),
        Expanded(
          child: Text(
            text,
            style: compact ? textTheme.bodySmall : textTheme.bodyMedium,
          ),
        ),
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
