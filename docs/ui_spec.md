# Spesifikasi UI — SIGAP-NETRA App (v3: identitas visual "Lensa")

Dokumen ini adalah **sumber kebenaran sisi antarmuka (UI)**. Versi lama (tema teal) diarsipkan di `docs/ui_spec_legacy_teal.md` dan tidak berlaku lagi.

**Tujuan:** semua **fungsi dan fitur sama** dengan aplikasi Kotlin lama, tetapi tampilan, warna, tata letak, dan widget dirancang ulang agar jelas aplikasi milik tim SIGAP-NETRA — bukan salinan aplikasi lama.

Pengguna: **pendamping / keluarga / peneliti** (bukan penyandang tunanetra). Platform: Android (prioritas uji), iOS (kode lintas platform). Material 3, mode **Terang / Gelap / Ikuti sistem**. Semua teks Bahasa Indonesia lewat `lib/l10n/app_id.arb`.

---

## 1. Konsep Desain: "Lensa"

SIGAP-NETRA = mata/lensa untuk pengguna. Identitas visual berangkat dari **lensa kamera**: bentuk lingkaran, cincin diafragma, fokus. Karakter: **tenang, jelas, modern, kontras tinggi** (konteks aksesibilitas), bukan dashboard "hijau-gradien".

Elemen khas (signature):

- **Lens Ring** — cincin lensa dengan dua bahasa bentuk: **nilai** (kecocokan, baterai) = track penuh + busur progres **kontinu** di atasnya dengan ujung membulat — terbaca "timbul keluar" (pola donut); **menunggu alat** = 24 segmen diafragma + cincin "fokus" berdenyut. Widget: `core/widgets/lens_ring.dart` (`CustomPainter`).
- **Large-title app bar** yang menyusut saat scroll (tanpa gradien, tanpa foto header).
- **Bento grid** untuk ringkasan angka (bukan baris 3 statistik).
- **Kartu tonal** (warna permukaan M3 bertingkat), bukan kartu putih bershadow.

## 2. Design Tokens

### Warna

| Token                                              | Terang        | Gelap                                             |
| -------------------------------------------------- | ------------- | ------------------------------------------------- |
| `brandSeed` (Netra Indigo)                         | `#4A47D6`     | sama (`ColorScheme.fromSeed`, varian _tonalSpot_) |
| `accent` (Lensa Amber, dipakai sebagai `tertiary`) | `#F5A524`     | `#FFC15A`                                         |
| `background`                                       | `#F6F6FB`     | `#0E0F1A`                                         |
| `surfaceContainer*`                                | dari skema M3 | dari skema M3                                     |
| `ok` (Terhubung / Cocok)                           | `#1E9E63`     | `#5FD39A`                                         |
| `bad` (Terputus / Tidak cocok / Error)             | `#D64550`     | `#FF8A92`                                         |
| `warn` (Menunggu / Peringatan)                     | `#E5A00D`     | `#FFC857`                                         |
| `neutral` (Belum / Tidak tersedia)                 | `#6B6F80`     | `#9EA3B5`                                         |

`ok / bad / warn / neutral` didefinisikan sebagai `ThemeExtension` (`StatusColors`) — jangan memakai warna mentah di widget. Semua pasangan teks/latar harus lolos kontras WCAG AA (4.5:1 teks normal, 3:1 teks besar/ikon). Warna **tidak boleh** menjadi satu-satunya pembawa makna: selalu sertakan ikon atau label (✓ Cocok, ✕ Tidak cocok, • Belum).

Seed warna hanya berada di `core/theme/design_tokens.dart`; mengganti identitas warna = mengubah satu konstanta.

### Tipografi

Satu keluarga: **Plus Jakarta Sans** (di-_bundle_ sebagai asset di `assets/fonts/`, tanpa unduhan saat runtime; cek lisensi OFL). Angka statistik memakai `FontFeature.tabularFigures()`.

| Peran                             | Gaya                  |
| --------------------------------- | --------------------- |
| Large title (app bar)             | 28 / Bold             |
| Title                             | 18 / SemiBold         |
| Body                              | 14 / Regular          |
| Label / chip                      | 12 / SemiBold         |
| Angka besar (bento, hasil bacaan) | 32–40 / Bold, tabular |

