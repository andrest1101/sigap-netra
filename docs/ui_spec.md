# Spesifikasi UI — SIGAP-NETRA App (v3: identitas visual "Lensa")

Dokumen ini adalah **sumber kebenaran sisi antarmuka (UI)**. Versi lama (tema teal) sudah dihapus; riwayat git tetap menyimpannya bila perlu dirujuk.

**Tujuan:** semua **fungsi dan fitur sama** dengan aplikasi Kotlin lama, tetapi tampilan, warna, tata letak, dan widget dirancang ulang agar jelas aplikasi milik tim SIGAP-NETRA — bukan salinan aplikasi lama.

Pengguna: **pendamping / keluarga / peneliti** (bukan penyandang tunanetra). Platform: Android (prioritas uji), iOS (kode lintas platform). Material 3, **terang-saja** (keputusan produk 2026-10-18: mode gelap dihapus). Semua teks Bahasa Indonesia lewat `lib/l10n/app_id.arb`.

---

## 1. Konsep Desain: "Lensa"

SIGAP-NETRA = mata/lensa untuk pengguna. Identitas visual berangkat dari **lensa kamera**: bentuk lingkaran, cincin diafragma, fokus. Karakter: **tenang, jelas, modern, kontras tinggi** (konteks aksesibilitas), bukan dashboard "hijau-gradien".

Elemen khas (signature):

- **Lens Ring** — cincin lensa dengan dua bahasa bentuk: **nilai** (kecocokan, baterai) = track penuh + busur progres **kontinu** di atasnya dengan ujung membulat — terbaca "timbul keluar" (pola donut); **menunggu alat** = 24 segmen diafragma + cincin "fokus" berdenyut. Widget: `core/widgets/lens_ring.dart` (`CustomPainter`).
- **App bar rapat yang menempel saat scroll** (tanpa gradien, tanpa foto header), dengan judul sebaris aksi, subjudul kontekstual di bawahnya, dan avatar Pengaturan.
- **Bento grid** untuk ringkasan angka (bukan baris 3 statistik).
- **Kartu tonal** (warna permukaan M3 bertingkat), bukan kartu putih bershadow.

## 2. Design Tokens

### Warna

| Token                                              | Nilai                                                  |
| -------------------------------------------------- | ------------------------------------------------------ |
| `brandSeed` (Netra Indigo)                         | `#4A47D6` (`ColorScheme.fromSeed`, varian _tonalSpot_) |
| `accent` (Lensa Amber, dipakai sebagai `tertiary`) | `#F5A524`                                              |
| `background`                                       | `#F6F6FB`                                              |
| `surfaceContainer*`                                | dari skema M3                                          |
| `ok` (Terhubung / Cocok)                           | `#1E9E63`                                              |
| `bad` (Terputus / Tidak cocok / Error)             | `#D64550`                                              |
| `warn` (Menunggu / Peringatan)                     | `#E5A00D`                                              |
| `neutral` (Belum / Tidak tersedia)                 | `#6B6F80`                                              |

`ok / bad / warn / neutral` didefinisikan sebagai `ThemeExtension` (`StatusColors`) — jangan memakai warna mentah di widget. Semua pasangan teks/latar harus lolos kontras WCAG AA (4.5:1 teks normal, 3:1 teks besar/ikon). Warna **tidak boleh** menjadi satu-satunya pembawa makna: selalu sertakan ikon atau label (✓ Cocok, ✕ Tidak cocok, • Belum).

Seed warna hanya berada di `core/theme/design_tokens.dart`; mengganti identitas warna = mengubah satu konstanta.

### Tipografi

Satu keluarga: **Plus Jakarta Sans** (di-_bundle_ sebagai asset di `assets/fonts/`, tanpa unduhan saat runtime; cek lisensi OFL). Angka statistik memakai `FontFeature.tabularFigures()`.

| Peran                             | Gaya                  |
| --------------------------------- | --------------------- |
| Judul tab akar (app bar)          | 18 / SemiBold         |
| Judul layar anak (app bar)        | 18 / SemiBold         |
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

### Header seksi & kartu

