# Spesifikasi UI — SiGap Netra App

Dokumen ini adalah sumber kebenaran sisi antarmuka (UI) untuk SiGap Netra App.
Cakupan: tema, design token, layout global, tiap layar beserta state-nya, pustaka
komponen, daftar string l10n, dan panduan aksesibilitas.

Semua isi merujuk pada `AGENTS.md`. Detail produk yang belum diputuskan ditandai
`[PERLU KONFIRMASI]` dan tidak boleh diasumsikan.

---

## 1. Prinsip dan Batasan

1. **Pengguna aplikasi adalah orang yang bisa melihat.** Aplikasi dipakai pasangan,
   keluarga, peneliti, dan pengembang. Aplikasi bukan untuk pengguna tunanetika
   langsung, sehingga tidak ada kebutuhan mode voice-over-first atau kontras
   ultra-tinggi untuk pengguna buta. Tetap, kontras tetap tinggi agar nyaman dibaca
   oleh orang berkacamata dan di tempat terang.
2. **Material 3.** Semua komponen memakai widget Material 3 (`FilledButton`,
   `OutlinedButton`, `Card`, `NavigationBar`, `BottomSheet`, `Dialog`,
   `SnackBar`). Jangan memakai widget Material 2 yang sudah deprecated.
3. **Tiga mode tema.** Light, dark, danIkuti sistem (`ThemeMode.system`) sebagai
   default. Pilihan tema disimpan di preferensi aplikasi dan dibaca sebelum
   `runApp` agar tidak ada kedipan tema.
4. **Bahasa Indonesia, 100 persen dari l10n.** Tidak ada string yang di-hardcode di
   widget, termasuk label, tooltip, pesan error, dan teks empty state. Semua
   diambil dari `lib/l10n/app_id.arb` lewat `flutter_localizations` +
   `gen_l10n`. Angka dan tanggal diformat dengan `intl`
   (`lib/core/utils/number_format_id.dart`) — pola pemisah ribuan/desimal
   `[PERLU KONFIRMASI]`.
5. **Android-first, iOS-safe.** Target uji utama Android. Jangan pakai API
   khusus platform tanpa cabang iOS yang setara. Safe area tetap dihormati
   (`SafeArea`), dan `NavigationBar` tetap dipakai di kedua platform agar
   konsisten visual.
6. **Empat state wajib.** Setiap layar async punya state loading, empty, error,
   dan data lewat `AsyncValue.when`, ditambah state offline/stale dari metadata
   snapshot (`isFromCache`).
7. **Aksesibilitasbaseline.** Rasio kontras teks minimal 4.5:1 (besar 3:1),
   target sentuh minimal 48x48 dp, dan tata letak tidak boleh terpotong pada
   `textScaleFactor` sampai 2.0.
8. **Tampilan bukan sumber kebenaran.** Status koneksi selalu dihitung ulang di
   klien (`deriveConnectivity`) dan status yang tampil di Firestore tidak
   dipercaya apa adanya.
9. **Privasi terlihat di UI.** Halaman mana pun yang menampilkan thumbnail harus
   menjelaskan bahwa gambar berasal dari perangkat dan bisa dimatikan di
   Pengaturan. Teks OCR ditampilkan dengan batas 500 karakter dan peringatan
   sebelum dibagikan.

---

## 2. Design Tokens

Semua token berada di `lib/core/theme/design_tokens.dart`, warna status di
`lib/core/theme/status_colors.dart`, tema di `lib/core/theme/app_theme.dart`.
Widget tidak boleh menulis angka warna langsung.

### 2.1 Warna dasar dan Material 3 scheme

Seed colour tunggal: teal `#00897B`. Scheme dibangkitkan dengan
`ColorScheme.fromSeed(seedColor: Color(0xFF00897B), brightness: ...)` agar
Material You tetap berlaku di Android 12+ dan konsisten di iOS.

Peran warna dipakai di seluruh UI:

| Peran | Light | Dark |
| --- | --- | --- |
| `primary` | teal seed `#00897B` | tonal teal terang hasil `fromSeed(brightness: dark)` |
| `onPrimary` | putih | putih |
| `primaryContainer` | teal muda | teal tua |
| `secondary` | hasil `fromSeed` | hasil `fromSeed` |
| `tertiary` | hasil `fromSeed` | hasil `fromSeed` |
| `surface` | netral terang | netral gelap |
| `surfaceContainer*` | netral | netral gelap |
| `onSurface` | teks utama | teks utama |
| `onSurfaceVariant` | teks sekunder | teks sekunder |
| `outline` | garis | garis |
| `error` | merah Material | merah Material |

> Nilai hex `primary`/`secondary`/`tertiary` selain seed adalah hasil algoritma
> Material 3, bukan pilihan manual. Jangan menulis angka hex hasil tebakan di
> kode: cukup deklarasikan seed lalu baca dari `Theme.of(context).colorScheme`.
> Dokumentasi hex turunan yang dipakai untuk review visual →
> `[PERLU KONFIRMASI]` (hasilkan dengan alat bantu Material Theme Builder).

Perbanan peran warna:

- Teal dipakai untuk aksi utama, header, dan elemen aktif.
- `secondary` untuk aksi sekunder (filter, tombol outlined).
- `tertiary` hanya untuk aksen dekoratif dan grafik (mis. donut akurasi).
- `error` khusus kegagalan dan status merah pada scheme; warna status merah
  selalu memakai token `StatusColors` agar konsisten.

### 2.2 Warna status (kustom, di luar scheme)

Warna status dipakai pada badge, pill, titik indikator, dan garis sidebar.
Warna tidak pernah menjadi satu-satunya pembawa makna: setiap status selalu
di accreditingi ikon dan/atau teks.

| Status | Makna | Light container | Light content | Light solid | Dark container | Dark content | Dark solid |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Green | Online, Cocok, berhasil | `#E3F3E6` | `#0F5C2A` | `#2E7D32` | `#16351D` | `#A5E6B0` | `#6BD98A` |
| Red | Offline terputus, Tidak cocok, error | `#FBE4E4` | `#8C1D1D` | `#C62828` | `#3B1A1A` | `#F2B8B8` | `#EF6A6A` |
| Amber | Peringatan, menunggu | `#FDF1DC` | `#7A4E00` | `#B26A00` | `#3A2C11` | `#F2CE8A` | `#E0A63C` |
| Grey | Belum, tidak diketahui | `#ECECEC` | `#4A4A4A` | `#757575` | `#2C2C2C` | `#D0D0D0` | `#9E9E9E` |

Ketentuan:

- Angka `*content` dipilih agar kontras teks minimal 4.5:1 terhadap
  `*container`. Semua nilai wajib diverifikasi dengan pemeriksa kontras
  sebelum rilis.
- Padanan warna untuk event severity (lihat Koneksi dan Sinkronisasi):
  `EventSeverity.info` → Grey, `warning` → Amber, `error` → Red.
- Status "menunggu validasi" memakai Amber; status "Belum" memakai Grey.
- Status perangkat online ditentukan client-side: online bila
  `now - lastSeen < 90 s`. Diperbarui lewat provider `tick` tiap 15 detik.

### 2.3 Gradien header

Header memakai gradien linear teal (bukan warna datar) agar bagian paling atas
layar jelas terpisah dari konten dan mudah dikenali saat menggulir.

| Token | Nilai |
| --- | --- |
| `AppGradients.header` | LinearGradient `#00897B` → `#00695C`, `begin: topLeft`, `end: bottomRight` |
| `AppGradients.headerDark` | `#00897B` → `#004D40` |
| Sudut header | bawah radius 24, atas 0 |

Teks di dalam header memakai warna putih; pada dark mode tetap putih karena
latar gradien selalu gelap. Tinggi header mengikuti `AppBar` M3 (56 dp) dan
bertambah dengan `SliverAppBar.large` pada layar yang butuh headline besar
(max 152 dp).

### 2.4 Skala spasi

Basis 4 dp. Nama token dipisah dari angka agar mudah dibaca di kode.

| Token | Nilai | Pemakaian |
| --- | --- | --- |
| `space2` | 2 dp | jarak antar ikon dan label sangat rapat |
| `space4` | 4 dp | jarak badge ke teks, padding dalam chip |
| `space8` | 8 dp | jarak antar baris metadata |
| `space12` | 12 dp | padding kartu ringkas, jarak label ke field |
| `space16` | 16 dp | padding layar horizontal, jarak antar kartu |
| `space20` | 20 dp | padding kartu besar |
| `space24` | 24 dp | jarak antar seksi |
| `space32` | 32 dp | jarak seksi besar |
| `space40` | 40 dp | padding empty state vertikal |
| `space48` | 48 dp | tinggi minimum target sentuh |

