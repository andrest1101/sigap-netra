import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../../../monitoring/presentation/providers/monitoring_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/notification_id.dart';
import '../../domain/usecases/new_detection_tracker.dart';
import '../../domain/usecases/select_notifiable_detections.dart';
import '../notification_content.dart';
import '../providers/notification_providers.dart';

/// Menjembatani stream pembacaan realtime ke notifikasi OS.
///
/// Dipasang di akar `MaterialApp.router` sehingga tetap hidup lintas tab.
/// Hanya perangkat utama yang dipantau — sama dengan Beranda/Validasi/Riwayat.
/// Selama saklar di Pengaturan mati, tidak ada subscription tambahan dan tidak
/// ada notifikasi.
class DetectionNotificationCoordinator extends ConsumerStatefulWidget {
  const DetectionNotificationCoordinator({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DetectionNotificationCoordinator> createState() =>
      _DetectionNotificationCoordinatorState();
}

class _DetectionNotificationCoordinatorState
    extends ConsumerState<DetectionNotificationCoordinator> {
  final NewDetectionTracker _tracker = NewDetectionTracker();
  String? _trackedDeviceId;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(detectionNotificationsEnabledProvider);
    final deviceId = ref.watch(primaryDeviceIdProvider);

    if (!enabled || deviceId == null) {
      _trackedDeviceId = null;
      _tracker.reset();
      return widget.child;
    }

    if (_trackedDeviceId != deviceId) {
      _trackedDeviceId = deviceId;
      _tracker.reset();
    }

    final provider = latestDetectionsProvider((
      deviceId: deviceId,
      limit: kNotificationDetectionLimit,
    ));

    // `WidgetRef.listen` Riverpod 3 tidak punya `fireImmediately`. Bila query
    // sudah punya data (mis. Beranda lebih dulu terbuka), tandai isinya sebagai
    // backlog sebelum listener dipasang supaya emisi berikutnya tidak
    // dianggap sebagai emisi pertama.
    final current = ref.read(provider).value;
    if (current != null && !_tracker.isPrimed) {
      _tracker.track(current);
    }

    ref.listen<AsyncValue<List<Detection>>>(provider, (previous, next) {
      final detections = next.value;
      if (detections == null) return;

      final newDetections = _tracker.track(detections);
      if (newDetections.isEmpty) return;

      final selected = selectNotifiableDetections(
        newDetections,
        now: ref.read(nowProvider)(),
      );
      if (selected.isEmpty) return;

      // Aplikasi hanya punya satu locale, jadi sumber string tidak perlu
      // menunggu `Localizations` di bawah MaterialApp.
      final l10n = lookupAppLocalizations(const Locale('id'));
      for (final detection in selected.reversed) {
        unawaited(_notify(detection, l10n));
      }
    });

    return widget.child;
  }

  Future<void> _notify(Detection detection, AppLocalizations l10n) async {
    try {
      if (!ref.read(detectionNotificationsEnabledProvider)) return;

      final content = buildDetectionNotificationContent(detection, l10n);
      await ref
          .read(notificationGatewayProvider)
          .show(
            id: notificationIdFor(detection.id),
            title: content.title,
            body: content.body,
            channelName: l10n.notificationChannelName,
            channelDescription: l10n.notificationChannelDescription,
          );
    } catch (_) {
      // Notifikasi tidak boleh menjatuhkan aplikasi; kegagalan platform cukup
      // membuat notifikasi ini tidak tampil.
    }
  }
}
