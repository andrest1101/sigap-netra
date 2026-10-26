import 'package:sigap_netra_app/features/notifications/domain/repositories/notification_gateway.dart';

class ShownNotification {
  const ShownNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final int id;
  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
}

/// Gerbang notifikasi palsu untuk widget test.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.permissionGranted = true});

  bool permissionGranted;
  int permissionRequests = 0;
  final List<ShownNotification> shown = <ShownNotification>[];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    shown.add(
      ShownNotification(
        id: id,
        title: title,
        body: body,
        channelName: channelName,
        channelDescription: channelDescription,
      ),
    );
  }
}