Lebar konten maksimum saat `textScale > 1.0` atau tablet: batasi konten di
`space24` dengan lebar maksimum 640 dp dan rata tengah agar baris tidak terlalu
panjang.

### 2.5 Radius

| Token | Nilai | Pemakaian |
| --- | --- | --- |
| `AppRadii.badge` | 8 dp | badge, chip, status pill |
| `AppRadii.button` | 12 dp | tombol, input field, kartu kecil |
| `AppRadii.card` | 16 dp | kartu konten |
| `AppRadii.bottomNav` | 24 dp | navigasi bawah, sudut atas sheet |
| `AppRadii.sheet` | 24 dp | atas `BottomSheet` | 
| `AppRadii.dialog` | 28 dp | `AlertDialog` M3 | 
| `AppRadii.circle` | penuh | FAB, avatar, radio |

> `sheet` dan `dialog` mengikuti default M3; boleh diubah asalkan tetap di
> Famili angka yang sama `[PERLU KONFIRMASI]`.

### 2.6 Skala tipografi

Menggunakan `TextTheme` Material 3 bawaan. Font bawaan platform (Roboto di
Android, SF Pro di iOS) — tanpa font kustom `[PERLU KONFIRMASI]`.

| Peran | Ukuran | Line height | Pemakaian |
| --- | --- | --- | --- |
| `headlineLarge` | 32 | 40 | Judul layar pada header besar (Beranda) |
| `headlineMedium` | 28 | 36 | Nama perangkat di layar detail |
| `headlineSmall` | 24 | 32 | Judul section besar |
| `titleLarge` | 22 | 28 | Judul layar lewat `AppBar.title` |
| `titleMedium` | 16 | 24 | Judul kartu, label field |
| `titleSmall` | 14 | 20 | Judul baris metadata, nama item |
| `bodyLarge` | 16 | 24 | Teks utama panjang, isi dialog |
| `bodyMedium` | 14 | 20 | Teks isi, deskripsi |
| `bodySmall` | 12 | 16 | Metadata, waktu relatif, catatan |
| `labelLarge` | 14 | 20 | Teks tombol |
| `labelMedium` | 12 | 16 | Teks badge, chip, tab |
| `labelSmall` | 11 | 16 | Legenda grafik, teks sangat pendek |

Ketentuan tipografi:

- Panjang teks satu baris dibatasi dengan `maxLines` dan ellipsis;
  `bodySmall` untuk data waktu relatif.
- Nilai uang memakai angka tabular (`FontFeature.tabularFigures`) agar mudah
  dibandingkan antar baris.
- Judul kartu tidak pernah hanya satu kata kunci tanpa konteks; gunakan
  `titleMedium` untuk nilai utama dan `bodySmall` untuk keterangan.

### 2.7 Elevation

| Level | Pemakaian |
| --- | --- |
| 0 | Latar layar, kartu di dalam daftar tanpa interaksi |
| 1 | Kartu yang bisa ditekan, `Card` pada daftar utama |
| 2 | Header yang menempel saat digulir, FAB |
| 3 | `BottomSheet`, dialog, menu popup |

Aturan: elevasi tidak boleh dipakai sebagai satu-satunya penanda status.
`Card` yang bisa ditekan memakai `Card.filled` atau warna container, bukan
hanya bayangan.

### 2.8 Durasi animasi

| Token | Nilai | Pemakaian |
| --- | --- | --- |
| `motionMicro` | 100 ms | perubahan warna status pill |
| `motionShort` | 200 ms | buka/tutup chip filter, snackbar masuk |
| `motionMedium` | 300 ms | transisi halaman, dialog, snackbar keluar |
| `motionLong` | 400 ms | sheet filter, animasi grafik |
| `skeletonCycle` | 1200 ms | satu siklus shimmer skeleton |

Semua animasi non-esensial dihapus saat
`MediaQuery.of(context).disableAnimations == true` atau mode aksesibilitas
"Mengurangi animasi" aktif. Shimmer skeleton diganti dengan blok abu muda
solid tanpa animasi.

---

## 3. Layout Global

### 3.1 Peta route (`go_router`)

Struktur memakai `StatefulShellRoute.indexedStack` agar lima tab menjaga state
scroll dan posisi filter masing-masing.

| Route | Layar | Auth | Catatan |
| --- | --- | --- | --- |
| `/splash` | Boot | ya | redirect; hanya tampil saat inisialisasi Firebase + auth |
| `/login` | Login | tidak | redirect ke `/beranda` bila sudah masuk |
| `/beranda` | Beranda | ya | branch tab 1 |
| `/validasi` | Validasi | ya | branch tab 2 |
| `/riwayat` | Riwayat | ya | branch tab 3 |
| `/riwayat/{detectionId}` | Detail Pembacaan | ya | child dari branch Riwayat |
| `/perangkat` | Daftar Perangkat | ya | branch tab 4 |
| `/perangkat/{deviceId}` | Detail Perangkat | ya | child dari branch Perangkat |
| `/perangkat/{deviceId}/wifi` | QR Wi-Fi | ya | child dari branch Perangkat |
| `/perangkat/{deviceId}/perintah` | Kontrol Jarak Jauh | ya | P1 |
| `/pengaturan` | Pengaturan | ya | branch tab 5 |
| `/pengaturan/koneksi` | Koneksi dan Sinkronisasi (semua perangkat) | ya | child dari branch Pengaturan |
| `/pengaturan/koneksi/{deviceId}` | Koneksi dan Sinkronisasi (satu perangkat) | ya | child dari branch Pengaturan |

Aturan redirect (`GoRouter.refreshListenable` dari provider auth):

- Belum masuk dan route bukan `/login` atau `/splash` → `/login`.
- Sudah masuk dan route `/login` → `/beranda`.
- Pengguna bukan anggota perangkat apa pun → tetap masuk, Beranda menampilkan
  empty state "Belum ada perangkat" (bukan error).

> Penamaan path memakai Bahasa Indonesia agar konsisten dengan label navigasi.
> Jika tim memilih path bahasa Inggris (`/home`, `/history`), cukup ganti tabel
> ini; tidak ada dampak ke domain/data `[PERLU KONFIRMASI]`.

### 3.2 Bottom navigation shell

Lima item, urut dan ikon berikut:

| # | Label l10n | Ikon (aktif / tidak aktif) | Branch |
| --- | --- | --- | --- |
| 1 | Beranda | `Icons.home_outlined` / `Icons.home` | `/beranda` |
| 2 | Validasi | `Icons.fact_check_outlined` / `Icons.fact_check` | `/validasi` |
| 3 | Riwayat | `Icons.history_outlined` / `Icons.history` | `/riwayat` |
| 4 | Perangkat | `Icons.devices_other_outlined` / `Icons.devices_other` | `/perangkat` |
| 5 | Pengaturan | `Icons.settings_outlined` / `Icons.settings` | `/pengaturan` |

- `NavigationBar` M3, tinggi 80 dp, radius atas 24 dp (`AppRadii.bottomNav`).
- Setiap item menampilkan label (bukan `selectedIcon` saja) agar mudah dibaca
  orang berkacamata.
- Badge jumlah menunggu validasi pada item Validasi, Amber; badge perangkat
  offline pada item Perangkat, Red. Badge hanya angka ringkas (maks 99+).
- Navigasi bawah disembunyikan pada layar full-screen yang butuh ruang:
  `/perangkat/{deviceId}/wifi` dan `/pengaturan/koneksi/{deviceId}`
  `[PERLU KONFIRMASI]` — default: tampilkan agar konteks perangkat tidak
  hilang.
- Double-tap pada item aktif menggulir ke atas (`ScrollController`) seperti
  perilaku `NavigationBar` M3.

### 3.3 GradientHeader

`lib/core/widgets/gradient_header.dart`.

- `SliverAppBar` dengan `expandedHeight` 152 dp (large) atau 104 dp (medium),
  `flexibleSpace` berisi gradien teal dan `SafeArea`.
- Isi: title besar (`headlineMedium`), subjudul opsional (`bodyMedium`, putih
  80% opacity), dan slot aksi di kanan (ikon 48 dp).
- `pinned: true`, `backgroundColor` warna gradien saat menyusut, foreground
  `onPrimary`.
- `Semantics(header: true)` pada title.
- Saat `textScale > 1.5`, `expandedHeight` bertambah 24 dp agar judul tidak
  terpotong.

### 3.4 OfflineBanner

`lib/core/widgets/offline_banner.dart`.

