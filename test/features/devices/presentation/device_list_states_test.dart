import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/errors/app_failure.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/domain/entities/device.dart';
import 'package:sigap_netra_app/features/devices/domain/repositories/device_repository.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/screens/device_list_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';

class _EmptyDeviceRepository implements DeviceRepository {
  const _EmptyDeviceRepository();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) =>
      Stream<List<Device>>.value(const <Device>[]);

  @override
  Stream<Device?> watchDevice(String deviceId) => Stream<Device?>.value(null);
}

class _FailingDeviceRepository implements DeviceRepository {
  const _FailingDeviceRepository();

  @override
  Stream<List<Device>> watchMyDevices({required String uid}) =>
      Stream<List<Device>>.error(const NetworkUnavailableFailure());

  @override
  Stream<Device?> watchDevice(String deviceId) =>
      Stream<Device?>.error(const NetworkUnavailableFailure());
}

void main() {
  Future<void> pumpDevices(
    WidgetTester tester,
    DeviceRepository repository, {
    double textScale = 1.0,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
          theme: AppTheme.light(),
          home: const DeviceListScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Perangkat 360x640 @1,3x: empty state tanpa overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDevices(tester, const _EmptyDeviceRepository(), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(find.text('Belum ada perangkat'), findsOneWidget);
    expect(
      find.text('Tambahkan perangkat untuk mulai memantau.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Perangkat 360x640 @1,3x: error state + Coba lagi dapat dicapai',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpDevices(
        tester,
        const _FailingDeviceRepository(),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Terjadi kesalahan'), findsOneWidget);
      final retry = find.text('Coba lagi');
      expect(retry, findsOneWidget);
      await tester.ensureVisible(retry);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(retry).bottom, lessThanOrEqualTo(640));
    },
  );
}
