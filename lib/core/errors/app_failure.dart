import 'package:equatable/equatable.dart';

import '../../l10n/generated/app_localizations.dart';

/// Pencarian pesan berdasarkan kunci l10n.
///
/// Generator `flutter gen-l10n` hanya menghasilkan getter, bukan peta
/// string-dinamis, jadi `ValidationFailure` yang membawa kuncinya sendiri
/// membutuhkan fungsi pencarian ini. Kunci yang tidak dikenal jatuh ke pesan
/// error umum supaya UI tidak pernah menampilkan string kosong.
extension AppLocalizationsLookup on AppLocalizations {
  String lookupKey(String key) => switch (key) {
    'loginInvalidEmail' => loginInvalidEmail,
    'loginWrongPassword' => loginWrongPassword,
    'loginTooManyAttempts' => loginTooManyAttempts,
    'loginAccountDisabled' => loginAccountDisabled,
    'loginEmailInUse' => loginEmailInUse,
    'loginWeakPassword' => loginWeakPassword,
    'loginRequiredField' => loginRequiredField,
    'provisioningInvalidSsid' => provisioningInvalidSsid,
    'provisioningPasswordTooShort' => provisioningPasswordTooShort,
    'stateErrorUnknown' => stateErrorUnknown,
    _ => stateErrorUnknown,
  };
}

/// Kegagalan yang bisa terjadi pada lapisan domain.
///
/// Domain tidak boleh tahu apa pun tentang `FirebaseException`, jadi semua
/// error dari data layer dipetakan menjadi nilai bertipe ini sebelum mencapai
/// presentation. Lihat `firebase_error_mapper.dart` untuk pemetaannya.
sealed class AppFailure extends Equatable {
  const AppFailure();

  /// Kunci pesan pada `lib/l10n/app_id.arb`.
  ///
  /// Berguna untuk log dan pengujian tanpa membangun widget tree.
  String get messageKey;

  /// Pesan siap tampil dalam Bahasa Indonesia.
  String message(AppLocalizations l10n) => switch (this) {
    PermissionDeniedFailure() => l10n.stateErrorPermissionDenied,
    NetworkUnavailableFailure() => l10n.stateErrorUnavailable,
    NotFoundFailure() => l10n.stateErrorNotFound,
    QuotaExceededFailure() => l10n.stateErrorResourceExhausted,
    ValidationFailure() => l10n.lookupKey(messageKey),
    UnknownFailure() => l10n.stateErrorUnknown,
  };

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
