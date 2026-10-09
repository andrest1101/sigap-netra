import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/retry_policy.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/usecases/watch_devices.dart';

/// Sumber data perangkat aktif.
///
/// Di-override di `main.dart`: `DeviceRepositoryImpl` untuk Firebase, atau
/// `FakeDeviceRepositoryImpl` saat mode pengembang aktif.
final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => throw UnimplementedError(
    'deviceRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final watchMyDevicesProvider = Provider<WatchMyDevices>(
  (ref) => WatchMyDevices(ref.watch(deviceRepositoryProvider)),
);

final watchDeviceProvider = Provider<WatchDevice>(
  (ref) => WatchDevice(ref.watch(deviceRepositoryProvider)),
);

/// Detak berkala untuk memaksa evaluate ulang status online.
///
/// `DateTime.now()` tidak memicu rebuild di Riverpod, jadi tanpa detak ini
/// perangkat akan tetap tampil online meski sudah melewati ambang 90 detik.
///
/// Timer dibatalkan saat provider dibuang. Tanpa itu widget test gagal dengan
/// "A Timer is still pending even after the widget tree was disposed".
final tickProvider = StreamProvider.autoDispose<int>((ref) {
  final controller = StreamController<int>();
  var tick = 0;

  final timer = Timer.periodic(
    const Duration(seconds: kConnectivityTickSeconds),
    (_) => controller.add(++tick),
  );

  ref.onDispose(() {
    timer.cancel();
    unawaited(controller.close());
  });

  return controller.stream;
});

/// Daftar mentah perangkat dari repository.
///
/// Sengaja tidak bergantung pada [tickProvider] supaya subscription Firestore
/// tidak dibuat ulang setiap detak; membuatnya ulang berarti kehilangan event
/// dan membakar kuota baca.
///
/// Tanpa pengguna yang masuk, stream kosong dikembalikan (bukan error) karena
/// daftar perangkat memang tidak boleh dibaca non-anggota (skema bagian 3).
///
/// Retry otomatis dimatikan agar state error benar-benar tampil di UI.
final rawDevicesProvider = StreamProvider.autoDispose<List<Device>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream<List<Device>>.value(const <Device>[]);
  return ref.watch(watchMyDevicesProvider).call(uid: uid);
}, retry: noRetry);

/// Daftar perangkat milik pengguna dengan status konektivitas yang dihitung
/// ulang setiap detak.
final myDevicesProvider = Provider.autoDispose<AsyncValue<List<Device>>>((ref) {
  final raw = ref.watch(rawDevicesProvider);
  ref.watch(tickProvider);

  final now = DateTime.now();
  return raw.whenData(
    (devices) => [for (final device in devices) device.withConnectivity(now)],
  );
});

/// Detail satu perangkat dengan status konektivitas yang dihitung ulang.
final deviceProvider = Provider.autoDispose.family<AsyncValue<Device?>, String>(
  (ref, deviceId) {
    final raw = ref.watch(rawDeviceProvider(deviceId));
    ref.watch(tickProvider);

    final now = DateTime.now();
    return raw.whenData((device) => device?.withConnectivity(now));
  },
);

/// Stream mentah satu perangkat.
final rawDeviceProvider = StreamProvider.autoDispose.family<Device?, String>((
  ref,
  deviceId,
) {
  return ref.watch(watchDeviceProvider).call(deviceId);
}, retry: noRetry);
