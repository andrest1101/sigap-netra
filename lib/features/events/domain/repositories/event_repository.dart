import '../entities/device_event.dart';
import '../entities/event_page.dart';

/// Kontrak repository event pada domain.
///
/// Tipe `type` event masih kandidat (`docs/firestore_schema.md` bagian 4.4,
/// `[PERLU KONFIRMASI]` daftar final), jadi kode hanya meneruskan string
/// mentah tanpa mengasumsikan daftar tertutup.
abstract interface class EventRepository {
  /// Memantau event terbaru satu perangkat, terbaru dulu.
  Stream<List<DeviceEvent>> watchEvents({String? deviceId, int limit = 50});

  /// Mengambil satu halaman event sesuai filter severity.
  ///
  /// [startAfter] null berarti halaman pertama. Mengembalikan [EventPage]
  /// yang membawa `nextCursor` untuk halaman berikutnya, atau null bila habis.
  Future<EventPage> getEventsPage({
    String? deviceId,
    EventSeverity? severity,
    int limit = 50,
    EventPageCursor? startAfter,
  });
}
