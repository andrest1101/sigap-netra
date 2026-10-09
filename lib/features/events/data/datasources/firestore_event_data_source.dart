import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/device_event.dart';
import '../../domain/entities/event_page.dart';
import '../models/device_event_model.dart';
import 'event_data_source.dart';

/// Sumber data event berbasis Firestore.
///
/// Read-only. Stream memakai `orderBy createdAt DESC` + `limit` (tanpa
/// composite). Halaman berfilter memakai composite `severity + createdAt`
/// sesuai indeks skema bagian 8 baris 7.
class FirestoreEventDataSource implements EventDataSource {
  FirestoreEventDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DeviceEvent>> watchEvents({String? deviceId, int limit = 50}) {
    if (deviceId == null || deviceId.isEmpty) {
      return Stream<List<DeviceEvent>>.value(const <DeviceEvent>[]);
    }
    return _firestore
        .collection(eventsCollectionPath(deviceId))
        .orderBy(DeviceEventFields.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DeviceEventModel.fromDocument(doc, deviceId: deviceId),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<EventPage> getEventsPage({
    String? deviceId,
    EventSeverity? severity,
    int limit = 50,
    EventPageCursor? startAfter,
  }) async {
    if (deviceId == null || deviceId.isEmpty) {
      return const EventPage(items: <DeviceEvent>[]);
    }
    var query = _firestore
        .collection(eventsCollectionPath(deviceId))
        .orderBy(DeviceEventFields.createdAt, descending: true);
    if (severity != null) {
      query = query.where(
        DeviceEventFields.severity,
        isEqualTo: switch (severity) {
          EventSeverity.info => DeviceEventFields.severityInfo,
          EventSeverity.warning => DeviceEventFields.severityWarning,
          EventSeverity.error => DeviceEventFields.severityError,
        },
      );
    }
    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter.createdAt)]);
    }
    final snapshot = await query.limit(limit + 1).get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    final items = pageDocs
        .map((doc) => DeviceEventModel.fromDocument(doc, deviceId: deviceId))
        .toList(growable: false);
    return EventPage(
      items: items,
      nextCursor: hasMore && items.isNotEmpty
          ? EventPageCursor.fromEvent(items.last)
          : null,
    );
  }
}
