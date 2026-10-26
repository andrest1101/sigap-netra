import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/notification_gateway.dart';

/// Gerbang notifikasi OS aktif.
///
/// Di-override di `main.dart` dengan implementasi `flutter_local_notifications`.
/// Default sengaja melempar agar wiring yang terlewat ketahuan saat runtime,
/// sama seperti repository lain.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => throw UnimplementedError(
    'notificationGatewayProvider harus di-override di main.dart atau test.',
  ),
);