- **Satu header seksi.** `SectionHeader` (bukan header privat) dengan varian `page`/`inset`, aksi kanan opsional, dan `dense`; judul `titleMedium` 16/SemiBold. Jarak ke konten 8, antar-seksi 24 (12 untuk `dense`). Varian `inset` tidak menambah padding horizontal karena body sudah memakai padding halaman 20.
- **Kartu seksi.** `SectionCard` tonal `surfaceContainerLow`, radius 20, hairline `outlineVariant`; divider inset 16 dan padding baris 12–16. Satu kartu = satu topik; jangan menumpuk `ListTile` telanjang tanpa pengelompokan.
- **Aksi berbentuk baris.** `ActionTile` untuk aksi di dalam kartu: leading 40 dp tonal, judul 14/SemiBold, keterangan 12/Regular, chevron 20; seluruh baris target sentuh. Chip mengambang hanya untuk filter/status, bukan daftar aksi.

### App bar

- **Empat tab akar** memakai `LargeTitleScaffold` dengan app bar **rapat** 18/SemiBold dan aksi sebaris di kanan (pil `SIMULASI`, refresh, menu, avatar). App bar menempel di atas saat konten digulir.
- **Subjudul kontekstual** (nama perangkat, progres validasi, atau jumlah riwayat) memakai 14/Regular dan berada tepat di bawah app bar, ikut tergulir. Jangan memakai large-title 28 di tab akar: judul besar dan baris aksi terpisah mendorong konten ke bawah (koreksi review produk 20 Okt 2026). Nama class `LargeTitleScaffold` adalah historis.
- **Avatar Pengaturan** adalah satu-satunya pintu Pengaturan di tab akar: lingkaran 34 dp berisi inisial nama/email (atau ikon orang), lencana gear 14 dp, target sentuh 48 dp, tooltip "Buka pengaturan". Tidak ada tombol gear terpisah.
- **Layar anak** memakai `BackAppBar` dengan judul 18/SemiBold — tidak mengulang judul tab akar. Tombol kembali eksplisit dengan fallback route saat deep-link.

### Gerak

Durasi 200–300 ms, `Curves.easeOutCubic`. Perpindahan tab: _fade-through_ 250 ms; hanya cabang asal dan tujuan tampil saat transisi, sementara navigator tab lain tetap tersimpan. Navigasi utama tetap langsung bila sistem meminta kurangi animasi. Skeleton berdenyut dan Lens Ring fokus juga menjadi statis; zoom dan petunjuk foto tetap berfungsi tanpa tween ketika gerak dikurangi. Thumbnail → detail: `Hero`. Haptic ringan saat Cocok/Tidak cocok; haptic sedang saat konfirmasi reset. Hormati "kurangi animasi" sistem.

### Mode data (kejujuran simulasi)

Data simulasi **tidak boleh** bisa tertukar dengan perangkat nyata. Sumber kebenaran bukan toggle di Pengaturan, melainkan hasil resolusi sekali di `main.dart` (`resolveDataSource`) yang dibagikan lewat `dataSourceSelectionProvider`:

| Kondisi                              | Sumber aktif | Alasan yang ditampilkan            |
| ------------------------------------ | ------------ | ---------------------------------- |
| Mode pengembang mati, Firebase siap  | Firebase     | —                                  |
| Mode pengembang mati, Firebase gagal | Simulasi     | "Firebase belum tersedia…"         |
| Mode pengembang aktif                | Simulasi     | "Mode pengembang dinyalakan…"      |

