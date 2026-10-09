import '../../../../core/constants/demo_ids.dart';
import '../../../monitoring/data/datasources/fake_detection_data_source.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/entities/detection_filter.dart';
import '../../domain/entities/detection_page.dart';
import '../../domain/repositories/history_repository.dart';
import '../repositories/history_repository_impl.dart';
import 'history_data_source.dart';

/// Sumber data riwayat simulasi untuk mode pengembang.
///
/// Berbagi penyimpanan dengan [FakeDetectionDataSource] supaya Validasi,
/// Riwayat, dan Beranda melihat data yang sama.
class FakeHistoryDataSource implements HistoryDataSource {
  FakeHistoryDataSource(this._detections);

  final FakeDetectionDataSource _detections;

  @override
  Future<DetectionPage> getDetectionsPage({
    required DetectionFilter filter,
    required String deviceName,
    int limit = 25,
    DetectionPageCursor? startAfter,
  }) async {
    final matched =
        _detections.itemsForTest.where(filter.matches).toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    var startIndex = 0;
    if (startAfter != null) {
      final found = matched.indexWhere(
        (item) =>
            item.createdAt.isAtSameMomentAs(startAfter.createdAt) &&
            item.id == startAfter.id,
      );
      if (found < 0) {
        return const DetectionPage(items: <Detection>[]);
      }
      startIndex = found + 1;
    }
    if (startIndex >= matched.length) {
      return const DetectionPage(items: <Detection>[]);
    }
    // Satu ekstra untuk tahu apakah masih ada halaman berikut.
    final endIndex = (startIndex + limit + 1).clamp(0, matched.length);
    final slice = matched.sublist(startIndex, endIndex);
    final hasMore = slice.length > limit;
    final items = hasMore ? slice.sublist(0, limit) : slice;
    return DetectionPage(
      items: items,
      nextCursor: hasMore && items.isNotEmpty
          ? DetectionPageCursor.fromDetection(items.last)
          : null,
    );
  }

  @override
  Future<void> deleteDetection({
    required String deviceId,
    required String detectionId,
    required String? thumbnailId,
  }) async {
    final remaining = _detections.itemsForTest
        .where((item) => item.id != detectionId)
        .toList(growable: false);
    _detections.replaceAll(remaining);
  }

  @override
  Future<void> resetValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) async {
    final updated = [
      for (final item in _detections.itemsForTest)
        if (item.id == detectionId)
          item.withValidationStatus(
            validationStatus: ValidationStatus.pending,
            validatedBy: validatedBy,
            validatedAt: DateTime.now(),
          )
        else
          item,
    ];
    _detections.replaceAll(updated);
  }

  @override
  Future<void> resetAllValidations({
    required String deviceId,
    required String? validatedBy,
  }) async {
    final now = DateTime.now();
    final updated = [
      for (final item in _detections.itemsForTest)
        if (item.validationStatus == ValidationStatus.pending)
          item
        else
          item.withValidationStatus(
            validationStatus: ValidationStatus.pending,
            validatedBy: validatedBy,
            validatedAt: now,
          ),
    ];
    _detections.replaceAll(updated);
  }
}

/// Implementasi [HistoryRepository] untuk data simulasi.
class FakeHistoryRepositoryImpl extends HistoryRepositoryImpl {
  FakeHistoryRepositoryImpl(super.dataSource)
    : super(deviceNameOf: (_) => kDemoDeviceName);
}
