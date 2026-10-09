import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../monitoring/data/models/detection_model.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/repositories/validation_summary.dart';
import 'validation_data_source.dart';

/// Sumber data validasi berbasis Firestore.
///
/// Tulis app dibatasi pada `validationStatus`, `validatedBy`, `validatedAt`
/// memakai `update()` dengan map dari [DetectionModel.validationUpdate].
/// Akurasi memakai agregasi `count()` per status sesuai skema bagian 7.3,
/// bukan mengunduh dokumen.
class FirestoreValidationDataSource implements ValidationDataSource {
  FirestoreValidationDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _detections(String deviceId) {
    return _firestore.collection(detectionsCollectionPath(deviceId));
  }

  @override
  Stream<List<Detection>> watchPendingDetections({
    required String deviceId,
    required String deviceName,
    int limit = 20,
  }) {
    return _detections(deviceId)
        .where(
          DetectionFields.validationStatus,
          isEqualTo: DetectionFields.statusPending,
        )
        .orderBy(DetectionFields.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DetectionModel.fromDocument(
                  doc,
                  deviceId: deviceId,
                  deviceName: deviceName,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<ValidationSummary> getValidationSummary({
    required String deviceId,
  }) async {
    final base = _detections(deviceId);
    final results = await Future.wait([
      base
          .where(
            DetectionFields.validationStatus,
            isEqualTo: DetectionFields.statusMatch,
          )
          .count()
          .get(),
      base
          .where(
            DetectionFields.validationStatus,
            isEqualTo: DetectionFields.statusMismatch,
          )
          .count()
          .get(),
      base
          .where(
            DetectionFields.validationStatus,
            isEqualTo: DetectionFields.statusPending,
          )
          .count()
          .get(),
    ]);
    return ValidationSummary(
      matches: results[0].count ?? 0,
      mismatches: results[1].count ?? 0,
      pending: results[2].count ?? 0,
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
    await _firestore
        .doc(detectionDocPath(deviceId, detectionId))
        .update(
          DetectionModel.validationUpdate(
            status: status,
            validatedBy: validatedBy,
          ),
        );
  }

  @override
  Future<void> undoValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) async {
    // validatedBy tetap disimpan sebagai jejak pembatalan; tidak boleh
    // dikosongkan (skema bagian 4.2).
    await _firestore
        .doc(detectionDocPath(deviceId, detectionId))
        .update(
          DetectionModel.validationUpdate(
            status: ValidationStatus.pending,
            validatedBy: validatedBy,
          ),
        );
  }
}
