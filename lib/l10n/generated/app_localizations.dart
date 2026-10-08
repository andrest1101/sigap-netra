import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'SiGap Netra'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pendamping kacamata pintar'**
  String get appSubtitle;

  /// No description provided for @commonRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get commonConfirm;

  /// No description provided for @commonBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get commonNext;

  /// No description provided for @commonSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In id, this message translates to:
  /// **'Saring'**
  String get commonFilter;

  /// No description provided for @commonRefresh.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get commonRefresh;

  /// No description provided for @commonLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat...'**
  String get commonLoading;

  /// No description provided for @commonYes.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In id, this message translates to:
  /// **'Tidak'**
  String get commonNo;

  /// No description provided for @commonNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada'**
  String get commonNone;

  /// No description provided for @commonUnknown.
  ///
  /// In id, this message translates to:
  /// **'Tidak diketahui'**
  String get commonUnknown;

  /// No description provided for @commonSeeAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get commonSeeAll;

  /// No description provided for @commonSeeDetail.
  ///
  /// In id, this message translates to:
  /// **'Lihat detail'**
  String get commonSeeDetail;

  /// No description provided for @stateLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat data...'**
  String get stateLoading;

  /// No description provided for @stateEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get stateEmptyTitle;

  /// No description provided for @stateEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Data akan muncul di sini setelah perangkat mengirim pembacaan.'**
  String get stateEmptyBody;

  /// No description provided for @stateErrorTitle.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan'**
  String get stateErrorTitle;

  /// No description provided for @stateErrorBody.
  ///
  /// In id, this message translates to:
  /// **'Data tidak dapat dimuat. Periksa koneksi Anda lalu coba lagi.'**
  String get stateErrorBody;

  /// No description provided for @stateErrorPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Anda tidak memiliki akses ke data ini.'**
  String get stateErrorPermissionDenied;

  /// No description provided for @stateErrorUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Layanan tidak dapat dihubungi saat ini.'**
  String get stateErrorUnavailable;

  /// No description provided for @stateErrorNotFound.
  ///
  /// In id, this message translates to:
  /// **'Data yang Anda cari tidak ditemukan.'**
  String get stateErrorNotFound;

  /// No description provided for @stateErrorResourceExhausted.
  ///
  /// In id, this message translates to:
  /// **'Kuota layanan habis. Coba lagi nanti.'**
  String get stateErrorResourceExhausted;

  /// No description provided for @stateErrorUnknown.
  ///
  /// In id, this message translates to:
  /// **'Kesalahan tidak diketahui. Coba lagi.'**
  String get stateErrorUnknown;

  /// No description provided for @stateErrorNoConnection.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada koneksi internet.'**
  String get stateErrorNoConnection;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In id, this message translates to:
  /// **'Mode luring'**
  String get offlineBannerTitle;

  /// No description provided for @offlineBannerBody.
  ///
  /// In id, this message translates to:
  /// **'Data mungkin sudah tidak terbaru.'**
  String get offlineBannerBody;

  /// No description provided for @offlineBannerCached.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan data dari cache perangkat.'**
  String get offlineBannerCached;

  /// No description provided for @navHome.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navHome;

  /// No description provided for @navValidation.
  ///
  /// In id, this message translates to:
  /// **'Validasi'**
  String get navValidation;

  /// No description provided for @navHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get navHistory;

  /// No description provided for @navDevices.
  ///
  /// In id, this message translates to:
  /// **'Perangkat'**
  String get navDevices;

  /// No description provided for @navSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get navSettings;

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk untuk memantau perangkat SiGap Netra.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get loginPasswordLabel;

  /// No description provided for @loginSignInWithEmail.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan email'**
  String get loginSignInWithEmail;

  /// No description provided for @loginSignInWithGoogle.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get loginSignInWithGoogle;

  /// No description provided for @loginSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get loginSignOut;

  /// No description provided for @loginPasswordHint.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi minimal 6 karakter.'**
  String get loginPasswordHint;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid.'**
  String get loginInvalidEmail;

  /// No description provided for @loginWrongPassword.
  ///
  /// In id, this message translates to:
  /// **'Email atau kata sandi salah.'**
  String get loginWrongPassword;

  /// No description provided for @loginTooManyAttempts.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Coba lagi nanti.'**
  String get loginTooManyAttempts;

  /// No description provided for @loginAccountDisabled.
  ///
  /// In id, this message translates to:
  /// **'Akun ini dinonaktifkan.'**
  String get loginAccountDisabled;

  /// No description provided for @loginEmailInUse.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah terdaftar.'**
  String get loginEmailInUse;

  /// No description provided for @loginWeakPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi terlalu lemah.'**
  String get loginWeakPassword;

  /// No description provided for @loginRequiredField.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi.'**
  String get loginRequiredField;

  /// No description provided for @homeTitle.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get homeTitle;

  /// No description provided for @homeSyncNow.
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan sekarang'**
  String get homeSyncNow;

  /// No description provided for @homeSyncSent.
  ///
  /// In id, this message translates to:
  /// **'Permintaan sinkronisasi dikirim.'**
  String get homeSyncSent;

  /// No description provided for @homeRecentActivity.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas terbaru'**
  String get homeRecentActivity;

  /// No description provided for @homeValidationSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan validasi'**
  String get homeValidationSummary;

  /// No description provided for @homeNoDevicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perangkat'**
  String get homeNoDevicesTitle;

  /// No description provided for @homeNoDevicesBody.
  ///
  /// In id, this message translates to:
  /// **'Daftarkan perangkat pertama Anda melalui menu Perangkat.'**
  String get homeNoDevicesBody;

  /// No description provided for @homeAccuracyLabel.
  ///
  /// In id, this message translates to:
  /// **'Akurasi'**
  String get homeAccuracyLabel;

  /// No description provided for @homeValidatedLabel.
  ///
  /// In id, this message translates to:
  /// **'Tervalidasi'**
  String get homeValidatedLabel;

  /// No description provided for @homePendingLabel.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get homePendingLabel;

  /// No description provided for @homeLastSeenLabel.
  ///
  /// In id, this message translates to:
  /// **'Terakhir terlihat'**
  String get homeLastSeenLabel;

  /// No description provided for @statusOnline.
  ///
  /// In id, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In id, this message translates to:
  /// **'Terputus'**
  String get statusOffline;

  /// No description provided for @statusConnecting.
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan'**
  String get statusConnecting;

  /// No description provided for @statusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get statusPending;

  /// No description provided for @statusMatch.
  ///
  /// In id, this message translates to:
  /// **'Cocok'**
  String get statusMatch;

  /// No description provided for @statusMismatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak cocok'**
  String get statusMismatch;

  /// No description provided for @statusUnvalidated.
  ///
  /// In id, this message translates to:
  /// **'Belum'**
  String get statusUnvalidated;

  /// No description provided for @statusWarning.
  ///
  /// In id, this message translates to:
  /// **'Perlu perhatian'**
  String get statusWarning;

  /// No description provided for @statusError.
  ///
  /// In id, this message translates to:
  /// **'Gangguan'**
  String get statusError;

  /// No description provided for @validationTitle.
  ///
  /// In id, this message translates to:
  /// **'Validasi'**
  String get validationTitle;

  /// No description provided for @validationMarkMatch.
  ///
  /// In id, this message translates to:
  /// **'Cocok'**
  String get validationMarkMatch;

  /// No description provided for @validationMarkMismatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak cocok'**
  String get validationMarkMismatch;

  /// No description provided for @validationUndo.
  ///
  /// In id, this message translates to:
  /// **'Batalkan validasi'**
  String get validationUndo;

  /// No description provided for @validationUndoDone.
  ///
  /// In id, this message translates to:
  /// **'Validasi dibatalkan.'**
  String get validationUndoDone;

  /// No description provided for @validationResetAll.
  ///
  /// In id, this message translates to:
  /// **'Reset semua validasi'**
  String get validationResetAll;

  /// No description provided for @validationResetAllConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset semua validasi?'**
  String get validationResetAllConfirmTitle;

  /// No description provided for @validationResetAllConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Semua penanda Cocok dan Tidak cocok akan dihapus. Tindakan ini tidak dapat dibatalkan.'**
  String get validationResetAllConfirmBody;

  /// No description provided for @validationFilterPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get validationFilterPending;

  /// No description provided for @validationFilterMatch.
  ///
  /// In id, this message translates to:
  /// **'Cocok'**
  String get validationFilterMatch;

  /// No description provided for @validationFilterMismatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak cocok'**
  String get validationFilterMismatch;

  /// No description provided for @validationEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pembacaan menunggu'**
  String get validationEmptyTitle;

  /// No description provided for @validationEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Semua pembacaan sudah divalidasi.'**
  String get validationEmptyBody;

  /// No description provided for @validationNoImage.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada gambar untuk pembacaan ini.'**
  String get validationNoImage;

  /// No description provided for @validationDistanceLabel.
  ///
  /// In id, this message translates to:
  /// **'Jarak'**
  String get validationDistanceLabel;

  /// No description provided for @validationConfidenceLabel.
  ///
  /// In id, this message translates to:
  /// **'Keyakinan'**
  String get validationConfidenceLabel;

  /// No description provided for @historyTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get historyTitle;

  /// No description provided for @historyFilterType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get historyFilterType;

  /// No description provided for @historyTypeMoney.
  ///
  /// In id, this message translates to:
  /// **'Uang'**
  String get historyTypeMoney;

  /// No description provided for @historyTypeText.
  ///
  /// In id, this message translates to:
  /// **'Teks'**
  String get historyTypeText;

  /// No description provided for @historyFilterDate.
  ///
  /// In id, this message translates to:
  /// **'Rentang tanggal'**
  String get historyFilterDate;

  /// No description provided for @historyFilterStatus.
  ///
  /// In id, this message translates to:
  /// **'Status validasi'**
  String get historyFilterStatus;

  /// No description provided for @historyToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get historyToday;

  /// No description provided for @historyLast7Days.
  ///
  /// In id, this message translates to:
  /// **'7 hari terakhir'**
  String get historyLast7Days;

  /// No description provided for @historyLast30Days.
  ///
  /// In id, this message translates to:
  /// **'30 hari terakhir'**
  String get historyLast30Days;

  /// No description provided for @historyAllTime.
  ///
  /// In id, this message translates to:
  /// **'Semua waktu'**
  String get historyAllTime;

  /// No description provided for @historyLoadMore.
  ///
  /// In id, this message translates to:
  /// **'Muat lagi'**
  String get historyLoadMore;

  /// No description provided for @historyEndOfList.
  ///
  /// In id, this message translates to:
  /// **'Inilah seluruh riwayat.'**
  String get historyEndOfList;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus pembacaan ini?'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Pembacaan dan thumbnail terkait akan dihapus permanen.'**
  String get historyDeleteBody;

  /// No description provided for @historyDeleted.
  ///
  /// In id, this message translates to:
  /// **'Pembacaan dihapus.'**
  String get historyDeleted;

  /// No description provided for @historySummaryTitle.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan harian'**
  String get historySummaryTitle;

  /// No description provided for @historyDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail pembacaan'**
  String get historyDetailTitle;

  /// No description provided for @devicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Perangkat'**
  String get devicesTitle;

  /// No description provided for @devicesEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perangkat'**
  String get devicesEmptyTitle;

  /// No description provided for @devicesEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan perangkat untuk mulai memantau.'**
  String get devicesEmptyBody;

  /// No description provided for @deviceDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail perangkat'**
  String get deviceDetailTitle;

  /// No description provided for @deviceFirmwareLabel.
  ///
  /// In id, this message translates to:
  /// **'Versi firmware'**
  String get deviceFirmwareLabel;

  /// No description provided for @deviceModelLabel.
  ///
  /// In id, this message translates to:
  /// **'Model'**
  String get deviceModelLabel;

  /// No description provided for @deviceWifiLabel.
  ///
  /// In id, this message translates to:
  /// **'Wi-Fi'**
  String get deviceWifiLabel;

  /// No description provided for @deviceBootCountLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah boot'**
  String get deviceBootCountLabel;

  /// No description provided for @deviceRemoteControl.
  ///
  /// In id, this message translates to:
  /// **'Kontrol jarak jauh'**
  String get deviceRemoteControl;

  /// No description provided for @deviceAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah perangkat'**
  String get deviceAdd;

  /// No description provided for @deviceRemoveTitle.
  ///
  /// In id, this message translates to:
  /// **'Lepas perangkat ini?'**
  String get deviceRemoveTitle;

  /// No description provided for @deviceRemoveBody.
  ///
  /// In id, this message translates to:
  /// **'Perangkat akan dihapus dari daftar Anda. Data di perangkat tidak terpengaruh.'**
  String get deviceRemoveBody;

  /// No description provided for @deviceRemoved.
  ///
  /// In id, this message translates to:
  /// **'Perangkat dilepas.'**
  String get deviceRemoved;

  /// No description provided for @deviceThumbnailOn.
  ///
  /// In id, this message translates to:
  /// **'Thumbnail diunggah'**
  String get deviceThumbnailOn;

  /// No description provided for @deviceThumbnailOff.
  ///
  /// In id, this message translates to:
  /// **'Thumbnail tidak diunggah'**
  String get deviceThumbnailOff;

  /// No description provided for @provisioningTitle.
  ///
  /// In id, this message translates to:
  /// **'Pasang Wi-Fi'**
  String get provisioningTitle;

  /// No description provided for @provisioningIntro.
  ///
  /// In id, this message translates to:
  /// **'Pindai QR ini dengan kamera kacamata untuk menghubungkan perangkat ke Wi-Fi.'**
  String get provisioningIntro;

  /// No description provided for @provisioningSsidLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Wi-Fi (SSID)'**
  String get provisioningSsidLabel;

  /// No description provided for @provisioningPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi Wi-Fi'**
  String get provisioningPasswordLabel;

  /// No description provided for @provisioningShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan kata sandi'**
  String get provisioningShowPassword;

  /// No description provided for @provisioningGenerate.
  ///
  /// In id, this message translates to:
  /// **'Buat QR'**
  String get provisioningGenerate;

  /// No description provided for @provisioningWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu perangkat terhubung...'**
  String get provisioningWaiting;

  /// No description provided for @provisioningSuccess.
  ///
  /// In id, this message translates to:
  /// **'Perangkat berhasil terhubung.'**
  String get provisioningSuccess;

  /// No description provided for @provisioningFailed.
  ///
  /// In id, this message translates to:
  /// **'Perangkat gagal terhubung. Periksa kata sandi Wi-Fi.'**
  String get provisioningFailed;

  /// No description provided for @provisioningInvalidSsid.
  ///
  /// In id, this message translates to:
  /// **'Nama Wi-Fi tidak valid.'**
  String get provisioningInvalidSsid;

  /// No description provided for @provisioningPasswordTooShort.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi Wi-Fi minimal 8 karakter.'**
  String get provisioningPasswordTooShort;

  /// No description provided for @provisioningPasswordNotStored.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi tidak disimpan di aplikasi.'**
  String get provisioningPasswordNotStored;

  /// No description provided for @commandsTitle.
  ///
  /// In id, this message translates to:
  /// **'Kontrol jarak jauh'**
  String get commandsTitle;

  /// No description provided for @commandsSyncNow.
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan sekarang'**
  String get commandsSyncNow;

  /// No description provided for @commandsSpeakText.
  ///
  /// In id, this message translates to:
  /// **'Ucapkan teks'**
  String get commandsSpeakText;

  /// No description provided for @commandsSetVolume.
  ///
  /// In id, this message translates to:
  /// **'Atur volume'**
  String get commandsSetVolume;

  /// No description provided for @commandsRestart.
  ///
  /// In id, this message translates to:
  /// **'Mulai ulang'**
  String get commandsRestart;

  /// No description provided for @commandsReprovision.
  ///
  /// In id, this message translates to:
  /// **'Pasang ulang Wi-Fi'**
  String get commandsReprovision;

  /// No description provided for @commandsSpeakTextLabel.
  ///
  /// In id, this message translates to:
  /// **'Teks untuk diucapkan'**
  String get commandsSpeakTextLabel;

  /// No description provided for @commandsVolumeLabel.
  ///
  /// In id, this message translates to:
  /// **'Volume'**
  String get commandsVolumeLabel;

  /// No description provided for @commandsStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get commandsStatusPending;

  /// No description provided for @commandsStatusSent.
  ///
  /// In id, this message translates to:
  /// **'Terkirim'**
  String get commandsStatusSent;

  /// No description provided for @commandsStatusAcked.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get commandsStatusAcked;

  /// No description provided for @commandsStatusDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get commandsStatusDone;

  /// No description provided for @commandsStatusFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get commandsStatusFailed;

  /// No description provided for @commandsConfirmRestartTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai ulang perangkat?'**
  String get commandsConfirmRestartTitle;

  /// No description provided for @commandsConfirmRestartBody.
  ///
  /// In id, this message translates to:
  /// **'Kacamata akan berhenti sejenak dan perlu dipakai kembali.'**
  String get commandsConfirmRestartBody;

  /// No description provided for @commandsSent.
  ///
  /// In id, this message translates to:
  /// **'Perintah dikirim.'**
  String get commandsSent;

  /// No description provided for @eventsTitle.
  ///
  /// In id, this message translates to:
  /// **'Koneksi dan sinkronisasi'**
  String get eventsTitle;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Catatan koneksi dan sistem perangkat akan muncul di sini.'**
  String get eventsEmptyBody;

  /// No description provided for @eventsSeverityInfo.
  ///
  /// In id, this message translates to:
  /// **'Info'**
  String get eventsSeverityInfo;

  /// No description provided for @eventsSeverityWarning.
  ///
  /// In id, this message translates to:
  /// **'Peringatan'**
  String get eventsSeverityWarning;

  /// No description provided for @eventsSeverityError.
  ///
  /// In id, this message translates to:
  /// **'Gangguan'**
  String get eventsSeverityError;

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguage;

  /// No description provided for @settingsPrivacy.
  ///
  /// In id, this message translates to:
  /// **'Privasi'**
  String get settingsPrivacy;

  /// No description provided for @settingsUploadThumbnails.
  ///
  /// In id, this message translates to:
  /// **'Kirim thumbnail pembacaan'**
  String get settingsUploadThumbnails;

  /// No description provided for @settingsUploadThumbnailsBody.
  ///
  /// In id, this message translates to:
  /// **'Thumbnail adalah satu-satunya gambar yang dapat dikirim. Ukurannya dibatasi 60 KB dan tidak menyertakan video atau audio.'**
  String get settingsUploadThumbnailsBody;

  /// No description provided for @settingsUploadThumbnailsConsentTitle.
  ///
  /// In id, this message translates to:
  /// **'Izinkan pengiriman thumbnail?'**
  String get settingsUploadThumbnailsConsentTitle;

  /// No description provided for @settingsUploadThumbnailsConsentBody.
  ///
  /// In id, this message translates to:
  /// **'Thumbnail berisi Potongan gambar pembacaan dan dapat memuat informasi pribadi. Video, audio, dan lokasi tidak pernah dikirim.'**
  String get settingsUploadThumbnailsConsentBody;

  /// No description provided for @settingsDeveloperMode.
  ///
  /// In id, this message translates to:
  /// **'Mode pengembang'**
  String get settingsDeveloperMode;

  /// No description provided for @settingsDeveloperModeBody.
  ///
  /// In id, this message translates to:
  /// **'Gunakan data simulasi tanpa perangkat keras dan tanpa Firebase.'**
  String get settingsDeveloperModeBody;

  /// No description provided for @settingsDataSourceFirebase.
  ///
  /// In id, this message translates to:
  /// **'Firebase'**
  String get settingsDataSourceFirebase;

  /// No description provided for @settingsDataSourceSimulation.
  ///
  /// In id, this message translates to:
  /// **'Simulasi'**
  String get settingsDataSourceSimulation;

  /// No description provided for @settingsAbout.
  ///
  /// In id, this message translates to:
  /// **'Tentang aplikasi'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi'**
  String get settingsVersion;

  /// No description provided for @settingsAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get settingsAccount;

  /// No description provided for @settingsSignedInAs.
  ///
  /// In id, this message translates to:
  /// **'Masuk sebagai'**
  String get settingsSignedInAs;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari aplikasi?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Anda perlu masuk lagi untuk melihat data perangkat.'**
  String get settingsSignOutConfirmBody;

  /// No description provided for @sharingTitle.
  ///
  /// In id, this message translates to:
  /// **'Bagikan hasil'**
  String get sharingTitle;

  /// No description provided for @sharingConsentTitle.
  ///
  /// In id, this message translates to:
  /// **'Izinkan berbagi data ini?'**
  String get sharingConsentTitle;

  /// No description provided for @sharingConsentBody.
  ///
  /// In id, this message translates to:
  /// **'Teks hasil pengenalan dapat memuat informasi pribadi. Data yang dibagikan tidak menyimpan foto, video, atau lokasi.'**
  String get sharingConsentBody;

  /// No description provided for @sharingAction.
  ///
  /// In id, this message translates to:
  /// **'Bagikan'**
  String get sharingAction;

  /// No description provided for @sharingShareText.
  ///
  /// In id, this message translates to:
  /// **'Hasil pengenalan SiGap Netra'**
  String get sharingShareText;

  /// No description provided for @sharingEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data untuk dibagikan.'**
  String get sharingEmpty;

  /// No description provided for @timeJustNow.
  ///
  /// In id, this message translates to:
  /// **'Baru saja'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} menit lalu'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} jam lalu'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} hari lalu'**
  String timeDaysAgo(int count);

  /// No description provided for @timeNever.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah'**
  String get timeNever;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