### Bentuk, spasi, elevasi

- Grid 4 dp; padding halaman 20; jarak antar-seksi 24.
- Radius: **hero card 28**, kartu 20, thumbnail 14, input 14, bottom sheet atas 28, tombol utama & chip **bentuk pil (stadium)**.
- Elevasi: **tonal**, bukan shadow. Daftar memakai garis 1 px `outlineVariant` bila perlu pemisah.
- Ikon: set **rounded** (`Icons.*_rounded`), ukuran 24; ikon status 20.
- Tap target ≥ 48 dp. Dukungan _text scale_ hingga 1,3× tanpa overflow.

### Gerak

Durasi 200–300 ms, `Curves.easeOutCubic`. Perpindahan tab: _fade-through_. Thumbnail → detail: `Hero`. Haptic ringan saat Cocok/Tidak cocok; haptic sedang saat konfirmasi reset. Hormati "kurangi animasi" sistem.

## 3. Arsitektur Informasi

**Bottom navigation: tepat 4 destinasi** (M3 `NavigationBar` standar, lebar penuh — **bukan** pil mengambang), label selalu tampil:

| Tab           | Isi                                                          |
| ------------- | ------------------------------------------------------------ |
| **Beranda**   | Hero perangkat, ringkasan bento, aktivitas terbaru           |
| **Validasi**  | Antrean validasi (tumpukan kartu)                            |
| **Riwayat**   | Daftar per hari · **Statistik** (segmen di dalam tab)        |
| **Perangkat** | Koneksi & sinkronisasi, QR Wi-Fi, kontrol, aktivitas & error |

**Pengaturan bukan tab:** dibuka lewat **avatar** di kanan app bar semua tab (`/settings`). Fitur baru (statistik, kontrol jarak jauh, ekspor, share) selalu bersarang di dalam tab ini — **tidak boleh menambah tab kelima.** Badge angka kecil (warna `warn`) hanya pada tab Validasi (batas "99+").

> Jika tim lebih suka tab "Pengaturan" seperti aplikasi lama, cukup tukar tab **Perangkat** ↔ **Pengaturan** di `app_router.dart`; isi layar tidak berubah.

## 4. Tabel Kesetaraan Fungsi (lama → baru)

Setiap fungsi aplikasi lama **harus** ada. Centang saat selesai (lihat `progress.md`).

| Fungsi di aplikasi lama                                                                                                    | Lokasi baru                                                                 |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Kartu status perangkat (nama, terhubung/terputus, baterai, menunggu, terakhir sinkron)                                     | Beranda → **Hero perangkat** + bento                                        |
| Alamat IP perangkat                                                                                                        | Perangkat → detail (hanya bila Mode pengembang aktif)                       |
| **Sinkronkan sekarang**                                                                                                    | Beranda → tombol utama Hero (`sync_now`)                                    |
| Kotak peringatan "perangkat belum tersambung…"                                                                             | Beranda → banner kontekstual di Hero saat offline, dengan 3 langkah ringkas |
| **Tampilkan QR hotspot**                                                                                                   | Beranda (saat offline) dan Perangkat → **Hubungkan** → layar `/wifi-qr`     |
| **Tarik Rekaman Validasi**                                                                                                 | Digantikan sinkron otomatis + Sinkronkan sekarang (D9 di PRD)               |
| Ringkasan: menunggu divalidasi, % kecocokan                                                                                | Beranda → bento (Menunggu, Kecocokan Lens Ring)                             |
| Validasi: filter Gabungan/Uang/Menu-Teks, "1 dari N", gambar, TERBACA SEBAGAI, confidence, jarak, waktu, Cocok/Tidak cocok | Tab **Validasi**                                                            |
| Riwayat: filter, daftar, status Cocok/Belum, hapus                                                                         | Tab **Riwayat**                                                             |
| **Reset Status Validasi**                                                                                                  | Riwayat → menu ⋯ → konfirmasi                                               |
| Pengaturan → Tema                                                                                                          | Pengaturan (avatar) → Tampilan                                              |
| Pengaturan → Koneksi dan sinkronisasi                                                                                      | Tab **Perangkat**                                                           |
| Pengaturan → Mode pengembang                                                                                               | Pengaturan → Lanjutan                                                       |
| Ikon QR + toggle tema di header                                                                                            | QR → Beranda/Perangkat; tema → Pengaturan                                   |

