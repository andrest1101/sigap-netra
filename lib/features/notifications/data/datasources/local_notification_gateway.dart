import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/repositories/notification_gateway.dart';

/// Implementasi [NotificationGateway] dengan `flutter_local_notifications`.
///
/// Plugin diinisialisasi malas pada pemakaian pertama supaya start aplikasi
/// tidak menunggu kanal notifikasi. Semua kegagalan platform diperlakukan
/// sebagai "tidak tersedia": notifikasi adalah fitur pelengkap, bukan jalur
/// keselamatan perangkat.
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Ikon monokrom di `android/app/src/main/res/drawable/ic_stat_sigap_netra.xml`.
  static const String _androidIcon = 'ic_stat_sigap_netra';

  static const String _channelId = 'sigap_netra_readings';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    const android = AndroidInitializationSettings(_androidIcon);
    // Jangan minta izin saat init: preferensi notifikasi default mati dan izin
    // baru diminta ketika pengguna menyalakan saklar di Pengaturan.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings: settings);
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    try {
      await _ensureInitialized();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          return await android?.requestNotificationsPermission() ?? false;
        case TargetPlatform.iOS:
          final ios = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          return await ios?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
              false;
        case TargetPlatform.macOS:
          final macOS = _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >();
          return await macOS?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
              false;
        case TargetPlatform.linux:
        case TargetPlatform.windows:
        case TargetPlatform.fuchsia:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (kIsWeb) return;

    await _ensureInitialized();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: _androidIcon,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
