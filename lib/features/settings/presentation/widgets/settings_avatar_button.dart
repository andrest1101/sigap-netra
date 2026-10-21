import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Avatar Pengaturan di app bar empat tab akar.
///
/// Inisial pengguna (nama tampilan, lalu email) menjadi identitas yang selalu
/// terlihat; lencana gear kecil di sudut menegaskan bahwa avatar adalah pintu
/// Pengaturan. Dibuka via `push` agar tombol kembali punya stack untuk pulang.
class SettingsAvatarButton extends ConsumerWidget {
  const SettingsAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final initial = _initialFor(user?.displayName, user?.email);

    return IconButton(
      key: const ValueKey('settings-avatar'),
      onPressed: () => const SettingsPath().push(context),
      tooltip: l10n.settingsOpenTitle,
      style: IconButton.styleFrom(
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
        fixedSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
        padding: EdgeInsets.zero,
      ),
      icon: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: initial == null
                  ? Icon(
                      Icons.person_outline_rounded,
                      size: 19,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : Text(
                      initial,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  size: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inisial aman untuk nama berhuruf non-ASCII (ambil code point pertama).
  static String? _initialFor(String? displayName, String? email) {
    final name = displayName?.trim() ?? '';
    final source = name.isNotEmpty ? name : email?.trim() ?? '';
    if (source.isEmpty) return null;
    return String.fromCharCode(source.runes.first).toUpperCase();
  }
}