## 5. Layar

### 5.1 Beranda

1. **App bar large-title:** judul "Beranda", subjudul nama perangkat (mis. `SGP-NETRA-0007`), avatar → Pengaturan.
2. **Hero perangkat** (kartu tonal `primaryContainer`, radius 28):
   - Baris identitas: lingkaran ikon kacamata dengan **titik status** (ok/bad); nama perangkat; chevron → detail.
   - **Strip 3 stat** (satu baris, pemisah hairline): status koneksi ("Terhubung"/"Terputus"), baterai ringkas (ikon + persen; "–" bila tidak tersedia), sinkron terakhir (jam absolut). Ring baterai besar **bukan** di Hero — satu-satunya ring besar di Beranda adalah ring kecocokan di bento.
   - Baris aksi (pil): **Sinkronkan** (filled; menampilkan pending → selesai/gagal) dan **QR Wi-Fi** (tonal). Saat offline, **QR Wi-Fi** menjadi aksi utama dan muncul panel 3 langkah: ① nyalakan hotspot/Wi-Fi ② tampilkan QR ③ arahkan ke kamera SIGAP-NETRA.
3. **Bento grid 2 kolom** (tone ubin `surfaceContainer` + hairline `outlineVariant`; dua ubin dalam satu baris **wajib sama tinggi** — `IntrinsicHeight` + `CrossAxisAlignment.stretch`):
   - **Menunggu validasi**: angka besar + tombol "Periksa" → tab Validasi.
   - **Kecocokan bacaan**: Lens Ring persen (hanya validasi manusia), diameter ±78, angka tengah `titleLarge`; track `outlineVariant` + busur progres kontinu berujung membulat di atas track (terbaca timbul keluar — bukan segmen ber-celah yang tampak seperti lekukan masuk ke dalam).
   - **Sinkron terakhir**: jam + tanggal sinkron terakhir (`lastSeen` perangkat, format `HH.mm · d MMM`).
   - **Hari ini**: jumlah pembacaan + rincian kategori (mis. "3 uang · 3 teks").
4. **Aktivitas terbaru:** 5 baris ringkas realtime (thumbnail kecil, nilai, waktu relatif, status). "Lihat semua" → Riwayat.

### 5.2 Validasi

- **App bar:** "Validasi", subjudul progres "1 dari N" (muncul bersama antrean; disembunyikan saat memuat / tanpa perangkat / antrean kosong); di bawahnya `SegmentedButton`: Gabungan · Uang · Menu/Teks + indikator progres linear tipis 6 dp.
- **Tumpukan kartu:** kartu teratas menampilkan area gambar (panel informatif "Gambar tidak diunggah" bila tanpa gambar; thumbnail rasio 4:3 saat media dimuat), kategori sebagai chip + nama perangkat, label kecil **TERBACA AS** + nilai besar (maks 4 baris), lalu baris `MetricChip`: keyakinan · jarak · waktu. Kartu di belakang **terlihat tepinya** sebagai tumpukan: terdorong 12 px ke bawah + menyempit 12 px per lapis, tone `surfaceContainerHigh` + hairline, samar (opacity bertingkat).
- **Aksi:** bar bawah dua tombol besar sejajar: **Tidak cocok** (outlined `bad.solid`) dan **Cocok** (filled `ok.solid`, teks `surface`). **Geser kartu** kiri/kanan = pintasan yang sama — hanya kartu yang bergeser (tombol & kerangka tetap diam), latar petunjuk berwarna status: kiri `bad.container` "Tidak cocok", kanan `ok.container` "Cocok". Setelah memilih: kartu berikutnya naik dengan animasi fade + slide 250 ms + snackbar **Urungkan** (5 dtk).
- **Tanpa gambar** (unggah gambar dimatikan): area gambar menjadi panel informatif "Gambar tidak diunggah" + ajakan membuka pengaturan privasi; validasi tetap bisa.
- **Empty state (3 kasus, jujur):** ① belum ada perangkat → "Belum ada perangkat terhubung" + "Buka Perangkat"; ② antrean habis → "Semua pembacaan sudah diperiksa" + "Buka Riwayat"; ③ filter aktif kosong padahal kategori lain masih menunggu → "Tidak ada antrean di filter ini" + jumlah yang menunggu + "Tampilkan semua" (reset filter ke Gabungan).

