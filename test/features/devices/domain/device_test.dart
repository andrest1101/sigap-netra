import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12, 0, 0);

  group('deriveConnectivity', () {
    test('sebelum perangkat pernah mengirim heartbeat, status unknown', () {
      expect(
        deriveConnectivity(lastSeen: null, now: now),
        DeviceConnectivity.unknown,
      );
    });

    test('lastSeen di dalam ambang 90 detik berarti online', () {
      expect(
        deriveConnectivity(
          lastSeen: now.subtract(const Duration(seconds: 89)),
          now: now,
        ),
        DeviceConnectivity.online,
      );
    });

    test('tepat di ambang 90 detik sudah terputus', () {
      expect(
        deriveConnectivity(
          lastSeen: now.subtract(const Duration(seconds: 90)),
          now: now,
        ),
        DeviceConnectivity.offline,
      );
    });

    test('jauh di masa lalu berarti terputus', () {
      expect(
        deriveConnectivity(
          lastSeen: now.subtract(const Duration(hours: 6)),
          now: now,
        ),
        DeviceConnectivity.offline,
      );
    });

    test('jam perangkat di masa depan tidak membuat status offline', () {
      // Jam perangkat bisa menyimpang. Selisih negatif harus diabaikan dan
      // dianggap online, bukan terputus.
      expect(
        deriveConnectivity(
          lastSeen: now.add(const Duration(minutes: 2)),
          now: now,
        ),
        DeviceConnectivity.online,
      );
    });

    test('ambang dapat disesuaikan per pemanggil', () {
      expect(
        deriveConnectivity(
          lastSeen: now.subtract(const Duration(seconds: 45)),
          now: now,
          thresholdSeconds: 30,
        ),
        DeviceConnectivity.offline,
      );
    });
  });

  group('Device.withConnectivity', () {
    test('menghitung ulang status terhadap waktu yang diberikan', () {
      final device = Device(
        deviceId: 'abc',
        name: 'Kacamata',
        connectivity: DeviceConnectivity.unknown,
        lastSeen: now.subtract(const Duration(minutes: 2)),
      );

      expect(device.connectivity, DeviceConnectivity.unknown);
      expect(
        device.withConnectivity(now).connectivity,
        DeviceConnectivity.offline,
      );
    });

    test('tidak mengubah field lain', () {
      final device = Device(
        deviceId: 'abc',
        name: 'Kacamata',
        connectivity: DeviceConnectivity.offline,
        model: 'MaixCAM',
        firmwareVersion: '1.0.0',
        wifiSsid: 'Rumah',
        lastSeen: now,
        bootCount: 7,
        settings: const DeviceSettings(uploadThumbnails: true),
      );

      final updated = device.withConnectivity(now);

      expect(updated.deviceId, device.deviceId);
      expect(updated.name, device.name);
      expect(updated.model, device.model);
      expect(updated.firmwareVersion, device.firmwareVersion);
      expect(updated.wifiSsid, device.wifiSsid);
      expect(updated.bootCount, device.bootCount);
      expect(updated.settings, device.settings);
      expect(updated.connectivity, DeviceConnectivity.online);
    });
  });

  group('DeviceSettings', () {
    test('uploadThumbnails default false demi privasi', () {
      expect(const DeviceSettings().uploadThumbnails, isFalse);
      expect(const DeviceSettings().uploadText, isFalse);
    });
  });
}
