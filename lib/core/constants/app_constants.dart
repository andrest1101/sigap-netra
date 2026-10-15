/// Konstanta aplikasi yang tidak bergantung pada fitur tertentu.
///
/// Nilai di sini mengikat aturan di `AGENTS.md` dan `docs/firestore_schema.md`.
/// Ubah hanya bila dokumen sumber ikut diperbarui.
library;

/// Ambang waktu (dalam detik) untuk menentukan perangkat sedang online.
///
/// Heartbeat perangkat 30 detik. Dengan ambang 90 detik kita mengizinkan tiga
/// heartbeat hilang berturut-turut sebelum ditandai terputus.
const int kDeviceOnlineThresholdSeconds = 90;

/// Interval heartbeat perangkat yang diharapkan, dalam detik.
const int kDeviceHeartbeatIntervalSeconds = 30;

/// Ukuran maksimum thumbnail yang boleh diunggah, dalam byte.
///
/// Hard limit dari kebijakan privasi. Gambar yang lebih besar harus ditolak di
/// sisi device sebelum dikirim, dan ditolak juga oleh Security Rules.
const int kMaxThumbnailBytes = 60 * 1000;

/// Batas jumlah karakter teks OCR yang disimpan dan ditampilkan.
const int kMaxOcrTextLength = 500;

/// Batas jumlah karakter teks OCR yang boleh ikut dibagikan lewat
/// `share_plus` setelah pengguna menyetujui dialog persetujuan.
const int kMaxSharedTextLength = 500;

/// Interval `tick` provider yang memaksa evaluate ulang status online, dalam
/// detik. Domba Dart tidak tahu tentang perubahan `DateTime.now()` sendiri.
const int kConnectivityTickSeconds = 15;

/// Pagu bawah jumlah pembacaan yang diambil untuk feed aktivitas terbaru di
/// Beranda. Selalu batasi query agar kuota baca Spark tetap aman.
const int kRecentActivityLimit = 20;

/// Jumlah pembacaan per halaman di Riwayat.
const int kHistoryPageSize = 25;

/// Jumlah entri yang diminta saat menghitung agregat badge dan akurasi.
const int kAggregationCountLimit = 1000;

/// Versi aplikasi yang ditampilkan di Pengaturan → Tentang.
///
/// Sinkronkan manual dengan `version:` di `pubspec.yaml` setiap rilis.
const String kAppVersionDisplay = '1.0.0+1';

/// Catatan status QR Wi-Fi yang ditampilkan di layar provisioning.
///
/// Payload memakai format standar ZXing yang sama dengan aplikasi Kotlin lama
/// (`WIFI:T:WPA;S:…;P:…;;`), tetapi firmware MaixCAM saat ini belum memindai
/// QR — provisioning tetap dilakukan dari layar sentuh alat.
const String kWifiQrPayloadNote =
    'Format mengikuti aplikasi lama (WIFI:T:WPA;S:…;P:…;;). Firmware alat '
    'belum memindai QR — bila QR tidak terbaca, masukkan Wi-Fi dari layar '
    'sentuh alat.';

/// Logo Google "G" resmi (PNG transparan) untuk tombol masuk Google.
///
/// Ikon Material `g_mobiledata` bukan logo Google dan menyesatkan, jadi
/// memakai aset ini. Ukuran asli 3840px — selalu tampilkan kecil (20-24dp).
const String kGoogleLogoAsset = 'assets/images/google_g_logo.png';

/// Minimum panjang kata sandi Wi-Fi yang diterima.
const int kMinWifiPasswordLength = 8;

/// Panjang maksimum kredensial Wi-Fi per field.
const int kMaxWifiSsidLength = 32;
const int kMaxWifiPasswordLength = 64;
