import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/placeholder_screen.dart';

/// Nama path route sebagai konstanta.
///
/// Dideklarasikan di sini, bukan di dalam `GoRoute`, agar widget bisa
/// menavigasi tanpa harus tahu struktur router secara detail.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/beranda';
  static const String validation = '/validasi';
  static const String history = '/riwayat';
  static const String historyDetail = '/riwayat/:detectionId';
  static const String devices = '/perangkat';
  static const String deviceDetail = '/perangkat/:deviceId';
  static const String deviceWifi = '/perangkat/:deviceId/wifi';
  static const String deviceCommands = '/perangkat/:deviceId/perintah';
  static const String settings = '/pengaturan';
  static const String settingsConnection = '/pengaturan/koneksi';
  static const String settingsConnectionDevice =
      '/pengaturan/koneksi/:deviceId';
}

/// Satu item bottom navigation beserta ikon aktif dan tidak aktif.
///
/// Bernama `AppNavDestination` agar tidak bentrok dengan
/// `NavigationDestination` milik Material, yang juga dipakai untuk label ikon.
@immutable
class AppNavDestination {
  const AppNavDestination({
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// Daftar lima tab sesuai urutan di `docs/ui_spec.md`.
  static const List<AppNavDestination> all = [
    AppNavDestination(
      path: AppRoutes.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppNavDestination(
      path: AppRoutes.validation,
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    AppNavDestination(
      path: AppRoutes.history,
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    AppNavDestination(
      path: AppRoutes.devices,
      icon: Icons.devices_other_outlined,
      selectedIcon: Icons.devices_other,
    ),
    AppNavDestination(
      path: AppRoutes.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];
}

/// Menentukan tujuan redirect berdasarkan status autentikasi dan lokasi saat ini.
///
/// Fungsi murni supaya aturan redirect bisa diuji tanpa widget tree.
String? redirectFor(AuthState authState, String location) {
  final isPublic = location == AppRoutes.login || location == AppRoutes.splash;

  return switch (authState) {
    AuthUnknown() => isPublic ? null : AppRoutes.splash,
    AuthSignedOut() => isPublic ? null : AppRoutes.login,
    AuthSignedIn() =>
      location == AppRoutes.login || location == AppRoutes.splash
          ? AppRoutes.home
          : null,
  };
}

/// Navigasi ke daftar perangkat.
class DevicesPath {
  const DevicesPath();

  void go(BuildContext context) => GoRouter.of(context).go(AppRoutes.devices);
}

/// Navigasi ke detail satu perangkat.
class DeviceDetailPath {
  const DeviceDetailPath(this.deviceId);

  final String deviceId;

  void go(BuildContext context) =>
      GoRouter.of(context).go('${AppRoutes.devices}/$deviceId');
}

/// Shell lima tab dengan `NavigationBar`.
///
/// `StatefulShellRoute.indexedStack` dipakai agar posisi scroll dan filter tiap
/// tab bertahan saat berpindah tab.
class AppBottomNavShell extends StatelessWidget {
  const AppBottomNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final labels = <String, String>{
      AppRoutes.home: l10n.navHome,
      AppRoutes.validation: l10n.navValidation,
      AppRoutes.history: l10n.navHistory,
      AppRoutes.devices: l10n.navDevices,
      AppRoutes.settings: l10n.navSettings,
    };

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final destination in AppNavDestination.all)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: labels[destination.path] ?? '',
            ),
        ],
      ),
    );
  }
}

/// Router aplikasi.
///
/// Dibuat satu kali oleh Riverpod dan di-cache, sehingga instance `GoRouter`
/// tidak hilang setiap rebuild yang akan menghapus state navigasi.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Notifier dibuat sekali dan router TIDAK dibangun ulang saat status auth
  // berubah. Rebuild akan menghapus state navigasi tiap tab, jadi perubahan
  // diteruskan lewat refreshListenable sebagai gantinya.
  final authRefresh = _AuthRefreshNotifier();

  ref.listen(authStateProvider, (previous, next) {
    authRefresh.update(next.value ?? const AuthUnknown());
  }, fireImmediately: true);

  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) =>
        redirectFor(authRefresh.authState, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderScreen(
          screenKey: 'login',
          icon: Icons.login,
          titleKey: 'loginTitle',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppBottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.validation,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'validation',
                  icon: Icons.fact_check_outlined,
                  titleKey: 'validationTitle',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'history',
                  icon: Icons.history,
                  titleKey: 'historyTitle',
                ),
              ),
              GoRoute(
                path: AppRoutes.historyDetail,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'historyDetail',
                  icon: Icons.receipt_long,
                  titleKey: 'historyDetailTitle',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.devices,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'devices',
                  icon: Icons.devices_other_outlined,
                  titleKey: 'devicesTitle',
                ),
              ),
              GoRoute(
                path: AppRoutes.deviceDetail,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'deviceDetail',
                  icon: Icons.visibility_outlined,
                  titleKey: 'deviceDetailTitle',
                ),
              ),
              GoRoute(
                path: AppRoutes.deviceWifi,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'deviceWifi',
                  icon: Icons.qr_code_2,
                  titleKey: 'provisioningTitle',
                ),
              ),
              GoRoute(
                path: AppRoutes.deviceCommands,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'deviceCommands',
                  icon: Icons.settings_remote,
                  titleKey: 'commandsTitle',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'settings',
                  icon: Icons.settings_outlined,
                  titleKey: 'settingsTitle',
                ),
              ),
              GoRoute(
                path: AppRoutes.settingsConnection,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'settingsConnection',
                  icon: Icons.sync_alt,
                  titleKey: 'eventsTitle',
                ),
              ),
              GoRoute(
                path: AppRoutes.settingsConnectionDevice,
                builder: (context, state) => const PlaceholderScreen(
                  screenKey: 'settingsConnectionDevice',
                  icon: Icons.sync_alt,
                  titleKey: 'eventsTitle',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Layar boot sederhana yang hanya menunggu status autentikasi.
///
/// Nanti akan menampilkan inisialisasi Firebase dan Pemeriksaan perangkat.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Memberi tahu `GoRouter` ketika status autentikasi berubah.
///
/// `redirect` dijalankan ulang setiap notifikasi, jadi layar berpindah antara
/// splash, login, dan beranda tanpa perlu push/replace manual.
class _AuthRefreshNotifier extends ChangeNotifier {
  AuthState _authState = const AuthUnknown();

  AuthState get authState => _authState;

  /// Memperbarui status dan memberi tahu pendengar bila berubah.
  void update(AuthState next) {
    if (next == _authState) return;
    _authState = next;
    notifyListeners();
  }
}
