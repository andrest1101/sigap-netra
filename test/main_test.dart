import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap_netra_app/features/settings/domain/entities/data_source.dart';
import 'package:sigap_netra_app/main.dart';

/// Aturan sumber data: Firebase hanya bila toggle mode pengembang mati DAN
/// init berhasil. Selain itu simulasi — aplikasi tidak pernah macet di splash
/// karena config hilang — tetapi alasannya ikut dilaporkan agar UI jujur.
///
/// Default `developer_mode` = false, sejalan dengan toggle di Pengaturan.
void main() {
  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('resolveDataSource', () {
    test('tanpa preferensi + Firebase siap memakai Firebase', () async {
      final preferences = await preferencesWith(const {});

      expect(
        resolveDataSource(preferences, true),
        const DataSourceSelection.firebase(),
      );
    });

    test(
      'tanpa preferensi + Firebase gagal: simulasi + alasan jujur',
      () async {
        final preferences = await preferencesWith(const {});

        final selection = resolveDataSource(preferences, false);

        expect(selection.isSimulation, isTrue);
        expect(
          selection.simulationReason,
          SimulationReason.firebaseUnavailable,
        );
      },
    );

    test('mode pengembang aktif memaksa simulasi', () async {
      final preferences = await preferencesWith({'developer_mode': true});

      final selection = resolveDataSource(preferences, true);

      expect(selection.isSimulation, isTrue);
      expect(selection.simulationReason, SimulationReason.developerMode);
    });

    test('mode pengembang mati + Firebase siap memakai Firebase', () async {
      final preferences = await preferencesWith({'developer_mode': false});

      expect(
        resolveDataSource(preferences, true),
        const DataSourceSelection.firebase(),
      );
    });

    test('mode pengembang mati + Firebase gagal tetap simulasi', () async {
      final preferences = await preferencesWith({'developer_mode': false});

      final selection = resolveDataSource(preferences, false);

      expect(selection.isSimulation, isTrue);
      expect(selection.simulationReason, SimulationReason.firebaseUnavailable);
    });

    test('mode pengembang menang atas Firebase yang tidak siap', () async {
      final preferences = await preferencesWith({'developer_mode': true});

      final selection = resolveDataSource(preferences, false);

      expect(selection.simulationReason, SimulationReason.developerMode);
    });
  });
}
