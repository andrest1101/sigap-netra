// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'SiGap Netra';

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
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle => 'Masuk untuk memantau perangkat SiGap Netra.';

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
  String get homeTitle => 'Beranda';

  @override
  String get homeSyncNow => 'Sinkronkan sekarang';

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
  String get historySummaryTitle => 'Ringkasan harian';

  @override
  String get historyDetailTitle => 'Detail pembacaan';

  @override
  String get historyEmptyTitle => 'Belum ada pembacaan';

  @override
  String get historyEmptyBody =>
      'Riwayat akan muncul setelah perangkat mengirim pembacaan pertama.';

  @override
  String get devicesTitle => 'Perangkat';

  @override
  String get devicesEmptyTitle => 'Belum ada perangkat';

  @override
  String get devicesEmptyBody => 'Tambahkan perangkat untuk mulai memantau.';

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
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get settingsThemeSystem => 'Ikuti sistem';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsPrivacy => 'Privasi';

  @override
  String get settingsUploadThumbnails => 'Kirim thumbnail pembacaan';

  @override
  String get settingsUploadThumbnailsBody =>
      'Thumbnail adalah satu-satunya gambar yang dapat dikirim. Ukurannya dibatasi 60 KB dan tidak menyertakan video atau audio.';

  @override
  String get settingsUploadThumbnailsConsentTitle =>
      'Izinkan pengiriman thumbnail?';

  @override
  String get settingsUploadThumbnailsConsentBody =>
      'Thumbnail berisi Potongan gambar pembacaan dan dapat memuat informasi pribadi. Video, audio, dan lokasi tidak pernah dikirim.';

  @override
  String get settingsDeveloperMode => 'Mode pengembang';

  @override
  String get settingsDeveloperModeBody =>
      'Gunakan data simulasi tanpa perangkat keras dan tanpa Firebase.';

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
  String get sharingShareText => 'Hasil pengenalan SiGap Netra';

  @override
  String get sharingEmpty => 'Tidak ada data untuk dibagikan.';

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
