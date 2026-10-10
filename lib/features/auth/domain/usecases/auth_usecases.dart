import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Memantau status autentikasi untuk redirect router.
class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AuthState> call() => _repository.watchAuthState();
}

/// Validasi format email bersama untuk masuk dan daftar.
///
/// Domain memakai pola sederhana (ada `@` + titik setelahnya), bukan regex
/// RFC penuh — cukup untuk menangkap salah ketik umum tanpa menolak alamat
/// sah yang aneh.
bool isValidEmail(String email) {
  final trimmed = email.trim();
  final at = trimmed.indexOf('@');
  if (at <= 0) return false;
  final dot = trimmed.indexOf('.', at + 1);
  return dot > at + 1 && dot < trimmed.length - 1;
}

/// Memasuk dengan email dan kata sandi.
class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email tidak boleh kosong.');
    }
    if (!isValidEmail(trimmedEmail)) {
      throw ArgumentError('loginInvalidEmail');
    }
    if (password.isEmpty) {
      throw ArgumentError('Kata sandi tidak boleh kosong.');
    }
    return _repository.signInWithEmail(email: trimmedEmail, password: password);
  }
}

/// Mendaftarkan akun baru.
///
/// Aturan: email valid, kata sandi minimal 6 karakter, konfirmasi cocok.
/// Pesan memakai kunci l10n (bukan teks Indonesia langsung) agar
/// presentation bisa menampilkannya apa adanya.
class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String confirmPassword,
    String? displayName,
  }) {
    final trimmedEmail = email.trim();
    final trimmedName = displayName?.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email tidak boleh kosong.');
    }
    if (!isValidEmail(trimmedEmail)) {
      throw ArgumentError('loginInvalidEmail');
    }
    if (password.length < 6) {
      throw ArgumentError('loginPasswordTooShort');
    }
    if (password != confirmPassword) {
      throw ArgumentError('loginPasswordMismatch');
    }
    return _repository.signUpWithEmail(
      email: trimmedEmail,
      password: password,
      displayName: trimmedName == null || trimmedName.isEmpty
          ? null
          : trimmedName,
    );
  }
}

/// Masuk sebagai tamu (akun anonim, tanpa validasi input).
class SignInAnonymously {
  const SignInAnonymously(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() => _repository.signInAnonymously();
}

/// Memasuk lewat akun Google.
class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() => _repository.signInWithGoogle();
}

/// Keluar dari akun.
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
