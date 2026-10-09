import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../monitoring/data/models/detection_model.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../domain/entities/detection_filter.dart';
import '../../domain/entities/detection_page.dart';
import 'history_data_source.dart';

/// Sumber data riwayat berbasis Firestore.
///
/// Kombinasi filter → query mengikuti indeks composite di
/// `docs/firestore_schema.md` bagian 8 (baris 1, 4-6). Paginasi memakai
/// `startAfter([createdAt])` pada `orderBy createdAt DESC` (skema 7.3).
/// Hapus memakai batch agar dokumen deteksi + `media` terhapus atomik.
class FirestoreHistoryDataSource implements HistoryDataSource {
  FirestoreHistoryDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _query(
    DetectionFilter filter, {
    DetectionPageCursor? startAfter,
  }) {
    final deviceId = filter.deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      throw ArgumentError(
        'DetectionFilter.deviceId wajib diisi: riwayat selalu per perangkat.',
      );
    }
    var query = _firestore
        .collection(detectionsCollectionPath(deviceId))
        .orderBy(DetectionFields.createdAt, descending: true);

    final type = filter.type;
    if (type != null) {
      query = query.where(
        DetectionFields.type,
        isEqualTo: type == DetectionType.text
            ? DetectionFields.typeText
            : DetectionFields.typeMoney,
      );
    }
    final status = filter.status;
    if (status != null) {
      query = query.where(
        DetectionFields.validationStatus,
        isEqualTo: switch (status) {
          ValidationStatus.match => DetectionFields.statusMatch,
          ValidationStatus.mismatch => DetectionFields.statusMismatch,
          ValidationStatus.pending => DetectionFields.statusPending,
        },
      );
    }
    if (startAfter != null) {
      // Kursor memakai nilai createdAt item terakhir halaman sebelumnya.
      query = query.startAfter([Timestamp.fromDate(startAfter.createdAt)]);
    }
    return query;
  }

  @override
  Future<DetectionPage> getDetectionsPage({
    required DetectionFilter filter,
    required String deviceName,
    int limit = 25,
    DetectionPageCursor? startAfter,
  }) async {
    final deviceId = filter.deviceId!;
    final snapshot = await _query(
      filter,
      startAfter: startAfter,
    ).limit(limit + 1).get();
    final docs = snapshot.docs;
    // Ambil satu ekstra untuk tahu apakah masih ada halaman berikut,
    // tanpa query tambahan (hemat 1 baca per halaman).
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    final items = pageDocs
        .map(
          (doc) => DetectionModel.fromDocument(
            doc,
            deviceId: deviceId,
            deviceName: deviceName,
          ),
        )
        .toList(growable: false);
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
    final batch = _firestore.batch();
    batch.delete(_firestore.doc(detectionDocPath(deviceId, detectionId)));
    // mediaId disarankan sama dengan detectionId (skema 4.3); bila
    // thumbnailId berbeda, pakai thumbnailId yang tersimpan di dokumen.
    final mediaId = thumbnailId;
    if (mediaId != null && mediaId.isNotEmpty) {
      batch.delete(_firestore.doc(mediaDocPath(deviceId, mediaId)));
    }
    await batch.commit();
  }

  @override
  Future<void> resetValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  }) async {
    // Memakai semantik undo yang sama: status kembali `pending` dengan jejak
    // `validatedBy`/`validatedAt` tetap terisi (skema bagian 4.2).
    await _firestore
        .doc(detectionDocPath(deviceId, detectionId))
        .update(
          DetectionModel.validationUpdate(
            status: ValidationStatus.pending,
            validatedBy: validatedBy,
          ),
        );
  }

  @override
  Future<void> resetAllValidations({
    required String deviceId,
    required String? validatedBy,
  }) async {
    // Batch dibatasi 500 tulis per commit (batas Firestore). Halaman diambil
    // 100 per iterasi agar batch tidak melebihi batas dengan aman.
    const pageSize = 100;
    DetectionPageCursor? cursor;
    while (true) {
      final page = await getDetectionsPage(
        filter: DetectionFilter(deviceId: deviceId),
        deviceName: '',
        limit: pageSize,
        startAfter: cursor,
      );
      if (page.items.isEmpty) return;
      final batch = _firestore.batch();
      for (final item in page.items) {
        if (item.validationStatus == ValidationStatus.pending) continue;
        batch.update(
          _firestore.doc(detectionDocPath(deviceId, item.id)),
          DetectionModel.validationUpdate(
            status: ValidationStatus.pending,
            validatedBy: validatedBy,
          ),
        );
      }
      await batch.commit();
      cursor = page.nextCursor;
      if (cursor == null) return;
    }
  }
}
