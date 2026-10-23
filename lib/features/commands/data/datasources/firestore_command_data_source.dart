import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/device_command.dart';
import '../models/device_command_model.dart';
import 'command_data_source.dart';

/// Sumber data perintah berbasis Firestore.
///
/// App hanya `add()` dokumen baru; tidak ada `update`/`delete` di sini.
/// Daftar memakai `orderBy createdAt DESC` + `limit` (tanpa composite).
class FirestoreCommandDataSource implements CommandDataSource {
  FirestoreCommandDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DeviceCommand>> watchCommands({
    required String deviceId,
    int limit = 20,
  }) {
    final snapshots = _firestore
        .collection(commandsCollectionPath(deviceId))
        .orderBy(DeviceCommandFields.createdAt, descending: true)
        .limit(limit)
        .snapshots();
    return mapFirebaseStreamErrors(snapshots).map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => DeviceCommandModel.fromDocument(doc, deviceId: deviceId),
          )
          .toList(growable: false),
    );
  }

  @override
  Stream<DeviceCommand?> watchCommand({
    required String deviceId,
    required String commandId,
  }) {
    final snapshots = _firestore
        .doc(commandDocPath(deviceId, commandId))
        .snapshots();
    return mapFirebaseStreamErrors(snapshots).map((snapshot) {
      if (!snapshot.exists) return null;
      return DeviceCommandModel.fromDocument(snapshot, deviceId: deviceId);
    });
  }

  @override
  Future<String> sendCommand({
    required String deviceId,
    required CommandType type,
    required Map<String, Object?> payload,
    required String? requestedBy,
  }) async {
    final ref = await mapFirebaseFutureErrors(
      _firestore
          .collection(commandsCollectionPath(deviceId))
          .add(
            DeviceCommandModel.createDocument(
              type: type,
              payload: payload,
              requestedBy: requestedBy,
            ),
          ),
    );
    return ref.id;
  }
}