- `MaterialBanner`/`Container` full-width di bawah header, tinggi minimum
  40 dp, warna Amber container, ikon `Icons.cloud_off`, dua baris teks
  (judul + "Data mungkin sudah tidak terbaru.").
- Muncul dari snapshot metadata: `snapshot.metadata.isFromCache == true`
  atau `connectivity` tidak tersedia. Provider khusus
  `staleDataProvider` menahan flag ini per layar.
- Aksi "Coba lagi" memanggil `ref.invalidate` pada provider layar tersebut.
- Bukan floating banner, tidak menutupi konten, dan selalu di dalam
  scroll view agar tidak menutupi navigasi bawah.

### 3.5 Snackbar conventions

`ScaffoldMessenger` global, gaya `SnackBarThemeData`:

| Jenis | Warna | Isi |
| --- | --- | --- |
| Sukses | `inverseSurface` dengan ikon Green | Pesan aksi berhasil, contoh "Validasi tersimpan" |
| Gagal | `errorContainer` | Pesan kegagalan ringkas + aksi "Coba lagi" |
| Informasi | `inverseSurface` | misalnya "Data mungkin sudah tidak terbaru" |

Aturan:

- Satu snackbar pada satu waktu; snackbar baru menggantikan yang lama
  (`hideCurrentSnackBar` lalu tampil).
- Durasi: sukses 4 detik, gagal 8 detik, `action` tidak pernah hilang otomatis
  (durasi menjadi tak terbatas saat ada aksi).
- Pesan tidak pernah memuat kode error teknis atau trace; pesan teknis untuk
  developer hanya tampil di mode pengembang.
- Waktu tampil selalu dihitung dari `Duration` tetap agar bisa diuji widget.
- Aksi destruktif (hapus pembacaan) tidak pernah memakai snackbar sebagai
  satu-satunya pemulihan; tetap dialog konfirmasi.

### 3.6 Pola empat state

Setiap layar async mengikuti pola berikut di `build()`:

- `AsyncValue.loading` → `LoadingView` (skeleton, bukan spinner penuh
  halaman, kecuali aksi yang singkat seperti tombol sync).
- `AsyncValue.error` → `ErrorView` dengan judul, pesan dari
  `firebase_error_mapper.dart`, dan tombol "Coba lagi".
- Data kosong (`AsyncData` berisi list kosong) → `EmptyView` dengan ikon,
  judul, pesan, dan satu aksi utama bila ada.
- `AsyncData` berisi data → isi layar.
- Overlay: bila `isFromCache == true`, tampilkan `OfflineBanner` di atas
  konten tanpa mengganti isi data.

### 3.7 Skeleton loading

`lib/core/widgets/skeleton.dart`.

- Placeholder abu muda (light) atau abu tua (dark) dengan shimmer 1200 ms.
- Bentuk skeleton mengikuti bentuk akhir (kartu perangkat 3 baris, baris
  riwayat 4 baris, kartu status 1 blok).
- `Semantics(label: <string l10n "memuat">)` satu kali pada skeleton root
  agar screen reader tidak membacakan tiap placeholder.

---

## 4. Layar

### 4.1 Splash / Boot

- **Route:** `/splash`
- **Tujuan:** Inisialisasi `Firebase.initializeApp`, memulihkan sesi auth, dan
  mengarahkan ke Login atau Beranda.
- **Komponen:** `GradientHeader` penuh tinggi, logo/nama aplikasi, spinner
  kecil, teks status inisialisasi.
- **State:** hanya loading singkat (maks 3 detik sebelum pesan fallback).
  Jika inisialisasi gagal lebih dari 5 detik, tampilkan `ErrorView` dengan
  aksi "Coba lagi" dan "Gunakan mode simulasi" bila developer mode aktif.

```
+------------------------------------------------+
|                                                |
|                                                |
|                 [ LOGO ]                       |
|                                                |
|              SiGap Netra                      |
|     Pendamping kacamata pintar                 |
|                                                |
|                 ( spinner )                    |
|      Menyambungkan ke layanan...               |
|                                                |
+------------------------------------------------+
```

- **String l10n:** `appName`, `appTagline`, `bootInitializing`,
  `bootRetry`, `bootUseSimulation`.
- **Interaksi:** tidak ada. Tombol "Coba lagi" hanya saat gagal.
- **A11y:** spinner diberi `Semantics(label: bootInitializing)` dan
  `LiveRegion`; teks minimum `bodyMedium`;-logo tidak menjadi satu-satunya
  penanda merek (ada nama teks).
- **Catatan:** skeleton/animasi dimatikan bila `disableAnimations`.

### 4.2 Login (email + Google)

- **Route:** `/login`
- **Tujuan:** Autentikasi pengguna (anggota perangkat) sebelum membuka data.
- **Komponen:** logo, judul, subjudul, `TextFormField` email, `TextFormField`
  kata sandi dengan tombol lihat/sembunyikan, tombol "Masuk", pemisah "atau",
  tombol "Masuk dengan Google", catatan privasi, blok developer mode.
- **State:**

| State | Tampilan |
| --- | --- |
| Loading | Tombol masuk dan Google menampilkan spinner inline; form tetap terlihat dan tidak nonaktif penuh |
| Error | `SnackBar` error di bawah form + `TextFormField` errorText per field; email salah kredensial ditampilkan di field email, bukan dialog |
| Data (valid) | Navigasi ke `/beranda` |
| Offline | Snackbar `errorNetwork`, tombol tetap dapat dicoba setelah koneksi kembali |

```
+------------------------------------------------+
|  [gradien teal: logo + nama aplikasi]          |
|                                                |
|  Masuk                                        |
|  Masuk untuk melihat data kacamata SiGap.     |
|                                                |
|  Email                                        |
|  [ nama@email.com                    ]        |
|                                                |
|  Kata sandi                                   |
|  [ ****************            (lihat) ]      |
|                                                |
|  [   Masuk (FilledButton, full width)    ]     |
|                                                |
|  -------------- atau --------------            |
|                                                |
|  [ Masuk dengan Google (OutlinedButton) ]      |
|                                                |
|  Belum punya akses? Hubungi pemilik akun.      |
|  [ Mode pengembang (checkbox) ]                |
+------------------------------------------------+
```

- **String l10n:** `loginTitle`, `loginSubtitle`, `loginEmailLabel`,
  `loginEmailHint`, `loginPasswordLabel`, `loginPasswordHint`, `loginSubmit`,
  `loginShowPassword`, `loginHidePassword`, `loginGoogle`, `loginOrSeparator`,
  `loginNeedAccess`, `loginInvalidEmail`, `loginWrongPassword`,
  `loginEmailInUse`, `loginTooManyAttempts`, `sessionExpired`,
  `developerModeLabel`, `commonRetry`, `commonCancel`.
- **Interaksi:** tap tombol; tap ikon lihat/sembunyikan kata sandi; keyboard
  action "done" pada kata sandi memicu submit; `AutofillHints.email`,
  `AutofillHints.password`.
- **A11y:** semua field punya label terikat; pesan error dikaitkan ke field via
  `semanticsLabel`; kontras teks field error memenuhi 4.5:1; urutan fokus
  mengikuti urutan visual; tombol tinggi 48 dp.
- **Catatan:** formulir password; registrasi dan reset kata sandi tidak ada di
  AGENTS.md — jika dibutuhkan, alur dan copy-nya `[PERLU KONFIRMASI]`.

### 4.3 Beranda (Home)

- **Route:** `/beranda`
- **Tujuan:** Ringkasan cepat: status perangkat, angka validasi, aktivitas
  terbaru, dan tombol sinkronisasi.
- **Komponen:** `GradientHeader` (judul + nama pengguna ringkas), `OfflineBanner`,
  `DeviceStatusCard` per perangkat (maks 2 di bawah header, sisanya
  "Lihat semua"), `ValidationSummaryCard` (jumlah Cocok / Tidak cocok / Belum,
  rasio akurasi, badge menunggu), `RecentActivitySection` (hasil
  `WatchLatestDetections`, maks 5 item), tombol "Sinkronkan sekarang"
  (`sync_now`) di header aksi.
- **State:**

| State | Tampilan |
| --- | --- |
| Loading | Skeleton: 1 kartu status, 1 kartu ringkasan, 4 baris aktivitas |
| Empty | Tidak ada perangkat → `EmptyView` "Belum ada perangkat" dengan aksi "Tambah perangkat"; ada perangkat tapi belum ada pembacaan → aktivitas kosong "Belum ada pembacaan" tanpa menutupi ringkasan |
| Error | `ErrorView` dengan "Coba lagi"; bila error `permission-denied`, pesan `errorAccessMessage` |
| Data | Kartu status + ringkasan + aktivitas |
| Offline | `OfflineBanner` + waktu relatif diberi keterangan "perkiraan" |

