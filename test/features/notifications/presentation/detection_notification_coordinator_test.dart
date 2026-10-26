import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap_netra_app/core/constants/app_constants.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/time/now_provider.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';
import 'package:sigap_netra_app/features/monitoring/presentation/providers/monitoring_providers.dart';
import 'package:sigap_netra_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:sigap_netra_app/features/notifications/presentation/widgets/detection_notification_coordinator.dart';
import 'package:sigap_netra_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';
import '../../../helpers/fake_notification_gateway.dart';

final DateTime _now = DateTime(2026, 10, 26, 10);

/// Menahan coordinator sampai query pembacaan sudah punya data, meniru
/// Beranda yang lebih dulu terbuka sebelum saklar notifikasi dinyalakan.
class _LateCoordinatorHarness extends StatefulWidget {
  const _LateCoordinatorHarness();

  @override
  State<_LateCoordinatorHarness> createState() =>
      _LateCoordinatorHarnessState();
}

class _LateCoordinatorHarnessState extends State<_LateCoordinatorHarness> {
  bool _showCoordinator = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              ref.watch(
                latestDetectionsProvider((
                  deviceId: kDemoDeviceId,
                  limit: kNotificationDetectionLimit,
                )),
              );
              return const SizedBox.shrink();
            },
          ),
          if (_showCoordinator)
            const DetectionNotificationCoordinator(child: SizedBox.shrink()),
          TextButton(
            onPressed: () => setState(() => _showCoordinator = true),
            child: const Text('mount'),
          ),
        ],
      ),
    );
  }
}

Detection _money({String id = 'det-baru', int? amount = 20000}) {
  return Detection(
    id: id,
    deviceId: kDemoDeviceId,
    deviceName: kDemoDeviceName,
    type: DetectionType.money,
    createdAt: _now,
    amount: amount,
    ocrText: 'OCR TIDAK BOLEH TAMPIL',
  );
}

Detection _text({String ocrText = 'PESAN PRIBADI'}) {
  return Detection(
    id: 'det-teks-baru',
    deviceId: kDemoDeviceId,
    deviceName: kDemoDeviceName,
    type: DetectionType.text,
    createdAt: _now,
    ocrText: ocrText,
  );
}

void main() {
  Future<FakeNotificationGateway> pumpCoordinator(
    WidgetTester tester, {
    required FakeAppGraph graph,
    bool enabled = true,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (enabled) 'detection_notifications_enabled': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final gateway = FakeNotificationGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(
            const AppUser(uid: 'user-1', email: 'user@example.com'),
          ),
          deviceRepositoryProvider.overrideWithValue(
            DemoDeviceRepository(now: _now),
          ),
          ...graph.overrides,
          notificationGatewayProvider.overrideWithValue(gateway),
          nowProvider.overrideWithValue(() => _now),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const DetectionNotificationCoordinator(
            child: Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );

    // Build awal: auth -> perangkat -> emisi pertama stream (primes).
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return gateway;
  }

  void emit(FakeAppGraph graph, Detection detection) {
    graph.detections.replaceAll([detection, ...graph.detections.itemsForTest]);
  }

  group('DetectionNotificationCoordinator', () {
    testWidgets('backlog awal tidak memicu notifikasi', (tester) async {
      final graph = FakeAppGraph(now: _now);
      final gateway = await pumpCoordinator(tester, graph: graph);

      expect(gateway.shown, isEmpty);
    });

    testWidgets('uang baru memicu notifikasi dengan nominal, tanpa OCR', (
      tester,
    ) async {
      final graph = FakeAppGraph(now: _now);
      final gateway = await pumpCoordinator(tester, graph: graph);

      emit(graph, _money());
      await tester.pump();
      await tester.pump();

      expect(gateway.shown, hasLength(1));
      final notification = gateway.shown.single;
      expect(notification.title, 'Pembacaan uang baru');
      expect(notification.body, contains('Rp 20.000'));
      expect(notification.body, contains(kDemoDeviceName));
      expect(notification.body, isNot(contains('OCR TIDAK BOLEH TAMPIL')));
      expect(notification.channelName, 'Pembacaan SIGAP-NETRA');
    });

    testWidgets('teks baru tidak membocorkan isi OCR', (tester) async {
      final graph = FakeAppGraph(now: _now);
      final gateway = await pumpCoordinator(tester, graph: graph);

      emit(graph, _text());
      await tester.pump();
      await tester.pump();

      expect(gateway.shown, hasLength(1));
      final notification = gateway.shown.single;
      expect(notification.title, 'Pembacaan teks baru');
      expect(notification.body, isNot(contains('PESAN PRIBADI')));
      expect(notification.body, contains(kDemoDeviceName));
    });

    testWidgets('saklar mati: tidak ada notifikasi', (tester) async {
      final graph = FakeAppGraph(now: _now);
      final gateway = await pumpCoordinator(
        tester,
        graph: graph,
        enabled: false,
      );

      emit(graph, _money());
      await tester.pump();
      await tester.pump();

      expect(gateway.shown, isEmpty);
    });

    testWidgets('backlog lama yang baru tersinkron tidak dinotifikasikan', (
      tester,
    ) async {
      final graph = FakeAppGraph(now: _now);
      final gateway = await pumpCoordinator(tester, graph: graph);

      emit(
        graph,
        Detection(
          id: 'det-terlambat',
          deviceId: kDemoDeviceId,
          deviceName: kDemoDeviceName,
          type: DetectionType.money,
          createdAt: _now.subtract(const Duration(minutes: 30)),
          amount: 50000,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(gateway.shown, isEmpty);
    });

    testWidgets('pembaruan status validasi tidak memicu notifikasi ulang', (
      tester,
    ) async {
      final graph = FakeAppGraph(now: _now);
      final gateway = await pumpCoordinator(tester, graph: graph);

      final existing = graph.detections.itemsForTest.first;
      graph.detections.replaceAll([
        existing.withValidationStatus(
          validationStatus: ValidationStatus.match,
          validatedBy: 'user-1',
          validatedAt: _now,
        ),
        ...graph.detections.itemsForTest.skip(1),
      ]);
      await tester.pump();
      await tester.pump();

      expect(gateway.shown, isEmpty);
    });

    testWidgets('query yang sudah berisi data tetap menjadi backlog', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'detection_notifications_enabled': true,
      });
      final preferences = await SharedPreferences.getInstance();
      final graph = FakeAppGraph(now: _now);
      final gateway = FakeNotificationGateway();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            currentUserProvider.overrideWithValue(
              const AppUser(uid: 'user-1', email: 'user@example.com'),
            ),
            deviceRepositoryProvider.overrideWithValue(
              DemoDeviceRepository(now: _now),
            ),
            ...graph.overrides,
            notificationGatewayProvider.overrideWithValue(gateway),
            nowProvider.overrideWithValue(() => _now),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const _LateCoordinatorHarness(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Data awal sudah dimuat oleh "Beranda", coordinator belum terpasang.
      expect(gateway.shown, isEmpty);

      await tester.tap(find.text('mount'));
      await tester.pump();
      await tester.pump();

      emit(graph, _money());
      await tester.pump();
      await tester.pump();

      expect(gateway.shown, hasLength(1));
      expect(gateway.shown.single.body, contains('Rp 20.000'));
    });
  });
}
