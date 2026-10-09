import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/device.dart';
import '../models/device_model.dart';
import 'device_data_source.dart';

/// Sumber data perangkat berbasis Firestore.
///
/// Aplikasi tidak pernah menulis ke sini. Query selalu dibatasi agar kuota baca
/// Spark tidak cepat habis, dan status online tidak pernah diambil dari dokumen
/// melainkan dihitung di pemetaan model.
class FirestoreDeviceDataSource implements DeviceDataSource {
  FirestoreDeviceDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  FirebaseFirestore get firestore => _firestore;

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) {
    // Filter keanggotaan per skema bagian 3: hanya perangkat yang anggotanya
    // mencakup UID pengguna. Nilai role tidak diinterpretasikan di sini
    // (lihat catatan `[PERLU KONFIRMASI]` pada entity `Device.members`).
    return _firestore
        .collection(kDevicesCollection)
        .where('members.$uid', isNull: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => DeviceModel.fromDocument(doc, now: now))
              .toList(growable: false);
        });
  }

  @override
  Stream<Device?> watchDevice(String deviceId) {
    return _firestore.doc(deviceDocPath(deviceId)).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return DeviceModel.fromDocument(snapshot, now: DateTime.now());
    });
  }
}
