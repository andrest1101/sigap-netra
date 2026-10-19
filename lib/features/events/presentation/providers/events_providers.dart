import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/retry_policy.dart';
import '../../domain/entities/device_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/event_usecases.dart';

/// Sumber data event aktif.
///
/// Di-override di `main.dart`: `EventRepositoryImpl` untuk Firebase, atau
/// `FakeEventRepositoryImpl` saat mode pengembang aktif.
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => throw UnimplementedError(
    'eventRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final watchEventsProvider = Provider<WatchEvents>(
  (ref) => WatchEvents(ref.watch(eventRepositoryProvider)),
);

/// Akses halaman event berfilter (server-side, memakai indeks
/// `severity + createdAt`). Dipakai Log koneksi saat saringan severity aktif.
final getEventsPageProvider = Provider<GetEventsPage>(
  (ref) => GetEventsPage(ref.watch(eventRepositoryProvider)),
);

/// Event terbaru satu perangkat, terbaru dulu.
///
/// `deviceId` null berarti semua perangkat pengguna (dipakai layar log
/// koneksi saat dibuka dari luar konteks perangkat).
final eventsProvider = StreamProvider.autoDispose
    .family<List<DeviceEvent>, String?>(
      (ref, deviceId) =>
          ref.watch(watchEventsProvider).call(deviceId: deviceId, limit: 50),
      retry: noRetry,
    );