### 5.3 Riwayat

- **App bar:** "Riwayat", subjudul jujur jumlah yang dimuat ("N pembacaan tersimpan"; "N+ pembacaan dimuat" bila masih ada halaman berikut), menu ⋯ (Reset status validasi…, Ekspor CSV, Bagikan ringkasan).
- **Segmen:** **Daftar | Statistik**.
- **Daftar:** filter chip kategori (Semua · Uang · Menu/Teks) + chip Saring yang membuka sheet filter status (Semua · Belum · Cocok · Tidak cocok; tutup sheet tanpa memilih mempertahankan filter aktif — tidak me-reset diam-diam). **Dikelompokkan per hari** ("Hari ini", "Kemarin", tanggal) dengan nomor urut global. Baris: ikon kategori 48 (uang/teks) + titik status menempel (pola Aktivitas Beranda), label SemiBold, subjudul `No. N · Keyakinan … · … cm`, chip status di kanan + chevron. **Geser untuk menghapus**: latar `bad.container`, konfirmasi SEBELUM hapus via `ConfirmSheet` (tanpa Undo — Firestore tak bisa undelete dan app dilarang membuat ulang deteksi, skema §1). Ketuk → detail (panel gambar informatif bila tanpa thumbnail, label, kartu OCR + Salin, MetricChip, "Divalidasi oleh UID · waktu", tombol Cocok `ok.solid` / Tidak cocok `outlined bad.solid` sama seperti Validasi §5.2, Bagikan + Hapus di app bar).
- **Empty state (3 kasus, jujur — pola Validasi §5.2):** ① belum ada perangkat → "Belum ada perangkat terhubung" + "Buka Perangkat"; ② riwayat benar-benar kosong → "Belum ada pembacaan"; ③ filter aktif kosong → "Tidak ada hasil untuk filter ini" + "Tampilkan semua" (reset kategori + status sekaligus).
- **Statistik (P1):** pembacaan per hari/minggu, per kategori, tren % kecocokan (`fl_chart`), dengan pemilih rentang.
- **Reset Status Validasi:** dialog konfirmasi menjelaskan jumlah rekaman terdampak; eksekusi batch; haptic sedang.

### 5.4 Perangkat

- **Kepala:** ringkasan status (titik status, baterai, versi firmware/model, terakhir terlihat/sinkron).
- **Hubungkan:** kartu dengan tombol **Tampilkan QR Wi-Fi** + teks bantuan singkat → `/wifi-qr`.
- **Kontrol (P1):** slider volume, slider ambang confidence, saklar deteksi aktif, saklar **Unggah gambar** (membuka sheet persetujuan), tombol Restart aplikasi alat. Setiap perubahan = command dengan status ditampilkan (menunggu → diterima → selesai/gagal).
- **Aktivitas & error:** timeline event dengan ikon severity (info/peringatan/error/kritis) + kode + pesan; filter severity; "Lihat semua".
- Mode pengembang aktif → tampil IP, ID perangkat, versi.

### 5.5 QR Wi-Fi (`/wifi-qr`, layar penuh)

Stepper 3 langkah:

1. **Jaringan:** segmen _Hotspot ponsel_ / _Wi-Fi rumah_; isian SSID dan password (sembunyikan/tampilkan). Opsi "Ingat nama jaringan" (password **tidak pernah disimpan**).
2. **Tampilkan QR:** QR hitam di atas panel putih (selalu, termasuk mode gelap, agar terbaca kamera), kecerahan layar dinaikkan bila memungkinkan, petunjuk "Arahkan ke kamera SIGAP-NETRA".
3. **Menunggu alat:** Lens Ring "fokus" berdenyut, hitung mundur 2 menit, mendengarkan heartbeat pertama → **Terhubung ✓** atau status gagal + coba lagi.
   ⚠️ Format payload QR **harus identik** dengan yang dibuat aplikasi lama/dipahami firmware (lihat `docs/device_protocol.md` §7).

