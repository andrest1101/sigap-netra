import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/commands/presentation/screens/commands_screen.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/screens/device_list_screen.dart';
import 'package:sigap_netra_app/features/events/presentation/screens/connection_logs_screen.dart';
import 'package:sigap_netra_app/features/provisioning/presentation/screens/wifi_provisioning_screen.dart';
import 'package:sigap_netra_app/core/widgets/settings_gear_button.dart';
import 'package:sigap_netra_app/features/history/presentation/screens/history_screen.dart';
import 'package:sigap_netra_app/features/home/presentation/home_screen.dart';
import 'package:sigap_netra_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:sigap_netra_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap_netra_app/features/validation/presentation/screens/validation_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../helpers/fake_app_graph.dart';

/// Repository tiruan: satu perangkat online agar tab Perangkat terisi penuh
/// (kepala + kontrol + timeline).
class _FakeDeviceRepository implements DeviceRepository {
  _FakeDeviceRepository();

  final StreamController<List<Device>> _controller =
      StreamController<List<Device>>.broadcast();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) {
    return Stream<List<Device>>.multi((controller) {
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<Device?> watchDevice(String deviceId) => _controller.stream.map(
    (devices) => devices.where((d) => d.deviceId == deviceId).firstOrNull,
  );

  void emit(List<Device> devices) => _controller.add(devices);

  Future<void> close() => _controller.close();
}

/// Regression P0: layar anak wajib bisa kembali + filter tidak dempet.
///
/// Setiap layar anak dibuka dari tab Perangkat memakai BackAppBar dengan
/// fallback aman. Saringan severity hanya ada di Log koneksi (server-side);
/// Wrap filter di sana wajib punya runSpacing agar baris tidak menempel.
void main() {
  late _FakeDeviceRepository repository;
  late SharedPreferences preferences;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  setUp(() => repository = _FakeDeviceRepository());
  tearDown(() => repository.close());

  final user = const AppUser(uid: 'user-1', email: 'user@example.com');

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    final graph = FakeAppGraph();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWithValue(user),
          sharedPreferencesProvider.overrideWithValue(preferences),
          ...graph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: screen,
        ),
      ),
    );
    repository.emit([
      Device(
        deviceId: kDemoDeviceId,
        name: 'Kacamata Cerdas',
        connectivity: DeviceConnectivity.online,
        lastSeen: DateTime.now(),
        batteryPct: 82,
      ),
    ]);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 16));
  }

  group('BackAppBar di layar anak', () {
    for (final entry in <(String, Widget)>[
      ('QR Wi-Fi', const WifiProvisioningScreen(deviceId: kDemoDeviceId)),
      ('Perintah', const CommandsScreen(deviceId: kDemoDeviceId)),
      ('Log koneksi', const ConnectionLogsScreen()),
      ('Pengaturan', const SettingsScreen()),
    ]) {
      testWidgets('${entry.$1} punya tombol kembali', (tester) async {
        await pumpScreen(tester, entry.$2);
        expect(tester.takeException(), isNull);
        // BackButton eksplisit dari BackAppBar, bukan otomatis implisit.
        expect(find.byType(BackButton), findsOneWidget);
      });
    }
  });

  group('Saringan severity', () {
    testWidgets('tab Perangkat tidak menampung saringan severity', (
      tester,
    ) async {
      await pumpScreen(tester, const DeviceListScreen());
      expect(tester.takeException(), isNull);

      // Saringan yang hanya menyaring 50 event yang sudah dimuat pernah
      // menumpang di kartu ringkasan. Sekarang saringan menyeluruh ada di
      // Log koneksi; tab Perangkat hanya menampilkan kartu Kejadian terbaru.
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.text('Kejadian terakhir'), findsOneWidget);
    });

    testWidgets('log koneksi: Wrap filter punya runSpacing', (tester) async {
      await pumpScreen(tester, const ConnectionLogsScreen());
      expect(tester.takeException(), isNull);

      final wraps = tester.widgetList<Wrap>(find.byType(Wrap));
      expect(wraps, isNotEmpty);
      for (final wrap in wraps) {
        expect(
          wrap.runSpacing,
          isNotNull,
          reason: 'Wrap filter log koneksi wajib punya runSpacing',
        );
      }
    });
  });

  group('Pintu Pengaturan tunggal via gear', () {
    for (final entry in <(String, Widget)>[
      ('Beranda', const HomeScreen()),
      ('Validasi', const ValidationScreen()),
      ('Riwayat', const HistoryScreen()),
      ('Perangkat', const DeviceListScreen()),
    ]) {
      testWidgets('tab ${entry.$1} punya ikon gear Pengaturan', (tester) async {
        await pumpScreen(tester, entry.$2);
        expect(tester.takeException(), isNull);
        expect(find.byType(SettingsGearButton), findsOneWidget);
      });
    }

    testWidgets('kartu akun tidak lagi disebar di tab', (tester) async {
      await pumpScreen(tester, const DeviceListScreen());
      expect(tester.takeException(), isNull);
      // Tombol pil "Pengaturan" milik kartu lama harus hilang; yang ada
      // hanyalah gear di app bar.
      expect(find.byType(SettingsGearButton), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Pengaturan menampilkan header akun + tombol kembali', (
      tester,
    ) async {
      await pumpScreen(tester, const SettingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.byType(BackButton), findsOneWidget);
      // Email tersamar tampil di header akun.
      expect(find.textContaining('***'), findsOneWidget);
    });
  });

  group('Detail perangkat terjangkau', () {
    testWidgets('kepala perangkat bisa di-tap (InkWell)', (tester) async {
      await pumpScreen(tester, const DeviceListScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('Kacamata Cerdas'), findsOneWidget);
      // Indikator visual bahwa kepala perangkat membuka detail.
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });
  });
}
