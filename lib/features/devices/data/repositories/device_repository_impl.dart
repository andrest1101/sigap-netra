import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device_data_source.dart';

/// Implementasi [DeviceRepository] di atas kontrak [DeviceDataSource].
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._dataSource);

  final DeviceDataSource _dataSource;

  @override
  Stream<List<Device>> watchMyDevices() => _dataSource.watchMyDevices();

  @override
  Stream<Device?> watchDevice(String deviceId) =>
      _dataSource.watchDevice(deviceId);
}