```
+------------------------------------------------+
|  [gradien teal] Beranda            [ (sync) ]  |
|                 Halo, Andre                    |
+------------------------------------------------+
| [! Mode tanpa koneksi - data mungkin stale]     |
+------------------------------------------------+
|  ┌──────────────────────────────────────────┐  |
|  │ Kacamata Utama            ( Online )     │  |
|  │ Terakhir terlihat 12 detik lalu           │  |
|  │                              [ Buka > ]   │  |
|  └──────────────────────────────────────────┘  |
|                                                |
|  Ringkasan Validasi                            |
|  ┌──────────────────────────────────────────┐  |
|  │  Cocok        Tidak cocok     Belum      │  |
|  │  128            9              14        │  |
|  │  Akurasi 93%  ( 128 / 137 )              │  |
|  │  [ 14 menunggu validasi ]                │  |
|  └──────────────────────────────────────────┘  |
|                                                |
|  Aktivitas Terbaru                Lihat semua  |
|  - Uang Rp50.000        10 dtk lalu            |
|  - Teks "Menu ..."      40 dtk lalu            |
|  - [thumbnail kecil, opsional]                 |
+------------------------------------------------+
| [ Beranda ][ Validasi ][ Riwayat ] [ ... ]     |
+------------------------------------------------+
```

- **String l10n:** `homeTitle`, `homeGreeting`, `homeSectionDevices`,
  `homeSeeAllDevices`, `homeSectionSummary`, `homeMetricMatch`,
  `homeMetricMismatch`, `homeMetricPending`, `homeAccuracyLabel`,
  `homePendingBadge`, `homeSectionRecent`, `homeSeeAllHistory`,
  `homeSyncNow`, `homeSyncNowSent`, `homeSyncNowHint`, `homeLastSeenAt`,
  `homeNoDevices`, `homeNoDetections`, `homeAddDevice`.
- **Interaksi:** tap kartu perangkat → detail; tap "Lihat semua" riwayat →
  `/riwayat`; tap ikon sinkron → kirim perintah `sync_now` (P0), tombol
  menampilkan spinner sampai perintah terkirim, tidak menunggu perangkat;
  long-press kartu perangkat → menu aksi cepat (buka detail, QR Wi-Fi)
  `[PERLU KONFIRMASI]`.
- **A11y:** setiap kartu perangkat adalah satu node semantik dengan label yang
  memuat nama, status, dan waktu terakhir terlihat; `Semantics(liveRegion:
  true)` pada jumlah menunggu validasi supaya pembaca layar anuncikan
  pembaruan; teks status memakai ikon + kata, bukan hanya warna;
  rasio akurasi selalu ditulis sebagai "Akurasi 93 persen (128 dari 137)".
- **Catatan:** greeting memakai nama tampilan pengguna. Bila nama kosong,
  gunakan `loginNeedAccount` fallback "Pengguna" — jangan pernah menampilkan
  email penuh.

### 4.4 Validasi

- **Route:** `/validasi`
- **Tujuan:** Antrean pembacaan yang belum divalidasi; pengguna menilai
  Cocok / Tidak cocok.
- **Komponen:** `GradientHeader` ringkas dengan penghitung "N menunggu", baris
  filter perangkat (chip horizontal), `ValidationCard` (thumbnail opsional,
  nilai/teks OCR, jarak bila ada, waktu relatif), dua tombol aksi
  `FilledButton.tonal` (Cocok) dan `OutlinedButton` (Tidak cocok), `SnackBar`
  dengan aksi "Batalkan".
- **State:**

| State | Tampilan |
| --- | --- |
| Loading | Skeleton 2 kartu validasi |
| Empty | `EmptyView` "Tidak ada pembacaan yang menunggu validasi" dengan aksi "Buka riwayat" |
| Error | `ErrorView` + "Coba lagi" |
| Data | Antrean kartu, pull-to-refresh, infinite scroll 10 item per halaman |
| Offline | `OfflineBanner`; tombol validasi tetap aktif bila dokumen masih dapat ditulis secara lokal, dengan catatan "Akan tersinkron saat online" `[PERLU KONFIRMASI]` |

```
+------------------------------------------------+
| [gradien teal] Validasi            (12 menunggu)|
|                 Pilih perangkat                 |
+------------------------------------------------+
|  ( Semua ) ( Kacamata Utama ) ( Kacamata 2 )  |
+------------------------------------------------+
|  ┌──────────────────────────────────────────┐  |
|  │ [ thumbnail 72x72, opsional ]            │  |
|  │  Uang Rp50.000                           │  |
|  │  Jarak 35 cm  ·  12 detik lalu           │  |
|  │  [   Cocok   ] [ Tidak cocok ]            │  |
|  └──────────────────────────────────────────┘  |
|  ┌──────────────────────────────────────────┐  |
|  │ [ (tidak ada gambar) ]                   │  |
|  │  Teks "Es Teh Manis 8.000"               │  |
|  │  1 menit lalu                            |  |
|  │  [   Cocok   ] [ Tidak cocok ]            │  |
|  └──────────────────────────────────────────┘  |
+------------------------------------------------+
```

- **String l10n:** `validationTitle`, `validationPendingCount`,
  `validationFilterDevice`, `validationFilterAll`, `validationMatch`,
  `validationMismatch`, `validationPendingBadge`, `validationUndo`,
  `validationSubmitted`, `validationUndone`, `validationUndoConfirmTitle`,
  `validationUndoConfirmMessage`, `validationResetAll`,
  `validationResetConfirmTitle`, `validationResetConfirmMessage`,
  `validationResetDone`, `validationEmpty`, `validationEmptyAction`,
  `validationNoThumbnail`, `validationOfflineQueued`.
- **Interaksi:** tap tombol Cocok/Tidak cocok untuk kirim; **swipe kanan =
  Cocok, swipe kiri = Tidak cocok** (dengan tombol aksi tetap sebagai jalur
  utama) `[PERLU KONFIRMASI]`; hasil swipe tidak dikirim langsung, harus
  ada konfirmasi visual; long-press kartu → "Batalkan validasi" dan
  "Buka detail"; tap "Batalkan" pada `SnackBar` → `UndoValidation` (hanya
  boleh mengubah field validasi, bukan menghapus dokumen).
- **A11y:** thumbnail punya `Semantics(label: validationThumbnailLabel)` yang
  menyebut jenis pembacaan dan waktu, bukan "gambar"; saat gambar tidak ada
  tampilkan `validationNoThumbnail`, bukan kotak kosong; `SnackBar` sudah
  otomatis diumumkan pembaca layar; target tombol minimal 56 dp
  (lebih besar dari 48 karena aksi utama dan dipakai dalam kondisi terburu-buru).
- **Catatan:** akurasi dihitung `match / (match + mismatch)` hanya dari
  validasi manusia. Thumbnails dimuat lazy per kartu dan di-cache di memori;
  query daftar tidak pernah mengunduh gambar.

### 4.5 Riwayat

#### 4.5.1 Daftar Riwayat

- **Route:** `/riwayat`
- **Tujuan:** Menelusuri seluruh pembacaan dengan filter, paginasi, hapus, dan
  berbagi ringkasan (P1).
- **Komponen:** `GradientHeader` ringkas, `FilterBar` (jenis pembacaan, status
  validasi, rentang tanggal, perangkat), `DetectionListTile` (ikon jenis,
  ringkasan teks, waktu relatif, `StatusPill`), tombol muat lagi, `FAB`
  "Bagikan" (P1).
- **State:**

| State | Tampilan |
| --- | --- |
| Loading | Skeleton 6 baris |
| Empty | Tanpa filter → `EmptyView` "Belum ada pembacaan"; dengan filter → "Tidak ada pembacaan yang cocok" + aksi "Hapus filter" |
| Error | `ErrorView` + "Coba lagi" |
| Data | List + paginasi `startAfterDocument`; `resource-exhausted` → pesan kuota + saran pagination |
| Offline | `OfflineBanner` + hint stale |

```
+------------------------------------------------+
| [gradien teal] Riwayat            [ Bagikan ]  |
+------------------------------------------------+
|  [Filter (2)]                                  |
|  Jenis: ( Semua ) ( Uang ) ( Teks )              |
|  Tanggal: 7 hari terakhir                      |
+------------------------------------------------+
|  Uang Rp50.000        ( Cocok )   12 dtk lalu  |
|  Teks "Menu ..."      ( Belum )   40 dtk lalu  |
|  Uang Rp20.000        ( Tidak cocok ) 2 mnt lalu |
|  ...                                          |
|  [ Muat lagi ]                                |
+------------------------------------------------+
```

