import '../entities/media_thumbnail.dart';
import '../repositories/media_repository.dart';

/// Use case pemuatan satu thumbnail untuk kartu yang terlihat.
///
/// Tipis seperti use case lain: validasi input kosong di sini supaya data
/// layer tidak perlu menebak maksud pemanggil.
class GetThumbnail {
  const GetThumbnail(this._repository);

  final MediaRepository _repository;

  Future<MediaThumbnail?> call({
    required String deviceId,
    required String thumbnailId,
  }) {
    if (deviceId.isEmpty || thumbnailId.isEmpty) return Future.value(null);
    return _repository.getThumbnail(
      deviceId: deviceId,
      thumbnailId: thumbnailId,
    );
  }
}
