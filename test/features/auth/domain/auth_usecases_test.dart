import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/auth/domain/entities/app_user.dart';
import 'package:sigap_netra_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:sigap_netra_app/features/auth/data/datasources/fake_auth_data_source.dart';

void main() {
  late FakeAuthDataSource dataSource;
  late FakeAuthRepositoryImpl repository;
  late SignInWithEmail signInWithEmail;

  setUp(() {
    dataSource = FakeAuthDataSource();
    repository = FakeAuthRepositoryImpl(dataSource);
    signInWithEmail = SignInWithEmail(repository);
  });

  tearDown(() => dataSource.dispose());

  group('SignInWithEmail', () {
    test('menolak email kosong sebelum menyentuh repository', () {
      expect(
        () => signInWithEmail(email: '   ', password: 'rahasia123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('menolak kata sandi kosong', () {
      expect(
        () => signInWithEmail(email: 'user@example.com', password: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('memangkas spasi pada email', () async {
      final user = await signInWithEmail(
        email: '  user@example.com ',
        password: 'rahasia123',
      );

      expect(user.email, 'user@example.com');
    });
  });

  group('AuthRepositoryImpl simulasi', () {
    test('status awal adalah signed out', () async {
      final states = await repository.watchAuthState().first;

      expect(states, isA<AuthSignedOut>());
    });

    test('status berubah setelah login', () async {
      await repository.signInWithEmail(
        email: 'user@example.com',
        password: 'rahasia123',
      );

      final state = await repository.watchAuthState().first;

      expect(state, isA<AuthSignedIn>());
      expect(repository.currentUser?.email, 'user@example.com');
    });

    test('signOut mengembalikan ke signed out', () async {
      await repository.signInWithGoogle();
      await repository.signOut();

      final state = await repository.watchAuthState().first;

      expect(state, isA<AuthSignedOut>());
      expect(repository.currentUser, isNull);
    });

    test('login demo Google tidak memerlukan konfigurasi apa pun', () async {
      final user = await repository.signInWithGoogle();

      expect(user.uid, isNotEmpty);
      expect(user.email, isNotEmpty);
    });
  });
}