- **Pil `SIMULASI`** (bentuk stadium, tone `warn`, ikon `science_rounded`, huruf kecil tebal ber-tracking) tampil di deret aksi app bar **keempat tab**, sebelum avatar Pengaturan. Saat data live pil berukuran nol sehingga app bar dan golden test tidak bergeser. Satu label semantik utuh: "Mode simulasi: data demo, bukan perangkat nyata."
- **Layar masuk** menampilkan blok keterangan yang sama sebelum form: data demo, tidak ada koneksi cloud, akun apa pun hanya tersimpan di perangkat, plus alasan aktifnya.
- **Pengaturan → Lanjutan → Sumber data** membaca hasil resolusi nyata (bukan niat toggle) dan menyebut alasannya. Ini yang membuat build tanpa Firebase tidak lagi menulis "Firebase" saat data yang tampil sebenarnya simulasi.
- Penanda **tidak** mengubah query, skema, atau izin: ia hanya menyatakan kenyataan. Jangan menambahkan tombol tutup permanen pada penanda ini.

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
| Pengaturan → Tema                                                                                                          | Dihapus 2026-10-18 — aplikasi terang-saja (tanpa pemilih tema)              |
| Pengaturan → Koneksi dan sinkronisasi                                                                                      | Tab **Perangkat**                                                           |
| Pengaturan → Mode pengembang                                                                                               | Pengaturan → Lanjutan                                                       |
| Ikon QR + toggle tema di header                                                                                            | QR → Beranda/Perangkat; toggle tema dihapus (terang-saja)                   |

## 5. Layar

### 5.1 Beranda

1. **App bar rapat:** judul "Beranda", subjudul nama perangkat (mis. `SGP-NETRA-0007`) di bawahnya, avatar → Pengaturan.
2. **Hero perangkat** (kartu tonal `primaryContainer`, radius 28):
   - Baris identitas: lingkaran ikon kacamata dengan **titik status** (ok/bad); nama perangkat; chevron → detail.
   - **Strip 3 stat** (satu baris, pemisah hairline): status koneksi ("Terhubung"/"Terputus"), baterai ringkas (ikon + persen; "–" bila tidak tersedia), sinkron terakhir (**hanya jam absolut** `HH.mm`). Tanggal lengkap tetap di Bento agar strip tidak terpotong di 390 dp. Ring baterai besar **bukan** di Hero — satu-satunya ring besar di Beranda adalah ring kecocokan di bento.
   - Baris aksi (pil): **Sinkronkan** (filled; menampilkan pending → selesai/gagal) dan **QR Wi-Fi** (tonal). Saat offline, **QR Wi-Fi** menjadi aksi utama dan muncul panel 3 langkah: ① nyalakan hotspot/Wi-Fi ② tampilkan QR ③ arahkan ke kamera SIGAP-NETRA.
3. **Bento grid 2 kolom** (tone ubin `surfaceContainer` + hairline `outlineVariant`; dua ubin dalam satu baris **wajib sama tinggi** — `IntrinsicHeight` + `CrossAxisAlignment.stretch`):
   - **Menunggu validasi**: angka besar + tombol "Periksa" → tab Validasi.
   - **Kecocokan bacaan**: Lens Ring persen (hanya validasi manusia), diameter ±78, angka tengah `titleLarge`; track `outlineVariant` + busur progres kontinu berujung membulat di atas track (terbaca timbul keluar — bukan segmen ber-celah yang tampak seperti lekukan masuk ke dalam).
   - **Sinkron terakhir**: jam + tanggal sinkron terakhir (`lastSeen` perangkat, format `HH.mm · d MMM`).
   - **Hari ini**: jumlah pembacaan + rincian kategori (mis. "3 uang · 3 teks").
4. **Aktivitas terbaru:** 5 baris ringkas realtime (thumbnail kecil, nilai, waktu relatif, status). "Lihat semua" → Riwayat.

### 5.2 Validasi

