import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Thumbnail satu pembacaan, dimuat lazily per `thumbnailId`.
///
/// Mengikuti `docs/firestore_schema.md` bagian 4.3: hanya lookup satu dokumen
/// `media/{thumbnailId}`, tidak pernah query daftar. Bytes selalu JPEG kecil
/// (<= 60 KB sebelum base64) dan disimpan di memori sesi saja.
class MediaThumbnail extends Equatable {
  const MediaThumbnail({
    required this.deviceId,
    required this.mediaId,
    required this.imageBytes,
  });

  final String deviceId;
  final String mediaId;
  final Uint8List imageBytes;

  @override
  List<Object?> get props => [deviceId, mediaId, imageBytes];
}
