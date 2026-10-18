import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/devices/presentation/providers/devices_providers.dart';
import 'l10n/generated/app_localizations.dart';

/// Root widget aplikasi.
///
/// Menyediakan `MaterialApp.router` dengan tema terang-saja (keputusan produk
/// 2026-10-18: mode gelap dihapus), lokalisasi Bahasa Indonesia sebagai
/// satu-satunya locale, dan router yang mengalihkan sesuai status autentikasi.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cache nama perangkat untuk join di data layer: repository Firestore
    // menyusun nama tampilan lewat cache ini karena dokumen deteksi tidak
    // menyimpan nama perangkat. Dipantau sepanjang umur aplikasi supaya
    // nama "masuk" sebelum kartu pertama butuh.
    ref.listen(myDevicesProvider, (previous, next) {
      final devices = next.value;
      if (devices == null) return;
      final cache = ref.read(deviceNameCacheProvider);
      for (final device in devices) {
        cache.update(device.deviceId, device.name);
      }
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
