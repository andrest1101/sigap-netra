import 'package:equatable/equatable.dart';

/// Pengguna yang sedang masuk ke aplikasi.
class AppUser extends Equatable {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [uid, email, displayName];
}

/// Status autentikasi yang diamati aplikasi.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Status autentikasi belum diketahui karena Firestore/Auth belum merespons.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Belum ada pengguna yang masuk.
final class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// Sudah ada pengguna yang masuk.
final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}
