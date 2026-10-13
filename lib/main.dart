import 'package:firebase_core/firebase_core.dart';
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
// Stub `lib/firebase_options.dart` ditimpa `flutterfire configure` (Fase 3).
// Selama masih stub, getter-nya melempar dan `main` jatuh ke simulasi.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase diinisialisasi bila `firebase_options.dart` sudah versi
  // generated. Selama masih stub (pra-Fase 3), getter melempar dan aplikasi
  // tetap jalan dalam mode simulasi — tidak macet di splash.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  final preferences = await SharedPreferences.getInstance();
  final dataSource = resolveDataSource(preferences, firebaseReady);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(
          buildAuthRepository(dataSource),
        ),
        deviceRepositoryProvider.overrideWithValue(
          buildDeviceRepository(dataSource),
        ),
      ],
      child: const App(),
    ),
  );
}

/// Menentukan sumber data dari preferensi tersimpan dan kesiapan Firebase.
///
/// Aturan: Firebase dipakai hanya bila pengguna mematikan mode simulasi
/// (toggle Pengaturan) DAN inisialisasi Firebase berhasil. Selain itu selalu
/// simulasi — aplikasi tidak pernah macet di splash karena config hilang.
DataSource resolveDataSource(
  SharedPreferences preferences,
  bool firebaseReady,
) {
  final developerMode = preferences.getBool('developer_mode') ?? true;

  if (developerMode) return DataSource.simulation;
  if (!firebaseReady) return DataSource.simulation;
  return DataSource.firebase;
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
