import '../entities/app_user.dart';

/// Kontrak autentikasi pada domain.
///
/// Implementasi Firestore/Auth ada di `features/auth/data`. Domain tidak tahu
/// apa pun tentang `firebase_auth`.
abstract interface class AuthRepository {
  /// Memantau status autentikasi secara berkelanjutan.
  Stream<AuthState> watchAuthState();

  /// Pengguna yang sedang masuk, atau null bila belum masuk.
  AppUser? get currentUser;

  /// Masuk dengan email dan kata sandi.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Masuk dengan akun Google.
  Future<AppUser> signInWithGoogle();

  /// Keluar dari akun.
  Future<void> signOut();
}
