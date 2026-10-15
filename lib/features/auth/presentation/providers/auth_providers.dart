import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/retry_policy.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Sumber autentikasi aktif.
///
/// Di-override di `main.dart` dengan `AuthRepositoryImpl` untuk Firebase atau
/// `FakeAuthRepositoryImpl` untuk mode pengembang. Provider ini tidak pernah
/// menyebut kedua implementasi secara langsung, sehingga presentation layer
/// selalu hanya melihat kontrak domain.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(
    'authRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

/// Use case autentikasi, diekspos per use case agar dependensinya eksplisit.
final watchAuthStateProvider = Provider<WatchAuthState>(
  (ref) => WatchAuthState(ref.watch(authRepositoryProvider)),
);

final signInWithEmailProvider = Provider<SignInWithEmail>(
  (ref) => SignInWithEmail(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleProvider = Provider<SignInWithGoogle>(
  (ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)),
);

final signUpWithEmailProvider = Provider<SignUpWithEmail>(
  (ref) => SignUpWithEmail(ref.watch(authRepositoryProvider)),
);

final signInAnonymouslyProvider = Provider<SignInAnonymously>(
  (ref) => SignInAnonymously(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

/// Status autentikasi saat ini, dipakai router untuk redirect.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(watchAuthStateProvider).call(),
  retry: retryBriefly,
);

/// Pengguna yang sedang masuk, atau null.
///
/// WAJIB reaktif terhadap [authStateProvider]: provider ini bisa terbaca
/// pertama kali saat app baru mulai (root `app.dart` memantau daftar perangkat
/// untuk cache nama) ketika belum ada pengguna. Tanpa `ref.watch` di sini,
/// nilai `null` tersebut ter-cache selamanya dan semua tab menampilkan
/// "Belum ada perangkat" meski login berhasil. Nilai dibaca dari getter
/// repository supaya sesi yang langsung dipulihkan Firebase tetap terbaca
/// tanpa menunggu emisi stream.
final currentUserProvider = Provider<AppUser?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});