- **App bar:** "Validasi", subjudul progres "1 dari N" (muncul bersama antrean; disembunyikan saat memuat / tanpa perangkat / antrean kosong); di bawahnya `SegmentedButton`: Gabungan · Uang · Menu/Teks + indikator progres linear tipis 6 dp.
- **Tumpukan kartu:** kartu teratas menampilkan area gambar (panel informatif "Gambar tidak diunggah" bila tanpa gambar; thumbnail rasio 4:3 saat media dimuat — tap foto → detail via Hero `detection-{id}`, tombol zoom di sudut membuka **penampil foto layar penuh** `PhotoViewerScreen`: cubit/geser + ketuk dua kali beranimasi 2,5×, tombol reset saat diperbesar, tutup; tanpa paket tambahan), kategori sebagai chip + nama perangkat, label kecil **TERBACA AS** + nilai besar (maks 4 baris), lalu baris `MetricChip`: keyakinan · jarak · waktu. Kartu di belakang **terlihat tepinya** sebagai tumpukan: terdorong 12 px ke bawah + menyempit 12 px per lapis, tone `surfaceContainerHigh` + hairline, samar (opacity bertingkat).
- **Aksi:** bar bawah dua tombol besar sejajar: **Tidak cocok** (outlined `bad.solid`) dan **Cocok** (filled `ok.solid`, teks `surface`). **Geser kartu** kiri/kanan = pintasan yang sama - hanya kartu yang bergeser (tombol & kerangka tetap diam). Latar yang terbuka memakai warna status (`bad.container` kiri, `ok.container` kanan) dengan ikon; label **"Tidak cocok"/"Cocok"** tampil sebagai pil mengambang di atas tepi atas kartu selama geseran, jadi tidak pernah tertutup kartu pada geseran awal. Setelah memilih: kartu berikutnya naik dengan animasi fade + slide 250 ms + snackbar **Urungkan** (5 dtk).
- **Tanpa gambar** (unggah gambar dimatikan): area gambar menjadi panel informatif "Gambar tidak diunggah" + ajakan membuka pengaturan privasi; validasi tetap bisa.
- **Empty state (3 kasus, jujur):** ① belum ada perangkat → "Belum ada perangkat terhubung" + "Buka Perangkat"; ② antrean habis → "Semua pembacaan sudah diperiksa" + "Buka Riwayat"; ③ filter aktif kosong padahal kategori lain masih menunggu → "Tidak ada antrean di filter ini" + jumlah yang menunggu + "Tampilkan semua" (reset filter ke Gabungan).

### 5.3 Riwayat

