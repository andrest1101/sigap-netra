import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/errors/app_failure.dart';
import 'package:sigap_netra_app/core/widgets/bento_tile.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/home/presentation/home_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

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

  Future<void> pumpHome(WidgetTester tester, {double textScale = 1.0}) async {
    final graph = FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(repository),
          // Daftar perangkat membutuhkan UID (filter keanggotaan), jadi test
          // mem-pump sebagai pengguna yang sudah masuk.
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          ...graph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: textScale == 1.0
              ? const HomeScreen()
              // Text scale sistem 1,3x (batas dukungan spec) diuji lewat
              // MediaQuery override — bukan parameter test yang fiktif.
              : Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(textScale)),
                    child: const HomeScreen(),
                  ),
                ),
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
      final graph = FakeAppGraph();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWithValue(repository),
            currentUserProvider.overrideWithValue(null),
            ...graph.overrides,
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
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          // lastSeen segar: konektivitas dihitung ulang vs jam nyata.
          lastSeen: DateTime.now(),
          batteryPct: 82,
        ),
      ]);
      await pumpFrames(tester);

      // Nama muncul 2x: subjudul app bar + Hero.
      expect(find.text('Kacamata Cerdas'), findsWidgets);
      // "Menunggu" muncul di tile bento + chip status tiap baris aktivitas.
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Akurasi'), findsOneWidget);
      // Tombol primer full-width memakai label penuh.
      expect(find.text('Sinkronkan sekarang'), findsOneWidget);
      expect(find.text('QR Wi-Fi'), findsOneWidget);
      // Stats strip: persen baterai ringkas.
      expect(find.text('82%'), findsOneWidget);
    });

    testWidgets('perangkat terputus menampilkan warna status merah', (
      tester,
    ) async {
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
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

    testWidgets('nama perangkat Hero memakai onPrimaryContainer', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 8, 12);
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      // Nama di Hero (bukan subjudul app bar): spesifik via descendant.
      final heroName = find.descendant(
        of: find.byType(DeviceHeroCard),
        matching: find.text('Kacamata Cerdas'),
      );
      expect(heroName, findsOneWidget);
      final context = tester.element(heroName);
      final scheme = Theme.of(context).colorScheme;
      final text = tester.widget<Text>(heroName);
      // Regression: teks di atas `primaryContainer` pernah memakai `onSurface`
      // sehingga menyatu dengan background.
      expect(text.style?.color, scheme.onPrimaryContainer);
    });

    testWidgets('nama perangkat Hero terbaca di mode gelap', (tester) async {
      final now = DateTime(2026, 10, 8, 12);
      final graph = FakeAppGraph();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWithValue(repository),
            currentUserProvider.overrideWithValue(
              const AppUser(uid: 'user-1', email: 'user@example.com'),
            ),
            ...graph.overrides,
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: ThemeMode.dark,
            home: const HomeScreen(),
          ),
        ),
      );
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      final heroName = find.descendant(
        of: find.byType(DeviceHeroCard),
        matching: find.text('Kacamata Cerdas'),
      );
      expect(heroName, findsOneWidget);
      final context = tester.element(heroName);
      final scheme = Theme.of(context).colorScheme;
      expect(Theme.of(context).brightness, Brightness.dark);
      final text = tester.widget<Text>(heroName);
      expect(text.style?.color, scheme.onPrimaryContainer);
    });

    testWidgets('tombol Hero bertingkat full-width', (tester) async {
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: DateTime.now(),
        ),
      ]);
      await pumpFrames(tester);

      // Primer full-width memakai label penuh (ruang cukup, tanpa wrap).
      expect(find.text('Sinkronkan sekarang'), findsOneWidget);
      expect(find.text('QR Wi-Fi'), findsOneWidget);
    });

    testWidgets('bento menampilkan jam absolut + breakdown hari ini', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 8, 12);
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      // Tile Sinkron: jam absolut, bukan hitungan relatif ganda.
      expect(find.textContaining('·'), findsWidgets);
      // Tile Hari ini: breakdown kategori dari data demo (4 uang · 2 teks).
      expect(find.textContaining('uang ·'), findsOneWidget);
      // Footer akurasi: sampel demo berisi 4 validasi (3 cocok, 1 tidak).
      expect(find.text('dari 4 validasi'), findsOneWidget);
    });

    testWidgets('tile Sinkron terakhir dan Hari ini sama tinggi', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 8, 12);
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      // "Hari ini" punya footer, "Sinkron terakhir" tidak — baris kedua
      // wajib memakai IntrinsicHeight + stretch agar kedua kotak sama
      // tinggi (regresi visual: dua kotak tampil berbeda ukuran).
      final syncedTile = find.ancestor(
        of: find.text('Sinkron terakhir'),
        matching: find.byType(BentoTile),
      );
      final todayTile = find.ancestor(
        of: find.text('Hari ini'),
        matching: find.byType(BentoTile),
      );
      expect(syncedTile, findsOneWidget);
      expect(todayTile, findsOneWidget);
      expect(
        tester.getSize(syncedTile).height,
        tester.getSize(todayTile).height,
      );
    });

    testWidgets('tetap muat pada text scale 1,3x', (tester) async {
      await pumpHome(tester, textScale: 1.3);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: DateTime.now(),
          batteryPct: 82,
        ),
      ]);
      await pumpFrames(tester);

      // RenderFlex overflow dilaporkan sebagai exception di widget test:
      // tile bento + ring akurasi 78 wajib tetap utuh pada text scale 1,3x.
      expect(tester.takeException(), isNull);
      expect(find.text('Akurasi'), findsOneWidget);
      expect(find.text('Sinkron terakhir'), findsOneWidget);
    });

    testWidgets('subjudul menampilkan nama perangkat primer', (tester) async {
      final now = DateTime(2026, 10, 8, 12);
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      // Nama muncul 2x: subjudul app bar + Hero.
      expect(find.text('Kacamata Cerdas'), findsWidgets);
    });

    Color qrBackground(WidgetTester tester) {
      // Tombol M3 merender Material tipe button dengan warna aktual —
      // baca dari sana (style widget null karena dari tema).
      final material = find.ancestor(
        of: find.text('QR Wi-Fi'),
        matching: find.byWidgetPredicate(
          (w) => w is Material && w.type == MaterialType.button,
        ),
      );
      expect(material, findsOneWidget);
      final color = tester.widget<Material>(material.first).color;
      expect(color, isNotNull);
      return color!;
    }

    testWidgets('saat online QR sekunder (tonal)', (tester) async {
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          // Konektivitas dihitung ulang dari lastSeen vs jam nyata —
          // harus segar agar benar-benar online.
          lastSeen: DateTime.now(),
        ),
      ]);
      await pumpFrames(tester);

      final context = tester.element(find.text('QR Wi-Fi'));
      expect(
        qrBackground(tester),
        Theme.of(context).colorScheme.secondaryContainer,
      );
    });

    testWidgets('saat offline QR menjadi aksi utama (filled)', (tester) async {
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.offline,
          lastSeen: DateTime(2026, 10, 8, 6),
        ),
      ]);
      await pumpFrames(tester);

      final context = tester.element(find.text('QR Wi-Fi'));
      expect(qrBackground(tester), Theme.of(context).colorScheme.primary);
    });

    testWidgets('aktivitas memakai chip status validasi', (tester) async {
      final now = DateTime(2026, 10, 8, 12);
      await pumpHome(tester);
      repository.emit([
        Device(
          deviceId: kDemoDeviceId,
          name: 'Kacamata Cerdas',
          connectivity: DeviceConnectivity.online,
          lastSeen: now,
        ),
      ]);
      await pumpFrames(tester);

      // Demo 5 item pending: chip status "Menunggu", bukan nomor #1..#5.
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('#1'), findsNothing);
    });
  });
}
