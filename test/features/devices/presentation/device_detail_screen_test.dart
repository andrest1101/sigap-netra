import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/core/time/now_provider.dart';
import 'package:sigap_netra_app/core/widgets/action_tile.dart';
import 'package:sigap_netra_app/core/widgets/section_card.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:sigap_netra_app/features/devices/presentation/screens/device_detail_screen.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_graph.dart';
import '../../../helpers/golden_clock.dart';

void main() {
  Future<void> pumpDetail(
    WidgetTester tester, {
    Size surfaceSize = const Size(800, 1400),
    double textScale = 1.0,
  }) async {
    final graph = FakeAppGraph(now: goldenNow);
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const DeviceDetailScreen(deviceId: kDemoDeviceId),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('detail perangkat memakai tiga kartu seksi yang utuh', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('Informasi perangkat'), findsOneWidget);
    expect(find.text('Privasi dan data'), findsOneWidget);
    expect(find.text('Aksi'), findsOneWidget);
    expect(find.byType(SectionCard), findsNWidgets(3));

    // Hero + info teknis.
    expect(find.text('Kacamata Cerdas'), findsOneWidget);
    expect(find.text('MaixCAM'), findsOneWidget);
    expect(find.text('simulasi-1.0.0'), findsOneWidget);

    // Aksi berupa baris sentuh, bukan chip mengambang.
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byType(ActionTile), findsNWidgets(3));
    expect(find.text('Pasang Wi-Fi'), findsOneWidget);
    expect(find.text('Kontrol jarak jauh'), findsOneWidget);
    expect(find.text('Log koneksi'), findsOneWidget);
  });

  testWidgets('360x800 @1,3x: kartu detail muat tanpa overflow', (
    tester,
  ) async {
    await pumpDetail(tester, surfaceSize: const Size(360, 800), textScale: 1.3);

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Aksi'), 300);
    expect(tester.takeException(), isNull);
    expect(find.text('Aksi'), findsOneWidget);
    expect(find.byType(ActionTile), findsNWidgets(3));
  });
}