- **App bar:** "Riwayat", subjudul jujur jumlah yang dimuat ("N pembacaan tersimpan"; "N+ pembacaan dimuat" bila masih ada halaman berikut), menu ⋯ (Reset status validasi…, Ekspor CSV, Bagikan ringkasan). **Ekspor CSV** membuka dialog persetujuan (teks OCR dapat memuat data pribadi) sebelum menulis berkas; isinya maksimal **500 pembacaan terbaru sesuai filter aktif** (kategori + status) sebagai CSV titik-koma + BOM UTF-8 (langsung rapi di Excel Indonesia); berkas dibuat di perangkat pengguna lalu dibuka lewat share sheet, dan bila filter memuat lebih banyak baris pengguna diberi tahu bahwa hasilnya terpotong.
- **Segmen:** **Daftar | Statistik**.
- **Header panel Statistik:** "Pembacaan per hari", "Jenis pembacaan", dan "Status validasi" memakai `SectionHeader` halaman (16/SemiBold) yang sama dengan tab lain — bukan header privat.
- **Daftar:** filter chip kategori (Semua · Uang · Menu/Teks) + chip Saring yang membuka sheet filter status (Semua · Belum · Cocok · Tidak cocok; tutup sheet tanpa memilih mempertahankan filter aktif — tidak me-reset diam-diam). **Dikelompokkan per hari** ("Hari ini", "Kemarin", tanggal) dengan nomor urut global. Header hari memuat ringkasan jujur di kanan: `{N} pembacaan · {uang} uang · {teks} teks` untuk grup yang sudah lengkap, dan `{N}+ pembacaan` **tanpa** rincian jenis untuk grup terakhir yang masih terpotong halaman berikut — jangan mengklaim angka yang belum diambil. Baris dua baris: thumbnail 56/radius 14 (`ThumbnailTile`: foto bila ada, **ikon kategori uang/teks** bila tanpa gambar — bukan ikon "gambar rusak" yang menyesatkan, skeleton saat memuat; tanpa unduh di query daftar — lazy per kartu via `media/{id}`) + titik status menempel (pola Aktivitas Beranda), label SemiBold, lalu baris meta `Wrap` rapat `No. N · HH.mm` + `MetricChip` keyakinan (dense) + `MetricChip` jarak (dense) + `StatusChip` dense, plus chevron di kanan. Chip status ikut di dalam `Wrap` (bukan dipaku di kanan) supaya di layar 360 dp isinya turun ke run berikutnya, bukan terpotong. Halaman berikutnya lewat tombol **Muat lagi** (`FilledButton.tonalIcon`); bila semua halaman sudah dimuat, muncul teks "Inilah seluruh riwayat.". **Geser untuk menghapus**: latar `bad.container`, konfirmasi SEBELUM hapus via `ConfirmSheet` (tanpa Undo — Firestore tak bisa undelete dan app dilarang membuat ulang deteksi, skema §1). Ketuk → detail (foto besar Hero bila ada thumbnail — ketuk foto atau tombol zoom di sudutnya untuk membuka penampil layar penuh `PhotoViewerScreen` — panel informatif bila tanpa thumbnail, label, kartu OCR + Salin, MetricChip, "Divalidasi oleh UID · waktu", tombol Cocok `ok.solid` / Tidak cocok `outlined bad.solid` sama seperti Validasi §5.2, Bagikan + Hapus di app bar).
- **Empty state (3 kasus, jujur — pola Validasi §5.2):** ① belum ada perangkat → "Belum ada perangkat terhubung" + "Buka Perangkat"; ② riwayat benar-benar kosong → "Belum ada pembacaan"; ③ filter aktif kosong → "Tidak ada hasil untuk filter ini" + "Tampilkan semua" (reset kategori + status sekaligus).
- **Statistik (P1):** pemilih rentang **7 hari terakhir | 4 minggu terakhir** (ChoiceChip). Semua angka dari `count()` agregat — grafik **tidak pernah** mengunduh dokumen (skema §7.3 poin 3): 7 hari = 17 hitungan, 4 minggu = 11 hitungan, dijalankan paralel.
  - **Hero akurasi:** `LensRing` 92 dengan warna `ok.solid`, persen besar di tengah, judul "Akurasi bacaan", keterangan "dari {N} validasi" (hanya validasi manusia); bila belum ada validasi di rentang itu → ring tanpa nilai + "Belum ada validasi pada rentang ini". Akurasi = `cocok / (cocok + tidak cocok)`; **menunggu tidak pernah dihitung benar** (integritas validasi).
  - **Strip KPI 3 sel:** Total pembacaan · Per hari (≈ rata-rata, dibulatkan) · Menunggu validasi (aksen `warn`).
  - **Grafik batang bertumpuk** per hari/minggu: uang = `primary`, teks = `tertiary`, label nilai di atas tiap batang, garis bantu + label sumbu, legenda kecil, dan **satu** label semantik untuk pembaca layar (batangnya di-exclude supaya tidak dibacakan berulang). Batang mingguan = blok 7 hari yang berakhir hari ini (4 × 7 = 28 hari, tidak ada blok terpotong).
  - **Kartu "Jenis pembacaan" & "Status validasi":** bar proporsi 12 dp + legenda berangka (`{jumlah} · {persen}%`), persen dari total jendela yang sama.
  - **State:** skeleton saat memuat; empty "Belum ada pembacaan pada rentang ini" + aksi "Lihat 4 minggu terakhir" (hanya bila rentang masih bisa diperpanjang); gagal → `ErrorView` + Coba lagi (bukan deretan nol yang menyesatkan).
  - **Catatan dependensi:** grafik digambar sendiri (`CustomPaint` + `ColoredBox`) **tanpa `fl_chart`**. `fl_chart 1.1.0` ternyata tidak dapat dikompilasi dengan SDK Flutter 3.32.8 — memakai `Matrix4.translateByDouble` yang baru ada di `vector_math ≥ 2.2`, sedangkan paket `flutter` menyematkan `vector_math 2.1.4` (constraint `fl_chart` sendiri hanya `^2.1.4` — bug hulu). Diputuskan **2026-10-17**: `fl_chart` dihapus dari `pubspec.yaml` (tidak diimpor siapa pun); jangan dipasang lagi sebelum ada versi yang kompatibel dengan SDK yang dipakai.
- **Reset Status Validasi:** dialog konfirmasi menjelaskan jumlah rekaman terdampak; eksekusi batch; haptic sedang.

### 5.4 Perangkat

