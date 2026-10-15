import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/commands/data/datasources/fake_command_data_source.dart';
import 'package:sigap_netra_app/features/commands/presentation/providers/commands_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/events/data/datasources/fake_event_data_source.dart';
import 'package:sigap_netra_app/features/events/presentation/providers/events_providers.dart';
import 'package:sigap_netra_app/features/history/data/datasources/fake_history_data_source.dart';
import 'package:sigap_netra_app/features/history/presentation/providers/history_providers.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/presentation/providers/monitoring_providers.dart';
import 'package:sigap_netra_app/features/validation/data/datasources/fake_validation_data_source.dart';
import 'package:sigap_netra_app/features/validation/presentation/providers/validation_providers.dart';

/// Repository perangkat statis untuk widget test.
///
/// Sengaja BUKAN `FakeDeviceDataSource`: data source itu menyalakan timer
/// heartbeat yang tidak terikat siklus hidup provider, sehingga tertinggal
/// sebagai timer pending saat test selesai. Repository ini selalu menyajikan
/// perangkat demo ([kDemoDeviceId]) tanpa timer.
class DemoDeviceRepository implements DeviceRepository {
  DemoDeviceRepository({this.isOnline = true, this.batteryPct = 82});

  final bool isOnline;
  final int? batteryPct;

  Device _device() => Device(
    deviceId: kDemoDeviceId,
    name: kDemoDeviceName,
    model: 'MaixCAM',
    firmwareVersion: 'simulasi-1.0.0',
    lastSeen: isOnline ? DateTime.now() : DateTime(2026, 1, 1),
    batteryPct: batteryPct,
    connectivity: isOnline
        ? DeviceConnectivity.online
        : DeviceConnectivity.offline,
  );

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) async* {
    yield [_device()];
  }

  @override
  Stream<Device?> watchDevice(String deviceId) async* {
    yield deviceId == kDemoDeviceId ? _device() : null;
  }
}

/// Graf fake bersama untuk widget test.
///
/// Meniru komposisi `main.dart` mode simulasi: SATU
/// [FakeDetectionDataSource] dibagi Validasi, Riwayat, dan Beranda, sehingga
/// validasi di satu layar langsung terlihat di layar lain. Setiap test
/// membuat instance baru supaya state tidak bocor antar test.
class FakeAppGraph {
  FakeAppGraph()
    : detections = FakeDetectionDataSource(),
      events = FakeEventDataSource(),
      commands = FakeCommandDataSource();

  final FakeDetectionDataSource detections;
  final FakeEventDataSource events;
  final FakeCommandDataSource commands;

  /// Override repository untuk `ProviderScope`.
  ///
  /// Tipe daftar dibiarkan terinferensi: Riverpod 3 tidak mengekspor tipe
  /// `Override` secara publik.
  ///
  /// `deviceRepositoryProvider` tidak ikut di sini — test memilih sendiri
  /// [DemoDeviceRepository] atau repository tiruan dengan kendali error.
  late final overrides = [
    detectionRepositoryProvider.overrideWithValue(
      FakeDetectionRepositoryImpl(
        detections,
        deviceNameOf: (_) => kDemoDeviceName,
      ),
    ),
    validationRepositoryProvider.overrideWithValue(
      FakeValidationRepositoryImpl(FakeValidationDataSource(detections)),
    ),
    historyRepositoryProvider.overrideWithValue(
      FakeHistoryRepositoryImpl(FakeHistoryDataSource(detections)),
    ),
    eventRepositoryProvider.overrideWithValue(FakeEventRepositoryImpl(events)),
    commandRepositoryProvider.overrideWithValue(
      FakeCommandRepositoryImpl(commands),
    ),
  ];
}
