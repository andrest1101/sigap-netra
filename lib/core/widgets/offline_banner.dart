import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';

/// Banner yang muncul saat data yang ditampilkan berasal dari cache lokal.
///
/// Data bertanda `isFromCache` pada snapshot Firestore, jadi saat banner ini
/// tampil berarti angka validasi, status online, dan ringkasan bisa saja sudah
/// tidak terbaru. Jangan sembunyikan kondisi ini karena dapat membuat pengguna
/// mengambil keputusan validasi yang keliru.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.isFromCache = true});

  /// Sumber data memang dari cache.
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceSm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 18,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.offlineBannerTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    isFromCache
                        ? l10n.offlineBannerCached
                        : l10n.offlineBannerBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
