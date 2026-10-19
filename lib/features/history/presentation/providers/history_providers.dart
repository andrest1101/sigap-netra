import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/retry_policy.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/entities/detection_filter.dart';
import '../../domain/entities/detection_page.dart';
import '../../domain/entities/history_insights.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/history_usecases.dart';

/// Sumber data riwayat aktif.
///
/// Di-override di `main.dart`: `HistoryRepositoryImpl` untuk Firebase, atau
/// `FakeHistoryRepositoryImpl` saat mode pengembang aktif.
final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => throw UnimplementedError(
    'historyRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final getDetectionsPageProvider = Provider<GetDetectionsPage>(
  (ref) => GetDetectionsPage(ref.watch(historyRepositoryProvider)),
);

final deleteDetectionProvider = Provider<DeleteDetection>(
  (ref) => DeleteDetection(ref.watch(historyRepositoryProvider)),
);

final resetValidationProvider = Provider<ResetValidation>(
  (ref) => ResetValidation(ref.watch(historyRepositoryProvider)),
);

final resetAllValidationsProvider = Provider<ResetAllValidations>(
  (ref) => ResetAllValidations(ref.watch(historyRepositoryProvider)),
);

final getHistoryInsightsProvider = Provider<GetHistoryInsights>(
  (ref) => GetHistoryInsights(ref.watch(historyRepositoryProvider)),
);

/// Kunci halaman riwayat: perangkat + filter aktif.
///
/// Batas baris sengaja TIDAK ikut jadi kunci: batas dibaca dari
/// [historyLimitProvider] supaya "Muat lagi" tidak mengganti instance family
/// dan halaman lama tetap tampil selama halaman berikutnya dimuat.
class HistoryPageKey extends Equatable {
  const HistoryPageKey({required this.deviceId, this.type, this.status});

  final String deviceId;
  final DetectionType? type;
  final ValidationStatus? status;

  @override
  List<Object?> get props => [deviceId, type, status];
}

/// Batas baris daftar riwayat; naik 25 setiap "Muat lagi".
///
/// Bertahap, bukan streaming tanpa batas, agar kuota baca Firestore tetap
/// kecil (skema bagian 7.3). Filter yang berubah mereset batas ini dari UI.
class HistoryLimitController extends Notifier<int> {
  @override
  int build() => kHistoryPageSize;

  void increase() => state = state + kHistoryPageSize;

  void reset() => state = kHistoryPageSize;
}

final historyLimitProvider = NotifierProvider<HistoryLimitController, int>(
  HistoryLimitController.new,
);

/// Satu halaman riwayat sesuai filter aktif.
final historyPageProvider = FutureProvider.autoDispose
    .family<DetectionPage, HistoryPageKey>((ref, key) {
      final limit = ref.watch(historyLimitProvider);
      return ref
          .watch(getDetectionsPageProvider)
          .call(
            filter: DetectionFilter(
              type: key.type,
              status: key.status,
              deviceId: key.deviceId,
            ),
            limit: limit,
          );
    }, retry: noRetry);

/// Kunci panel Statistik: perangkat + jendela waktu yang dipilih.
class HistoryInsightsKey extends Equatable {
  const HistoryInsightsKey({required this.deviceId, required this.window});

  final String deviceId;
  final HistoryWindow window;

  @override
  List<Object?> get props => [deviceId, window];
}

/// Ringkasan agregat panel Statistik (Riwayat → segmen Statistik).
///
/// Batas jendela dihitung dari `DateTime.now()` saat provider pertama dibaca;
/// angka ikut disegarkan ketika halaman invalidate provider ini (hapus baris,
/// reset validasi) — bukan timer, supaya tidak ada hitungan yang menganggur.
final historyInsightsProvider = FutureProvider.autoDispose
    .family<HistoryInsights, HistoryInsightsKey>((ref, key) {
      return ref
          .watch(getHistoryInsightsProvider)
          .call(
            deviceId: key.deviceId,
            window: key.window,
            now: DateTime.now(),
          );
    }, retry: noRetry);
