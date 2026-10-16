import '../../domain/entities/media_thumbnail.dart';

/// Kontrak sumber data thumbnail pada data layer.
///
/// Implementasi produksi memakai Firestore (lookup satu dokumen); implementasi
/// simulasi memakai dummy aset 100rb + gambar prosedural kecil.
abstract interface class MediaDataSource {
  /// Memuat satu thumbnail lewat `media/{thumbnailId}`.
  ///
  /// Null bila dokumen tidak ada (upload mati / sudah terhapus) atau isinya
  /// tidak valid — pemanggil merender panel "tanpa gambar", bukan error.
  Future<MediaThumbnail?> getThumbnail({
    required String deviceId,
    required String thumbnailId,
  });
}
