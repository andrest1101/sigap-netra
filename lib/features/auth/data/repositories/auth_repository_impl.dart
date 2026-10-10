import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';

/// Implementasi [AuthRepository] di atas Firebase Auth.
///
/// Satu-satunya tempat di aplikasi yang memanggil `signInWithGoogle` dan
/// friends. Error dipetakan ke `AppFailure` supaya presentation tidak pernah
/// melihat `FirebaseAuthException`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  @override
  Stream<AuthState> watchAuthState() =>
      mapFirebaseAuthStream(_dataSource.authStateChanges());

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownFailure();
      }
      return AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } on Object catch (error) {
      throw _dataSource.mapError(error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final credential = await _dataSource.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw const UnknownFailure();
      }
      return AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } on Object catch (error) {
      throw _dataSource.mapError(error);
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownFailure();
      }
      return AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } on Object catch (error) {
      throw _dataSource.mapError(error);
    }
  }

  @override
  Future<AppUser> signInAnonymously() async {
    try {
      final credential = await _dataSource.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw const UnknownFailure();
      }
      return AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } on Object catch (error) {
      throw _dataSource.mapError(error);
    }
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
