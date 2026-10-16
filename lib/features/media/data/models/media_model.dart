import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/media_thumbnail.dart';

/// Nama field Firestore untuk dokumen thumbnail.
///
/// Satu-satunya tempat yang menulis nama field ini di sisi aplikasi, sesuai
/// `docs/firestore_schema.md` bagian 4.3.
abstract final class MediaFields {
  static const String bytes = 'bytes';
  static const String mime = 'mime';
  static const String size = 'size';
  static const String createdAt = 'createdAt';

  /// Satu-satunya nilai `mime` yang diterima rules maupun aplikasi.
  static const String mimeJpeg = 'image/jpeg';
}

/// Pemetaan dokumen Firestore `media/{id}` ke entity domain.
///
/// Defensif seperti [DetectionModel]: mime salah, ukuran lewat batas, atau
/// base64 rusak semuanya menjadi null ("tanpa gambar"), bukan crash — gambar
/// adalah pelengkap validasi, bukan syaratnya.
abstract final class MediaModel {
  static MediaThumbnail? fromData({
    required Map<String, dynamic>? data,
    required String deviceId,
    required String mediaId,
  }) {
    final fields = data ?? const <String, dynamic>{};
    if (fields[MediaFields.mime] != MediaFields.mimeJpeg) return null;
    final size = fields[MediaFields.size];
    if (size is! int || size <= 0 || size > kMaxThumbnailBytes) return null;
    final encoded = fields[MediaFields.bytes];
    if (encoded is! String ||
        encoded.isEmpty ||
        encoded.length > kMaxThumbnailBase64Length) {
      return null;
    }
    late final Uint8List bytes;
    try {
      bytes = base64Decode(encoded);
    } catch (_) {
      return null;
    }
    if (bytes.isEmpty || bytes.length > kMaxThumbnailBytes) return null;
    return MediaThumbnail(
      deviceId: deviceId,
      mediaId: mediaId,
      imageBytes: bytes,
    );
  }
}
