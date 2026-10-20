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

/// Panjang maksimum string base64 dokumen `media.bytes`.
///
/// 60.000 byte menjadi ~80.000 karakter setelah base64; batas 81.920 mengikuti
/// `docs/firestore_schema.md` bagian 4.3 dan `firebase/firestore.rules`.
const int kMaxThumbnailBase64Length = 81920;

/// Batas jumlah karakter teks OCR yang disimpan dan ditampilkan.
const int kMaxOcrTextLength = 500;

/// Batas jumlah karakter teks OCR yang boleh ikut dibagikan lewat
/// `share_plus` setelah pengguna menyetujui dialog persetujuan.
const int kMaxSharedTextLength = 500;

/// Interval `tick` provider yang memaksa evaluate ulang status online, dalam
/// detik. Domba Dart tidak tahu tentang perubahan `DateTime.now()` sendiri.
const int kConnectivityTickSeconds = 15;

/// Jumlah pembacaan per halaman di Riwayat (dan langkah "Muat lagi").
const int kHistoryPageSize = 25;

/// Batas keras jumlah baris satu ekspor CSV Riwayat.
///
/// Ekspor mengambil paling banyak 500 pembacaan terbaru **sesuai filter
/// aktif** dalam satu query — bukan seluruh riwayat — agar kuota baca Spark
/// tetap aman (skema §7.3). Bila masih ada sisa, pengguna diberi tahu bahwa
/// hasilnya terpotong.
const int kDetectionCsvMaxRows = 500;

/// Jumlah kejadian per halaman di Log koneksi saat saringan severity aktif.
///
/// Halaman berfilter memakai query server (`getEventsPage`) dengan kursor;
/// saringan "Semua" tetap realtime dan dibatasi 50 kejadian terbaru.
const int kEventsPageSize = 25;

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

/// Logo Google "G" resmi (PNG transparan, 96px) untuk tombol masuk Google.
///
/// Ikon Material `g_mobiledata` bukan logo Google dan menyesatkan, jadi
/// memakai aset ini. Aset sudah dioptimalkan dari sumber 3840px — tampilkan
/// kecil (20-24 dp), tanpa batas dekode.
const String kGoogleLogoAsset = 'assets/images/google_g_logo.png';

/// Mark merek SIGAP-NETRA (mata + gelombang sinyal), sudah dipangkas dari
/// `assets/images/logo.jpeg`. Dipakai lewat `LogoMark` — jangan `Image.asset`
/// langsung di layar.
const String kLogoMarkAsset = 'assets/images/logo_mark.png';

/// Minimum panjang kata sandi Wi-Fi yang diterima.
const int kMinWifiPasswordLength = 8;

/// Panjang maksimum kredensial Wi-Fi per field.
const int kMaxWifiSsidLength = 32;
const int kMaxWifiPasswordLength = 64;
