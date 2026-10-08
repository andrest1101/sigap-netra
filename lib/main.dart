import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/auth/data/datasources/auth_data_source.dart';
import 'features/auth/data/datasources/fake_auth_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/devices/data/datasources/fake_device_data_source.dart';
import 'features/devices/data/datasources/firestore_device_data_source.dart';
import 'features/devices/data/repositories/device_repository_impl.dart';
import 'features/devices/domain/repositories/device_repository.dart';
import 'features/devices/presentation/providers/devices_providers.dart';
import 'features/settings/domain/entities/data_source.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(
          buildAuthRepository(resolveDataSource(preferences)),
        ),
        deviceRepositoryProvider.overrideWithValue(
          buildDeviceRepository(resolveDataSource(preferences)),
        ),
      ],
      child: const App(),
    ),
  );
}

/// Menentukan sumber data dari preferensi tersimpan.
///
/// Mode pengembang aktif secara bawaan sampai Firebase siap, supaya aplikasi
/// tetap bisa dijalankan dan diuji tanpa konfigurasi apa pun.
DataSource resolveDataSource(SharedPreferences preferences) {
  final developerMode = preferences.getBool('developer_mode');
  if (developerMode != null) {
    return developerMode ? DataSource.simulation : DataSource.firebase;
  }
  return DataSource.simulation;
}

/// Memilih implementasi autentikasi sesuai sumber data.
///
/// Presentasi hanya pernah melihat kontrak domain; pemilihan implementasi
/// Firebase atau simulasi terjadi di satu tempat ini.
AuthRepository buildAuthRepository(DataSource dataSource) =>
    switch (dataSource) {
      DataSource.simulation => FakeAuthRepositoryImpl(FakeAuthDataSource()),
      DataSource.firebase => AuthRepositoryImpl(FirebaseAuthDataSource()),
    };

/// Memilih implementasi perangkat sesuai sumber data.
DeviceRepository buildDeviceRepository(DataSource dataSource) =>
    switch (dataSource) {
      DataSource.simulation => FakeDeviceRepositoryImpl(FakeDeviceDataSource()),
      DataSource.firebase => DeviceRepositoryImpl(FirestoreDeviceDataSource()),
    };