- **String l10n:** `historyTitle`, `historyFilter`, `historyFilterType`,
  `historyFilterTypeAll`, `historyFilterTypeMoney`, `historyFilterTypeText`,
  `historyFilterStatus`, `historyFilterStatusAll`, `historyFilterDate`,
  `historyFilterDevice`, `historyActiveFilterCount`, `historyClearFilters`,
  `historyLoadMore`, `historyEndOfList`, `historyShare`, `historyEmpty`,
  `historyEmptyFiltered`, `historyEmptyClearFilter`, `historyQuotaError`,
  `commonDelete`, `commonCancel`.
- **Interaksi:** tap baris → detail; tap `Filter` → `BottomSheet` dengan
  radius atas 24; tap chip filter untuk mengosongkan satu filter; scroll ke
  bawah mencapai ujung → tombol "Muat lagi"; pull-to-refresh; swipe kiri pada
  baris → tombol "Hapus" (hapus tetap butuh konfirmasi dialog).
- **A11y:** `FilterBar` adalah satu baris `Semantics` dengan ringkasan filter
  aktif; baris dapat difokus dan dibaca sebagai satu kalimat
  ("Uang lima puluh ribu, Cocok, 12 detik lalu"); hasil filter diumumkan lewat
  `liveRegion` ("24 pembacaan ditemukan"); tombol "Muat lagi" punya label
  eksplisit, tidak hanya ikon.

#### 4.5.2 Filter (BottomSheet)

```
+------------------------------------------------+
|  Filter pembacaan                    ( Tutup )|
+------------------------------------------------+
|  Jenis pembacaan                               |
|  ( Semua ) ( Uang ) ( Teks )                  |
|                                                |
|  Status validasi                               |
|  ( Semua ) ( Cocok ) ( Tidak cocok ) ( Belum ) |
|                                                |
|  Perangkat                                     |
|  ( Semua ) ( Kacamata Utama )                 |
|                                                |
|  Rentang tanggal                               |
|  7 hari terakhir (dropdown)                   |
|                                                |
|  [ Terapkan (FilledButton, full width) ]      |
|  [ Atur ulang ]                                |
+------------------------------------------------+
```

- **String l10n:** `historyFilterTitle`, `historyApplyFilter`,
  `historyResetFilters`, `commonClose`, dan seluruh key filter di atas.
- **A11y:** setiap kelompok filter adalah `Semantics(container: true)` dengan
  label kelompok; pilihan berupa `ChoiceChip` yang bisa difokus keyboard;
  pilihan aktif ditandai ikon centang, bukan hanya warna.

#### 4.5.3 Detail Pembacaan

- **Route:** `/riwayat/{detectionId}`
- **Tujuan:** Melihat satu pembacaan lengkap beserta status validasi dan
  riwayatnya.
- **Komponen:** `AppBar` dengan tombol hapus, header jenis pembacaan, kartu
  nilai/teks OCR penuh (maks 500 karakter, dipotong dengan tombol "Tampilkan
  semua"), thumbnail besar opsional, baris metadata (waktu, perangkat, jarak
  bila ada), `StatusPill` + siapa yang memvalidasi + kapan, tombol aksi
  validasi (jika belum divalidasi).
- **State:** loading (skeleton 1 kartu), error (`ErrorView`), data, empty
  (`EmptyView` "Pembacaan tidak ditemukan" bila dokumen terhapus), offline.
- **String l10n:** `historyDetailTitle`, `historyDetailShowMore`,
  `historyDetailShowLess`, `historyDeleteTitle`, `historyDeleteMessage`,
  `historyDeleted`, `historyNotFound`, `historyValidatedByAt`,
  `historyDistanceLabel`, `historyThumbnailUnavailable`,
  `historyThumbnailConsentNote`.
- **Interaksi:** tap "Hapus" → dialog konfirmasi → hapus dokumen deteksi
  beserta `media` terkait; salin teks OCR ke clipboard dengan aksi sekunder
  dan snackbar konfirmasi; tap "Tampilkan semua" untuk teks panjang.
- **A11y:** teks OCR diberi `SelectableText` agar bisa disalin dan dibaca
  screen reader; dialog hapus memfokuskan tombol "Batal" secara default;
  pertanyaan konfirmasi menyebut nama perangkat agar tidak ambigu saat dialog
  muncul di atas list.
- **Catatan:** thumbnail hanya ditampilkan bila
  `settings.uploadThumbnails` pernah aktif dan dokumen `media` tersedia;
  jika tidak, tampilkan `historyThumbnailUnavailable` (bukan gambar rusak).
  Berbagi teks OCR selalu lewat dialog persetujuan karena bisa memuat data
  pribadi.

### 4.6 Perangkat

#### 4.6.1 Daftar Perangkat

- **Route:** `/perangkat`
- **Tujuan:** Melihat seluruh perangkat yang dianggarkan ke pengguna beserta
  status konektivitas.
- **Komponen:** `GradientHeader` (judul + jumlah perangkat), ringkasan chip
  (N online / N offline), `DeviceCard` (nama, `StatusPill`, waktu terakhir
  terlihat, jumlah menunggu validasi), `FloatingActionButton.extended`
  "Tambah perangkat".
- **State:** loading (3 skeleton kartu), empty ("Belum ada perangkat" +
  penjelasan bahwa pengguna perlu ditambahkan oleh pemilik akun), error
  (`permission-denied` → "Anda tidak punya akses ke perangkat mana pun"),
  data, offline.
- **String l10n:** `devicesTitle`, `devicesCount`, `devicesOnlineCount`,
  `devicesOfflineCount`, `devicesEmpty`, `devicesEmptyDescription`,
  `devicesAccessDenied`, `devicesAdd`, `deviceStatusOnline`,
  `deviceStatusOffline`, `deviceStatusUnknown`, `deviceLastSeen`, `homeLastSeenAt`.
- **Interaksi:** tap kartu → detail; swipe kiri → tidak ada aksi destruktif
  (aplikasi tidak boleh menghapus dokumen perangkat) sehingga swipe
  dinonaktifkan, bukan menampilkan aksi palsu; pull-to-refresh.
- **A11y:** status daring/terputus selalu ditulis kata + ikon + warna;
  waktu relatif ditulis lengkap pada `Semantics`
  ("terakhir terlihat 12 detik lalu"); badge jumlah menunggu dibaca oleh
  screen reader sebagai "14 menunggu validasi".

#### 4.6.2 Detail Perangkat

- **Route:** `/perangkat/{deviceId}`
- **Tujuan:** Semua yang diketahui tentang satu perangkat: status, validasi,
  aktivitas, dan pintasan ke QR Wi-Fi, kontrol jarak jauh, dan log sinkronisasi.
- **Komponen:** `GradientHeader` dengan nama perangkat + `StatusPill`, kartu
  status (`lastSeen`, jumlah pembacaan hari ini), kartu ringkasan validasi,
  `SectionActions` (Kirim Wi-Fi lewat QR, Kontrol Jarak Jauh (P1), Koneksi dan
  Sinkronisasi), `RecentActivitySection` 5 item terakhir.
- **State:** loading, error, data, empty (tidak ada pembacaan), offline.
- **String l10n:** `deviceDetailTitle`, `deviceOverviewSection`,
  `deviceActionsSection`, `deviceSendWifiQr`, `deviceRemoteControl`,
  `deviceConnectionLogs`, `deviceReadingsToday`, `deviceNoReadingsYet`,
  `deviceSettingsSection`, `deviceMemberOnlyNote`.
- **Interaksi:** tap tiap baris aksi → route anak; tap aktivitas → detail
  pembacaan; tidak ada aksi tulis selain yang tercantum (aplikasi tidak
  mengubah dokumen perangkat).
- **A11y:** urutan bagian mengikuti urutan baca; tiap baris aksi minimal 56 dp
  dengan ikon + teks; tidak ada informasi yang disampaikan lewat warna saja.
- **Catatan:** aplikasi hanya boleh menulis `commands`, field validasi pada
  `detections`, serta menghapus `detections`/`media`. Field perangkat yang
  ditampilkan harus mengikuti `docs/firestore_schema.md`; kolom seperti
  baterai, suhu, atau versi firmware **belum didefinisikan**
  `[PERLU KONFIRMASI]` dan tidak boleh ditampilkan sampai schema disepakati.

### 4.7 QR Wi-Fi (Provisioning)

- **Route:** `/perangkat/{deviceId}/wifi`
- **Tujuan:** Menampilkan kode QR berisi kredensial Wi-Fi untuk dipindai oleh
  perangkat, lengkap dengan status perangkat setelah provisioning.
