import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/retry_policy.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/repositories/validation_repository.dart';
import '../../domain/repositories/validation_summary.dart';
import '../../domain/usecases/validation_usecases.dart';

/// Sumber data validasi aktif.
///
/// Di-override di `main.dart`: `ValidationRepositoryImpl` untuk Firebase, atau
/// `FakeValidationRepositoryImpl` saat mode pengembang aktif.
final validationRepositoryProvider = Provider<ValidationRepository>(
  (ref) => throw UnimplementedError(
    'validationRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final watchPendingDetectionsProvider = Provider<WatchPendingDetections>(
  (ref) => WatchPendingDetections(ref.watch(validationRepositoryProvider)),
);

final getValidationSummaryProvider = Provider<GetValidationSummary>(
  (ref) => GetValidationSummary(ref.watch(validationRepositoryProvider)),
);

final submitValidationProvider = Provider<SubmitValidation>(
  (ref) => SubmitValidation(ref.watch(validationRepositoryProvider)),
);

final undoValidationProvider = Provider<UndoValidation>(
  (ref) => UndoValidation(ref.watch(validationRepositoryProvider)),
);

/// Antrean validasi satu perangkat: hanya pembacaan berstatus `pending`,
/// terbaru dulu.
final pendingDetectionsProvider = StreamProvider.autoDispose
    .family<List<Detection>, String>(
      (ref, deviceId) =>
          ref.watch(watchPendingDetectionsProvider).call(deviceId: deviceId),
      retry: noRetry,
    );

/// Ringkasan validasi manusia satu perangkat (`matches`/`mismatches`/`pending`).
///
/// Dihitung ulang setiap antrean pending berubah (validasi atau pembatalan
/// dari layar mana pun), sehingga badge Beranda ikut sinkron tanpa polling.
final validationSummaryProvider = FutureProvider.autoDispose
    .family<ValidationSummary, String>((ref, deviceId) {
      ref.watch(pendingDetectionsProvider(deviceId));
      return ref.watch(getValidationSummaryProvider).call(deviceId: deviceId);
    }, retry: noRetry);
