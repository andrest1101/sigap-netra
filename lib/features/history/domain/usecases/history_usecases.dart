import '../../../monitoring/domain/entities/detection.dart';
import '../entities/detection_filter.dart';
import '../entities/detection_page.dart';
import '../entities/history_insights.dart';
import '../repositories/history_repository.dart';

/// Kontrak pengambilan halaman riwayat.
class GetDetectionsPage {
  const GetDetectionsPage(this._repository);

  final HistoryRepository _repository;

  Future<DetectionPage> call({
    required DetectionFilter filter,
    int limit = 25,
    DetectionPageCursor? startAfter,
  }) {
    return _repository.getDetectionsPage(
      filter: filter,
      limit: limit,
      startAfter: startAfter,
    );
  }
}

/// Kontrak penghapusan pembacaan beserta media terkait.
class DeleteDetection {
  const DeleteDetection(this._repository);

  final HistoryRepository _repository;

  Future<void> call({
    required String deviceId,
    required String detectionId,
    required String? thumbnailId,
  }) {
    return _repository.deleteDetection(
      deviceId: deviceId,
      detectionId: detectionId,
      thumbnailId: thumbnailId,
    );
  }
}

/// Kontrak pembatalan validasi dari riwayat.
class ResetValidation {
  const ResetValidation(this._repository);

  final HistoryRepository _repository;

  Future<void> call({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) {
    return _repository.resetValidation(
      deviceId: deviceId,
      detectionId: detectionId,
      validatedBy: validatedBy,
    );
  }
}

/// Kontrak reset seluruh validasi satu perangkat (batch + konfirmasi di UI).
class ResetAllValidations {
  const ResetAllValidations(this._repository);

  final HistoryRepository _repository;

  Future<void> call({required String deviceId, required String? validatedBy}) {
    return _repository.resetAllValidations(
      deviceId: deviceId,
      validatedBy: validatedBy,
    );
  }
}

/// Kontrak ringkasan agregat untuk panel Statistik Riwayat.
///
/// Memakai `count()` (agregasi server) untuk setiap batang grafik dan setiap
/// status validasi — bukan mengunduh dokumen (`docs/firestore_schema.md` §7.3
/// poin 3 dan 5). Hitungan dijalankan paralel: jendela 7 hari = 17 hitungan,
/// 4 minggu = 11 hitungan; hitungan agregat ditagih per 1.000 entri indeks
/// sehingga praktis 1 baca per hitungan.
class GetHistoryInsights {
  const GetHistoryInsights(this._repository);

  final HistoryRepository _repository;

  Future<HistoryInsights> call({
    required String deviceId,
    required HistoryWindow window,
    required DateTime now,
  }) async {
    final ranges = insightWindowRanges(now: now, window: window);
    final windowStart = ranges.first.start;
    final windowEnd = ranges.last.end;

    DetectionFilter bucket(InsightRange range, DetectionType type) =>
        DetectionFilter(
          deviceId: deviceId,
          type: type,
          since: range.start,
          before: range.end,
        );

    DetectionFilter status(ValidationStatus value) => DetectionFilter(
      deviceId: deviceId,
      status: value,
      since: windowStart,
      before: windowEnd,
    );

    // Urutan daftar ini dipakai kembali saat menyusun hasil: dua hitungan per
    // batang (uang, teks) lalu tiga hitungan status di jendela yang sama.
    final counts = await Future.wait<int>([
      for (final range in ranges) ...[
        _repository.countDetections(filter: bucket(range, DetectionType.money)),
        _repository.countDetections(filter: bucket(range, DetectionType.text)),
      ],
      _repository.countDetections(filter: status(ValidationStatus.match)),
      _repository.countDetections(filter: status(ValidationStatus.mismatch)),
      _repository.countDetections(filter: status(ValidationStatus.pending)),
    ]);

    final buckets = <InsightBucket>[
      for (var i = 0; i < ranges.length; i++)
        InsightBucket(
          range: ranges[i],
          money: counts[i * 2],
          text: counts[i * 2 + 1],
        ),
    ];
    final statusOffset = ranges.length * 2;

    return HistoryInsights(
      window: window,
      buckets: buckets,
      matched: counts[statusOffset],
      mismatched: counts[statusOffset + 1],
      pending: counts[statusOffset + 2],
    );
  }
}
