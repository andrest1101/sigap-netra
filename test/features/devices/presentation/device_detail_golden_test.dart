import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/time/now_provider.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/screens/device_detail_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/app_fonts.dart';
import '../../../helpers/fake_app_graph.dart';
import '../../../helpers/golden_clock.dart';
import '../../../helpers/precache_logo.dart';

/// Golden Detail perangkat: hero + Informasi/Privasi/Aksi dalam tiga kartu.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('light: kartu informasi, privasi, dan aksi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await precacheLogoMark(tester);

    final graph = FakeAppGraph(now: goldenNow);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => goldenNow),
          deviceRepositoryProvider.overrideWithValue(
            DemoDeviceRepository(now: goldenNow),
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
          theme: AppTheme.light(),
          home: const DeviceDetailScreen(deviceId: kDemoDeviceId),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(DeviceDetailScreen),
      matchesGoldenFile('../goldens/device_detail_phone_light.png'),
    );
  });
}
