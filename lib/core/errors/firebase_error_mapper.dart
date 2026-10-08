import 'package:firebase_auth/firebase_auth.dart';

import 'app_failure.dart';

/// Pemetaan error Firebase ke `AppFailure` milik domain.
///
/// File ini adalah satu-satunya tempat yang boleh menyentuh tipe error dari
/// `cloud_firestore` dan `firebase_auth` untuk keperluan pelaporan ke layer
/// presentation. Dengan begitu domain dan presentation tidak perlu tahu apa pun
/// tentang kode error Firebase.
extension FirebaseErrorMapper on FirebaseException {
  AppFailure toAppFailure() {
    switch (code) {
      case 'permission-denied':
      case 'unauthenticated':
        return const PermissionDeniedFailure();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return const NetworkUnavailableFailure();
      case 'not-found':
        return const NotFoundFailure();
      case 'resource-exhausted':
      case 'failed-precondition':
        return const QuotaExceededFailure();
      default:
        return const UnknownFailure();
    }
  }
}

/// Pemetaan error dari `FirebaseAuthException`.
extension FirebaseAuthErrorMapper on FirebaseAuthException {
  AppFailure toAppFailure() {
    switch (code) {
      case 'invalid-email':
        return const ValidationFailure('loginInvalidEmail');
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return const ValidationFailure('loginWrongPassword');
      case 'too-many-requests':
        return const ValidationFailure('loginTooManyAttempts');
      case 'user-disabled':
        return const ValidationFailure('loginAccountDisabled');
      case 'email-already-in-use':
        return const ValidationFailure('loginEmailInUse');
      case 'weak-password':
        return const ValidationFailure('loginWeakPassword');
      case 'network-request-failed':
        return const NetworkUnavailableFailure();
      case 'requires-recent-login':
      case 'user-token-expired':
        return const PermissionDeniedFailure();
      default:
        return const UnknownFailure();
    }
  }
}
