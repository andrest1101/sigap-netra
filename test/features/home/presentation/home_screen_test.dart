import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/errors/app_failure.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/home/presentation/home_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Repository tiruan dengan kendali atas state tiap skenario test.
class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository();

  final StreamController<List<Device>> _controller =
      StreamController<List<Device>>.broadcast();

  Object? errorToEmit;

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) {
    final error = errorToEmit;
    if (error != null) {
      return Stream<List<Device>>.error(error);
    }
    return Stream<List<Device>>.multi((controller) {
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<Device?> watchDevice(String deviceId) => _controller.stream.map(
    (devices) => devices.where((d) => d.deviceId == deviceId).firstOrNull,
  );

  void emit(List<Device> devices) => _controller.add(devices);

  Future<void> close() => _controller.close();
}

void main() {
  late FakeDeviceRepository repository;

  setUp(() => repository = FakeDeviceRepository());
  tearDown(() => repository.close());

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(repository),
          // Daftar perangkat membutuhkan UID (filter keanggotaan), jadi test
          // mem-pump sebagai pengguna yang sudah masuk.
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: HomeScreen(),
        ),
      ),
    );
  }

  // Skeleton memakai animasi berulang, jadi `pumpAndSettle` tidak pernah
  // selesai selama state loading. Karena itu setiap transisi dipompa secara
  // eksplisit. Pump terakhir melewati tick konektivitas 15 detik supaya timer
  // periodic sempat fire — tanpanya binding protes ada timer pending saat
  // finalisasi tree (flutter_test `!timersPending`).
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  group('Beranda', () {
    testWidgets('tanpa pengguna yang masuk menampilkan empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWithValue(repository),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            locale: Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: HomeScreen(),
          ),
        ),
      );
      await pumpFrames(tester);

      expect(find.text('Belum ada perangkat'), findsOneWidget);
    });

    testWidgets('menampilkan skeleton saat memuat', (tester) async {
      await pumpHome(tester);
      await pumpFrames(tester);

      // Bento belum tampil karena data belum pernah datang.
      expect(find.text('Menunggu'), findsNothing);
      expect(find.text('Belum ada perangkat'), findsNothing);
    });

    testWidgets('menampilkan empty state saat tidak ada perangkat', (
      tester,
    ) async {
      await pumpHome(tester);
      repository.emit([]);
      await pumpFrames(tester);

      expect(find.text('Belum ada perangkat'), findsOneWidget);
      expect(find.text('Tambah perangkat'), findsOneWidget);
    });

    testWidgets('menampilkan error dengan aksi coba lagi', (tester) async {
      repository.errorToEmit = const NetworkUnavailableFailure();
      await pumpHome(tester);
      await pumpFrames(tester);

      expect(find.text('Terjadi kesalahan'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(
        find.text('Layanan tidak dapat dihubungi saat ini.'),
        findsOneWidget,
      );
    });

    testWidgets('error dari kode Firebase dipetakan ke pesan ramah', (
      tester,
    ) async {
      repository.errorToEmit = const QuotaExceededFailure();
      await pumpHome(tester);
      await pumpFrames(tester);

      expect(
        find.text('Kuota layanan habis. Coba lagi nanti.'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan hero dan bento perangkat', (tester) async {
      final now = DateTime(2026, 10, 8, 12);
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: 'dev-1',
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      expect(find.text('Kacamata Cerdas'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Akurasi'), findsOneWidget);
      expect(find.text('Sinkronkan sekarang'), findsOneWidget);
      expect(find.text('QR Wi-Fi'), findsOneWidget);
    });

    testWidgets('perangkat terputus menampilkan warna status merah', (
      tester,
    ) async {
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: 'dev-1',
          name: 'Kacamata Cerdas 2',
          connectivity: DeviceConnectivity.offline,
          // Status akhir dihitung ulang dari lastSeen, jadi test harus
          // memberi nilai yang benar-benar sudah melewati ambang 90 detik.
          lastSeen: DateTime(2026, 10, 8, 6),
        ),
      ]);
      await pumpFrames(tester);

      expect(find.textContaining('Terputus'), findsWidgets);
    });
  });
}
