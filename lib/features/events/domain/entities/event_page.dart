import 'package:equatable/equatable.dart';

import 'device_event.dart';

/// Kursor halaman event yang bebas Firestore.
///
/// Domain tidak boleh mengimpor `DocumentSnapshot`, jadi kursor memakai nilai
/// field `createdAt` + `id` item terakhir. Data layer Firestore memakainya
/// lewat `startAfter([createdAt])` pada query `orderBy createdAt DESC`.
class EventPageCursor extends Equatable {
  const EventPageCursor({required this.createdAt, required this.id});

  /// Dibangun dari item terakhir halaman sebelumnya.
  factory EventPageCursor.fromEvent(DeviceEvent event) {
    return EventPageCursor(createdAt: event.createdAt, id: event.id);
  }

  final DateTime createdAt;
  final String id;

  @override
  List<Object?> get props => [createdAt, id];
}

/// Satu halaman event beserta kursor halaman berikutnya.
///
/// [nextCursor] null berarti tidak ada halaman lagi.
class EventPage extends Equatable {
  const EventPage({required this.items, this.nextCursor});

  final List<DeviceEvent> items;
  final EventPageCursor? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
