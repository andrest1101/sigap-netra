import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';

import '../../../helpers/fake_app_graph.dart';

/// Regresi P0 presentasi: `currentUserProvider` pernah TIDAK reaktif — dibaca
/// pertama kali saat belum melanggan (root `app.dart` memantau daftar
/// perangkat untuk cache nama), nilai `null`-nya ter-cache selamanya, sehingga
/// semua tab menampilkan "Belum ada perangkat" meski login berhasil.
///
/// Catatan Riverpod 3: provider tanpa listener aktif berstatus "pause" —
/// update dependency tidak diproses sampai diamati lagi, dan `container.read`
/// bisa mengembalikan nilai lama. Karena itu test ini mengamati lewat listener
/// seperti konsumen nyata (widget/provider chain), bukan read lepas.
void main() {
  test(
    'login email mengisi currentUserProvider hingga ke daftar perangkat',
    () async {
      final dataSource = FakeAuthDataSource();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepositoryImpl(dataSource),
          ),
          deviceRepositoryProvider.overrideWithValue(DemoDeviceRepository()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(dataSource.dispose);

      // Meniru `app.dart`: daftar perangkat dipantau seumur aplikasi.
      final subscription = container.listen(myDevicesProvider, (_, _) {});
      addTearDown(subscription.close);

      // Dibaca saat belum ada pengguna — di sinilah nilai `null` dulu ter-cache.
      expect(container.read(currentUserProvider), isNull);

      await container
          .read(authRepositoryProvider)
          .signInWithEmail(
            email: 'presentasi@sigapnetra.local',
            password: 'kacamata-cerdas',
          );
      await pumpEventQueue();

      expect(
        container.read(currentUserProvider)?.email,
        'presentasi@sigapnetra.local',
      );
      // Rantai penuh ikut hidup: daftar perangkat tidak lagi kosong.
      expect(container.read(myDevicesProvider).value, hasLength(1));

      await container.read(authRepositoryProvider).signOut();
      await pumpEventQueue();

      expect(container.read(currentUserProvider), isNull);
    },
  );

  test('currentUserProvider terisi setelah login tamu', () async {
    final dataSource = FakeAuthDataSource();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepositoryImpl(dataSource),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(dataSource.dispose);

    final subscription = container.listen(currentUserProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(container.read(currentUserProvider), isNull);

    await container.read(authRepositoryProvider).signInAnonymously();
    await pumpEventQueue();

    expect(container.read(currentUserProvider)?.uid, 'guest-demo');
  });
}
