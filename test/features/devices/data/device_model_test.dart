import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/devices/data/models/device_model.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);

  group('timestamp parsing', () {
    test('Timestamp Firestore dikonversi ke DateTime', () {
      final device = DeviceModel.fromData(
        data: {'lastSeen': Timestamp.fromDate(now)},
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.lastSeen, now);
      expect(device.connectivity, DeviceConnectivity.online);
    });

    test('milidetik integer dari device REST diterima', () {
      final device = DeviceModel.fromData(
        data: {'lastSeen': now.millisecondsSinceEpoch},
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.lastSeen, now);
    });

    test('tipe timestamp yang tidak dikenali menghasilkan null', () {
      final device = DeviceModel.fromData(
        data: {'lastSeen': 'bukan-timestamp'},
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.lastSeen, isNull);
      expect(device.connectivity, DeviceConnectivity.unknown);
    });
  });

  group('pemetaan field', () {
    test('nama kosong jatuh ke deviceId', () {
      final device = DeviceModel.fromData(
        data: {'name': ''},
        deviceId: 'dev-9',
        now: now,
      );

      expect(device.name, 'dev-9');
    });

    test('settings yang bukan Map kembali ke default', () {
      final device = DeviceModel.fromData(
        data: {'settings': 'bukan-map'},
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.settings.uploadThumbnails, isFalse);
      expect(device.settings.uploadText, isFalse);
    });

    test('settings dengan uploadText true saja dipertahankan', () {
      final device = DeviceModel.fromData(
        data: {
          'settings': {'uploadThumbnails': false, 'uploadText': true},
        },
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.settings.uploadThumbnails, isFalse);
      expect(device.settings.uploadText, isTrue);
    });

    test('bootCount double diterima dan dibulatkan', () {
      final device = DeviceModel.fromData(
        data: {'bootCount': 7.9},
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.bootCount, 7);
    });

    test('batteryPct valid dipetakan, di luar rentang menjadi null', () {
      final ok = DeviceModel.fromData(
        data: {'batteryPct': 82},
        deviceId: 'dev-1',
        now: now,
      );
      expect(ok.batteryPct, 82);

      final over = DeviceModel.fromData(
        data: {'batteryPct': 150},
        deviceId: 'dev-1',
        now: now,
      );
      expect(over.batteryPct, isNull);

      final missing = DeviceModel.fromData(
        data: const <String, dynamic>{},
        deviceId: 'dev-1',
        now: now,
      );
      expect(missing.batteryPct, isNull);
    });

    test('members hanya memakai entri string ke string', () {
      final device = DeviceModel.fromData(
        data: {
          'members': {'user-1': 'owner', 'user-2': 42, 7: 'viewer'},
        },
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.members, {'user-1': 'owner'});
    });

    test('members bukan map menjadi kosong', () {
      final device = DeviceModel.fromData(
        data: {'members': 'bukan-map'},
        deviceId: 'dev-1',
        now: now,
      );

      expect(device.members, isEmpty);
    });
  });

  group('data null', () {
    test('dokumen tanpa field apa pun tidak membuat pemetaan gagal', () {
      final device = DeviceModel.fromData(
        data: null,
        deviceId: 'dev-x',
        now: now,
      );

      expect(device.deviceId, 'dev-x');
      expect(device.name, 'dev-x');
      expect(device.model, isNull);
      expect(device.firmwareVersion, isNull);
      expect(device.wifiSsid, isNull);
      expect(device.bootCount, isNull);
      expect(device.lastSeen, isNull);
      expect(device.connectivity, DeviceConnectivity.unknown);
    });
  });

  test('docPath konsisten dengan firestore_paths', () {
    expect(DeviceModel.docPath('abc'), 'devices/abc');
  });
}
