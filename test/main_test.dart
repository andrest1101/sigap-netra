import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap_netra_app/features/settings/domain/entities/data_source.dart';
import 'package:sigap_netra_app/main.dart';

/// Aturan sumber data: Firebase hanya bila toggle dimatikan DAN init
/// berhasil. Selain itu selalu simulasi — aplikasi tidak pernah macet
/// di splash karena config hilang.
void main() {
  group('resolveDataSource', () {
    test('default (tanpa preferensi) adalah simulasi', () async {
      SharedPreferences.setMockInitialValues(const {});
      final preferences = await SharedPreferences.getInstance();

      expect(resolveDataSource(preferences, true), DataSource.simulation);
      expect(resolveDataSource(preferences, false), DataSource.simulation);
    });

    test('mode pengembang aktif memaksa simulasi', () async {
      SharedPreferences.setMockInitialValues({'developer_mode': true});
      final preferences = await SharedPreferences.getInstance();

      expect(resolveDataSource(preferences, true), DataSource.simulation);
    });

    test('mode pengembang mati + Firebase siap memakai Firebase', () async {
      SharedPreferences.setMockInitialValues({'developer_mode': false});
      final preferences = await SharedPreferences.getInstance();

      expect(resolveDataSource(preferences, true), DataSource.firebase);
    });

    test('mode pengembang mati + Firebase gagal tetap simulasi', () async {
      SharedPreferences.setMockInitialValues({'developer_mode': false});
      final preferences = await SharedPreferences.getInstance();

      expect(resolveDataSource(preferences, false), DataSource.simulation);
    });
  });
}
