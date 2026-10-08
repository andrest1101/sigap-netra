import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';

/// Tampilan empty standar.
///
/// [title] dan [message] boleh dikosongkan untuk memakai teks bawaan. Aksi
/// sekunder lewat [action] dipakai untuk mengarahkan pengguna ke langkah
/// berikutnya, misalnya "Tambah perangkat".
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.title,
    this.message,
    this.action,
    this.icon = Icons.inbox_outlined,
  });

  final String? title;
  final String? message;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              title ?? l10n.stateEmptyTitle,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              message ?? l10n.stateEmptyBody,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: DesignTokens.spaceXl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Tampilan loading standar untuk kasus yang struktur datanya belum diketahui,
/// sehingga skeleton tidak bisa dipakai.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: DesignTokens.spaceLg),
          Text(
            message ?? l10n.stateLoading,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
