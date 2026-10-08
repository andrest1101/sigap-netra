import 'dart:async';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Sumber data autentikasi simulasi untuk mode pengembang.
///
/// Menyimpan satu pengguna demo di memori. Tidak menyentuh Firebase maupun
/// perangkat keras, sehingga seluruh alur aplikasi dapat dicoba. Login demo
/// hanya memerlukan email dan kata sandi yang tidak kosong.
class FakeAuthDataSource {
  // UID demo lokal. Bukan format UID Firestore final dan tidak boleh dipakai
  // sebagai contoh struktur auth production.
  static const String _demoUid = 'simulasi-user-1';
  static const String _demoEmail = 'demo@sigapnetra.local';

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  AppUser? _currentUser;

  /// Mengemit status saat ini lalu setiap perubahan berikutnya.
  ///
  /// Berbeda dengan `Stream.broadcast` biasa, pendengar baru langsung
  /// mendapatkan nilai terkini. Tanpa itu, provider yang dibangun ulang akan
  /// menunggu selamanya karena nilainya dikirim sebelum ada pendengar.
  Stream<AuthState> authStateChanges() {
    return Stream<AuthState>.multi((controller) {
      final user = _currentUser;
      controller.add(user == null ? const AuthSignedOut() : AuthSignedIn(user));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  AppUser? get currentUser => _currentUser;

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const ValidationFailure('loginRequiredField');
    }
    final user = AppUser(uid: _demoUid, email: email.trim());
    _currentUser = user;
    _controller.add(AuthSignedIn(user));
    return user;
  }

  Future<AppUser> signInWithGoogle() async {
    // Mode pengembang tidak bergantung pada Google. Login tetap memakai akun
    // demo supaya alur aplikasi bisa dilanjutkan tanpa konfigurasi apa pun.
    const user = AppUser(uid: _demoUid, email: _demoEmail);
    _currentUser = user;
    _controller.add(const AuthSignedIn(user));
    return user;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(const AuthSignedOut());
  }

  void dispose() => _controller.close();
}

/// Implementasi [AuthRepository] untuk data simulasi.
class FakeAuthRepositoryImpl implements AuthRepository {
  FakeAuthRepositoryImpl(this._dataSource);

  final FakeAuthDataSource _dataSource;

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Stream<AuthState> watchAuthState() => _dataSource.authStateChanges();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => _dataSource.signInWithEmail(email: email, password: password);

  @override
  Future<AppUser> signInWithGoogle() => _dataSource.signInWithGoogle();

  @override
  Future<void> signOut() => _dataSource.signOut();
}
