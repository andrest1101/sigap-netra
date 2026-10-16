import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/retry_policy.dart';
import '../../domain/entities/media_thumbnail.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/usecases/get_thumbnail.dart';

/// Sumber thumbnail aktif.
///
/// Di-override di `main.dart`: `MediaRepositoryImpl` untuk Firebase, atau
/// `FakeMediaRepositoryImpl` saat mode pengembang aktif.
final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => throw UnimplementedError(
    'mediaRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final getThumbnailProvider = Provider<GetThumbnail>(
  (ref) => GetThumbnail(ref.watch(mediaRepositoryProvider)),
);

/// Kunci lookup thumbnail: perangkat + ID dokumen `media`.
///
/// `thumbnailId` milik satu deteksi — bukan koleksi — sehingga family dua
/// string ini stabil dan aman untuk cache Riverpod per kartu.
class ThumbnailQuery extends Equatable {
  const ThumbnailQuery({required this.deviceId, required this.thumbnailId});

  final String deviceId;
  final String thumbnailId;

  @override
  List<Object?> get props => [deviceId, thumbnailId];
}

/// Satu thumbnail untuk kartu yang terlihat.
///
/// `autoDispose`: bytes hanya hidup selama kartu tampil; keluar layar =
/// dibuang dari memori (skema 4.3: cache memori sesi, bukan disk).
final thumbnailProvider = FutureProvider.autoDispose
    .family<MediaThumbnail?, ThumbnailQuery>(
      (ref, query) => ref
          .watch(getThumbnailProvider)
          .call(deviceId: query.deviceId, thumbnailId: query.thumbnailId),
      retry: noRetry,
    );