- **Kepala:** ringkasan status (titik status, baterai, versi firmware/model, terakhir terlihat/sinkron).
- **Detail perangkat:** hero identitas + tiga kartu seksi ber-`SectionHeader.inset`: **Informasi perangkat** (model, firmware, Wi-Fi, baterai, jumlah boot), **Privasi dan data** (status thumbnail dan catatan read-only), dan **Aksi**. Tindakan **Pasang Wi-Fi**, **Kontrol jarak jauh**, dan **Log koneksi** memakai `ActionTile` (bukan `ActionChip` mengambang).
- **Hubungkan:** kartu dengan tombol **Tampilkan QR Wi-Fi** + teks bantuan singkat → `/wifi-qr`.
- **Kontrol (fungsional sejak 2026-10-18):** slider **Volume** (satu perintah `set_volume` per penyesuaian selesai, bukan per geseran; angka tabular), **Sinkronkan sekarang**, **Ucapkan teks** (sheet teks, batas 200 karakter), dan **Mulai ulang** (konfirmasi dulu). Perintah boleh dikirim saat alat offline — diantre dan dieksekusi saat alat kembali, dengan catatan jujur di bawah tombol selama alat tidak tersambung; status menunggu selalu berbunyi **"Menunggu alat · {waktu}"**, tidak pernah "kedaluwarsa".
- **Timeline dua kartu terpisah (2026-10-20):** masing-masing kartu tonal `surfaceContainerLow` + hairline, padding baris 12/16, leading ikon 40 dp bernada status, divider inset 16, tinggi baris ±56–64 dp.
  - **Kejadian terakhir:** maksimal **4 event terbaru**; pesan SemiBold + meta `waktu · kategori` (Jaringan/Perintah/Sistem/Pembacaan/Kejadian) + chip severity. **Kode mentah** (`wlan_disconnected`, `command_failed`) hanya tampil di Log koneksi, bukan di kartu. "Lihat semua" → Log koneksi.
  - **Perintah terakhir:** maksimal **3 perintah terbaru**; judul + baris waktu + chip status. "Lihat semua" → layar Kontrol jarak jauh. Kosong → "Belum ada perintah yang dikirim dari aplikasi".
  - Saringan severity **tidak** ditampilkan di tab ini: saringan di kartu hanya akan menyaring 50 event yang sudah dimuat. Saringan menyeluruh (query server + paginasi) ada di **Log koneksi**.
  - Loading/error/empty ditangani di dalam masing-masing kartu, bukan sebagai daftar mengambang. Dua seksi tidak boleh digabung dalam satu daftar tanpa label.
- **Sub-layar Kontrol jarak jauh (Batch 2):** dua header seksi `SectionHeader.inset`, **Aksi cepat** dan **Riwayat perintah**. Aksi cepat = satu `SectionCard` berisi lima `ActionTile` (Sinkron · Ucapkan · Volume · Restart · Pasang ulang Wi-Fi) dengan ikon 40, keterangan singkat, dan chevron. Riwayat = satu `SectionCard` berisi `CommandTile.embedded` dengan divider inset; status pindah ke baris judul dan baris waktu/hasil memakai lebar penuh. Tanpa perangkat: notice **"Belum ada perangkat dipilih"** + tombol **Buka Perangkat**, semua `ActionTile` nonaktif dengan ikon kunci dan alasan yang terlihat. Loading/empty/error ditangani di dalam kartu riwayat. Tile yang sama dipakai tab "Perintah jarak jauh" di Log koneksi supaya bahasa status tidak pernah divergen.
- **Sub-layar Log koneksi:** tab **Event** punya dua mode jujur — **Semua** = streaming realtime 50 kejadian terbaru + catatan "Menampilkan N kejadian terbaru. Pilih saringan untuk menjelajah lebih jauh."; **saringan severity** = query server berhalaman (`getEventsPage`, indeks `severity + createdAt`, 25 per halaman) dengan tombol **Muat lagi**, spinner saat memuat, retry inline tanpa menghapus daftar yang sudah tampil, dan "Semua kejadian pada saringan ini sudah dimuat." saat habis. Tanpa perangkat terpilih saringan disembunyikan (schema tidak mengizinkan query lintas perangkat). Kode mentah event tampil di sini untuk diagnosis.
- **[PERLU KONFIRMASI] Kontrol yang menunggu kontrak firmware — jangan bangun UI palsu:** slider ambang keyakinan, saklar deteksi aktif/nonaktif, dan saklar unggah thumbnail jarak jauh belum punya jenis perintah di `docs/firestore_schema.md` §4.5; ditahan sampai tim perangkat mengonfirmasi.
- Mode pengembang aktif → tampil IP, ID perangkat, versi.

