import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';
import 'package:sigap_netra_app/features/settings/domain/entities/data_source.dart';
import 'package:sigap_netra_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:sigap_netra_app/features/settings/presentation/widgets/simulation_badge.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

/// Penanda mode simulasi harus lahir dari sumber data **yang benar-benar
/// dipakai**, bukan dari toggle di Pengaturan.
void main() {
  Future<void> pumpMarkers(
    WidgetTester tester,
    DataSourceSelection selection,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataSourceSelectionProvider.overrideWithValue(selection)],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: AppBar(actions: const [SimulationBadge()]),
            body: const SimulationNotice(showLoginHint: true),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('data live: badge dan notice tidak memakan ruang', (
    tester,
  ) async {
    await pumpMarkers(tester, const DataSourceSelection.firebase());

    expect(find.text('SIMULASI'), findsNothing);
    expect(find.text('Mode simulasi aktif'), findsNothing);
  });

  testWidgets('simulasi karena mode pengembang: label + alasan tampil', (
    tester,
  ) async {
    await pumpMarkers(
      tester,
      const DataSourceSelection.simulation(SimulationReason.developerMode),
    );

    expect(find.text('SIMULASI'), findsOneWidget);
    expect(find.text('Mode simulasi aktif'), findsOneWidget);
    expect(
      find.text('Mode pengembang dinyalakan di Pengaturan.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Masuk dengan email apa pun; akun ini hanya tersimpan di perangkat.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('simulasi karena Firebase gagal: alasan berbeda, bukan klaim', (
    tester,
  ) async {
    await pumpMarkers(
      tester,
      const DataSourceSelection.simulation(
        SimulationReason.firebaseUnavailable,
      ),
    );

    expect(
      find.text('Firebase belum tersedia pada build ini.'),
      findsOneWidget,
    );
    expect(
      find.text('Mode pengembang dinyalakan di Pengaturan.'),
      findsNothing,
    );
  });

  testWidgets('badge punya satu label semantik yang utuh', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMarkers(
      tester,
      const DataSourceSelection.simulation(SimulationReason.developerMode),
    );

    expect(
      find.bySemanticsLabel('Mode simulasi: data demo, bukan perangkat nyata.'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