- **Komponen:** `AppBar` dengan "Peringatan keamanan", `StepIndicator`
  (3 langkah), `TextFormField` SSID (dengan toggle tampilkan daftar Wi-Fi
  tersimpan `[PERLU KONFIRMASI]`), `TextFormField` kata sandi (obscuring,
  tombol lihat), tombol "Tampilkan QR", kartu QR (white, quiet zone, minimal
  25% ukuran layar), catatan privasi, panel status "Menunggu perangkat
  terhubung".
- **State:**

| State | Tampilan |
| --- | --- |
| Loading | Spinner pada tombol kirim, form tetap terisi |
| Error | Validasi field (inline) + snackbar untuk kegagalan kirim |
| Data | Kartu QR tampil setelah payload berhasil dibangun |
| Offline | Snackbar offline; QR tetap bisa dibuat karena payload dibangun di klien (bukan unduhan), namun status koneksi perangkat tidak dapat dipantau |
| Sukses | Dialog "Perangkat berhasil terhubung" + tombol "Selesai" |

```
+------------------------------------------------+
|  Wi-Fi lewat QR                    ( Peringatan)|
+------------------------------------------------+
|  (1 Isi data)  (2 Tampilkan QR)  (3 Pindai)    |
+                                                |
|  Nama Wi-Fi (SSID)                            |
|  [ RumahNet                          ]        |
|                                                |
|  Kata sandi Wi-Fi                             |
|  [ ****************            (lihat) ]      |
|                                                |
|  [   Tampilkan QR (FilledButton)        ]     |
|                                                |
|  ┌──────────────────────────────────────────┐  |
|  │                                          │  |
|  │                 [ QR ]                   │  |
|  │                                          │  |
|  └──────────────────────────────────────────┘  |
|  Pindai kode ini dengan kamera kacamata.      |
|                                                |
|  [! Kata sandi Wi-Fi tidak disimpan di aplikasi]|
|  [! Siapa pun yang memfoto layar ini bisa      |
|      melihat kata sandi. Sembunyikan layar.   ]|
|                                                |
|  Status: Menunggu perangkat terhubung...      |
+------------------------------------------------+
```

- **String l10n:** `provisioningTitle`, `provisioningStepData`,
  `provisioningStepQr`, `provisioningStepScan`, `provisioningSsidLabel`,
  `provisioningPasswordLabel`, `provisioningShowPassword`,
  `provisioningHidePassword`, `provisioningShowQr`, `provisioningRegenerate`,
  `provisioningQrHint`, `provisioningSecurityNotice`,
  `provisioningPasswordNotSaved`, `provisioningWaitingDevice`,
  `provisioningSuccessTitle`, `provisioningSuccessMessage`,
  `provisioningTimeoutHint`, `provisioningErrorEmptySsid`,
  `provisioningErrorEmptyPassword`, `provisioningDone`, `provisioningWarningTitle`.
- **Interaksi:** ketik SSID/kata sandi; tap lihat/sembunyikan; tap "Tampilkan
  QR" membangun payload lewat `BuildWifiQrPayload`; "Buat ulang QR" hanya
  untuk memperbarui token acak bila ada `[PERLU KONFIRMASI]`; pantau
  `WatchFirstHeartbeat` untuk mendeteksi perangkat berhasil masuk.
- **A11y:** kata sandi selalu obscured secara default; QR diberi
  `Semantics(label: provisioningQrSemantics)` karena kode QR tidak bisa
  "dibaca" tanpa kamera; peringatan keamanan memakai `Banner` dengan ikon dan
  `LiveRegion`; kontras teks putih di atas gradien minimal 4.5:1.
- **Aturan format (tidak boleh diarang):** payload QR dibangun oleh
  `BuildWifiQrPayload` dan **harus mengikuti format aplikasi Kotlin lama**.
  Format itu belum tersedia di repo, jadi panjang field, encoding, dan
  penanda versi **tidak boleh ditulis di dokumen ini** →
  `[PERLU KONFIRMASI]` (lihat `AGENTS.md` §3 dan §13). Password tidak pernah
  disimpan di preferensi lokal, log, atau riwayat.
- **Alur tambah perangkat:** layar untuk membuat perangkat baru belum
  ditentukan di `AGENTS.md`; firmware dan aplikasi lama harus menjadi sumber
  sebelum alur ini digambar `[PERLU KONFIRMASI]`.

### 4.8 Kontrol Jarak Jauh (P1)

- **Route:** `/perangkat/{deviceId}/perintah`
- **Tujuan:** Mengirim perintah ke perangkat dari jarak jauh dan memantau
  status eksekusinya.
- **Komponen:** `AppBar`, kartu daftar perintah (`CommandTile`: nama perintah,
  waktu kirim, `StatusPill` status), grup tombol aksi perintah, banner
  "Perangkat offline — perintah akan diproses saat perangkat terhubung kembali"
  bila perangkat sedang terputus.
- **State:** loading, empty ("Belum ada perintah terkirim"), error, data,
  offline.
- **String l10n:** `commandsTitle`, `commandsSendNow`, `commandsSending`,
  `commandsSent`, `commandsStatusPending`, `commandsStatusCompleted`,
  `commandsStatusFailed`, `commandsStatusUnknown`, `commandsEmpty`,
  `commandsEmptyDescription`, `commandsOfflineNotice`, `commandsConfirmTitle`,
  `commandsConfirmMessage`, `commandsSendFailed`, `commandsLog`.
- **Interaksi:** tap tombol perintah → dialog konfirmasi (teks jelaskan
  efeknya) → kirim → `SnackBar` "Perintah dikirim"; tap baris riwayat → detail
  status; pull-to-refresh.
- **A11y:** dialog konfirmasi menyatakan efek perintah dalam satu kalimat
  sederhana tanpa jargon; status perintah memakai warna + ikon + teks;
  perubahan status diumumkan lewat `LiveRegion` yang sopan (`polite`) agar
  tidak mengganggu pengguna yang sedang membaca.
- **Catatan P1:** daftar jenis perintah selain `sync_now` tidak ada di
  `AGENTS.md`; jangan menambahkan tombol perintah baru sebelum
  `docs/device_protocol.md` menyetakannya → `[PERLU KONFIRMASI]`. Perintah
  lain yang membutuhkan paket baru atau layanan berbayar juga perlu izin.

### 4.9 Pengaturan

- **Route:** `/pengaturan`
- **Tujuan:** Preferensi tampilan, mode pengembang, privasi thumbnail, akun,
  dan pintasan ke log sinkronisasi.
- **Komponen:** `GradientHeader` ringkas, daftar `ListTile` dikelompokkan:
  **Tampilan** (tema), **Mode pengembang** (sumber data, aktifkan mode),
  **Privasi** (kirim thumbnail kecil), **Koneksi** (Koneksi dan Sinkronisasi),
  **Akun** (email pengguna disamarkan, keluar), **Tentang** (versi aplikasi).
- **State:** loading (preferensi belum termuat), error, data, offline.
- **String l10n:** `settingsTitle`, `settingsSectionAppearance`,
  `settingsTheme`, `settingsThemeSystem`, `settingsThemeLight`,
  `settingsThemeDark`, `settingsSectionDeveloper`, `settingsDeveloperMode`,
  `settingsDeveloperModeDescription`, `settingsDataSource`,
  `settingsDataSourceFirebase`, `settingsDataSourceSimulation`,
  `settingsSectionPrivacy`, `settingsUploadThumbnails`,
  `settingsUploadThumbnailsDescription`, `settingsThumbnailsConsentTitle`,
  `settingsThumbnailsConsentMessage`, `settingsThumbnailsConsentAccept`,
  `settingsThumbnailsConsentDecline`, `settingsSectionConnection`,
  `settingsConnectionLogs`, `settingsSectionAccount`, `settingsSignedInAs`,
  `settingsLogout`, `logoutConfirmTitle`, `logoutConfirmMessage`,
  `settingsSectionAbout`, `settingsAppVersion`.
- **Interaksi:** tap tema → dialog pilihan (Ikuti sistem/Terang/Gelap) langsung
  menerapkan; toggle developer mode → dialog konfirmasi bahwa data sumber akan
  diganti, toggle thumbnail → dialog persetujuan privasi eksplisit sebelum
  menyalakan (default mati); tap keluar → dialog konfirmasi.
- **A11y:** toggle memakai `SwitchListTile` dengan label dan deskripsi yang
  mudah dibaca; dialog persetujuan ditampilkan dalam `AlertDialog`
  dengan tombol "Tidak" sebagai default; teks privasi dibaca utuh oleh
  pembaca layar tanpa dipotong.