### 5.5 QR Wi-Fi (`/wifi-qr`, layar penuh)

Header langkah kustom 3 langkah (bukan `Stepper` Material): penanda 1-2-3 dengan garis progres, label tetap terlihat, langkah aktif disorot, dan langkah selesai dapat diketuk untuk kembali. Hanya isi langkah aktif yang dibangun; panel isi scrollable dengan padding bawah aman. Urutan langkah, nama field, dan payload QR tidak berubah.

1. **Jaringan:** segmen _Hotspot ponsel_ / _Wi-Fi rumah_; isian SSID dan password (sembunyikan/tampilkan). Opsi "Ingat nama jaringan" (password **tidak pernah disimpan**).
2. **Tampilkan QR:** QR hitam di atas panel putih (selalu putih agar terbaca kamera alat), kecerahan layar dinaikkan bila memungkinkan, petunjuk "Arahkan ke kamera SIGAP-NETRA".
3. **Menunggu alat:** Lens Ring "fokus" berdenyut + hitung mundur 2 menit. Tiga keadaan jujur: **menunggu** (denyut fokus + tombol Kembali); **Terhubung ✓** (ring penuh `ok.solid` + centang, hanya saat `lastSeen` perangkat maju melewati patokan saat langkah dibuka — bukti detak baru, bukan klaim kosong; tombol Selesai); **Belum tersambung** (hitung mundur habis tanpa detak: ring "Wi-Fi off", penjelasan, tombol Kembali + Coba lagi yang mengambil patokan ulang). App tidak pernah mengklaim "terhubung" tanpa detak baru.
   ⚠️ Format payload QR **harus identik** dengan yang dibuat aplikasi lama/dipahami firmware (lihat `docs/device_protocol.md` §7).

### 5.6 Pengaturan (`/settings`, via avatar)

- **Struktur kartu (Batch 2):** header akun tetap hero `primaryContainer` (avatar, nama, email tersamar, **Keluar** di baris terpisah) + tiga seksi ber-`SectionHeader.inset`: **Privasi dan data**, **Lanjutan**, **Tentang**. Setiap seksi memakai `SectionCard` tonal + hairline, divider inset 16, leading 36, dan padding 16. Teks penjelas panjang memakai lebar penuh di bawah saklar — bukan subtitle yang terhimpit switch. Tidak ada label seksi biru/privat.
- **Tampilan:** tidak ada pemilih tema — aplikasi terang-saja (keputusan produk 2026-10-18).
- **Privasi & data:** status unggah gambar (ubah/cabut) + penjelasan thumbnail maksimal 200 KB dan tanpa video/audio; catatan retensi jujur (data dapat dihapus kapan saja dari Riwayat; penghapusan otomatis 30 hari **belum aktif** — lihat `docs/firestore_schema.md` §7.4); hapus semua data perangkat (P1).
- **Lanjutan:** **Mode pengembang** + catatan berlaku setelah mulai ulang; sumber data (Firebase / Simulasi). Baris **Sumber data** selalu melaporkan sumber yang benar-benar aktif beserta alasannya (lihat §2 "Mode data"); toggle hanya menyatakan niat dan baru berlaku setelah mulai ulang. ⚠️ "Uji kamera" pada aplikasi lama belum jelas maksudnya — tanyakan sebelum dibangun.
- **Akun & Tentang:** akun (email, keluar) ada di hero; **Tentang** hanya versi aplikasi.
- **Batas bawah aman:** isi Pengaturan dibungkus `SafeArea` bawah + padding gulir 24 dp. Pada Android edge-to-edge, baris **Tentang / versi** tidak boleh tertutup navigation bar dan harus masih punya ruang gulir setelah kartu terakhir.

