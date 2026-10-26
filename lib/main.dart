import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/demo_ids.dart';
import 'features/auth/data/datasources/auth_data_source.dart';
import 'features/auth/data/datasources/fake_auth_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/commands/data/datasources/fake_command_data_source.dart';
import 'features/commands/data/datasources/firestore_command_data_source.dart';
import 'features/commands/data/repositories/command_repository_impl.dart';
import 'features/commands/domain/repositories/command_repository.dart';
import 'features/commands/presentation/providers/commands_providers.dart';
import 'features/devices/data/datasources/fake_device_data_source.dart';
import 'features/devices/data/datasources/firestore_device_data_source.dart';
import 'features/devices/data/device_name_cache.dart';
import 'features/devices/data/repositories/device_repository_impl.dart';
import 'features/devices/domain/repositories/device_repository.dart';
import 'features/devices/presentation/providers/devices_providers.dart';
import 'features/events/data/datasources/fake_event_data_source.dart';
import 'features/events/data/datasources/firestore_event_data_source.dart';
import 'features/events/data/repositories/event_repository_impl.dart';
import 'features/events/domain/repositories/event_repository.dart';
import 'features/events/presentation/providers/events_providers.dart';
import 'features/history/data/datasources/fake_history_data_source.dart';
import 'features/history/data/datasources/firestore_history_data_source.dart';
import 'features/history/data/repositories/history_repository_impl.dart';
import 'features/history/domain/repositories/history_repository.dart';
import 'features/history/presentation/providers/history_providers.dart';
import 'features/media/data/datasources/fake_media_data_source.dart';
import 'features/media/data/datasources/firestore_media_data_source.dart';
import 'features/media/data/datasources/media_data_source.dart';
import 'features/media/data/repositories/media_repository_impl.dart';
import 'features/media/domain/repositories/media_repository.dart';
import 'features/media/presentation/providers/media_providers.dart';
import 'features/monitoring/data/datasources/fake_detection_data_source.dart';
import 'features/monitoring/data/datasources/firestore_detection_data_source.dart';
import 'features/monitoring/data/repositories/detection_repository_impl.dart';
import 'features/monitoring/domain/repositories/detection_repository.dart';
import 'features/monitoring/presentation/providers/monitoring_providers.dart';
import 'features/notifications/data/datasources/local_notification_gateway.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';
import 'features/settings/domain/entities/data_source.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/validation/data/datasources/fake_validation_data_source.dart';
import 'features/validation/data/datasources/firestore_validation_data_source.dart';
import 'features/validation/data/repositories/validation_repository_impl.dart';
import 'features/validation/domain/repositories/validation_repository.dart';
import 'features/validation/presentation/providers/validation_providers.dart';
// Konfigurasi Android sudah dihasilkan `flutterfire configure` untuk project
// `sigap-netra`. Bila inisialisasi tetap gagal (mis. config tidak lengkap),
// `main` jatuh ke simulasi dengan penanda jelas, bukan diam-diam.
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
  final selection = resolveDataSource(preferences, firebaseReady);
  final dataSource = selection.dataSource;
  // Satu cache nama perangkat untuk seluruh graf: dipakai repository
  // Firestore saat menyusun nama tampilan (dokumen deteksi tidak menyimpan
  // nama perangkat), dan di-refresh `app.dart` setiap daftar perangkat
  // berubah.
  final deviceNameCache = DeviceNameCache();
  final repositories = buildRepositories(dataSource, deviceNameCache);
  final notificationGateway = LocalNotificationGateway();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        dataSourceSelectionProvider.overrideWithValue(selection),
        authRepositoryProvider.overrideWithValue(
          buildAuthRepository(dataSource),
        ),
        deviceRepositoryProvider.overrideWithValue(
          buildDeviceRepository(dataSource),
        ),
        deviceNameCacheProvider.overrideWithValue(deviceNameCache),
        detectionRepositoryProvider.overrideWithValue(repositories.detection),
        validationRepositoryProvider.overrideWithValue(repositories.validation),
        historyRepositoryProvider.overrideWithValue(repositories.history),
        mediaRepositoryProvider.overrideWithValue(repositories.media),
        eventRepositoryProvider.overrideWithValue(repositories.events),
        commandRepositoryProvider.overrideWithValue(repositories.commands),
        notificationGatewayProvider.overrideWithValue(notificationGateway),
      ],
      child: const App(),
    ),
  );
}

