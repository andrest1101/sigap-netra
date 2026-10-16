import '../../domain/entities/media_thumbnail.dart';
import '../../domain/repositories/media_repository.dart';
import '../datasources/media_data_source.dart';

/// Implementasi [MediaRepository] di atas kontrak [MediaDataSource].
class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._dataSource);

  final MediaDataSource _dataSource;

  @override
  Future<MediaThumbnail?> getThumbnail({
    required String deviceId,
    required String thumbnailId,
  }) {
    return _dataSource.getThumbnail(
      deviceId: deviceId,
      thumbnailId: thumbnailId,
    );
  }
}

/// Implementasi [MediaRepository] untuk data simulasi.
class FakeMediaRepositoryImpl extends MediaRepositoryImpl {
  FakeMediaRepositoryImpl(super.dataSource);
}
