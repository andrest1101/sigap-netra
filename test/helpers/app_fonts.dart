import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/theme/app_theme.dart';

/// Empat berkas bobot Plus Jakarta Sans yang dibundel aplikasi.
const List<String> _fontAssets = [
  'assets/fonts/PlusJakartaSans-Regular.ttf',
  'assets/fonts/PlusJakartaSans-Medium.ttf',
  'assets/fonts/PlusJakartaSans-SemiBold.ttf',
  'assets/fonts/PlusJakartaSans-Bold.ttf',
];

/// Memuat font aplikasi sebelum golden diambil.
///
/// Tanpa ini `flutter test` merender setiap huruf sebagai kotak Ahem — golden
/// tidak membuktikan tipografi, line break, atau overflow yang sebenarnya.
/// Panggil sekali lewat `setUpAll(loadAppFonts)` di setiap berkas golden.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Future.wait([_loadTextFonts(), _loadMaterialIcons()]);
}

Future<void> _loadTextFonts() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final asset in _fontAssets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

/// Memuat ikon Material dari cache SDK agar golden benar-benar menampilkan
/// ikon, bukan kotak Ahem. `flutter test` tidak memuat font ikon secara
/// otomatis; `FLUTTER_ROOT` selalu tersedia pada proses test.
Future<void> _loadMaterialIcons() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;

  final file = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/'
    'materialicons-regular.otf',
  );
  if (!await file.exists()) return;

  final bytes = await file.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}
