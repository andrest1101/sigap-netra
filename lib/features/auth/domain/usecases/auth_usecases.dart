import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Memantau status autentikasi untuk redirect router.
class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AuthState> call() => _repository.watchAuthState();
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
    if (password.isEmpty) {
      throw ArgumentError('Kata sandi tidak boleh kosong.');
    }
    return _repository.signInWithEmail(email: trimmedEmail, password: password);
  }
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
