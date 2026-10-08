import '../../../events/domain/entities/device_event.dart';

/// Kontrak repository event pada domain.
///
/// Firestore repository belum diimplementasikan karena daftar `type` event,
/// paging, dan security masih berstatus `[PERLU KONFIRMASI]`.
abstract interface class EventRepository {
  /// Memantau event satu perangkat atau semua perangkat.
  Stream<List<DeviceEvent>> watchEvents({String? deviceId, int limit = 50});
}