### 5.6 Pengaturan (`/settings`, via avatar)

- **Tampilan:** Tema — segmen Terang / Gelap / Sistem.
- **Privasi & data:** status unggah gambar (ubah/cabut), retensi 30 hari, hapus semua data perangkat (P1).
- **Lanjutan:** **Mode pengembang** → sumber data (Firebase / Simulasi), tampilkan IP/ID/versi. ⚠️ "Uji kamera" pada aplikasi lama belum jelas maksudnya — tanyakan sebelum dibangun.
- **Akun:** email, keluar. **Tentang:** versi aplikasi.

### 5.7 Splash & Login

Splash: logo lensa dengan animasi cincin "memfokus". Login: Email/Password dan Google, bahasa ramah, error jelas.

## 6. Inventaris Widget Bersama (`lib/core/widgets/`)

`LargeTitleScaffold` · `LensRing` · `StatusDot` · `StatusChip` · `MetricChip` · `BentoTile` · `DeviceHeroCard` · `SectionHeader` · `ThumbnailTile` · `DayGroupedList` · `SwipeStack` · `UndoSnackbar` (helper) · `ConfirmSheet` · `ConsentSheet` · `EmptyState` · `ErrorState` · `SkeletonBox` · `OfflineBanner`.

Semua widget menerima data lewat parameter; tidak ada akses Firebase di dalamnya.

## 7. State & Kasus Tepi (wajib di tiap layar)

Loading (skeleton) · kosong · error + coba lagi · data dari cache ("data mungkin lama") · alat offline · baterai tidak tersedia · pembacaan tanpa jarak · teks OCR panjang · tanpa gambar · `permission-denied` · koneksi pulih (pembaruan halus, tanpa kedip) · text scale besar · mode gelap.

## 8. Aksesibilitas

`Semantics` label untuk Lens Ring ("Kecocokan 96 persen"), tombol ikon, status chip; urutan fokus logis; target ≥ 48 dp; tidak mengandalkan warna saja; teks ≥ 14 sp; dukung TalkBack/VoiceOver; aksi geser selalu punya tombol setara.

## 9. Checklist Anti-Salinan (agent WAJIB menghindari tampilan lama)

- ❌ Header gradien teal dengan teks kecil di atas judul besar
- ❌ Warna utama teal/hijau `#00897B`; tombol aksi lebar penuh berwarna hijau
- ❌ Bottom nav berbentuk pil mengambang dengan badge merah
- ❌ Kartu putih bershadow dengan radius 16 dan ikon QR + toggle tema di setiap header
- ❌ Baris tiga statistik berdampingan di kartu perangkat
- ❌ Tab filter gaya "putih aktif" di atas daftar
- ❌ Tombol "Reset Status Validasi" lebar penuh di bawah daftar
- ✅ Large-title, tonal, Lens Ring, bento, daftar per hari, tumpukan kartu, 4 tab standar M3, pil

## 10. Fitur Rencana (dari spesifikasi lama) dan Statusnya

| Fitur                                     | Status                                                   |
| ----------------------------------------- | -------------------------------------------------------- |
| Notifikasi realtime                       | P2 — lokal saat aplikasi aktif; push butuh Blaze         |
| Grafik riwayat                            | P1 (Riwayat → Statistik)                                 |
| Export CSV/PDF                            | CSV P1; PDF P2                                           |
| Multi-perangkat                           | P2 (pemilih perangkat di Hero)                           |
| Mode offline                              | Cache Firestore + banner                                 |
| TTS di aplikasi                           | P2 (`flutter_tts`, tombol "Dengarkan")                   |
| Ambang confidence untuk validasi otomatis | P2 — ditandai terpisah; tidak dihitung dalam % kecocokan |
