import 'dart:async';

import '../../../../core/constants/demo_ids.dart';
import '../../../monitoring/data/datasources/fake_detection_data_source.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/repositories/validation_repository.dart';
import '../../domain/repositories/validation_summary.dart';
import '../repositories/validation_repository_impl.dart';
import 'validation_data_source.dart';

/// Sumber data validasi simulasi untuk mode pengembang.
///
/// Berbagi penyimpanan dengan [FakeDetectionDataSource] supaya Validasi,
/// Riwayat, dan Beranda melihat data yang sama. Tulis memakai aturan yang
/// sama dengan Firestore: hanya tiga field validasi, dan jejak pembatalan
/// tidak dihapus (`validatedBy`/`validatedAt` tetap terisi saat undo).
class FakeValidationDataSource implements ValidationDataSource {
  FakeValidationDataSource(this._detections);

  final FakeDetectionDataSource _detections;

  List<Detection> get _items => _detections.itemsForTest;

  @override
  Stream<List<Detection>> watchPendingDetections({
    required String deviceId,
    required String deviceName,
    int limit = 20,
  }) {
    return _detections
        .watchLatestDetections(
          deviceId: deviceId,
          deviceName: deviceName,
          limit: 1000,
        )
        .map(
          (items) => items
              .where(
                (item) => item.validationStatus == ValidationStatus.pending,
              )
              .take(limit)
              .toList(growable: false),
        );
  }

  @override
  Future<ValidationSummary> getValidationSummary({
    required String deviceId,
  }) async {
    if (deviceId != kDemoDeviceId) return const ValidationSummary.empty();
    var matches = 0;
    var mismatches = 0;
    var pending = 0;
    for (final item in _items) {
      switch (item.validationStatus) {
        case ValidationStatus.match:
          matches++;
        case ValidationStatus.mismatch:
          mismatches++;
        case ValidationStatus.pending:
          pending++;
      }
    }
    return ValidationSummary(
      matches: matches,
      mismatches: mismatches,
      pending: pending,
    );
  }

  @override
  Future<void> submitValidation({
    required String deviceId,
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  }) async {
    assert(
      status == ValidationStatus.match || status == ValidationStatus.mismatch,
      'submitValidation hanya untuk match/mismatch; pending memakai undoValidation.',
    );
    _update(detectionId, status, validatedBy);
  }

  @override
  Future<void> undoValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) async {
    // validatedBy tetap disimpan sebagai jejak pembatalan; tidak boleh
    // dikosongkan (skema bagian 4.2).
    _update(detectionId, ValidationStatus.pending, validatedBy);
  }

  void _update(
    String detectionId,
    ValidationStatus status,
    String? validatedBy,
  ) {
    final updated = [
      for (final item in _items)
        if (item.id == detectionId)
          item.withValidationStatus(
            validationStatus: status,
            validatedBy: validatedBy,
            validatedAt: DateTime.now(),
          )
        else
          item,
    ];
    _detections.replaceAll(updated);
  }
}

/// Implementasi [ValidationRepository] untuk data simulasi.
class FakeValidationRepositoryImpl extends ValidationRepositoryImpl {
  FakeValidationRepositoryImpl(super.dataSource)
    : super(deviceNameOf: (_) => kDemoDeviceName);
}