### 5.7 Splash & Login

Splash: logo lensa dengan animasi cincin "memfokus". Login: Email/Password dan Google, bahasa ramah, error jelas. Saat aplikasi memakai simulasi, blok **Mode simulasi aktif** tampil di bawah hero — sebelum pengguna memasukkan kredensial — dengan alasan dan catatan bahwa akun apa pun hanya tersimpan di perangkat.

**Layar masuk responsif:** hero ringkas dipakai saat tinggi < 900 dp atau text scale > 1,15× (cincin 64, jarak dan padding kartu poin dipadatkan). Hero, form, CTA, tautan daftar, dan catatan privasi berada dalam satu `SingleChildScrollView` dengan padding bawah 32 dp di dalam `SafeArea`; footer memakai `Wrap` agar "Belum punya akun? / Daftar" tetap utuh di 360 dp @1,3×. Tautan daftar tidak boleh menempel atau tertutup navigation bar.

**Cangkang native:** splash OS berlatar `#F6F6FB` + cakram logo (senada splash dalam-app, transisi tanpa kedip); ikon launcher adaptive (Android) & penuh (iOS/legacy) dari mark; label perangkat **SIGAP-NETRA**; status bar ikon gelap + latar transparan dipasang di akar `lib/app.dart`. Aset di `assets/branding/` (dihasilkan `tool/generate_branding_icons.ps1`), konfigurasi tool di `pubspec.yaml`.

## 6. Inventaris Widget Bersama (`lib/core/widgets/`)

`LargeTitleScaffold` · `LensRing` · `StatusDot` · `StatusChip` · `MetricChip` · `BentoTile` · `DeviceHeroCard` · `SectionHeader` · `SectionCard` · `ActionTile` · `ThumbnailTile` · `PhotoViewerScreen` + `PhotoZoomButton` · `DayGroupedList` · `SwipeStack` · `UndoSnackbar` (helper) · `ConfirmSheet` · `ConsentSheet` · `EmptyState` · `ErrorState` · `SkeletonBox` · `OfflineBanner`.

Semua widget menerima data lewat parameter; tidak ada akses Firebase di dalamnya.

`ConfirmSheet` dan `ConsentSheet` memakai kerangka bersama: isi (ikon, judul, pesan) scrollable, tinggi sheet maksimal 85% layar, baris aksi tetap di bawah dalam `SafeArea`, dan fokus awal pada Batal. Teks panjang pada 360×640 @1,3× tidak boleh mendorong tombol keluar dari layar.

## 7. State & Kasus Tepi (wajib di tiap layar)

Loading (skeleton) · kosong · error + coba lagi · data dari cache ("data mungkin lama") · alat offline · baterai tidak tersedia · pembacaan tanpa jarak · teks OCR panjang · tanpa gambar · `permission-denied` · koneksi pulih (pembaruan halus, tanpa kedip) · text scale besar.

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
- ✅ App bar rapat, tonal, Lens Ring, bento, daftar per hari, tumpukan kartu, 4 tab standar M3, pil

## 10. Fitur Rencana (dari spesifikasi lama) dan Statusnya

| Fitur                                     | Status                                                   |
| ----------------------------------------- | -------------------------------------------------------- |
| Notifikasi realtime                       | P2 — lokal saat aplikasi aktif; push butuh Blaze         |
| Grafik riwayat                            | ✅ P1 selesai — batang dari `count()` (digambar sendiri, tanpa `fl_chart`; §5.3) |
| Export CSV/PDF                            | ✅ CSV P1 selesai — 500 terbaru sesuai filter aktif, CSV titik-koma + BOM, consent sebelum menulis berkas (§5.3); PDF P2 |
| Multi-perangkat                           | P2 (pemilih perangkat di Hero)                           |
| Mode offline                              | Cache Firestore + banner                                 |
| TTS di aplikasi                           | P2 (`flutter_tts`, tombol "Dengarkan")                   |
| Ambang confidence untuk validasi otomatis | P2 — ditandai terpisah; tidak dihitung dalam % kecocokan |
