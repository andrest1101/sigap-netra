import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../media/presentation/providers/media_providers.dart';

/// Foto hasil bacaan untuk kartu Validasi (rasio 4:3, ketuk → detail).
///
/// Empat state eksplisit: tanpa-ID (panel "tidak diunggah"), memuat
/// (skeleton 4:3), gagal (panel + "Coba lagi"), dan gambar (Hero 4:3).
/// Gambar tidak pernah menjadi syarat validasi — tombol Cocok/Tidak cocok
/// selalu tersedia di bawah kartu apa pun state foto.
class ValidationPhoto extends ConsumerWidget {
  const ValidationPhoto({
    required this.deviceId,
    required this.thumbnailId,
    required this.detectionId,
    required this.semanticsLabel,
    required this.onOpenDetail,
    super.key,
  });

  final String deviceId;
  final String? thumbnailId;
  final String detectionId;
  final String semanticsLabel;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final id = thumbnailId;

    Widget frame(Widget child) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(color: colorScheme.surfaceContainerHigh, child: child),
      );
    }

    if (id == null || id.isEmpty) {
      return frame(
        _NoPhotoPanel(
          title: l10n.validationNoImageTitle,
          body: l10n.validationNoImageBody,
        ),
      );
    }

    final async = ref.watch(
      thumbnailProvider(ThumbnailQuery(deviceId: deviceId, thumbnailId: id)),
    );
    return async.when(
      loading: () => frame(
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusThumbnail),
            ),
          ),
        ),
      ),
      error: (error, _) => frame(
        _NoPhotoPanel(
          title: l10n.validationNoImageTitle,
          body: _messageFor(context, error),
          action: TextButton.icon(
            onPressed: () => ref.invalidate(
              thumbnailProvider(
                ThumbnailQuery(deviceId: deviceId, thumbnailId: id),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.commonRetry),
          ),
        ),
      ),
      data: (thumbnail) {
        final bytes = thumbnail?.imageBytes;
        if (bytes == null || bytes.isEmpty) {
          return frame(
            _NoPhotoPanel(
              title: l10n.validationNoImageTitle,
              body: l10n.validationNoImageBody,
            ),
          );
        }
        return frame(
          _PhotoImage(
            bytes: bytes,
            heroTag: 'detection-$detectionId',
            semanticsLabel: semanticsLabel,
            onOpenDetail: onOpenDetail,
          ),
        );
      },
    );
  }

  String _messageFor(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is AppFailure) return failureMessage(error, l10n);
    return l10n.stateErrorBody;
  }
}

/// Panel "tanpa foto": ikon + judul + isi + aksi opsional (Coba lagi).
class _NoPhotoPanel extends StatelessWidget {
  const _NoPhotoPanel({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacePage),
      child: Row(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                Text(
                  body,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gambar foto + lencana "ketuk untuk detail" + Hero ke layar detail.
class _PhotoImage extends StatelessWidget {
  const _PhotoImage({
    required this.bytes,
    required this.heroTag,
    required this.semanticsLabel,
    required this.onOpenDetail,
  });

  final Uint8List bytes;
  final Object heroTag;
  final String semanticsLabel;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetail,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, _, _) => Container(
                  color: colorScheme.surfaceContainerHigh,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Positioned(
                right: DesignTokens.spaceSm,
                bottom: DesignTokens.spaceSm,
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceXs),
                    decoration: BoxDecoration(
                      color: colorScheme.scrim.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusBadge,
                      ),
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 16,
                      color: colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
