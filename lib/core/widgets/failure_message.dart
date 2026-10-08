import '../errors/app_failure.dart';
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

/// Mengubah `AppFailure` menjadi pesan siap tampil.
///
/// Dipakai semua layar agar pesan error konsisten dan `core/errors`
/// tidak perlu bergantung pada Flutter localization.
String failureMessage(AppFailure failure, AppLocalizations l10n) =>
    switch (failure) {
      PermissionDeniedFailure() => l10n.stateErrorPermissionDenied,
      NetworkUnavailableFailure() => l10n.stateErrorUnavailable,
      NotFoundFailure() => l10n.stateErrorNotFound,
      QuotaExceededFailure() => l10n.stateErrorResourceExhausted,
      ValidationFailure(:final messageKey) => l10n.lookupKey(messageKey),
      UnknownFailure() => l10n.stateErrorUnknown,
    };
