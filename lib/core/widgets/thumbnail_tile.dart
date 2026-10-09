import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Ubin thumbnail 56 dp radius 14 untuk baris daftar.
///
/// Tiga state eksplisit: [ThumbnailTile.image] (bytes JPEG siap tampil),
/// [ThumbnailTile.unavailable] (panel informatif, bukan area kosong), dan
/// [ThumbnailTile.loading] (skeleton kotak). Kondisi "gambar tidak tersedia"
/// selalu berupa teks sesuai identitas v3.
class ThumbnailTile extends StatelessWidget {
  const ThumbnailTile.image({
    required Uint8List this.imageBytes,
    required this.semanticsLabel,
    super.key,
    this.size = DesignTokens.thumbnailSize,
    this.heroTag,
  }) : _mode = _ThumbnailMode.image;

  const ThumbnailTile.unavailable({
    required this.semanticsLabel,
    super.key,
    this.size = DesignTokens.thumbnailSize,
  }) : imageBytes = null,
       heroTag = null,
       _mode = _ThumbnailMode.unavailable;

  const ThumbnailTile.loading({
    super.key,
    this.size = DesignTokens.thumbnailSize,
  }) : imageBytes = null,
       semanticsLabel = null,
       heroTag = null,
       _mode = _ThumbnailMode.loading;

  final Uint8List? imageBytes;
  final String? semanticsLabel;
  final Object? heroTag;
  final double size;
  final _ThumbnailMode _mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(DesignTokens.radiusThumbnail);

    Widget tile;
    switch (_mode) {
      case _ThumbnailMode.loading:
        tile = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: radius,
          ),
        );
      case _ThumbnailMode.unavailable:
        tile = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: radius,
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      case _ThumbnailMode.image:
        final image = ClipRRect(
          borderRadius: radius,
          child: Image.memory(
            imageBytes!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, _, _) => Container(
              width: size,
              height: size,
              color: colorScheme.surfaceContainerHigh,
              child: Icon(
                Icons.broken_image_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
        tile = heroTag == null ? image : Hero(tag: heroTag!, child: image);
    }

    final label = semanticsLabel;
    if (label == null) return tile;
    return Semantics(label: label, image: true, child: tile);
  }
}

enum _ThumbnailMode { image, unavailable, loading }
