import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sigap_netra_app/core/utils/relative_time.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id');
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  group('RelativeTime.timeOnly', () {
    test('memakai jam absolut 24 jam untuk strip sempit', () {
      expect(
        RelativeTime.timeOnly(DateTime(2026, 10, 20, 22, 15), l10n: l10n),
        '22.15',
      );
    });

    test('null tetap jujur sebagai belum pernah', () {
      expect(RelativeTime.timeOnly(null, l10n: l10n), 'Belum pernah');
    });
  });

  group('RelativeTime.timeAndDate', () {
    test('menyertakan tanggal pendek untuk tile bento', () {
      expect(
        RelativeTime.timeAndDate(DateTime(2026, 10, 20, 22, 15), l10n: l10n),
        '22.15 · 20 Okt',
      );
    });
  });
}