/// Menentukan sumber data dari preferensi tersimpan dan kesiapan Firebase.
///
/// Aturan: Firebase dipakai bila pengguna **tidak** menyalakan mode pengembang
/// dan inisialisasi Firebase berhasil. Selain itu simulasi — aplikasi tidak
/// pernah macet di splash karena config hilang.
///
/// Default `developer_mode` adalah `false`, sejalan dengan toggle di
/// Pengaturan. Sebelumnya `main` memakai `true` sementara controller memakai
/// `false`, sehingga instalasi baru menampilkan data demo sambil Pengaturan
/// menulis "Firebase". Sekarang keduanya sepakat; bila Firebase memang belum
/// siap, hasilnya tetap simulasi, tetapi dengan alasan yang jujur.
DataSourceSelection resolveDataSource(
  SharedPreferences preferences,
  bool firebaseReady,
) {
  final developerMode = preferences.getBool('developer_mode') ?? false;

  if (developerMode) {
    return const DataSourceSelection.simulation(SimulationReason.developerMode);
  }
  if (!firebaseReady) {
    return const DataSourceSelection.simulation(
      SimulationReason.firebaseUnavailable,
    );
  }
  return const DataSourceSelection.firebase();
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

/// Graf repository aktif: satu himpunan yang dipakai seluruh layar.
class AppRepositories {
  const AppRepositories({
    required this.detection,
    required this.validation,
    required this.history,
    required this.media,
    required this.events,
    required this.commands,
  });

  final DetectionRepository detection;
  final ValidationRepository validation;
  final HistoryRepository history;
  final MediaRepository media;
  final EventRepository events;
  final CommandRepository commands;
}

/// Membangun seluruh graf repository untuk sumber data terpilih.
///
/// Mode simulasi: semua fake berbagi satu [FakeDetectionDataSource] sehingga
/// validasi dari layar Validasi langsung terlihat di Riwayat, Beranda, dan
/// badge tab — bukan dua "dunia" data yang terpisah.
///
/// Mode Firebase: tiap feature memakai data source Firestore-nya sendiri dan
/// nama perangkat diselesaikan lewat [DeviceNameCache].
AppRepositories buildRepositories(
  DataSource dataSource,
  DeviceNameCache deviceNameCache,
) {
  switch (dataSource) {
    case DataSource.simulation:
      final detections = FakeDetectionDataSource();
      final media = FakeMediaDataSource(detections);
      return AppRepositories(
        detection: FakeDetectionRepositoryImpl(
          detections,
          deviceNameOf: (_) => kDemoDeviceName,
        ),
        validation: FakeValidationRepositoryImpl(
          FakeValidationDataSource(detections),
        ),
        history: FakeHistoryRepositoryImpl(
          FakeHistoryDataSource(detections, onEvictThumbnail: media.evict),
        ),
        media: FakeMediaRepositoryImpl(media),
        events: FakeEventRepositoryImpl(FakeEventDataSource()),
        commands: FakeCommandRepositoryImpl(FakeCommandDataSource()),
      );
    case DataSource.firebase:
      final MediaDataSource mediaDataSource = FirestoreMediaDataSource();
      return AppRepositories(
        detection: DetectionRepositoryImpl(
          FirestoreDetectionDataSource(),
          deviceNameOf: deviceNameCache.resolve,
        ),
        validation: ValidationRepositoryImpl(
          FirestoreValidationDataSource(),
          deviceNameOf: deviceNameCache.resolve,
        ),
        history: HistoryRepositoryImpl(
          FirestoreHistoryDataSource(),
          deviceNameOf: deviceNameCache.resolve,
        ),
        media: MediaRepositoryImpl(mediaDataSource),
        events: EventRepositoryImpl(FirestoreEventDataSource()),
        commands: CommandRepositoryImpl(FirestoreCommandDataSource()),
      );
  }
}
