import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/router/app_router.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';

void main() {
  const signedIn = AuthSignedIn(AppUser(uid: 'u1', email: 'user@example.com'));
  const signedOut = AuthSignedOut();
  const unknown = AuthUnknown();

  group('redirectFor', () {
    test('status belum diketahui dan route privat -> splash', () {
      expect(redirectFor(unknown, AppRoutes.home), AppRoutes.splash);
    });

    test('status belum diketahui di splash tetap di splash', () {
      expect(redirectFor(unknown, AppRoutes.splash), isNull);
    });

    test('belum masuk dan route privat -> login', () {
      expect(redirectFor(signedOut, AppRoutes.history), AppRoutes.login);
    });

    test('belum masuk di login tetap di login', () {
      expect(redirectFor(signedOut, AppRoutes.login), isNull);
    });

    test('sudah masuk di login -> beranda', () {
      expect(redirectFor(signedIn, AppRoutes.login), AppRoutes.home);
    });

    test('sudah masuk di splash -> beranda', () {
      expect(redirectFor(signedIn, AppRoutes.splash), AppRoutes.home);
    });

    test('sudah masuk di route privat tidak dialihkan', () {
      expect(redirectFor(signedIn, AppRoutes.validation), isNull);
      expect(redirectFor(signedIn, AppRoutes.settings), isNull);
    });

    test('route detail ikut dilindungi', () {
      expect(redirectFor(signedOut, '/perangkat/dev-1/wifi'), AppRoutes.login);
    });
  });
}
