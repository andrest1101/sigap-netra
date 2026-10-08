import 'package:equatable/equatable.dart';

/// Kegagalan yang bisa terjadi pada lapisan domain.
///
/// Domain tidak boleh tahu apa pun tentang `FirebaseException`, jadi semua
/// error dari data layer dipetakan menjadi nilai bertipe ini sebelum mencapai
/// presentation. Lihat `firebase_error_mapper.dart` untuk pemetaannya.
sealed class AppFailure extends Equatable {
  const AppFailure();

  /// Kunci pesan pada `lib/l10n/app_id.arb`.
  ///
  /// Berguna untuk log dan pengujian tanpa membangun widget tree. Pesan
  /// siap-tampil diselesaikan oleh `failureMessage()` di presentation.
  String get messageKey;

  /// Aksi pemulihan yang bisa ditawarkan ke pengguna.
  RecoveryAction get recoveryAction;

  @override
  List<Object?> get props => [messageKey, recoveryAction];
}

/// Aksi pemulihan yang tersedia untuk ditampilkan di pesan error.
enum RecoveryAction {
  /// Pengguna boleh mencoba ulang, misalnya dengan tombol "Coba lagi".
  retry,

  /// Pengguna perlu masuk ulang.
  reauthenticate,

  /// Tidak ada aksi; hanya informatif (mis. data tidak ditemukan).
  none,
}

/// Keamanan atau aturan Firestore menolak operasi.
final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure();

  @override
  String get messageKey => 'stateErrorPermissionDenied';

  @override
  RecoveryAction get recoveryAction => RecoveryAction.reauthenticate;
}

/// Layanan tidak dapat dihubungi: offline, DNS, atau timeout.
final class NetworkUnavailableFailure extends AppFailure {
  const NetworkUnavailableFailure();

  @override
  String get messageKey => 'stateErrorUnavailable';

  @override
  RecoveryAction get recoveryAction => RecoveryAction.retry;
}

/// Dokumen yang diminta tidak ada.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();

  @override
  String get messageKey => 'stateErrorNotFound';

  @override
  RecoveryAction get recoveryAction => RecoveryAction.none;
}

/// Kuota Firebase (baca/tulis/hapus) habis. Plan Spark akan membatasi.
final class QuotaExceededFailure extends AppFailure {
  const QuotaExceededFailure();

  @override
  String get messageKey => 'stateErrorResourceExhausted';

  @override
  RecoveryAction get recoveryAction => RecoveryAction.retry;
}

/// Validasi input lokal gagal, misalnya SSID kosong atau kata sandi terlalu
/// pendek. Tidak berasal dari jaringan.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.key);

  final String key;

  @override
  String get messageKey => key;

  @override
  RecoveryAction get recoveryAction => RecoveryAction.none;
}

/// Kegagalan yang tidak terpetakan.
final class UnknownFailure extends AppFailure {
  const UnknownFailure();

  @override
  String get messageKey => 'stateErrorUnknown';

  @override
  RecoveryAction get recoveryAction => RecoveryAction.retry;
}
