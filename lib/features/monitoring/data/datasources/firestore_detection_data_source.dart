import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/detection_model.dart';
import 'detection_data_source.dart';
import '../../domain/entities/detection.dart';

/// Sumber data pembacaan berbasis Firestore.
///
/// Read-only: tidak ada tulis apa pun di sini. Query memakai
/// `orderBy createdAt DESC` + `limit` sesuai `docs/firestore_schema.md`
/// bagian 7.3 (single-field, tanpa composite index).
class FirestoreDetectionDataSource implements DetectionDataSource {
  FirestoreDetectionDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Detection>> watchLatestDetections({
    required String deviceId,
    required String deviceName,
    int limit = 10,
  }) {
    return _firestore
        .collection(detectionsCollectionPath(deviceId))
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
}
