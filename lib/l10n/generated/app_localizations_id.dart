// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'SIGAP-NETRA';

  @override
  String get appSubtitle => 'Pendamping kacamata pintar';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonConfirm => 'Konfirmasi';

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonNext => 'Lanjut';

  @override
  String get commonSearch => 'Cari';

  @override
  String get commonFilter => 'Saring';

  @override
  String get commonRefresh => 'Muat ulang';

  @override
  String get commonLoading => 'Memuat...';

  @override
  String get commonYes => 'Ya';

  @override
  String get commonNo => 'Tidak';

  @override
  String get commonNone => 'Tidak ada';

  @override
  String get commonUnknown => 'Tidak diketahui';

  @override
  String get commonSeeAll => 'Lihat semua';

  @override
  String get commonSeeDetail => 'Lihat detail';

  @override
  String get commonLoadMore => 'Muat lagi';

  @override
  String get commonDone => 'Selesai';

  @override
  String get stateLoading => 'Memuat data...';

  @override
  String get stateEmptyTitle => 'Belum ada data';

  @override
  String get stateEmptyBody =>
      'Data akan muncul di sini setelah perangkat mengirim pembacaan.';

  @override
  String get stateErrorTitle => 'Terjadi kesalahan';

  @override
  String get stateErrorBody =>
      'Data tidak dapat dimuat. Periksa koneksi Anda lalu coba lagi.';

  @override
  String get stateErrorPermissionDenied =>
      'Anda tidak memiliki akses ke data ini.';

  @override
  String get stateErrorUnavailable => 'Layanan tidak dapat dihubungi saat ini.';

  @override
  String get stateErrorNotFound => 'Data yang Anda cari tidak ditemukan.';

  @override
  String get stateErrorResourceExhausted =>
      'Kuota layanan habis. Coba lagi nanti.';

  @override
  String get stateErrorUnknown => 'Kesalahan tidak diketahui. Coba lagi.';

  @override
  String get stateErrorNoConnection => 'Tidak ada koneksi internet.';

  @override
  String get offlineBannerTitle => 'Mode luring';

  @override
  String get offlineBannerBody => 'Data mungkin sudah tidak terbaru.';

  @override
  String get offlineBannerCached => 'Menampilkan data dari cache perangkat.';

  @override
  String get navHome => 'Beranda';

  @override
  String get navValidation => 'Validasi';

  @override
  String get navHistory => 'Riwayat';

  @override
  String get navDevices => 'Perangkat';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get loginOrDivider => 'atau';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle => 'Masuk untuk memantau perangkat SIGAP-NETRA.';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Kata sandi';

  @override
  String get loginSignInWithEmail => 'Masuk dengan email';

  @override
  String get loginSignInWithGoogle => 'Masuk dengan Google';

  @override
  String get loginSignOut => 'Keluar';

  @override
  String get loginPasswordHint => 'Kata sandi minimal 6 karakter.';

  @override
  String get loginInvalidEmail => 'Format email tidak valid.';

  @override
  String get loginWrongPassword => 'Email atau kata sandi salah.';

  @override
  String get loginTooManyAttempts =>
      'Terlalu banyak percobaan. Coba lagi nanti.';

  @override
  String get loginAccountDisabled => 'Akun ini dinonaktifkan.';

  @override
  String get loginEmailInUse => 'Email ini sudah terdaftar.';

  @override
  String get loginWeakPassword => 'Kata sandi terlalu lemah.';

  @override
  String get loginRequiredField => 'Wajib diisi.';

  @override
  String get loginWelcomeBack => 'Selamat datang kembali';

  @override
  String get loginWelcomeSubtitle =>
      'Masuk untuk memantau perangkat SIGAP-NETRA.';

  @override
  String get loginHeroPointMoney => 'Bacaan uang & teks';

  @override
  String get loginHeroPointValidate => 'Validasi oleh pendamping';

  @override
  String get loginHeroPointPrivate => 'Tanpa video, audio, GPS';

  @override
  String get loginNoAccount => 'Belum punya akun?';

  @override
  String get loginSignUpLink => 'Daftar';

  @override
  String get loginContinueAsGuest => 'Lanjutkan sebagai tamu';

  @override
  String get loginPasswordMismatch => 'Konfirmasi kata sandi tidak cocok.';

  @override
  String get loginPasswordTooShort => 'Kata sandi minimal 6 karakter.';

  @override
  String get loginSignUpTitle => 'Buat akun';

  @override
  String get loginSignUpSubtitle =>
      'Daftar untuk memantau perangkat SIGAP-NETRA.';

  @override
  String get loginNameLabel => 'Nama (opsional)';

  @override
  String get loginNameHint => 'Nama panggilan Anda';

  @override
  String get loginConfirmPasswordLabel => 'Konfirmasi kata sandi';

  @override
  String get loginCreateAccount => 'Buat akun';

  @override
  String get loginHaveAccount => 'Sudah punya akun?';

  @override
  String get loginSignInLink => 'Masuk';

  @override
  String get loginPrivacyNote =>
      'Hanya email untuk login perangkat. Tanpa video, audio, atau lokasi.';

  @override
  String get loginGuestFailed => 'Masuk tamu gagal. Coba lagi nanti.';

  @override
  String get loginSignUpFailed => 'Pendaftaran gagal. Coba lagi nanti.';

  @override
  String get loginShowPassword => 'Tampilkan kata sandi';

  @override
  String get loginHidePassword => 'Sembunyikan kata sandi';

  @override
  String get homeTitle => 'Beranda';

  @override
  String get homeSyncNow => 'Sinkronkan sekarang';

  @override
  String get homeSyncShort => 'Sinkronkan';

  @override
  String get homeSyncSent => 'Permintaan sinkronisasi dikirim.';

  @override
  String get homeRecentActivity => 'Aktivitas terbaru';

  @override
  String get homeValidationSummary => 'Ringkasan validasi';

  @override
  String get homeNoDevicesTitle => 'Belum ada perangkat';

  @override
  String get homeNoDevicesBody =>
      'Daftarkan perangkat pertama Anda melalui menu Perangkat.';

  @override
  String get homeAccuracyLabel => 'Akurasi';

  @override
  String get homeValidatedLabel => 'Tervalidasi';

  @override
  String get homePendingLabel => 'Menunggu';

  @override
  String get homeLastSeenLabel => 'Terakhir terlihat';

  @override
  String homeAccuracyFromCount(int count) {
    return 'dari $count validasi';
  }

  @override
  String get homeNoValidation => 'Belum ada validasi';

  @override
  String homeTodayBreakdown(int money, int text) {
    return '$money uang · $text teks';
  }

  @override
  String get homeEmptyActivityTitle => 'Belum ada aktivitas';

  @override
  String get homeEmptyActivityBody =>
      'Pembacaan terbaru dari perangkat akan muncul di sini.';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Terputus';

  @override
  String get statusConnecting => 'Menghubungkan';

  @override
  String get statusPending => 'Menunggu';

  @override
  String get statusMatch => 'Cocok';

  @override
  String get statusMismatch => 'Tidak cocok';

  @override
  String get statusUnvalidated => 'Belum';

  @override
  String get statusWarning => 'Perlu perhatian';

  @override
  String get statusError => 'Gangguan';

  @override
  String get validationTitle => 'Validasi';

  @override
  String get validationMarkMatch => 'Cocok';

  @override
  String get validationMarkMismatch => 'Tidak cocok';

  @override
  String get validationUndo => 'Batalkan validasi';

  @override
  String get validationUndoDone => 'Validasi dibatalkan.';

  @override
  String get validationResetAll => 'Reset semua validasi';

  @override
  String get validationResetAllConfirmTitle => 'Reset semua validasi?';

  @override
  String get validationResetAllConfirmBody =>
      'Semua penanda Cocok dan Tidak cocok akan dihapus. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get validationFilterPending => 'Menunggu';

  @override
  String get validationFilterMatch => 'Cocok';

  @override
  String get validationFilterMismatch => 'Tidak cocok';

  @override
  String get validationEmptyTitle => 'Tidak ada pembacaan menunggu';

  @override
  String get validationEmptyBody => 'Semua pembacaan sudah divalidasi.';

  @override
  String get validationNoImage => 'Tidak ada gambar untuk pembacaan ini.';

  @override
  String get validationDistanceLabel => 'Jarak';

  @override
  String get validationConfidenceLabel => 'Keyakinan';

  @override
  String validationConfidenceValue(String value) {
    return 'Keyakinan: $value';
  }

  @override
  String get validationConfidenceNoValue => 'Keyakinan tidak tersedia';

  @override
  String get historyTitle => 'Riwayat';

  @override
  String get historyFilterType => 'Jenis';

  @override
  String get historyTypeMoney => 'Uang';

  @override
  String get historyTypeText => 'Teks';

  @override
  String get historyFilterDate => 'Rentang tanggal';

  @override
  String get historyFilterStatus => 'Status validasi';

  @override
  String get historyToday => 'Hari ini';

  @override
  String get historyLast7Days => '7 hari terakhir';

  @override
  String get historyLast30Days => '30 hari terakhir';

  @override
  String get historyAllTime => 'Semua waktu';

  @override
  String get historyLoadMore => 'Muat lagi';

  @override
  String get historyEndOfList => 'Inilah seluruh riwayat.';

  @override
  String get historyDeleteTitle => 'Hapus pembacaan ini?';

  @override
  String get historyDeleteBody =>
      'Pembacaan dan thumbnail terkait akan dihapus permanen.';

  @override
  String get historyDeleted => 'Pembacaan dihapus.';

  @override
  String historyDeletedNamed(String label) {
    return '$label dihapus dari riwayat.';
  }

  @override
  String get historyResetDone => 'Status validasi direset.';

  @override
  String get historyActionFailed =>
      'Tindakan gagal. Periksa koneksi lalu coba lagi.';

  @override
  String get historySummaryTitle => 'Ringkasan harian';

  @override
  String get historyDetailTitle => 'Detail pembacaan';

  @override
  String get historyRecognitionResult => 'Hasil pengenalan';

  @override
  String get historyEmptyTitle => 'Belum ada pembacaan';

  @override
  String get historyEmptyBody =>
      'Riwayat akan muncul setelah perangkat mengirim pembacaan pertama.';

  @override
  String get historyNoDeviceTitle => 'Belum ada perangkat terhubung';

  @override
  String get historyNoDeviceBody =>
      'Riwayat membaca dari kacamata SIGAP-NETRA. Hubungkan perangkat dulu untuk melihat pembacaan.';

  @override
  String get historyNoDeviceAction => 'Buka Perangkat';

  @override
  String get historyFilterShowAll => 'Tampilkan semua';

  @override
  String get devicesTitle => 'Perangkat';

  @override
  String get devicesEmptyTitle => 'Belum ada perangkat';

  @override
  String get devicesEmptyBody => 'Tambahkan perangkat untuk mulai memantau.';

  @override
  String devicesMultipleNote(int count) {
    return 'Menampilkan perangkat utama dari $count perangkat.';
  }

  @override
  String get deviceDetailTitle => 'Detail perangkat';

  @override
  String get deviceFirmwareLabel => 'Versi firmware';

  @override
  String get deviceModelLabel => 'Model';

  @override
  String get deviceWifiLabel => 'Wi-Fi';

  @override
  String get deviceBootCountLabel => 'Jumlah boot';

  @override
  String get deviceRemoteControl => 'Kontrol jarak jauh';

  @override
  String get deviceAdd => 'Tambah perangkat';

  @override
  String get deviceRemoveTitle => 'Lepas perangkat ini?';

  @override
  String get deviceRemoveBody =>
      'Perangkat akan dihapus dari daftar Anda. Data di perangkat tidak terpengaruh.';

  @override
  String get deviceRemoved => 'Perangkat dilepas.';

  @override
  String get deviceThumbnailOn => 'Thumbnail diunggah';

  @override
  String get deviceThumbnailOff => 'Thumbnail tidak diunggah';

  @override
  String get deviceLocalActive => 'Aktif';

  @override
  String get deviceLocalInactive => 'Tidak aktif';

  @override
  String get provisioningTitle => 'Pasang Wi-Fi';

  @override
  String get provisioningIntro =>
      'Pindai QR ini dengan kamera kacamata untuk menghubungkan perangkat ke Wi-Fi.';

  @override
  String get provisioningSsidLabel => 'Nama Wi-Fi (SSID)';

  @override
  String get provisioningPasswordLabel => 'Kata sandi Wi-Fi';

  @override
  String get provisioningShowPassword => 'Tampilkan kata sandi';

  @override
  String get provisioningGenerate => 'Buat QR';

  @override
  String get provisioningWaiting => 'Menunggu perangkat terhubung...';

  @override
  String get provisioningSuccess => 'Perangkat berhasil terhubung.';

  @override
  String get provisioningFailed =>
      'Perangkat gagal terhubung. Periksa kata sandi Wi-Fi.';

  @override
  String get provisioningInvalidSsid => 'Nama Wi-Fi tidak valid.';

  @override
  String get provisioningPasswordTooShort =>
      'Kata sandi Wi-Fi minimal 8 karakter.';

  @override
  String get provisioningPasswordNotStored =>
      'Kata sandi tidak disimpan di aplikasi.';

  @override
  String get provisioningSuccessHint =>
      'Alat sudah mengirim detak dari jaringan ini. Layar ini bisa ditutup.';

  @override
  String get provisioningTimeoutTitle => 'Belum tersambung';

  @override
  String get provisioningTimeoutBody =>
      'Alat belum mengirim detak dalam 2 menit. Periksa nama jaringan dan kata sandi, lalu coba lagi.';

  @override
  String get commandsTitle => 'Kontrol jarak jauh';

  @override
  String get commandsSyncNow => 'Sinkronkan sekarang';

  @override
  String get commandsSpeakText => 'Ucapkan teks';

  @override
  String get commandsSetVolume => 'Atur volume';

  @override
  String get commandsRestart => 'Mulai ulang';

  @override
  String get commandsReprovision => 'Pasang ulang Wi-Fi';

  @override
  String get commandsSpeakTextLabel => 'Teks untuk diucapkan';

  @override
  String get commandsVolumeLabel => 'Volume';

  @override
  String get commandsStatusPending => 'Menunggu';

  @override
  String get commandsStatusSent => 'Terkirim';

  @override
  String get commandsStatusAcked => 'Diterima';

  @override
  String get commandsStatusDone => 'Selesai';

  @override
  String get commandsStatusFailed => 'Gagal';

  @override
  String get commandsConfirmRestartTitle => 'Mulai ulang perangkat?';

  @override
  String get commandsConfirmRestartBody =>
      'Kacamata akan berhenti sejenak dan perlu dipakai kembali.';

  @override
  String get commandsSent => 'Perintah dikirim.';

  @override
  String get commandsSendFailed => 'Perintah gagal dikirim. Coba lagi.';

  @override
  String commandsWaitingForDevice(String time) {
    return 'Menunggu alat · $time';
  }

  @override
  String commandsVolumeValue(int level) {
    return 'Volume $level';
  }

  @override
  String commandsDetailSpeakText(String text) {
    return 'Teks: “$text”';
  }

  @override
  String get eventsTitle => 'Koneksi dan sinkronisasi';

  @override
  String get eventsEmptyTitle => 'Belum ada catatan';

  @override
  String get eventsEmptyBody =>
      'Catatan koneksi dan sistem perangkat akan muncul di sini.';

  @override
  String get eventsSeverityInfo => 'Info';

  @override
  String get eventsSeverityWarning => 'Peringatan';

  @override
  String get eventsSeverityError => 'Gangguan';

  @override
  String get eventsCategoryNetwork => 'Jaringan';

  @override
  String get eventsCategoryCommand => 'Perintah';

  @override
  String get eventsCategorySystem => 'Sistem';

  @override
  String get eventsCategoryReading => 'Pembacaan';

  @override
  String get eventsCategoryGeneral => 'Kejadian';

  @override
  String eventsLatestNote(int count) {
    return 'Menampilkan $count kejadian terbaru. Pilih saringan untuk menjelajah lebih jauh.';
  }

  @override
  String get eventsAllLoaded =>
      'Semua kejadian pada saringan ini sudah dimuat.';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsUploadThumbnails => 'Kirim thumbnail pembacaan';

  @override
  String get settingsUploadThumbnailsBody =>
      'Thumbnail adalah satu-satunya gambar yang dapat dikirim. Ukurannya dibatasi 60 KB dan tidak menyertakan video atau audio.';

  @override
  String get settingsDeviceUploadsReadOnly =>
      'Nilai ini hanya informasi perangkat.';

  @override
  String get settingsUploadThumbnailsConsentTitle =>
      'Izinkan pengiriman thumbnail?';

  @override
  String get settingsUploadThumbnailsConsentBody =>
      'Thumbnail berisi Potongan gambar pembacaan dan dapat memuat informasi pribadi. Video, audio, dan lokasi tidak pernah dikirim.';

  @override
  String get settingsUploadsManageOnDevice =>
      'Pengunggahan diatur di dokumen perangkat, bukan di aplikasi ini.';

  @override
  String get settingsDeveloperMode => 'Mode pengembang';

  @override
  String get settingsDeveloperModeBody =>
      'Gunakan data simulasi tanpa perangkat keras dan tanpa Firebase.';

  @override
  String get settingsAppliesAfterRestart =>
      'Berlaku setelah aplikasi dimulai ulang.';

  @override
  String get settingsDataSourceFirebase => 'Firebase';

  @override
  String get settingsDataSourceSimulation => 'Simulasi';

  @override
  String get settingsAbout => 'Tentang aplikasi';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsAccount => 'Akun';

  @override
  String get settingsSignedInAs => 'Masuk sebagai';

  @override
  String get settingsSignedInUid => 'ID pengguna';

  @override
  String get settingsSignedOutAsGuest => 'Tamu (belum masuk)';

  @override
  String get settingsSignOutConfirmTitle => 'Keluar dari aplikasi?';

  @override
  String get settingsSignOutConfirmBody =>
      'Anda perlu masuk lagi untuk melihat data perangkat.';

  @override
  String get sharingTitle => 'Bagikan hasil';

  @override
  String get sharingConsentTitle => 'Izinkan berbagi data ini?';

  @override
  String get sharingConsentBody =>
      'Teks hasil pengenalan dapat memuat informasi pribadi. Data yang dibagikan tidak menyimpan foto, video, atau lokasi.';

  @override
  String get sharingAction => 'Bagikan';

  @override
  String get sharingShareText => 'Hasil pengenalan SIGAP-NETRA';

  @override
  String get sharingEmpty => 'Tidak ada data untuk dibagikan.';

  @override
  String get sharingSummaryTitle => 'Ringkasan SIGAP-NETRA';

  @override
  String sharingSummaryTotal(int count) {
    return 'Total: $count pembacaan';
  }

  @override
  String sharingSummaryBreakdown(int money, int text) {
    return 'Uang: $money · Teks: $text';
  }

  @override
  String sharingSummaryAccuracy(String value, int count) {
    return 'Akurasi validasi: $value dari $count pembacaan';
  }

  @override
  String get homeDeviceHero => 'Perangkat';

  @override
  String get homeConnectedNow => 'Terhubung';

  @override
  String get homeDisconnectedSince => 'Terputus';

  @override
  String get homeBatteryLabel => 'Baterai';

  @override
  String get homeBatteryUnavailable => 'Baterai tidak tersedia';

  @override
  String get homePendingReview => 'Periksa';

  @override
  String homeAccuracySemantic(String value) {
    return 'Kecocokan $value persen';
  }

  @override
  String get homeSyncedLabel => 'Sinkron terakhir';

  @override
  String get homeTodayLabel => 'Hari ini';

  @override
  String homeReadingsToday(int count) {
    return '$count pembacaan';
  }

  @override
  String get homeOfflineSetupTitle => 'Perangkat belum tersambung';

  @override
  String get homeOfflineStepOne => 'Nyalakan hotspot atau Wi-Fi';

  @override
  String get homeOfflineStepTwo => 'Tampilkan QR Wi-Fi';

  @override
  String get homeOfflineStepThree => 'Arahkan ke kamera SIGAP-NETRA';

  @override
  String get homeWifiQrAction => 'QR Wi-Fi';

  @override
  String get homeSyncing => 'Menyinkronkan...';

  @override
  String get homeSyncFailed => 'Sinkronisasi gagal. Coba lagi.';

  @override
  String get homeNoDeviceHeroTitle => 'Belum ada perangkat terhubung';

  @override
  String get homeNoDeviceHeroBody => 'Hubungkan kacamata untuk mulai memantau.';

  @override
  String get validationQueueTitle => 'Antrean validasi';

  @override
  String validationProgressValue(int current, int total) {
    return '$current dari $total';
  }

  @override
  String get validationFilterAll => 'Gabungan';

  @override
  String get validationFilterMoney => 'Uang';

  @override
  String get validationFilterText => 'Menu/Teks';

  @override
  String get validationReadAs => 'TERBACA SEBAGAI';

  @override
  String get validationProcessingLabel => 'Waktu proses';

  @override
  String get validationNoImageTitle => 'Gambar tidak diunggah';

  @override
  String get validationNoImageBody =>
      'Validasi tetap bisa dilanjutkan. Aktifkan unggah gambar di pengaturan privasi bila perlu.';

  @override
  String get validationNoImageAction => 'Buka pengaturan privasi';

  @override
  String get photoViewerZoom => 'Perbesar foto';

  @override
  String get photoViewerClose => 'Tutup foto';

  @override
  String get photoViewerReset => 'Kembalikan ukuran';

  @override
  String get photoViewerHint => 'Cubit atau ketuk dua kali untuk memperbesar';

  @override
  String get validationAllDoneTitle => 'Semua pembacaan sudah diperiksa';

  @override
  String get validationAllDoneBody =>
      'Lihat kembali hasil sebelumnya di Riwayat.';

  @override
  String get validationGoHistory => 'Buka Riwayat';

  @override
  String get validationUndoAction => 'Urungkan';

  @override
  String get validationSaved => 'Validasi tersimpan.';

  @override
  String get validationSaveFailed =>
      'Validasi gagal disimpan. Periksa koneksi lalu coba lagi.';

  @override
  String get validationUndoFailed => 'Pembatalan validasi gagal. Coba lagi.';

  @override
  String get validationNoDeviceTitle => 'Belum ada perangkat terhubung';

  @override
  String get validationNoDeviceBody =>
      'Validasi membaca antrean dari kacamata SIGAP-NETRA. Hubungkan perangkat dulu untuk mulai memvalidasi.';

  @override
  String get validationNoDeviceAction => 'Buka Perangkat';

  @override
  String get validationFilterEmptyTitle => 'Tidak ada antrean di filter ini';

  @override
  String validationFilterEmptyBody(int count) {
    return 'Masih ada $count pembacaan menunggu di kategori lain.';
  }

  @override
  String get validationFilterShowAll => 'Tampilkan semua';

  @override
  String get historyListTab => 'Daftar';

  @override
  String get historyStatsTab => 'Statistik';

  @override
  String historyStoredCount(int count) {
    return '$count pembacaan tersimpan';
  }

  @override
  String historyStoredCountMore(int count) {
    return '$count+ pembacaan dimuat';
  }

  @override
  String get historyFilterEmptyTitle => 'Tidak ada hasil untuk filter ini';

  @override
  String get historyFilterEmptyBody =>
      'Coba ubah kategori atau status validasi untuk melihat pembacaan lain.';

  @override
  String get historyCopied => 'Teks disalin.';

  @override
  String get historyCopyAction => 'Salin teks';

  @override
  String historyValidatedByAt(String uid, String time) {
    return 'Divalidasi oleh $uid · $time';
  }

  @override
  String get historyFilterAll => 'Semua';

  @override
  String get historyFilterMatch => 'Cocok';

  @override
  String get historyFilterMismatch => 'Tidak cocok';

  @override
  String get historyFilterPending => 'Belum';

  @override
  String get historyYesterday => 'Kemarin';

  @override
  String historyReadNumber(int number) {
    return 'No. $number';
  }

  @override
  String historyConfidenceValue(String value) {
    return 'Keyakinan $value';
  }

  @override
  String historyDistanceValue(int value) {
    return '$value cm';
  }

  @override
  String get historyStatsRange7 => '7 hari terakhir';

  @override
  String get historyStatsRange4Weeks => '4 minggu terakhir';

  @override
  String get historyStatsChartDaily => 'Pembacaan per hari';

  @override
  String get historyStatsChartWeekly => 'Pembacaan per minggu';

  @override
  String historyStatsChartSemantics(int total, int days) {
    return 'Grafik pembacaan: $total pembacaan dalam $days hari terakhir';
  }

  @override
  String get historyStatsEmptyTitle => 'Belum ada pembacaan pada rentang ini';

  @override
  String get historyStatsEmptyBody =>
      'Coba rentang waktu yang lebih panjang, atau pastikan perangkat sudah mengirim pembacaan.';

  @override
  String get historyStatsEmptyAction => 'Lihat 4 minggu terakhir';

  @override
  String get historyStatsAccuracyTitle => 'Akurasi bacaan';

  @override
  String historyStatsAccuracyCaption(int count) {
    return 'dari $count validasi';
  }

  @override
  String get historyStatsNoValidation => 'Belum ada validasi pada rentang ini';

  @override
  String get historyStatsTotalLabel => 'Total pembacaan';

  @override
  String get historyStatsPerDayLabel => 'Per hari';

  @override
  String get historyStatsPendingLabel => 'Menunggu validasi';

  @override
  String get historyStatsTypesTitle => 'Jenis pembacaan';

  @override
  String historyStatsTypeSemantics(int money, int text) {
    return 'Uang $money, teks $text';
  }

  @override
  String get historyStatsValidationTitle => 'Status validasi';

  @override
  String historyStatsValidationSemantics(
    int matched,
    int mismatched,
    int pending,
  ) {
    return 'Cocok $matched, tidak cocok $mismatched, menunggu $pending';
  }

  @override
  String historyStatsLegendValue(int count, int percent) {
    return '$count · $percent%';
  }

  @override
  String historyDayStat(int count) {
    return '$count pembacaan';
  }

  @override
  String historyDayStatMore(int count) {
    return '$count+ pembacaan';
  }

  @override
  String historyDayTypes(int money, int text) {
    return '$money uang · $text teks';
  }

  @override
  String get historyResetMenu => 'Reset status validasi...';

  @override
  String get historyExportCsv => 'Ekspor CSV';

  @override
  String get historyShareSummary => 'Bagikan ringkasan';

  @override
  String get historyExportConsentAccept => 'Lanjutkan';

  @override
  String get historyExportConsentTitle => 'Ekspor CSV memuat teks pribadi';

  @override
  String get historyExportConsentBody =>
      'Berkas CSV memuat teks OCR apa adanya yang dapat berisi informasi pribadi. Berkas dibuat di perangkat Anda dan hanya Anda yang menentukan ke mana berkas dibagikan.';

  @override
  String get historyExportPreparing => 'Menyiapkan berkas CSV…';

  @override
  String get historyExportEmpty =>
      'Tidak ada pembacaan pada filter ini untuk diekspor.';

  @override
  String historyExportTruncated(int count) {
    return 'Berkas memuat $count pembacaan terbaru pada filter ini. Persempit filter untuk sisanya.';
  }

  @override
  String get historyExportFailed =>
      'Gagal menyiapkan berkas CSV. Periksa koneksi lalu coba lagi.';

  @override
  String get deviceConnectTitle => 'Hubungkan';

  @override
  String get deviceConnectBody =>
      'Tampilkan QR Wi-Fi ke kamera kacamata untuk menghubungkan perangkat ke jaringan.';

  @override
  String get deviceShowQr => 'Tampilkan QR Wi-Fi';

  @override
  String get deviceControlTitle => 'Kontrol';

  @override
  String get deviceControlOfflineNote =>
      'Alat sedang tidak tersambung — perintah dijalankan otomatis begitu alat kembali.';

  @override
  String get deviceEventsTitle => 'Kejadian terakhir';

  @override
  String get deviceCommandsTitle => 'Perintah terakhir';

  @override
  String get deviceCommandsEmpty =>
      'Belum ada perintah yang dikirim dari aplikasi.';

  @override
  String get deviceLastSeenLabel => 'Terakhir terlihat';

  @override
  String deviceFirmwareShort(String version) {
    return 'Firmware $version';
  }

  @override
  String deviceModelShort(String model) {
    return 'Model $model';
  }

  @override
  String get deviceIdLabel => 'ID perangkat';

  @override
  String get provisioningStepNetwork => 'Jaringan';

  @override
  String get provisioningStepQr => 'Tampilkan QR';

  @override
  String get provisioningStepWaiting => 'Menunggu alat';

  @override
  String get provisioningHotspot => 'Hotspot ponsel';

  @override
  String get provisioningHomeWifi => 'Wi-Fi rumah';

  @override
  String get provisioningRememberSsid => 'Ingat nama jaringan';

  @override
  String provisioningCountdown(int seconds) {
    return 'Menunggu $seconds dtk';
  }

  @override
  String get settingsPrivacyTitle => 'Privasi dan data';

  @override
  String get settingsAdvancedTitle => 'Lanjutan';

  @override
  String get settingsAccountTitle => 'Akun';

  @override
  String get settingsAboutTitle => 'Tentang';

  @override
  String get settingsSourceTitle => 'Sumber data';

  @override
  String get settingsShowTechnicalIds => 'Tampilkan ID teknis';

  @override
  String get settingsRetentionTitle => 'Retensi data';

  @override
  String get settingsRetentionBody =>
      'Pembacaan dan thumbnail dapat dihapus kapan saja dari Riwayat. Penghapusan otomatis 30 hari belum aktif.';

  @override
  String get settingsDeleteAllTitle => 'Hapus semua data perangkat';

  @override
  String get settingsDeleteAllBody => 'Segera hadir.';

  @override
  String get settingsOpenTitle => 'Buka pengaturan';

  @override
  String get splashLoading => 'Menyiapkan SIGAP-NETRA...';

  @override
  String get timeJustNow => 'Baru saja';

  @override
  String timeMinutesAgo(int count) {
    return '$count menit lalu';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count jam lalu';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String get timeNever => 'Belum pernah';
}