- **Catatan privasi:** `settings.uploadThumbnails` default `false`. Mengaktifkannya
  memunculkan persetujuan yang menyebutkan batas ukuran thumbnail (maks 60 KB)
  dan fakta bahwa hanya gambar kecil pembacaan yang dikirim, bukan video,
  audio, atau lokasi. Menonaktifkannya tidak menghapus thumbnail lama dari
  cloud (mekanisme penghapusan dari aplikasi belum ada → `[PERLU KONFIRMASI]`).

### 4.10 Koneksi dan Sinkronisasi

- **Route:** `/pengaturan/koneksi` dan `/pengaturan/koneksi/{deviceId}`
- **Tujuan:** Dua tab dalam satu layar: kegagalan/event perangkat dan riwayat
  perintah, untuk membantu mendiagnosis sinkronisasi.
- **Komponen:** `AppBar` dengan filter perangkat (jika belum di route), `TabBar`
  (Kegagalan Perangkat / Riwayat Perintah), `EventTile`
  (severity sebagai `StatusPill`, pesan, waktu), `CommandTile`, pull-to-refresh.
- **State:** loading (skeleton per tab), empty ("Belum ada kegagalan
  tercatat" / "Belum ada perintah"), error, data, offline.
- **String l10n:** `connectivityTitle`, `connectivityTabEvents`,
  `connectivityTabCommands`, `connectivitySeverityInfo`,
  `connectivitySeverityWarning`, `connectivitySeverityError`,
  `connectivityEventsEmpty`, `connectivityEventsEmptyDescription`,
  `connectivityCommandsEmpty`, `connectivityOfflineNotice`,
  `connectivityLastSync`, `connectivityOpenDevice`.
- **Interaksi:** ganti tab; tap event untuk membuka perangkat terkait; swipe
  untuk refresh di kedua tab.
- **A11y:** severity dibacakan sebagai "Peringatan: <pesan>" agar makna warna
  tidak hilang; tab memakai `Semantics(selected: true)` untuk yang aktif;
  waktu ditulis absolut pada `Semantics` (relatif untuk mata, absolut untuk
  pembaca layar).
- **Catatan:** event hanya dibuat oleh perangkat; aplikasi tidak menulisnya.
  Daftar kolom event harus mengikuti `docs/firestore_schema.md` (belum ada di repo →
  `[PERLU KONFIRMASI]` untuk daftar kolom).

### 4.11 Empty states

Semua `EmptyView` memakai satu komponen dengan struktur: ikon 48 dp dalam
lingkaran container, judul `titleLarge`, pesan `bodyMedium`, aksi opsional
`FilledButton`.

| Layar | Judul | Pesan | Aksi |
| --- | --- | --- | --- |
| Beranda (tanpa perangkat) | `homeNoDevices` | "Perangkat belum ditambahkan ke akun ini." | `homeAddDevice` |
| Beranda (perangkat tanpa pembacaan) | `homeNoDetections` | "Belum ada pembacaan dari perangkat ini." | — |
| Validasi | `validationEmpty` | "Semua pembacaan sudah divalidasi." | `validationEmptyAction` (Buka riwayat) |
| Riwayat (kosong) | `historyEmpty` | "Riwayat akan muncul setelah perangkat mengirim pembacaan pertama." | — |
| Riwayat (filter) | `historyEmptyFiltered` | "Tidak ada pembacaan yang cocok dengan filter." | `historyEmptyClearFilter` |
| Perangkat | `devicesEmpty` | "Belum ada perangkat. Hubungi pemilik akun untuk menambahkan perangkat." | `devicesAdd` |
| Perintah | `commandsEmpty` | "Belum ada perintah yang dikirim ke perangkat ini." | — |
| Log koneksi | `connectivityEventsEmpty` | "Tidak ada kegagalan tercatat." | — |
| Detail (dokumen hilang) | `historyNotFound` | "Pembacaan ini sudah tidak ada." | Kembali |

Aturan: empty state tidak pernah memakai warna status (bukan error), tinggi
area 40 dp, dan pada textScale 2.0 tombol berubah jadi full width.

### 4.12 Error states

`ErrorView` menampilkan: ikon sesuai jenis (merah untuk error, abu untuk
akses), judul, pesan ramah Bahasa Indonesia, tombol "Coba lagi", dan opsional
baris "Detail teknis" yang hanya terlihat di mode pengembang.

Pemetaan error (`firebase_error_mapper.dart`) ke pesan:

| Kode | Judul l10n | Pesan l10n |
| --- | --- | --- |
| `permission-denied` | `errorAccessTitle` | `errorAccessMessage` ("Anda tidak punya akses ke data ini. Hubungi pemilik akun.") |
| `unavailable` | `errorServerTitle` | `errorServerMessage` ("Layanan sedang tidak bisa dihubungi. Coba lagi sebentar lagi.") |
| `not-found` | `errorNotFoundTitle` | `errorNotFoundMessage` ("Data yang dicari sudah tidak ada.") |
| `resource-exhausted` | `errorQuotaTitle` | `errorQuotaMessage` ("Batas penggunaan data tercapai sementara. Hapus filter yang tidak perlu lalu coba lagi.") |
| `deadline-exceeded` / timeout | `errorTimeoutTitle` | `errorTimeoutMessage` ("Koneksi terlalu lambat. Periksa jaringan Anda.") |
| jaringan mati | `errorOfflineTitle` | `errorOfflineMessage` ("Tidak ada koneksi internet. Menampilkan data tersimpan bila ada.") |
| lainnya | `errorGenericTitle` | `errorGenericMessage` ("Terjadi kesalahan. Coba lagi.") |

Aturan:

- Tidak pernah menampilkan kode error, path dokumen, atau email lengkap ke
  pengguna akhir.
- `retry` me-`invalidate` provider terkait, bukan me-reload aplikasi.
- Error pada aksi (bukan memuat halaman) lewat `SnackBar`, bukan mengganti
  seluruh layar.
- Detail teknis hanya di mode pengembang, disalin ke clipboard satu-tap.

---

## 5. Pustaka Komponen

Semua di `lib/core/widgets/` kecuali yang ditandai.

| Komponen | File | Peran | Catatan penting |
| --- | --- | --- | --- |
| `GradientHeader` | `gradient_header.dart` | SliverAppBar gradien teal | pinned, white foreground, `Semantics(header: true)` |
| `StatusPill` | `status_pill.dart` | Badge status dengan ikon + teks | Input: label l10n + `StatusColor` token; radius 8; min height 24 |
| `Skeleton` | `skeleton.dart` | Placeholder shimmer | Hormati `disableAnimations`; satu label semantik |
| `LoadingView` | `loading_view.dart` | Skeleton penuh layar | Dipakai saat memuat halaman untuk pertama kali |
| `ErrorView` | `error_view.dart` | Judul + pesan + coba lagi | Pesan dari mapper, tanpa jargon |
| `EmptyView` | `empty_view.dart` | Judul + pesan + aksi | Ikon 48 dp dalam container |
| `OfflineBanner` | `offline_banner.dart` | Amber banner + aksi retry | Muncul dari `isFromCache` |
| `SectionHeader` | `section_header.dart` | Judul section + aksi kanan | Untuk daftar panjang |

Komponen per-feature:

| Komponen | Layar | Peran |
| --- | --- | --- |
| `DeviceStatusCard` | Beranda, Perangkat, Detail Perangkat | Nama + status + last seen |
| `DeviceSummaryStrip` | Perangkat | Chip jumlah online/offline |
| `ValidationSummaryCard` | Beranda, Detail Perangkat | Metrik Cocok/Tidak cocok/Belum + akurasi |
| `DetectionListTile` | Riwayat, Aktivitas Terbaru | Baris ringkas pembacaan |
| `DetectionDetailCard` | Detail Pembacaan, Validasi | Konten lengkap + metadata |
| `ValidationActions` | Validasi, Detail Pembacaan | Dua tombol Cocok / Tidak cocok |
| `DetectionThumbnail` | Validasi, Detail | Gambar lazy-loaded + fallback |
| `FilterSheet` | Riwayat | BottomSheet filter |
| `WifiQrCard` | QR Wi-Fi | Kartu QR putih + catatan |
| `CommandTile` | Perintah, Koneksi | Riwayat perintah + status |
| `EventTile` | Koneksi | Event + severity |
| `SyncButton` | Beranda, Detail Perangkat | Kirim `sync_now` |
| `ConsentDialog` | Pengaturan, Berbagi | Dialog persetujuan privasi |
| `AccuracyDonut` | Beranda | Grafik donat akurasi (`fl_chart`) |

Aturan bersama semua komponen:

- Tidak ada string hardcoded; constructor menerima teks yang sudah dilokalkan.
- Ukuran mengikuti design token; tidak ada angka piksel/panjang teks yang
  ditulis langsung.
- Semua komponen menyesuaikan diri terhadap light/dark dan text scale.
- Widget interaktif memberi `Semantics(button: true)` + label yang menjelaskan
  aksi, bukan hanya nama ikon.

---

## 6. Copywriting dan Kunci l10n

Semua string ada di `lib/l10n/app_id.arb`. Nama kunci memakai `camelCase`
mengikuti konvensi gen_l10n. Placeholder ARB: `{count}`, `{time}`, `{value}`,
`{device}` dengan metadata `example`. Untuk jumlah yang berubah (mis. "3
pembacaan"), gunakan plural ARB (`zero/one/other`) karena Bahasa Indonesia punya
beberapa bentuk.

### 6.1 Aplikasi umum

| String Indonesia | Kunci |
| --- | --- |
| SiGap Netra | `appName` |
| Pendamping kacamata pintar tunanetika | `appTagline` |
| Coba lagi | `commonRetry` |
| Batal | `commonCancel` |
| Tutup | `commonClose` |
| Konfirmasi | `commonConfirm` |
| Simpan | `commonSave` |
| Hapus | `commonDelete` |
| Batalkan | `commonUndo` |
| Cari | `commonSearch` |
| Filter | `commonFilter` |
| Memuat... | `commonLoading` |
| Lainnya | `commonMore` |
| Mode tanpa koneksi | `offlineBannerTitle` |
| Data mungkin sudah tidak terbaru | `offlineBannerMessage` |
| Sedang mencoba menyambung kembali | `offlineBannerRetryHint` |
| Tidak ada perubahan | `noChangesLabel` |

### 6.2 Status dan label domain

| String Indonesia | Kunci |
| --- | --- |
| Online | `statusOnline` |
| Offline | `statusOffline` |
| Belum | `statusUnknown` |
| Cocok | `validationMatch` |
| Tidak cocok | `validationMismatch` |
| Menunggu validasi | `statusAwaitingValidation` |
| Uang | `detectionTypeMoney` |
| Teks | `detectionTypeText` |
| Terakhir terlihat {time} | `relativeLastSeen` |
| {time} lalu | `relativeTimePast` |
| Jarak {value} cm | `distanceLabel` |
| Akurasi {percent} ({match} dari {total}) | `accuracyLabel` |

### 6.3 Error

| String Indonesia | Kunci |
| --- | --- |
| Ada masalah | `errorGenericTitle` |
| Terjadi kesalahan. Coba lagi. | `errorGenericMessage` |
| Tidak punya akses | `errorAccessTitle` |
| Anda tidak punya akses ke data ini. Hubungi pemilik akun. | `errorAccessMessage` |
| Layanan sedang bermasalah | `errorServerTitle` |
| Layanan sedang tidak bisa dihubungi. Coba lagi sebentar lagi. | `errorServerMessage` |
| Data tidak ditemukan | `errorNotFoundTitle` |
| Data yang dicari sudah tidak ada. | `errorNotFoundMessage` |
| Batas penggunaan tercapai | `errorQuotaTitle` |
| Batas penggunaan data tercapai sementara. Hapus filter yang tidak perlu lalu coba lagi. | `errorQuotaMessage` |
| Koneksi terlalu lambat | `errorTimeoutTitle` |
| Koneksi terlalu lambat. Periksa jaringan Anda. | `errorTimeoutMessage` |
| Tidak ada koneksi | `errorOfflineTitle` |
| Tidak ada koneksi internet. Menampilkan data tersimpan bila ada. | `errorOfflineMessage` |
| Lihat detail teknis | `errorShowTechnicalDetails` |

### 6.4 Catatan gaya bahasa

- Sapaan lugas: "Anda" untuk pengguna, hindari "Anda harus" yang menakutkan.
- Istilah teknis (snapshot, cache, token, payload) hanya muncul di detail
  teknis mode pengembang, tidak di teks utama.
- Tidak memakai kata yang menyalahkan pengguna; penyebab kegagalan
  selalu dijelaskan sebagai masalah jaringan atau layanan, bukan kesalahan
  pengguna.
- Angka memakai angka Arab dan pemisah ribuan lokal (locale `id`).
- Gaya huruf: hindari kapitalisasi berlebihan; gunakan kapital di awal kalimat.
- Istilah produk tetap dalam Bahasa Indonesia: perangkat, pembacaan,
  validasi, riwayat, pengaturan.

---

## 7. Panduan Aksesibilitas

1. **Kontras.** Teks biasa minimal 4.5:1, teks besar 3:1. Semua pasangan warna
   status pada §2.2 diverifikasi sebelum rilis; teks putih di atas gradien
   header diuji pada titik paling terang dan paling gelap gradien.
2. **Target sentuh.** Minimal 48x48 dp untuk semua target interaktif; target
   utama (validasi, tombol utama di empty state) minimal 56 dp. Jarak antar
   target minimal 8 dp.
3. **Text scale.** Layout harus rapi sampai `textScaleFactor` 2.0: gunakan
   `Flexible`/`Wrap`, hindari tinggi tetap untuk baris teks, dan biarkan
   header bertambah tinggi. Tidak ada elipsis pada nilai uang atau teks OCR
   penuh; boleh ellipsis hanya pada metadata waktu dengan `Semantics` yang
   memuat waktu absolut.
4. **Semantik.** Satu widget = satu node semantik. `merge` di dalam kartu
   kompak, `Semantics(header: true)` untuk semua judul section, `liveRegion`
   (default `polite`) untuk penghitung menunggu dan perubahan status
   perintah. Label menjelaskan isi/efek, bukan nama ikon
   ("Batalkan validasi pembacaan uang 50.000" bukan "Tombol").
5. **Warna bukan satu-satunya pembawa makna.** Setiap status punya ikon + teks +
   warna. Grafik akurasi selalu disertai angka setara dalam bentuk teks.
6. **Gambar.** Thumbnail punya label yang menyebut jenis pembacaan dan waktu;
   kondisi "gambar tidak tersedia" selalu berupa teks, bukan area kosong.
7. **Animasi.** Semua animasi non-esensial dihormati saat
   `disableAnimations` aktif atau pengguna memilih "Kurangi animasi" di
   pengaturan sistem. Tidak ada elemen berkedip lebih dari 3 Hz.
8. **Snackbar.** Pesan penting (validasi tersimpan, perintah terkirim) selalu
   diumumkan otomatis; aksi penting (batalkan validasi) tidak pernah hilang
   otomatis sebelum dibaca.
9. **Dialog.** Tombol destruktif tidak otomatis terfokus; fokus default pada
   tombol batal/pertahankan. Judul dialog menyebut objek yang dikenai
   ("Hapus pembacaan ini?").
10. **Urutan fokus dan keyboard.** Urutan tab mengikuti urutan visual;
    semua aksi punya jalur non-layar-sentuh (pintasan keyboard untuk desktop
    saat diuji) `[PERLU KONFIRMASI]` sesuai target platform.
11. **Warna perangkat.** Android dynamic color dinonaktifkan supaya palet
    status (hijau/merah/amber/abu) tetap konsisten dengan makna yang sudah
    disepakati; dynamic color tidak mengubah `StatusColors`.
12. **Pengujian.** Wajib dicek pada textScale 1.0 dan 2.0, light dan dark,
    TalkBack/VoiceOver sekali per rilis, dan dengan `debugDisableShadows` untuk
    memastikan informasi tidak bergantung pada bayangan.

---

## 8. Hal yang Menunggu Keputusan

Ringkasan hal yang sengaja tidak dikarang di dokumen ini:

1. Skema lengkap dan daftar kolom `Device`, `Detection`, `DeviceEvent`,
   `DeviceCommand` (butuh `docs/firestore_schema.md`).
2. Format payload QR Wi-Fi persis dari aplikasi Kotlin lama.
3. Daftar jenis `CommandType` selain `sync_now` (P1).
4. Alur "Tambah perangkat" (bagaimana akun dan perangkat dihubungkan).
5. Font kustom (saat ini memakai font sistem) dan konfirmasi hex turunan
   Material 3 untuk dokumentasi.
6. Perilaku thumbnail ketika `uploadThumbnails` dimatikan (apakah ada
   penghapusan thumbnail lama di app atau tidak).
7. Alur registrasi / lupa kata sandi (tidak disebut di `AGENTS.md`).
8. Anggaran kuota baca/tulis dan dampaknya pada batas `limit(...)`
   per stream (butuh PRD §9).