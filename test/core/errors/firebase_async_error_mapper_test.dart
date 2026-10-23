import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/errors/app_failure.dart';
import 'package:sigap_netra_app/core/errors/firebase_error_mapper.dart';

void main() {
  FirebaseException firebaseError(String code) => FirebaseException(
    plugin: 'cloud_firestore',
    code: code,
    message: 'Firestore error: $code',
  );

  group('mapFirebaseStreamErrors', () {
    test('permission-denied menjadi PermissionDeniedFailure', () async {
      await expectLater(
        mapFirebaseStreamErrors(
          Stream<int>.error(firebaseError('permission-denied')),
        ),
        emitsError(isA<PermissionDeniedFailure>()),
      );
    });

    test('unavailable menjadi NetworkUnavailableFailure', () async {
      await expectLater(
        mapFirebaseStreamErrors(
          Stream<int>.error(firebaseError('unavailable')),
        ),
        emitsError(isA<NetworkUnavailableFailure>()),
      );
    });

    test('error non-Firebase diteruskan tanpa diubah', () async {
      final error = StateError('bukan error Firebase');

      await expectLater(
        mapFirebaseStreamErrors(Stream<int>.error(error)),
        emitsError(same(error)),
      );
    });
  });

  group('mapFirebaseFutureErrors', () {
    test('permission-denied menjadi PermissionDeniedFailure', () async {
      await expectLater(
        mapFirebaseFutureErrors(
          Future<int>.error(firebaseError('permission-denied')),
        ),
        throwsA(isA<PermissionDeniedFailure>()),
      );
    });

    test('nilai sukses diteruskan apa adanya', () async {
      expect(await mapFirebaseFutureErrors(Future<int>.value(42)), 42);
    });
  });
}
