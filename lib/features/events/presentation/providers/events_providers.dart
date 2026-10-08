import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device_event.dart';

final eventsProvider = NotifierProvider<EventsController, List<DeviceEvent>>(
  EventsController.new,
);

class EventsController extends Notifier<List<DeviceEvent>> {
  /// Contoh UI sementara, bukan log Firestore.
  @override
  List<DeviceEvent> build() => _initial();
}

List<DeviceEvent> _initial() {
  final now = DateTime.now();
  return [
    DeviceEvent(
      id: 'evt-boot',
      deviceId: 'simulasi-maixcam-1',
      type: 'boot',
      severity: EventSeverity.info,
      message: 'Perangkat selesai booting.',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    DeviceEvent(
      id: 'evt-wifi-disconnect',
      deviceId: 'simulasi-maixcam-1',
      type: 'wlan_disconnected',
      severity: EventSeverity.warning,
      message: 'Koneksi Wi-Fi terputus sebentar.',
      createdAt: now.subtract(const Duration(minutes: 18)),
    ),
    DeviceEvent(
      id: 'evt-command-failed',
      deviceId: 'simulasi-maixcam-1',
      type: 'command_failed',
      severity: EventSeverity.error,
      message: 'Perintah restart gagal dieksekusi.',
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
  ];
}
