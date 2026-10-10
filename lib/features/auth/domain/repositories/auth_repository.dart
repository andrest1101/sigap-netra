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

  /// Mendaftarkan akun baru dengan email dan kata sandi.
  ///
  /// [displayName] opsional (nama panggilan pendamping).
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Masuk sebagai tamu (akun anonim).
  ///
  /// Butuh provider Anonymous aktif di Firebase console. Tanpa itu data
  /// source melempar `AppFailure` yang ditangani ramah di presentation.
  Future<AppUser> signInAnonymously();

  /// Keluar dari akun.
  Future<void> signOut();
}
