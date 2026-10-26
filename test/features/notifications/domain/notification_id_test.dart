import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/notifications/domain/notification_id.dart';

void main() {
  group('notificationIdFor', () {
    test('stabil untuk ID yang sama', () {
      expect(
        notificationIdFor('det-money-100k'),
        notificationIdFor('det-money-100k'),
      );
    });

    test('ID berbeda menghasilkan notifikasi berbeda', () {
      expect(
        notificationIdFor('det-money-100k'),
        isNot(notificationIdFor('det-money-50k')),
      );
    });

    test('tidak pernah nol dan selalu 31-bit', () {
      for (final id in ['a', '-1', 'det-text', '']) {
        final value = notificationIdFor(id);
        expect(value, greaterThan(0));
        expect(value, lessThanOrEqualTo(0x7fffffff));
      }
    });
  });
}
