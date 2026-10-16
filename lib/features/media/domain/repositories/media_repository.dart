import '../entities/media_thumbnail.dart';

/// Kontrak repository thumbnail pada domain.
///
/// Read-only dari sisi aplikasi: dokumen `media` dibuat device dan dihapus
/// lewat hapus deteksi (`docs/firestore_schema.md` bagian 1). Lookup selalu
/// per `thumbnailId` milik satu perangkat; tidak ada query daftar thumbnail.
abstract interface class MediaRepository {
  /// Memuat satu thumbnail untuk kartu yang sedang terlihat.
  ///
  /// Mengembalikan null bila dokumen belum ada (upload mati) atau sudah
  /// terhapus — pemanggil merender panel "tanpa gambar", bukan error.
  Future<MediaThumbnail?> getThumbnail({
    required String deviceId,
    required String thumbnailId,
  });
}
