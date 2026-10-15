import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/retry_policy.dart';
import '../../domain/entities/detection.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../domain/usecases/watch_detections.dart';

/// Sumber data pembacaan aktif.
///
/// Di-override di `main.dart`: `DetectionRepositoryImpl` untuk Firebase, atau
/// `FakeDetectionRepositoryImpl` saat mode pengembang aktif.
final detectionRepositoryProvider = Provider<DetectionRepository>(
  (ref) => throw UnimplementedError(
    'detectionRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final watchLatestDetectionsProvider = Provider<WatchLatestDetections>(
  (ref) => WatchLatestDetections(ref.watch(detectionRepositoryProvider)),
);

/// Pembacaan terbaru satu perangkat (Beranda + Validasi + Riwayat).
///
/// Family memakai record Dart `(deviceId, limit)`; record punya kesetaraan
/// struktural sehingga kunci family stabil antar rebuild.
final latestDetectionsProvider = StreamProvider.autoDispose
    .family<List<Detection>, ({String deviceId, int limit})>(
      (ref, query) => ref
          .watch(watchLatestDetectionsProvider)
          .call(deviceId: query.deviceId, limit: query.limit),
      retry: noRetry,
    );

/// Satu pembacaan realtime untuk layar detail: satu dokumen, bukan halaman.
final detectionProvider = StreamProvider.autoDispose
    .family<Detection?, ({String deviceId, String detectionId})>(
      (ref, query) => ref
          .watch(detectionRepositoryProvider)
          .watchDetection(
            deviceId: query.deviceId,
            detectionId: query.detectionId,
          ),
      retry: noRetry,
    );
