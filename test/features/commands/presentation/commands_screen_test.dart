import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/widgets/action_tile.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/commands/domain/entities/device_command.dart';
import 'package:sigap_netra_app/features/commands/presentation/screens/commands_screen.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

/// Repository tanpa perangkat untuk menguji keadaan kosong.
class _EmptyDeviceRepository implements DeviceRepository {
  const _EmptyDeviceRepository();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) async* {
    yield const [];
  }

  @override
  Stream<Device?> watchDevice(String deviceId) async* {
    yield null;
  }
}

void main() {
  Future<FakeAppGraph> pumpCommands(
    WidgetTester tester, {
    String? deviceId = kDemoDeviceId,
    DeviceRepository? deviceRepository,
    Size surfaceSize = const Size(800, 1200),
    double textScale = 1.0,
  }) async {
    final graph = FakeAppGraph();
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(
            deviceRepository ?? DemoDeviceRepository(),
          ),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          ...graph.overrides,
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: CommandsScreen(deviceId: deviceId),
            ),
          ),
        ),
      ),
    );
    return graph;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('perintah baru memakai bahasa jujur "Menunggu alat"', (
    tester,
  ) async {
    final graph = await pumpCommands(tester);
    await settle(tester);
    final before = graph.commands.itemsForTest.length;

    // Aksi cepat sekarang berupa `ActionTile` (seluruh baris target sentuh),
    // bukan `FilledButton`; ketuk labelnya langsung. Riwayat juga dapat memuat
    // judul yang sama, jadi batasi finder ke tile aksi.
    final syncAction = find.widgetWithText(ActionTile, 'Sinkronkan sekarang');
    await tester.ensureVisible(syncAction);
    await tester.tap(syncAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(graph.commands.itemsForTest.length, before + 1);
    expect(find.text('Perintah dikirim.'), findsOneWidget);
    // Bukan "kedaluwarsa"/"gagal": perintah masih menunggu alat.
    expect(find.textContaining('Menunggu alat'), findsWidgets);

    // Habiskan timer simulasi device (1 dtk ack, 2 dtk done) + snackbar.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('sheet volume mengirim level yang dikonfirmasi', (tester) async {
    final graph = await pumpCommands(tester);
    await settle(tester);

    await tester.tap(find.text('Atur volume'));
    await tester.pumpAndSettle();

    // Slider sheet mulai dari 70 (default yang tampil).
    expect(find.text('Volume: 70'), findsOneWidget);
    // Geser slider sedikit lalu konfirmasi.
    await tester.drag(find.byType(Slider), const Offset(-120, 0));
    await tester.pump();
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    final newest = graph.commands.itemsForTest.first;
    expect(newest.type, CommandType.setVolume);
    expect(newest.payload['level'], isA<int>());
    expect(newest.payload['level'], lessThan(70));

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('sheet ucapkan teks mengirim teks + ringkasan payload', (
    tester,
  ) async {
    final graph = await pumpCommands(tester);
    await settle(tester);

    await tester.tap(find.text('Ucapkan teks'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo dunia');
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    final newest = graph.commands.itemsForTest.first;
    expect(newest.type, CommandType.speakText);
    expect(newest.payload['text'], 'Halo dunia');
    // Ringkasan payload tampil di tile bersama (bukan hanya di payload).
    expect(find.textContaining('Teks:'), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tanpa perangkat: aksi nonaktif dan alasan terlihat', (
    tester,
  ) async {
    await pumpCommands(
      tester,
      deviceId: null,
      deviceRepository: const _EmptyDeviceRepository(),
    );
    await settle(tester);

    expect(find.text('Belum ada perangkat dipilih'), findsOneWidget);
    expect(
      find.text('Pilih perangkat di tab Perangkat sebelum mengirim perintah.'),
      findsOneWidget,
    );
    expect(find.text('Buka Perangkat'), findsOneWidget);

    final actions = tester.widgetList<ActionTile>(find.byType(ActionTile));
    expect(actions, hasLength(5));
    expect(actions.every((action) => action.onTap == null), isTrue);
  });

  testWidgets('360x800 @1,3x: aksi dan riwayat muat tanpa overflow', (
    tester,
  ) async {
    await pumpCommands(
      tester,
      surfaceSize: const Size(360, 800),
      textScale: 1.3,
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Aksi cepat'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Riwayat perintah'), 300);
    expect(tester.takeException(), isNull);
    expect(find.text('Riwayat perintah'), findsOneWidget);
  });
}
