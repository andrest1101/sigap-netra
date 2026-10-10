import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/commands/presentation/screens/commands_screen.dart';
import '../../features/devices/presentation/screens/device_detail_screen.dart';
import '../../features/devices/presentation/screens/device_list_screen.dart';
import '../../features/events/presentation/screens/connection_logs_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/monitoring/presentation/providers/monitoring_providers.dart';
import '../../features/provisioning/presentation/screens/wifi_provisioning_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/validation/presentation/screens/validation_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/lens_ring.dart';

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

  /// Daftar empat tab sesuai identitas v3: Beranda, Validasi, Riwayat,
  /// Perangkat. Pengaturan dibuka lewat avatar (`/pengaturan`), bukan tab.
  static const List<AppNavDestination> all = [
    AppNavDestination(
      path: AppRoutes.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppNavDestination(
      path: AppRoutes.validation,
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
    ),
    AppNavDestination(
      path: AppRoutes.history,
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    AppNavDestination(
      path: AppRoutes.devices,
      icon: Icons.devices_other_outlined,
      selectedIcon: Icons.devices_other_rounded,
    ),
  ];
}

/// Menentukan tujuan redirect berdasarkan status autentikasi dan lokasi saat ini.
///
/// Fungsi murni supaya aturan redirect bisa diuji tanpa widget tree.
String? redirectFor(AuthState authState, String location) {
  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.splash;

  return switch (authState) {
    AuthUnknown() => isAuthRoute ? null : AppRoutes.splash,
    AuthSignedOut() =>
      location == AppRoutes.splash
          ? AppRoutes.login
          : isAuthRoute
          ? null
          : AppRoutes.login,
    AuthSignedIn() => isAuthRoute ? AppRoutes.home : null,
  };
}

/// Navigasi ke daftar perangkat.
class DevicesPath {
  const DevicesPath();

  void go(BuildContext context) => GoRouter.of(context).go(AppRoutes.devices);
}

/// Navigasi ke detail satu perangkat.
///
/// Layar anak: selalu [push] agar tombol kembali tersedia. [go] hanya untuk
/// deep-link / fallback (tidak ada stack kembali).
class DeviceDetailPath {
  const DeviceDetailPath(this.deviceId);

  final String deviceId;

  String get location => '${AppRoutes.devices}/$deviceId';

  void go(BuildContext context) => GoRouter.of(context).go(location);

  void push(BuildContext context) => GoRouter.of(context).push(location);
}

/// Navigasi ke detail satu pembacaan riwayat.
class HistoryDetailPath {
  const HistoryDetailPath(this.detectionId);

  final String detectionId;

  String get location => '${AppRoutes.history}/$detectionId';

  void go(BuildContext context) => GoRouter.of(context).go(location);

  void push(BuildContext context) => GoRouter.of(context).push(location);
}

/// Navigasi ke tab Validasi.
class ValidationPath {
  const ValidationPath();

  void go(BuildContext context) =>
      GoRouter.of(context).go(AppRoutes.validation);
}

/// Navigasi ke tab Riwayat.
class HistoryPath {
  const HistoryPath();

  void go(BuildContext context) => GoRouter.of(context).go(AppRoutes.history);
}

/// Navigasi ke layar Pengaturan.
///
/// Layar daun top-level: selalu [push] agar tombol kembali tersedia. [go]
/// hanya untuk fallback (tidak ada stack kembali).
class SettingsPath {
  const SettingsPath();

  void go(BuildContext context) => GoRouter.of(context).go(AppRoutes.settings);

  void push(BuildContext context) =>
      GoRouter.of(context).push(AppRoutes.settings);
}

/// Navigasi ke layar QR Wi-Fi satu perangkat.
///
/// Layar anak: selalu [push] agar tombol kembali tersedia. [go] hanya untuk
/// deep-link / fallback (tidak ada stack kembali).
class DeviceWifiPath {
  const DeviceWifiPath(this.deviceId);

  final String deviceId;

  String get location => '${AppRoutes.devices}/$deviceId/wifi';

  void go(BuildContext context) => GoRouter.of(context).go(location);

  void push(BuildContext context) => GoRouter.of(context).push(location);
}

/// Navigasi ke layar perintah satu perangkat.
///
/// Layar anak: selalu [push] agar tombol kembali tersedia. [go] hanya untuk
/// deep-link / fallback (tidak ada stack kembali).
class DeviceCommandsPath {
  const DeviceCommandsPath(this.deviceId);

  final String deviceId;

  String get location => '${AppRoutes.devices}/$deviceId/perintah';

  void go(BuildContext context) => GoRouter.of(context).go(location);

  void push(BuildContext context) => GoRouter.of(context).push(location);
}

/// Navigasi ke layar log koneksi (semua perangkat).
///
/// Layar daun top-level: selalu [push] agar tombol kembali tersedia. [go]
/// hanya untuk fallback (tidak ada stack kembali).
class ConnectionLogsPath {
  const ConnectionLogsPath();

  void go(BuildContext context) =>
      GoRouter.of(context).go(AppRoutes.settingsConnection);

  void push(BuildContext context) =>
      GoRouter.of(context).push(AppRoutes.settingsConnection);
}

/// Shell empat tab dengan `NavigationBar` standar M3 (label selalu tampil).
///
/// `StatefulShellRoute.indexedStack` dipakai agar posisi scroll dan filter tiap
/// tab bertahan saat berpindah tab. Badge angka kecil (warna warn, batas
/// "99+") hanya pada tab Validasi sesuai identitas v3.
class AppBottomNavShell extends ConsumerWidget {
  const AppBottomNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final labels = <String, String>{
      AppRoutes.home: l10n.navHome,
      AppRoutes.validation: l10n.navValidation,
      AppRoutes.history: l10n.navHistory,
      AppRoutes.devices: l10n.navDevices,
    };

    final pendingCount = ref.watch(pendingDetectionsProvider).length;
    final badge = pendingCount <= 0
        ? null
        : pendingCount > 99
        ? '99+'
        : '$pendingCount';

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
              icon: badge != null && destination.path == AppRoutes.validation
                  ? Badge(label: Text(badge), child: Icon(destination.icon))
                  : Icon(destination.icon),
              selectedIcon:
                  badge != null && destination.path == AppRoutes.validation
                  ? Badge(
                      label: Text(badge),
                      child: Icon(destination.selectedIcon),
                    )
                  : Icon(destination.selectedIcon),
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
        builder: (context, state) => const LoginScreen(),
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
                builder: (context, state) => const ValidationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
              GoRoute(
                path: AppRoutes.historyDetail,
                builder: (context, state) => HistoryDetailScreen(
                  detectionId: state.pathParameters['detectionId']!,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.devices,
                builder: (context, state) => const DeviceListScreen(),
              ),
              GoRoute(
                path: AppRoutes.deviceDetail,
                builder: (context, state) => DeviceDetailScreen(
                  deviceId: state.pathParameters['deviceId']!,
                ),
              ),
              GoRoute(
                path: AppRoutes.deviceWifi,
                builder: (context, state) => WifiProvisioningScreen(
                  deviceId: state.pathParameters['deviceId']!,
                ),
              ),
              GoRoute(
                path: AppRoutes.deviceCommands,
                builder: (context, state) =>
                    CommandsScreen(deviceId: state.pathParameters['deviceId']),
              ),
            ],
          ),
        ],
      ),
      // Pengaturan (v3): bukan tab — dibuka lewat avatar, route top-level.
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsConnection,
        builder: (context, state) => const ConnectionLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsConnectionDevice,
        builder: (context, state) =>
            ConnectionLogsScreen(deviceId: state.pathParameters['deviceId']),
      ),
    ],
  );
});

/// Layar boot identitas SIGAP-NETRA.
///
/// Logo lensa (cincin diafragma) dengan animasi "memfokus" + nama aplikasi +
/// indikator loading. Hanya menunggu status autentikasi.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: l10n.appTitle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const LensRing(diameter: 120, mode: LensRingMode.focusing),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: ShapeDecoration(
                      color: colorScheme.primaryContainer,
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      Icons.visibility_rounded,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.appTitle,
              style: textTheme.headlineSmall?.copyWith(
                letterSpacing: DesignTokens.letterSpacingBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.splashLoading,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
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
