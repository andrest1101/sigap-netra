import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/devices/data/datasources/fake_device_data_source.dart';

/// Perilaku simulasi yang dipakai presentasi: terlepas dari akun yang masuk,
/// perangkat demo harus terlihat supaya UI bisa dicoba/dipresentasikan tanpa
/// hardware. Filter keanggotaan asli tetap dimiliki data source Firestore.
void main() {
  test('perangkat demo terlihat untuk uid apa pun, termasuk tamu', () async {
    final dataSource = FakeDeviceDataSource();
    addTearDown(dataSource.dispose);
    final repository = FakeDeviceRepositoryImpl(dataSource);

    for (final uid in <String>[kDemoUserId, 'user-lain', 'guest-demo']) {
      final devices = await repository.watchMyDevices(uid: uid).first;
      expect(
        devices.map((device) => device.deviceId),
        <String>[kDemoDeviceId],
        reason: 'uid "$uid" harus melihat perangkat demo',
      );
    }
  });

  test('watchDevice mengembalikan perangkat demo hanya untuk id-nya', () async {
    final dataSource = FakeDeviceDataSource();
    addTearDown(dataSource.dispose);
    final repository = FakeDeviceRepositoryImpl(dataSource);

    final device = await repository.watchDevice(kDemoDeviceId).first;
    expect(device?.deviceId, kDemoDeviceId);
    expect(device?.name, kDemoDeviceName);
    expect(await repository.watchDevice('perangkat-lain').first, isNull);
  });
}
