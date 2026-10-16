import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/media_thumbnail.dart';
import '../models/media_model.dart';
import 'media_data_source.dart';

/// Sumber data thumbnail berbasis Firestore.
///
/// Hanya lookup satu dokumen `media/{thumbnailId}` per kartu yang terlihat
/// (skema 7.3 aturan 4) — tidak pernah query daftar. Dokumen hilang atau
/// tidak valid menjadi null ("tanpa gambar"); hanya error transport yang
/// dilempar sebagai [AppFailure] agar UI bisa menawarkan "Coba lagi".
class FirestoreMediaDataSource implements MediaDataSource {
  FirestoreMediaDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<MediaThumbnail?> getThumbnail({
    required String deviceId,
    required String thumbnailId,
  }) async {
    try {
      final doc = await _firestore
          .doc(mediaDocPath(deviceId, thumbnailId))
          .get();
      if (!doc.exists) return null;
      return MediaModel.fromData(
        data: doc.data(),
        deviceId: deviceId,
        mediaId: doc.id,
      );
    } on FirebaseException catch (e) {
      throw e.toAppFailure();
    }
  }
}
