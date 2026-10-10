import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/app_user.dart';

/// Sumber data autentikasi berbasis Firebase Auth.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuth get auth => _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Masuk dengan Google melalui alur dua langkah.
  ///
  /// `google_sign_in` 7.x tidak lagi offer `FirebaseAuth.signInWithGoogle`,
  /// jadi token ID dari Google ditukar menjadi `OAuthCredential` lalu
  /// diteruskan ke Firebase.
  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const ValidationFailure('loginWrongPassword');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  /// Mendaftarkan akun baru; mengisi nama tampilan bila diberikan.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final name = displayName?.trim();
    if (credential.user != null && name != null && name.isNotEmpty) {
      await credential.user!.updateDisplayName(name);
      await credential.user!.reload();
    }
    return credential;
  }

  /// Masuk anonim sebagai tamu.
  ///
  /// Gagal dengan `operation-not-allowed` bila provider Anonymous belum
  /// diaktifkan di Firebase console — dipetakan ke `AppFailure` oleh
  /// repository agar presentation menampilkan pesan ramah.
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  AppFailure mapError(Object error) {
    if (error is FirebaseAuthException) return error.toAppFailure();
    if (error is FirebaseException) return error.toAppFailure();
    return const UnknownFailure();
  }
}

/// Aliran status autentikasi mentah dari Firebase, sudah dipetakan ke
/// `AppUser` domain. Dipakai juga oleh `FakeAuthDataSource` melalui pola yang
/// sama agar repository tidak perlu tahu asal datanya.
Stream<AuthState> mapFirebaseAuthStream(Stream<User?> stream) {
  return stream.map((user) {
    if (user == null) return const AuthSignedOut();
    return AuthSignedIn(
      AppUser(uid: user.uid, email: user.email, displayName: user.displayName),
    );
  });
}
