# Progress — SIGAP-NETRA App

## 2026-10-20 U4 — Sumber data jujur + penanda mode simulasi

Batch ini menutup kontradiksi yang bisa menyesatkan: `main.dart` memakai `developer_mode ?? true` sementara toggle Pengaturan memakai `?? false`, sehingga instalasi baru menampilkan data demo sambil Pengaturan menulis "Firebase". Sekarang sumber data adalah **hasil resolusi**, bukan niat toggle, dan UI menandainya secara permanen.

- **Satu kebenaran sumber data.** `DataSourceSelection` + `SimulationReason` (`developerMode` / `firebaseUnavailable`) di domain settings. `resolveDataSource` mengembalikan selection lengkap dengan alasan; default `developer_mode` kini `false` di `main` dan controller. Firebase hanya dipakai bila toggle mati **dan** init berhasil; kegagalan tetap jatuh ke simulasi, tetapi dengan alasan yang bisa dibaca pengguna.
- **Provider app-wide.** `dataSourceSelectionProvider` di-override sekali di `main.dart`, lalu dibaca UI. Default `firebase` hanya untuk widget test/preview; build produksi selalu meng-override. UI tidak pernah menyimpulkan mode dari preferensi.
- **Pil `SIMULASI`.** `SimulationBadge` tampil di deret aksi app bar **Beranda, Validasi, Riwayat, Perangkat** (sebelum gear): stadium tone `warn`, ikon `science_rounded`, huruf kecil tebal ber-tracking, satu label semantik utuh. Saat data live ukurannya nol, jadi app bar dan golden tidak bergeser. Test 360 dp memastikan pil + gear + menu Riwayat tetap muat.
- **Layar masuk jujur.** `SimulationNotice` di bawah hero menjelaskan data demo, tidak ada koneksi cloud, akun apa pun hanya tersimpan di perangkat, plus alasan aktifnya — sebelum pengguna memasukkan kredensial.
- **Pengaturan tidak lagi berbohong.** Baris **Sumber data** membaca `dataSourceSelectionProvider` dan menyebut alasannya ("Simulasi — mode pengembang aktif." / "Simulasi — Firebase belum tersedia pada build ini." / "Firebase — data tersinkron ke cloud."), bukan menyimpulkan dari nilai toggle.
- **Test.** +15 (dari 262): 6 aturan `resolveDataSource` (termasuk prioritas mode pengembang), 4 `simulation_badge_test` (live nol ukuran, dua alasan, semantik), 2 sumber data Pengaturan, 1 notice login, 6 penanda di tab + batas 360 dp. Golden tab/layar masuk **tidak berubah** karena default test adalah data live.
- **Verifikasi.** `dart format .` bersih (193 file, 0 berubah); `flutter analyze` No issues; `flutter test` **277 lulus**.
- **Catatan.** Tanpa paket baru, tanpa perubahan schema/rules/device. **Ditunda:** kesegaran data `isFromCache` (butuh threading metadata lewat data layer; `OfflineBanner` masih kode mati) dan temuan U5 bahwa `PhotoViewerScreen` dibuka lewat branch navigator sehingga bottom nav tetap terlihat di layar "penuh" — jangan dipindah ke root tanpa menguji ulang Hero. Berikutnya: audit U5 pada 360–390 dp + text scale 1,3×.

## 2026-10-20 U2 — Motion terarah dan hormati preferensi sistem

- **Fade-through tab yang menjaga state.** `FadeThroughBranchContainer` menganimasikan keluar/masuk hanya cabang navigator lama dan baru (250 ms), menjaga stack tiap tab, dan menonaktifkan input, ticker, serta semantik untuk cabang tak aktif. Saat animasi berkurang, pergantian langsung tanpa fade.
- **Kebijakan gerak terpusat.** `MotionPolicy` membaca `MediaQuery.disableAnimations`; `NavigationBar` memakai durasi sesuai preferensi sistem. Lens Ring fokus dan skeleton shimmer berhenti/menjadi statis ketika diminta, lalu pulih bila preferensi berubah.
- **Penampil foto.** Transisi layar, zoom programatik, dan petunjuk zoom memakai durasi/kurva token; zoom langsung bila gerak dikurangi. Interaksi pinch/pan dan hasil zoom tetap sama.
- **Test.** Ditambahkan test transisi cabang (incoming/outgoing) dan reduced motion; seluruh test aplikasi lulus.
- **Verifikasi.** `dart format` bersih; `flutter analyze` No issues; `flutter test` **262 lulus**.
- **Catatan.** Tanpa paket baru, perubahan schema/rules/device, maupun perubahan fungsi produk. Urutan poles selanjutnya: U4 strip simulasi → U5 audit 360–390 dp → U6 aksesibilitas.

## 2026-10-20 U3 — Zoom foto layar penuh (Validasi + detail Riwayat)

Foto hasil bacaan kini bisa diperiksa lebih dekat tanpa paket pihak ketiga. Penampil baru memakai `InteractiveViewer` bawaan Flutter, jadi tidak ada unduhan tambahan dan bytes tetap berasal dari `thumbnailProvider` yang sudah ada.

- **`PhotoViewerScreen`** (`lib/core/widgets/photo_viewer.dart`): latar `scrim`, foto `BoxFit.contain` dengan Hero dari foto asal, pinch/geser (`minScale` 1, `maxScale` 5), ketuk dua kali beranimasi ke 2,5× di titik ketukan, tombol reset saat diperbesar, tombol tutup 48 dp, dan `SystemUiOverlayStyle.light` selama layar gelap. Petunjuk "Cubit atau ketuk dua kali untuk memperbesar" memudar saat zoom agar tidak menutupi foto.
- **`PhotoZoomButton`**: area sentuh 48 dp dengan visual lingkaran 36 dp di sudut foto, dipakai di kartu Validasi dan detail Riwayat. Di Validasi, ketuk foto tetap membuka detail (alur lama); tombol zoom membuka penampil langsung tanpa meninggalkan antrean. Di detail, ketuk foto besar atau tombol zoom sama-sama membuka penampil.
- **Semantik foto Validasi**: parameter `semanticsLabel` yang sebelumnya tidak terpakai kini dipasang pada `Image.memory`; label detail memakai `detection.displayLabel`, bukan teks generik.
- **l10n**: 4 kunci baru (`photoViewerZoom`, `photoViewerClose`, `photoViewerReset`, `photoViewerHint`).
- **Test**: +6 — 4 `photo_viewer_test` (render, double-tap + reset, golden ponsel 390×844, tutup kembali), 1 `validation_photo_test` (tombol zoom membuka penampil), 1 `history_detail_test` (ketuk foto membuka penampil). Total **260 lulus**.
- **Verifikasi**: `dart format .` bersih; `flutter analyze` No issues; `flutter test` 260 lulus. Golden `photo_viewer_light.png` diperiksa manual; golden Validasi tidak berubah karena tombol berada di bawah viewport 800×600.
- **Catatan**: tanpa paket baru, tanpa perubahan schema/rules/device. Lanjut U2 motion.

## 2026-10-20 P1 — Rapikan tab Perangkat + hentikan data demo menyesatkan

Poles UI/UX lanjutan sebelum hardware (setelah U1). Dua keluhan nyata pengguna: thumbnail demo "AYAM GORENG" tampak seperti gambar rusak, dan kartu Kejadian/Perintah di tab Perangkat terasa sesak serta tidak berstruktur. Sekaligus menutup saringan severity yang menyesatkan (hanya menyaring 50 event yang sudah dimuat).

- **Demo thumbnail jujur.** `det-text-menu` tidak lagi membawa `thumbnailId`; generator PNG prosedural (`buildDemoThumbnailBytes` + encoder zlib/CRC) dihapus. `FakeMediaDataSource` hanya menyajikan dua foto uang asli (`demo_money_100k.jpg`, `demo_money_50k.jpg`); ID tanpa aset mengembalikan `null`, bukan gambar karangan. Test media diperbarui (evict/cache memakai ID uang; item teks tanpa aset diuji `null`).
- **Placeholder tanpa gambar = ikon kategori.** `ThumbnailTile.unavailable` menerima `icon`; baris Riwayat memakai ikon uang/teks, bukan `image_not_supported_outlined`. Ikon kategori kecil di sudut thumbnail dihapus (dulu duplikat). Panel tanpa gambar di detail Riwayat juga memakai ikon kategori. `broken_image_outlined` tetap dipakai hanya saat decode gambar benar-benar gagal.
- **Tab Perangkat: dua kartu terpisah.** `Kejadian terakhir` (maks 4 event) dan `Perintah terakhir` (maks 3 perintah) kini masing-masing berupa kartu tonal `surfaceContainerLow` + hairline, dengan anatomi baris konsisten: leading ikon 40 dp berlatar tonal, judul SemiBold, meta `waktu · kategori`, chip status, divider inset 16, padding 12/16. Loading/error/empty ditangani di dalam kartu.
- **Aksi "Lihat semua" jelas.** Header Kejadian → Log koneksi; header Perintah → layar Kontrol jarak jauh. Aksi "Lihat semua" di kartu Kontrol dihapus karena membuka daftar perintah, bukan kontrol.
- **Saringan severity pindah tempat.** Filter severity dihapus dari tab Perangkat (dulu hanya menyaring 50 event yang sudah dimuat); satu-satunya saringan menyeluruh tetap di Log koneksi (query server + paginasi). Test navigasi mengunci perilaku baru ini.
- **Kode event manusiawi.** Helper murni `eventCategoryLabel` memetakan prefiks (`wlan`/`wifi` → Jaringan, `command` → Perintah, `boot`/`config`/`storage`/`auth` → Sistem, `camera`/`lidar`/`sensor` → Pembacaan, fallback → Kejadian) + 5 kunci l10n. Kode mentah hanya tampil di Log koneksi. 2 unit test baru.
- **Verifikasi.** `dart format .` bersih (186 file, 0 berubah); `flutter analyze` No issues; `flutter test` **254 lulus** (dari 253; −1 test generator media, +2 test kategori). Golden `device_tab_light.png` & `history_tab_light.png` diregenerasi dan diperiksa manual (kartu terpisah, ikon kategori, tanpa gambar bergaris).
- **Catatan.** Tanpa paket baru, tanpa perubahan schema/rules/device. Urutan poles lanjut: U3 zoom foto → U2 motion → U4 strip simulasi → U5 audit per layar → U6 a11y.

## 2026-10-19 U1 — Cangkang native & brand: ikon launcher, splash OS, label perangkat, status bar

Batch pertama poles UI/UX sebelum menyentuh hardware (urutan rencana: U1 cangkang native → U3 zoom foto → U2 motion → U4 strip simulasi → U5 audit per layar → U6 a11y). Tujuan: aplikasi berhenti tampil sebagai "Flutter default" sejak ikon, splash, dan labelnya — bukan sekadar layar dalam.

- **Aset branding build-time.** Skrip baru `tool/generate_branding_icons.ps1` menghasilkan `assets/branding/{app_icon,app_icon_foreground,splash_logo}.png` dari satu sumber `assets/images/logo_mark.png` (konten mark terukur 486×342 px di dalam 512²; skala diatur lewat "lebar konten = % kanvas": ikon 86%, foreground adaptive 58% — aman di safe zone 66/108 dp, cakram splash 62.5% agar tampil ±160 dp). Latar kanvas ikon `#FFFDFB` (titik tengah gradasi latar sumber) — batas gambar tak terlihat, terukur selisih ≤4/255. Folder `assets/branding/` sengaja **tidak** didaftarkan di `pubspec.assets` (murni build-time).
- **Ikon launcher** (`flutter_launcher_icons` 0.14.4, dev): ikon Android legacy + **adaptive icon** (`mipmap-anydpi-v26`, background `#FFFDFB` via `colors.xml`, `inset="0%"` karena aset sudah dihitung sendiri) + ikon iOS penuh (`remove_alpha_ios`). Catatan: tool 0.14.x juga menulis nilai mencurigakan ke `ios/Runner.xcodeproj/project.pbxproj` (`GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon`; `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` sudah ada sebelumnya) — perubahan itu **direvert**; kemungkinan muncul lagi bila tool dijalankan ulang.
- **Splash native** (`flutter_native_splash` 2.4.7, dev): latar `#F6F6FB` (= `BrandColors.background`) + cakram logo, varian gelap disetel sama (terang-saja); Android 12+ memakai ikon launcher bawaan di lingkaran putih (`windowSplashScreenIconBackgroundColor`) sehingga transisi ke splash dalam-app tanpa kedip warna. Cakram digambar lewat `SetClip`: percobaan `TextureBrush` + transformasi matriks menghasilkan cakram terpotong garis lurus — ketangkap uji titik bentuk, bukan mata; uji itu kini gagal-cepat bila bentuknya salah.
- **Label perangkat.** `android:label` (AndroidManifest) + `CFBundleDisplayName`/`CFBundleName` (Info.plist) = **SIGAP-NETRA**.
- **Status bar eksplisit.** Gaya system UI terang-saja (ikon gelap, status bar transparan, navigation bar senada scaffold) dipasang di akar `lib/app.dart` lewat `AnnotatedRegion` — berlaku juga di layar tanpa AppBar (splash, login); AppBar bawaan tidak menimpa selama tema tidak menyetel `systemOverlayStyle` sendiri.
- **Optimasi aset.** `google_g_logo.png` 3840²/190 KB → 96²/**4 KB** (bicubic); `cacheWidth/cacheHeight: 80` di `login_screen.dart` dihapus — aset sudah kecil, satu resample lebih sedikit. Golden login **lolos tanpa regenerasi** (temuan R1 "190 KB untuk tampilan 20dp" selesai).
- **Verifikasi.** `dart format` bersih (0 dari 184 file); `flutter analyze` No issues; `flutter test` **253 lulus** tanpa perubahan golden; `flutter build apk --debug` **sukses** (JAVA_HOME jdk-21). Hasil generator diperiksa manual satu per satu: mipmap xxxhdpi legacy, adaptive foreground, iOS 1024, drawable-xxxhdpi/splash.
- **Dokumentasi:** `docs/ui_spec.md` §5.7 (paragraf cangkang native), `AGENTS.md` §5 (tool build-time) + §6 (baris `tool/` dan `assets/`).
- **Masih terbuka:** R2 (63 kunci l10n mati), R3 (dependensi dev tak terpakai), R4 (helper rute log koneksi), `applicationId` `com.example.*`; rencana poles lanjut: U3 zoom foto → U2 motion → U4 strip simulasi → U5 audit per layar → U6 a11y.

## 2026-10-19 R1 — Bersih-bersih kode mati & file sampah (audit repositori penuh)

Audit read-only penuh atas permintaan user (file tak perlu + hal lain), lalu eksekusi batch yang disetujui user: **R1 saja**. Semua yang dibuang terverifikasi **nol referensi** di `lib/` + `test/` (di luar generated) dan **nol test** yang menyentuhnya. R2 (63 kunci l10n mati), R3 (dependensi tak terpakai), dan R4 (helper rute log koneksi) ditunda atas keputusan user.

- **File sampah dibersihkan.** `$null` di root (130 B — hasil salah redirect `> $null` di PowerShell, ter-commit tak sengaja di `4736e98`) dihapus lewat `git rm`; `firestore-debug.log` (163 KB sisa uji emulator) + `sigap_netra_app.iml` dihapus dari disk (keduanya sudah di-ignore, murni lokal).
- **Kode mati dihapus (9 file).** `DeviceCard` (`device_card.dart`); `ValidateWifiCredentials` (layar QR memvalidasi per-field dengan `kMinWifiPasswordLength`, komentar use case itu juga sudah basi); rantai preferensi settings yang tak tersambung (`AppPreferences`, `PreferencesRepository`, `WatchPreferences`/`UpdatePreferences`, `PreferencesRepositoryImpl`, `PreferencesDataSource`, `SharedPreferencesDataSource`) — `settings_providers.dart` memang menyimpan langsung via `sharedPreferencesProvider` (`developer_mode`, `upload_thumbnails_privacy`).
- **`StatusPill` dirapikan.** Enum `AppStatusTone` pindah ke `core/theme/status_colors.dart` (rumah semantik status); widget `StatusPill` yang mati + file `core/widgets/status_pill.dart` dihapus; 10 importer disesuaikan (6 hapus impor karena `status_colors` sudah diimpor, 4 pindah jalur impor).
- **Arsip spec teal dihapus.** `docs/ui_spec_legacy_teal.md` (58 KB, ditandai tidak berlaku) — riwayat git tetap menyimpannya; kalimat rujukan di awal `docs/ui_spec.md` diperbarui. Entri historis `progress.md` lama sengaja tidak diubah (jurnal).
- **Dokumen disinkronkan.** `AGENTS.md`: tabel fitur — `provisioning` tanpa `ValidateWifiCredentials`; `settings` = `DataSource` + catatan "preferensi lokal via `sharedPreferencesProvider` (tanpa layer domain/data)"; komentar pohon `core/widgets/` kini memuat daftar yang nyata.
- **Verifikasi.** `dart format` bersih (0 dari 184 file berubah); `flutter analyze` No issues; `flutter test` **253 lulus** — tetap sama karena semua yang dibuang memang tak diuji.
- Temuan audit lain yang dicatat & sengaja ditunda: 63 kunci l10n mati (~17%), `cupertino_icons`/`mocktail`/`firebase_auth_mocks` tak terpakai, `OfflineBanner` menunggu sinyal `isFromCache` Firestore nyata, rute mentah `/pengaturan/koneksi/:deviceId` di detail Perangkat (belum helper), aset `google_g_logo.png` 190 KB untuk tampilan 20dp, `applicationId` masih `com.example.*`.

## 2026-10-18 P1 — Rumah tangga dokumen, audit Pengaturan, ekspor CSV, dan aturan device diperbaiki + diuji emulator

Sesi lanjutan setelah Batch A/B (keduanya sudah di-commit user). Fokus: menyelaraskan dokumen dengan kenyataan kode, menutup kopi basi (retensi, nama use case, indeks ganda), mewujudkan menu "Ekspor CSV" yang tadinya snackbar kosong, dan membuktikan `firebase/firestore.rules` benar-benar jalan di emulator — bukan hanya "ditulis".

- **Dokumen diselaraskan (K1).** `AGENTS.md`: rujukan `device/AGENTS.md` diperbaiki (aturan root berlaku sampai file itu ada), pohon `device/` disinkronkan (baru `sigap_cloud.py` + `config.example.py`), tabel fitur memakai nama kelas nyata — `validation`: `WatchPendingDetections/SubmitValidation/UndoValidation/GetValidationSummary` (bukan `GetAccuracy`), `history`: `GetDetectionsPage/DeleteDetection/ResetValidation/ResetAllValidations/GetHistoryInsights/BuildDetectionsCsv` (bukan `GetDailySummary`), `settings` tanpa pemilih tema (+`DataSource`), `provisioning` = fungsi murni `buildWifiQrPayload` + `ValidateWifiCredentials`, `auth` +`SignUpWithEmail/SignInAnonymously`, `commands` = `WatchCommands/WatchCommand/SendCommand`. `README.md` ditulis ulang (jalankan, mode pengembang, deploy Firebase, tes, struktur).
- **`docs/firestore_schema.md`.** §4.2 `label` resmi **opsional** (Opsi A: device hari ini tidak mengirimnya; `amount`+`currency` yang otoritatif untuk uang). §7.3 angka limit nyata: Beranda = satu listener `latestDetections(limit: 100)` untuk kartu "Hari ini" sekaligus 5 aktivitas, Validasi 20, Riwayat 25, Log 50 realtime / 25 berhalaman, Command 20. §7.4 catatan UI retensi. §8 penjelasan peta indeks fisik: 8 baris pemakaian → **5 definisi unik** (duplikat identik membuat deploy mencoba create dua kali). §9 dua temuan emulator; §11 item 1 (bootstrap create) dan item 24 **SELESAI**.
- **`docs/device_protocol.md`.** §2.2 tidak lagi menyajikan Opsi A/B sebagai pilihan terbuka — keputusan 2026-10-13 tercatat (Opsi B sementara + `Document.updateTime` sebagai kebenaran cadangan). §4.4.2 `label` opsional selaras skema. §11: #10 DIPUTUSKAN, #13 PRD §9 ada, #19 batas sisi app (teks 1–200, volume 0–100) vs skala audio firmware tetap terbuka, #20/#21 rules ditulis + diuji emulator.
- **`PRD.md`.** Ringkasan model data diselaraskan ke skema (kategori `money|text`, `amount`/`label`, `distanceCm`/`ocrText`; retensi 30 hari ditandai **target** — TTL tidak tersedia di Spark). F12 ditulis sesuai implementasi.
- **`firebase/firestore.indexes.json` dedupe (K3).** 8 definisi duplikatif → **5 unik** (#1–#3 satu indeks `validationStatus+createdAt DESC`; #4–#5 satu indeks `type+createdAt DESC`) + komentar pemetaan ke skema §8.
- **Audit Pengaturan (K4).** Kunci l10n mati `settingsLanguage`/`settingsPrivacy` dihapus (+regenerate); teks retensi diganti jujur: *"Pembacaan dan thumbnail dapat dihapus kapan saja dari Riwayat. Penghapusan otomatis 30 hari belum aktif."* Suite baru `settings_screen_test` (5 test: retensi jujur & "Bahasa" hilang, Batal consent tidak mengubah preferensi, Ya menyimpan `upload_thumbnails_privacy`, mode pengembang menulis `developer_mode`, versi `1.0.0+1` sinkron `kAppVersionDisplay`).
- **Ekspor CSV (F12) nyata — bukan snackbar "segera hadir" lagi.** Domain murni `buildDetectionsCsv`: header `waktu;jenis;nilai;mata_uang;teks;keyakinan;jarak_cm;status`; pemisah **titik-koma** + BOM UTF-8 supaya langsung rapi di Excel Indonesia; angka polos desimal koma (`NumberFormatId.plain`); baris baru OCR dinormalkan ` · `; escape RFC 4180; status memakai kata UI. Berkas `sigap-netra-riwayat-yyyyMMdd-HHmmss.csv` ditulis ke folder sementara lalu dibagikan lewat `share_plus` (`XFile`) — **tidak ada upload**, consent lewat `ConsentSheet` dulu. Alur Riwayat: consent → satu query `limit(500)` **sesuai filter aktif** → share sheet; kosong → snackbar jujur; terpotong >500 → diberi tahu setelah sheet ditutup; `_snack` menyembunyikan pesan lama (tidak mengantre). Kunci l10n baru (consent/preparing/empty/truncated/failed) + `historyExportComingSoon` dihapus. Test: 7 unit builder + 3 widget (Batal tidak menulis; isi header + nama berkas regex; filter kosong).
- **`firebase/firestore.rules` v0.3 — dua bug nyata ketangkap emulator:** (a) **`create` device selalu ditolak** karena `isDevice()` memanggil `get()` dokumen yang belum ada → diganti bootstrap mandiri `isSignedIn() && request.resource.data.authUid == request.auth.uid` + allow-list key + validasi `settings`; (b) **`create` deteksi gagal evaluasi saat `ocrText` null eksplisit** (`.size()` pada null) padahal skema mengizinkannya → kini `null` diterima, non-string (map dengan `.size()`, dsb.) ditolak lewat `is string`.
- **Infra uji rules di emulator (K2).** Folder baru `firebase/tests/`: `@firebase/rules-unit-testing` 6 + `firebase` 13, berkas `rules.test.mjs` **25 test / 6 suite** — cakupan: baca member vs outsider vs anon; self-bootstrap create (+tolak `authUid` asing / key liar); update device vs pengecualian owner `members`; detections (create sah, status/field validasi, OCR >500 + non-string, update hanya 3 field, delete); media (opt-in, mime, 60.000 byte, 81.920 string); events; commands (payload kredensial, requestedBy, transisi satu arah pending→sent→acked→done|failed, `failed` wajib `resultNote`); catch-all deny. `firebase.json` + blok `emulators` (port 8080, UI mati, singleProjectMode) dan `.gitignore` (`.firebase/`, `firebase/tests/node_modules/`). Perintah: `firebase emulators:exec --only firestore --project demo-sigap-netra "node --test firebase/tests/rules.test.mjs"` — butuh **Java 21+** (firebase-tools 15 menolak Java 17; mesin dipasangi Microsoft OpenJDK 21.0.12).
- **Verifikasi.** `dart format` bersih; `flutter analyze` No issues; `flutter test` **253 lulus** (dari 238); emulator rules **25/25 lulus**.
- Tetap terbuka: mekanisme retensi otomatis (belum ada — hanya salinan yang dijujurkan), format payload QR Wi-Fi legacy, daftar kelas/nominal uang, command ambang keyakinan/deteksi/upload jarak jauh, skala audio firmware.

## 2026-10-18 Batch B — Perangkat: Kontrol fungsional, timeline dua seksi, Log berhalaman, QR tiga hasil

Batch ini mengubah tab **Perangkat** dari tampilan dekoratif menjadi benar-benar bekerja, sekaligus menutup tiga "kebohongan halus": chip Kontrol yang hanya berpindah layar, timeline yang mencampur event + perintah tanpa label, dan langkah "Menunggu alat" yang berakhir tanpa jawaban.

- **Kontrol fungsional di tab:** slider **Volume** (satu perintah `set_volume` per penyesuaian selesai — bukan per geseran), tombol **Sinkronkan sekarang**, chip **Ucapkan teks** (sheet) dan **Mulai ulang** (konfirmasi). Chip dekoratif lama dihapus. Perintah boleh dikirim saat alat offline (diantre device), dengan catatan jujur di bawah tombol saat alat tidak tersambung.
- **Bahasa pending jujur:** status `pending` selalu tampil **"Menunggu alat · {waktu}"** — tidak pernah "kedaluwarsa"/"gagal", karena perintah offline tetap dieksekusi saat alat kembali. Berlaku di tile bersama, timeline, dan layar Kontrol.
- **Aksi & tile bersama (anti-divergensi):** `commands/presentation/command_actions.dart` (satu jalur kirim/sheet/konfirmasi + snackbar), `widgets/command_tile.dart`, `widgets/command_presentation.dart` (label/ikon/nada/ringkasan payload). Dipakai tab Perangkat, layar Kontrol, dan tab Perintah di Log koneksi.
- **Timeline dua seksi:** **Kejadian terakhir** (event + filter severity + "Lihat semua") dan **Perintah terakhir** (3 terbaru) dipisah dengan loading/error/empty masing-masing; empty saringan tidak lagi menyamar sebagai "belum ada kejadian".
- **Subtitle multi-perangkat jujur:** saat akun punya >1 perangkat, muncul catatan "Menampilkan perangkat utama dari N perangkat" (sebelumnya subtitle menghitung semua tetapi hanya satu dirender).
- **Log koneksi — dua mode jujur:** "Semua" tetap realtime 50 terbaru + catatan batas; **saringan severity** memakai query server berhalaman (`getEventsPage`, indeks `severity + createdAt`, 25/halaman) dengan **Muat lagi**, spinner, retry inline yang tidak menghapus daftar, dan catatan "sudah dimuat". Provider `getEventsPageProvider` + `kEventsPageSize` ditambahkan; guard balapan (`_fetchGeneration`) menjaga hasil fetch lama tidak menimpa saringan baru.
- **QR Wi-Fi langkah 3 — tiga hasil:** menunggu (denyut fokus + hitung mundur) / **Terhubung ✓** (ring penuh + centang; hanya saat `lastSeen` maju melewati patokan saat langkah dibuka — lewat stream `deviceProvider`, bukan polling) / **Belum tersambung** (timeout 2 menit: Kembali + Coba lagi yang mengambil patokan ulang). Layar menjadi `ConsumerStatefulWidget`; smoke test QR diperbarui ke `ProviderScope`.
- **Bug diperbaiki saat pengujian:** controller sheet "Ucapkan teks" dulu di-dispose segera setelah `pop()` sehingga terpakai selama animasi keluar (crash "used after being disposed" + overflow); sekarang dimiliki `_SpeakTextSheet` (`State.dispose`) dengan `isScrollControlled` + ruang aman keyboard.
- **[PERLU KONFIRMASI] Kontrol tertahan firmware (tidak dibuatkan UI palsu):** ambang keyakinan, saklar deteksi aktif, dan unggah thumbnail jarak jauh belum punya jenis perintah di `docs/firestore_schema.md` §4.5. Kandidat syarat tambahan QR (`wifiSsid` cocok) juga menunggu konfirmasi apakah firmware memperbarui field itu saat reprovision.
- **Test:** suite baru `commands_screen_test` (pending jujur, sheet volume, sheet teks + ringkasan payload) dan `connection_logs_screen_test` (catatan realtime, saringan server, Muat lagi 30 item, tab Perintah); perluasan `wifi_provisioning_screen_test` (terhubung via detak baru, timeout + coba lagi) dan `device_tab_golden_test` (kirim sungguhan, slider, dua seksi; surface 800×1400). Golden `device_tab_light.png` diregenerasi dan diperiksa manual. `flutter analyze` bersih, **238 test lulus** (dari 226).
- **Dokumentasi:** `docs/ui_spec.md` §5.4 (Kontrol fungsional, timeline dua seksi, sub-layar Kontrol + Log koneksi, blok [PERLU KONFIRMASI]) dan §5.5 langkah 3 (tiga keadaan).

## 2026-10-18 Batch A — Terang-saja: mode gelap dihapus seluruhnya

Keputusan produk (dipilih user): aplikasi **terang-saja**. Mode gelap tidak lagi ditawarkan maupun mengikuti setelan ponsel — satu identitas visual, tanpa pemilih tema. Batch ini hanya menyentuh tema; **golden terang diverifikasi tetap byte-identik** (invarian paling penting dari batch ini).

- **Inti tema:** `AppTheme.dark()` dihapus; `_build()` tidak lagi menerima `Brightness` dan selalu membangun skema terang. `StatusColors.dark` dihapus; `StatusColors.of()` kini fallback ke `light` untuk `ThemeData` polos (ada regression test-nya di `lens_ring_test`). Token `accentDark`/`backgroundDark` dihapus, `backgroundLight` → `BrandColors.background`.
- **Preferensi:** `AppPreferences.themeMode` + kunci `'theme_mode'` + `theme_providers.dart` dihapus. Kunci lama di instalasi lawas diabaikan (tidak dibaca lagi) — tidak ada migrasi yang perlu dijalankan.
- **Pengaturan:** seksi "Tampilan" (SegmentedButton tema) dihapus; seksi Privasi kini seksi pertama. Kunci l10n `settingsThemeSystem/Light/Dark`, `settingsAppearance`, `settingsDisplayTitle` dihapus dari `app_id.arb` + regenerate.
- **Test:** 5 golden gelap dihapus (Beranda, Validasi, Perangkat, Login, Statistik Riwayat) beserta seluruh kabel `darkTheme`/`themeMode`/`pump*(mode:)`; 1 test baru: fallback `StatusColors.of` pada tema polos. Hasil: `flutter analyze` bersih, **226 test lulus** (dari 232; −8 test gelap +1 fallback + perubahan kabel).
- **Dokumentasi:** `docs/ui_spec.md` (design token jadi satu kolom nilai; catatan QR; seksi 5.6; daftar state), `PRD.md` (ringkasan §1 + acceptance F6), `AGENTS.md` §5 (terang-saja; paket `fl_chart` & `fake_cloud_firestore` dikeluarkan dari daftar). Mode gelap tidak lagi muncul di dokumen mana pun.

## 2026-10-17 P1 — Riwayat R2: segmen Statistik nyata (`count()` agregat) + poles daftar + logo brand asli

Dua pekerjaan dalam satu batch, keduanya menyentuh tampilan kasat mata: **(A)** mark logo SIGAP-NETRA asli menggantikan logo lama, **(B)** halaman Riwayat dinaikkan satu tingkat — segmen **Statistik** yang benar-benar hidup (tanpa mengunduh dokumen) dan daftar yang lebih terbaca. Pola audit per halaman tetap: 1 halaman selesai → lanjut.

- **Logo (A).** `assets/images/logo_mark.png` (dipangkas dari `logo.jpeg`, latar putih dipertahankan, dipotong bulat) dirender **hanya** lewat satu widget `core/widgets/logo_mark.dart` (`LogoMark`, `kLogoMarkAsset`): splash 72, login 52, Hero Beranda & kepala detail Perangkat 56. Tidak ada lagi jalur render logo kedua; helper test `precacheLogoMark` menjaga golden tetap ter-decode.
- **Statistik (B).** Panel "segera hadir" diganti panel nyata: `HistoryWindow` (7 hari = 7 batang harian; 4 minggu = 4 blok **7 hari penuh** yang berakhir hari ini, 28 hari tanpa potongan), `HistoryInsights` (`accuracyPercent`, `averagePerDay`, `isEmpty`, jendela), `GetHistoryInsights` (2 hitungan per batang: uang & teks + 3 hitungan status → **17 hitungan** untuk 7 hari, **11** untuk 4 minggu, paralel), `countDetections` di kontrak/repository/data source (+ fake memakai `filter.matches`).
- **UI Statistik.** ChoiceChip rentang → hero akurasi `LensRing` 92 (`ok.solid`, persen di tengah, "dari {N} validasi") + KPI Total pembacaan · Per hari (≈) · Menunggu validasi (`warn`) → grafik batang bertumpuk uang/teks (`primary`/`tertiary`) dengan label nilai di atas batang, garis bantu, legenda, dan **satu** label semantik (batang di-exclude) → kartu "Jenis pembacaan" & "Status validasi" (bar proporsi 12 dp + legenda `{jumlah} · {persen}%`). State: skeleton, empty jujur ("Belum ada pembacaan pada rentang ini" + aksi "Lihat 4 minggu terakhir" hanya bila rentang masih bisa diperpanjang), error `ErrorView` + Coba lagi (bukan deretan nol). Akurasi = `cocok ÷ (cocok + tidak cocok)`; **pending tidak pernah dihitung benar**; rentang memakai `createdAt` `[since, before)` supaya sepakat dengan tanggal di daftar.
- **Grafik digambar sendiri — `fl_chart` dihapus.** `fl_chart 1.1.0` **tidak bisa dikompilasi** di SDK Flutter 3.32.8: memakai `Matrix4.translateByDouble` yang baru ada di `vector_math ≥ 2.2`, sementara paket `flutter` menyematkan `vector_math 2.1.4` (constraint `fl_chart` sendiri cuma `^2.1.4` — bug hulu). Grafik ditulis manual (`CustomPaint` + `ColoredBox`, `daily_readings_chart.dart`) dan **keputusan owner 2026-10-17: `fl_chart` dihapus dari `pubspec.yaml`** (tidak diimpor siapa pun) — jangan dipasang lagi sebelum ada versi yang kompatibel. AGENTS.md §5 masih menyebut `fl_chart` sebagai paket yang diharapkan (menunggu keputusan owner untuk dicabut dari daftar itu).
- **Bug nyata dari inspeksi golden.** Segmen `ColoredBox` (batang grafik & bar komposisi) runtuh jadi **0 px** karena sumbu lintang longgar → fix `CrossAxisAlignment.stretch`; dikunci regresi "semua segmen berwarna punya ukuran > 0" (1 px hairline tetap sah).
- **Poles daftar.** Header hari berisi ringkasan jujur (`{N} pembacaan · {uang} uang · {teks} teks`; grup terakhir yang terpotong halaman → `{N}+ pembacaan` **tanpa** rincian jenis), baris dua baris dengan `Wrap` rapat (`No. N · HH.mm` + `MetricChip` keyakinan/jarak dense + `StatusChip` dense) — chip status dipindah ke dalam `Wrap` supaya layar 360 dp tidak terpotong (sebelumnya chip memaku di kanan dan menghimpit baris meta), tombol "Muat lagi" `FilledButton.tonalIcon` + "Inilah seluruh riwayat." di halaman terakhir, `ref.invalidate(historyInsightsProvider)` setelah hapus/reset, kunci `ValueKey('day-<tanggal>')` untuk header hari.
- **Data demo lebih hidup.** `_pastDayPattern` 27 hari → **123 bacaan** (93 uang / 30 teks; 114 cocok / 7 tidak cocok / 2 menunggu → akurasi **94%**; jendela 7 hari 36 bacaan → **91%**), deterministik relatif hari ini supaya angka panel & golden tidak berubah antartanggal (hanya urutan nama hari berotasi; font test merender tiap huruf sama). Hari ini tetap 6 bacaan (4 uang / 2 teks, 2 menunggu) — semua test lama yang mengunci angka hari ini tetap sah.
- **Indeks & kuota.** **Tidak ada indeks baru**: jalur `count()` sengaja memakai `orderBy createdAt DESC` yang sama dengan daftar sehingga dijamin dilayani indeks #2–#5 (`firestore_history_data_source.dart`), bukan query tanpa urutan yang arahnya belum tentu dicocokkan Firestore. `docs/firestore_schema.md` §7.3 (aturan agregat Statistik: 17/11 hitungan, akurasi jendela) + §8 (composite wajib untuk setara + rentang, bukan hanya untuk `orderBy`) dijelaskan ulang; `PRD.md` §9 menambah baris anggaran baca panel Statistik + F5/F11 diperbarui.
- **Test**: baru `history_insights_test` (8: jendela 7/28 hari, pagar setengah terbuka, agregasi per batang/jenis/status, jendela kosong, `DetectionFilter` rentang) + `history_stats_test` (10: angka 7 hari 91%/36/≈5 + legenda 26·72%/10·28%, ganti rentang 94%/123/≈4, 7→4 batang, tab daftar header/partial/pil, empty + jalan keluar, error + Coba lagi, 360 dp tanpa overflow, regresi segmen 0 px). Golden baru `history_stats_light/dark.png` (800×1180, seluruh panel diinspeksi). Golden lain di-regenerate: `history_tab_light` (baris baru) & `home_tab_light/dark` (akurasi 94% + "dari 121 validasi"). Assertion lama disesuaikan ("25+ pembacaan dimuat", "dari 121 validasi"). Helper `FakeAppGraph(historyRepositoryBuilder:)` untuk memaksa jalur gagal tanpa override ganda (Riverpod 3 menolak dua override provider yang sama).
- **Docs**: `docs/ui_spec.md` §5.3 (Daftar + Statistik + catatan dependensi `fl_chart`), `docs/firestore_schema.md` §7.3/§8, `PRD.md` F5 + F11 + §9.
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **232 lulus**; golden di-regenerate + diperiksa sebagai PNG (bukan hanya "test hijau").

## 2026-10-16 R3 — Thumbnail media: Validasi + Riwayat berfoto, dummy 100rb Google

Pipeline `media/{id}` lazy per kartu: Firestore lookup satu dokumen (bukan query daftar), `MediaModel` defensif (mime/size/base64/60KB → null), `thumbnailProvider` autoDispose family, cache memori sesi. `ValidationPhoto` 4 state (tanpa-ID / skeleton 4:3 / gagal + Coba lagi / Hero 4:3 tap→detail), `_RowThumb` + `_DetailImage` selaras. Demo: `det-money-100k` memakai foto dummy Google `assets/images/demo_money_100k.jpg` (JPEG ±55 KB, di bawah batas privasi 60 KB; BUKAN hasil bacaan alat), item lain prosedural PNG 96x72, `det-text-sampul` sengaja tanpa thumbnail (panel tetap hidup). Aturan foto 4:3 mendorong konten keluar viewport test 800px → drag -800 sebelum tap/assert + `skipOffstage:false`; gesture swipe dari pojok kartu bukan teks nominal.

- **Test baru (13)**: `media_model_test` (6: valid, null, mime, size, base64, decode) + `fake_media_data_source_test` (4: dummy aset <60KB, prosedural header PNG + IHDR 96x72, null defensif, cache identik) + `validation_photo_test` (3: panel tanpa-ID, foto + Hero + tap, null → panel tanpa Image).
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **208 lulus**; goldens Validasi (terang/gelap/swipe) + Riwayat terang di-regenerate (foto dummy ikut terkunci).

## 2026-10-16 P1 — Poles tab Riwayat R1: list/detail jujur selaras Validasi

Audit UI/UX per halaman berlanjut (pola: 1 halaman selesai → lanjut). Halaman kedua: **Riwayat list + detail** (Statistik + CSV + thumbnail = R2/R3 terpisah).

- **Subjudul jujur**: "Ringkasan harian · N" menyesatkan (kunci penamaan lama, bukan ringkasan) → "N pembacaan tersimpan", atau "N+ pembacaan dimuat" bila `nextCursor` masih ada (klaim total diam-diam = bug).
- **Empty state 3 kasus** (pola Validasi): belum ada perangkat → "Buka Perangkat" (bukan "belum ada pembacaan"); riwayat benar-benar kosong; filter aktif kosong → "Tidak ada hasil untuk filter ini" + "Tampilkan semua" (reset kategori + status sekaligus).
- **Baris daftar**: ikon kategori 48 + titik status menempel (pola Aktivitas Beranda) ganti ikon "gambar rusak" ganda yang menyesatkan (thumbnail belum ada pipeline di R1, bukan rusak); label SemiBold; nomor urut global (lama: `indexOf` per grup — nomor mengulang tiap hari); chevron; navigasi via `HistoryDetailPath().push()` (bukan path literal); latar hapus → `bad.container`/`bad.content` (selaras Validasi, dijaga test warna).
- **Sheet filter status**: bug tutup-sheet me-reset filter diam-diam ("Semua" dan batal keduanya `null`) → marker `_kAllStatusFilter`; batal mempertahankan filter aktif.
- **Detail**: snackbar salin "Simpan" (salah — tidak ada yang disimpan) → "Teks disalin." + tooltip "Salin teks"; validatedBy "ID pengguna: uid" (label mentah) → "Divalidasi oleh uid · waktu"; tombol Cocok/Tidak cocok selaras Validasi (`ok.solid` filled / `bad.solid` outlined, dijaga test warna).
- **Import mati dibersihkan**: `ThumbnailTile`/`go_router` (list), `StatusPill` tetap dipakai list (tone enum) — detail masih memakai `status_pill.dart` untuk enum (R2 merapikan bila perlu).
- **Test**: `history_screen_test.dart` (5: tanpa perangkat, subjudul, filter kosong + reset, ikon kategori + chip, warna hapus bad) + `history_detail_test.dart` (5 + 1 unit: label + chip + Urungkan, pasangan ok/bad, validatedBy, snackbar salin, undo via alur daftar→detail→kembali + status pending, format rupiah). Pelajaran: router test satu-route crash saat `pop` (`!_debugLocked`) — alur test wajib mulai dari halaman dummy lalu push.
- **Golden**: `history_tab_light.png` di-regenerate + diinspeksi (baris ikon kategori + titik status + chip campur + chevron).
- **Docs**: `docs/ui_spec.md` §5.3 diselaraskan (subjudul jujur, empty 3 kasus, baris, hapus konfirmasi-dulu tanpa undo, detail, sheet marker).
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **195 lulus**.

## 2026-10-15 P1 — Poles tab Validasi: empty state jujur, petunjuk geser ber-warna status, tumpukan kartu nyata

Audit UI/UX per halaman dimulai (pola baru: 1 halaman selesai → lanjut halaman berikutnya). Halaman pertama: **Validasi**.

- **Bug empty-state**: filter "Uang"/"Menu/Teks" yang kosong dulu menampilkan "Semua pembacaan sudah diperiksa" padahal kategori lain masih menunggu — dan sebelum perangkat terhubung pun sama. Sekarang tiga kasus terpisah dengan aksi masing-masing: belum ada perangkat → "Buka Perangkat"; antrean habis → "Buka Riwayat"; filter kosong → "Tidak ada antrean di filter ini" + "{count} pembacaan menunggu di kategori lain" + "Tampilkan semua" (reset filter). String baru di `app_id.arb` + regenerasi l10n.
- **Petunjuk geser ber-warna status**: latar petunjuk kini tinted radius kartu — kiri `bad.container`/`bad.content` ("Tidak cocok"), kanan `ok.container`/`ok.content` ("Cocok"); sebelumnya ikon+teks `primary` polos tanpa latar. `Dismissible` dipindah agar **hanya tumpukan kartu** yang bergeser — tombol aksi dan kerangka layar tetap diam (sebelumnya seluruh kolom ikut terseret).
- **Tombol keputusan selaras ui_spec §5.2**: "Cocok" filled `ok.solid` (teks `surface`), "Tidak cocok" outlined `bad.solid`; implementasi lama memakai primary/`colorScheme.error` (menyimpang dari spec) — kini dijaga unit test warna.
- **Tumpukan kartu benar-benar terlihat**: kartu bayangan lama sepenuhnya tertutup kartu opak (efek "dua kartu samar" tak pernah tampak). Sekarang terdorong 12 px + inset 12 px per lapis, ruang peek disediakan via padding kartu depan, opacity 0,85/0,55 (iterasi 0,35→0,55→0,7→0,85 lewat inspeksi golden), tone `surfaceContainerHigh` + hairline. Pergantian kartu dianimasikan `AnimatedSwitcher` fade + slide 250 ms (key per-deteksi) — sebelumnya kartu berganti patah.
- **Test**: +4 widget test — tanpa perangkat; filter kosong + "Tampilkan semua"; warna tombol `ok.solid`; text scale 1,3× di viewport ponsel 390×844. Golden baru: `validation_tab_light/dark.png` + `validation_swipe_light.png` (mid-drag; drag butuh dua `moveBy` karena gerakan pertama habis untuk touch slop) di `test/features/validation/goldens/` — diinspeksi termasuk zoom 4× tepi tumpukan.
- **Docs**: `docs/ui_spec.md` §5.2 diselaraskan dengan realitas (subjudul progres, empty state 3 kasus, petunjuk geser berwarna, tumpukan + animasi, label maks 4 baris).
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **183 lulus**.

## 2026-10-15 P1-hotfix — Lens Ring: busur progres kontinu ala donut ("timbul keluar")

Follow-up review user (referensi gambar donut 25/50/75/100%): busur akurasi masih terlihat "masuk ke dalam"; minta gaya busur kontinu yang timbul keluar.

- Akar masalah: mode nilai memakai 24 segmen diafragma (celah 18%) dengan ujung membulat — pada diameter 78 (dan ring baterai 56) panjang segmen ≈ 7 px < stroke 10 px sehingga cap tiap segmen saling tumpang-tindih → terbaca seperti rangkaian butiran/lekukan, bukan busur.
- Fix `lens_ring.dart`: mode nilai → track penuh + **busur progres kontinu di atasnya** (ujung membulat, mulai pukul 12 searah jarum); 100% digambar sebagai lingkaran penuh (menghindari tonjolan di titik sambung 360°). Mode menunggu alat (login/provisioning) tetap 24 segmen diafragma + denyut fokus — rendering fokus tidak berubah (golden login byte-identical). Penanda "tidak tersedia" (4 mata angin) tetap.
- Golden di-regenerate + diinspeksi termasuk crop zoom 5–6x: home light/dark, device light/dark. Ring baterai tab Perangkat ikut kontinu (satu widget bersama).
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **176 lulus**.

## 2026-10-15 P1-hotfix — Poles Beranda pasca-review UI (ring akurasi, tinggi bento, tonal)

Review user atas screenshot Beranda. Tiga temuan; arah perbaikan (ring "perjelas + perbesar", kartu "naik 1 tonal") dipilih user eksplisit.

- Ring akurasi ("kayak masuk ke dalam"): analisis pixel screenshot membuktikan geometri ring BENAR (track & progres selebar/radius sama) — penyebabnya persepsi: track `surfaceContainerHighest` nyaris menyatu dengan kartu sehingga sisa 25% terbaca "lekukan". Fix: track default `LensRing` → `outlineVariant` (kontras terang ≈1,15:1 → ≈1,45:1; di gelap juga lebih terlihat), diameter tile 64 → **78**, angka tengah `titleMedium` → `titleLarge`. Ring baterai (tab Perangkat) & ring fokus (login) ikut lebih jelas — satu widget bersama, disengaja.
- Kotak "Sinkron terakhir" vs "Hari ini" beda tinggi: baris kedua bento TIDAK memakai `IntrinsicHeight` + `stretch` (baris pertama sudah), padahal "Hari ini" punya footer → selisih ±20 px. Fix: pola yang sama dengan baris pertama.
- Latar "polos putih": tile bento `surfaceContainerLow` (#F6F2FA) nyaris sama dengan halaman (#F6F6FB). Fix: tone tile → `surfaceContainer` (#F0ECF4; gelap #1F1F25) + bubble ikon `surfaceContainerHighest` agar tetap 2 tingkat. Halaman & Hero tidak diubah (identitas M3 kartu tonal tanpa shadow).
- Test baru: regresi "kedua tile sama tinggi" (bandingkan `tester.getSize` via `BentoTile`) + "tetap muat pada text scale 1,3x" (overflow = exception). Golden Beranda **gelap** ditambahkan (sebelumnya hanya terang).
- Golden di-regenerate + PNG diinspeksi: home light/dark, device light/dark, login light/dark. Artefak `test/**/failures/` dihapus.
- Docs: `docs/ui_spec.md` §5.1 diselaraskan dengan realitas (Hero = strip 3 stat bukan ring baterai besar, tile "Sinkron terakhir" = `lastSeen` bukan `lastSyncAt`, catatan tone + satu ring besar 78 + aturan tinggi seragam; janji sparkline dihapus — belum ada implementasinya).
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **176 lulus**.

## 2026-10-15 P1-hotfix — Perangkat dummy terlihat setelah login (regresi presentasi)

Laporan user: setelah login (email/Google/daftar baru/tamu) Beranda bilang "Belum ada perangkat" — dummy hilang, presentasi besok terancam. Ternyata regresi dari wiring P1.

- Akar masalah: `currentUserProvider` (`auth_providers.dart`) TIDAK reaktif — dibaca pertama kali oleh root `app.dart` (listener cache nama perangkat) saat belum login → `null` ter-cache selamanya → `rawDevicesProvider` selalu stream kosong, apa pun akunnya. Ditemukan lewat audit rantai provider + probe Riverpod 3.
- Fix inti: `currentUserProvider` kini `ref.watch(authStateProvider)` lalu baca getter repository — nilai ikut berubah saat login/logout, dan tetap benar untuk sesi terpulihkan Firebase (Fase 3).
- Fix simulasi: `FakeDeviceDataSource.watchMyDevices` tidak lagi memfilter UID — perangkat demo terlihat untuk SEMUA akun termasuk tamu; filter keanggotaan asli tetap hanya di jalur Firestore.
- Sampel demo hidup: `FakeDetectionDataSource` → 6 item (2 menunggu, 3 cocok, 1 tidak cocok; akurasi 75% "dari 4 validasi"); item baru `det-money-20k`. Validasi antrean 2 kartu, Riwayat chip campur (kuning/hijau/merah), bento Beranda terisi.
- Test baru: `current_user_provider_test` (login email via rantai root + tamu), `fake_device_repository_test` (uid apa pun + `watchDevice`), `login_device_flow_test` (widget: kosong → login email → perangkat muncul → logout → tamu). Update `validation_screen_test` ("1 dari 2"/"1 dari 1") + `home_screen_test` ("dari 4 validasi").
- Pelajaran Riverpod 3: provider tanpa listener aktif berstatus "pause" — update dependency tidak diproses dan `container.read` bisa mengembalikan nilai cache lama; test reaktivitas WAJIB mengamati lewat listener (seperti konsumen nyata), bukan read lepas.
- Golden: `home_tab_light.png` (ring akurasi 75% + footer) & `history_tab_light.png` (chip campur) di-regenerate + PNG diinspeksi.
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` **174 lulus**. Build tidak diulang (disepakati: user rebuild saat presentasi).

## 2026-10-15 P1 — Satu dunia data (UI → repository) + QR payload legacy

Tujuan: hilangkan dua dunia berdampingan (notifier demo vs Firebase) dan sisa fitur mati. Semua layar sekarang membaca repository yang sama, dipilih SEKALI di `main.dart` (developer mode → simulasi; toggle off + init sukses → Firebase). Simulasi tetap utuh tanpa alat/Firebase.

- Komposisi `main.dart`: `AppRepositories` + `buildRepositories(dataSource, cache)`; simulasi = SATU `FakeDetectionDataSource` dibagi Validasi/Riwayat/Beranda; Firebase = `Firestore*` + `DeviceNameCache`. Override 6 provider repository + cache.
- Provider baru: `latestDetectionsProvider` (family record deviceId+limit), `detectionProvider`, `pendingDetectionsProvider`, `validationSummaryProvider`, `historyPageProvider` (+`HistoryPageKey` tanpa limit, `historyLimitProvider` +25/halaman), `eventsProvider(deviceId?)`, `commandsProvider(deviceId?)`, `sendCommandProvider`, `sharing_providers`, `deviceNameCacheProvider`, `primaryDeviceIdProvider`. Notifier `detectionsProvider` lama DIHAPUS.
- Layar direfaktor penuh (semua `AsyncValue.when` dengan loading/empty/error/data): Validasi (submit/undo nyata + invalidate), Riwayat (paginasi server + Muat lagi, hapus permanen via `ConfirmSheet`, bagikan = ringkasan angka tanpa OCR), Detail Riwayat (realtime + validasi + hapus → pop + snackbar), Beranda (bento `validationSummaryProvider` + aktivitas `latestDetectionsProvider(100)`), Perangkat (timeline event+perintah async + `_TimelineError`), Log koneksi (resolve deviceId), Kontrol (kirim perintah + snackbar gagal), badge Validasi di router.
- QR provisioning: `buildWifiQrPayload` murni (format legacy `WIFI:T:WPA;S:<ssid>;P:<sandi>;;` + escape ZXing `\ ; , : "`; tanpa sandi → tanpa `P:`) dirender `QrImageView` 220 di panel putih; catatan jujur firmware belum memindai QR; komentar layar usang dihapus.
- Riverpod 3.3.2: `.valueOrNull` → `.value` (nullable), `ref.listen` tanpa `fireImmediately`; tipe `Override` tidak diekspor → helper test memakai inferensi tipe.
- Android build (blocker baru, dibereskan): NDK `flutter.ndkVersion` 26 → 27.0.12077973, `minSdk` 21 → 23 (batas `firebase_auth`), Kotlin plugin 2.1.0 → 2.3.0 (metadata firebase-auth 2.3.0) + migrasi `kotlinOptions` → `compilerOptions` DSL (KGP 2.3), `.kotlin/` masuk `android/.gitignore`.
- Test: helper `test/helpers/fake_app_graph.dart` (graf fake bersama + `DemoDeviceRepository` tanpa timer heartbeat) dipakai 6 file widget test; semua ID pindah ke `kDemoDeviceId`; test baru payload QR (5) + smoke render QR (1). **169 test hijau**.
- Verifikasi: `dart format` bersih; `flutter analyze` No issues; `flutter test` 169 lulus; `flutter build apk --debug` sukses (NDK 27 + minSdk 23 + Kotlin 2.3); `flutter build windows --debug` sukses + smoke exe ALIVE 8 detik.

## 2026-10-09 Refactor UI/UX massal — identitas visual v3 "Lensa"

Keputusan owner: teal/hijau `#00897B` diganti total (warna lama = warna app sebelumnya), desain lama tidak diikuti, PRD warna ikut diganti, rename brand **SIGAP-NETRA**, sistem tidak disentuh (murni presentation + theme + l10n + docs + assets). Referensi: `docs/ui_spec.md` v3 (dari Claude). Sistem dikerjakan setelah presentasi.

- Fondasi: seed **Netra Indigo `#4A47D6`** + aksen **Lensa Amber** (`#F5A524`/`#FFC15A` tertiary); `StatusColors` → `ThemeExtension` (ok `#1E9E63`, bad `#D64550`, warn `#E5A00D`, neutral `#6B6F80` + dark shades); radii hero 28/card 20/thumbnail 14/input 14/sheet 28, tombol & chip pil; background `#F6F6FB`/`#0E0F1A`; font **Plus Jakarta Sans** di-bundle (`assets/fonts/`, OFL); dynamic color tetap mati.
- `GradientHeader` dihapus total; diganti `LargeTitleScaffold` (app bar large-title menyusut).
- Widget baru: `LensRing` (CustomPainter diafragma + mode focusing), `StatusDot`/`StatusChip`/`MetricChip`, `BentoTile`/`BentoNumber`/`SectionHeader`, `ThumbnailTile` (3 state eksplisit), `ConfirmSheet`/`ConsentSheet`/`showUndoSnackbar`.
- Layar: Splash lensa + SIGAP-NETRA; Login identitas baru + divider "atau"; Beranda (Hero + bento 2 kolom + 5 aktivitas); Validasi (SegmentedButton + progres + tumpukan kartu + swipe + Urungkan 5 dtk + panel tanpa-gambar); Riwayat (segmen Daftar|Statistik + chip + grup per hari + swipe-hapus + menu ⋯); Perangkat = hub (kepala + Hubungkan + Kontrol + timeline + filter severity); QR stepper 3 langkah (payload tetap shell); Pengaturan via avatar (segmen tema + ConsentSheet + versi konstanta).
- Router: tepat 4 tab M3 standar + badge warn "99+" hanya Validasi; `/pengaturan` top-level.
- Status tone lama (`success/error/warning`) → `ok/bad/warn`; `info` → tertiary. Palet info biru dihapus.
- Docs: `AGENTS.md` §5, `PRD.md`, `docs/ui_spec.md` = v3 (lama diarsip `ui_spec_legacy_teal.md`), judul brand di schema/protocol/rules/indexes/progress → SIGAP-NETRA. Nama package Dart tetap `sigap_netra_app`.
- Test: home test ikut identitas baru + `pumpFrames` melewati tick 15 dtk (hindari `!timersPending`); 93 hijau.
- Verifikasi: `dart format` bersih, `flutter analyze` No issues, `flutter test` 93 lulus, `flutter build windows --debug` sukses (LNK1168 sempat terjadi karena exe lama masih jalan — dimatikan lalu build ulang), smoke-run exe ALIVE 8 detik.

## 2026-10-09 Perbaikan bug presentasi (warna, nama, sampel, Validasi)

Laporan user: (1) teks putih menyatu background, (2) "Kacamata Kamar" + Beranda terlalu turun, (3) sampel campur objek, (4) tab Validasi kosong.

- Bug 1 (warna): Hero Beranda + panel offline ke `onPrimaryContainer` konsisten; Lens Ring baterai pakai `onHero` untuk track/progres/angka; hairline `outlineVariant` di `CardTheme` global + Hero + BentoTile + DeviceHead + ConnectCard + detail + tile event/perintah + OCR card + placeholder statistik. Audit pasangan silang seluruh lib: tidak ada yang tersisa.
- Bug 2 (nama + layout): `kDemoDeviceName` → "Kacamata Cerdas"; semua hardcode demo ke `demo_ids.dart` (monitoring/events/commands providers); test ikut rename. Beranda dirapatkan: padding Hero 8→0, bento 24→12, `SectionHeader.compact`, avatar 56→48, ring 64→56 (konten naik ±60-80px, large-title v3 dipertahankan).
- Bug 3 (sampel): 5 sampel realistis uang + teks OCR (100rb/50rb/struk minimarket/10rb/PINTU KELUAR); komentar larangan menambah jenis selain uang/teks di dua `_sample()`; test baru assert dua jenis saja.
- Bug 4 (Validasi crash layout, bukan data): `Expanded` dalam sliver tak terbatas → `LargeTitleScaffold.fillRemaining` (`SliverFillRemaining`); layar lain aman (audit: hanya Validasi). Regression test: render kartu + filter + Cocok/snackbar + Urungkan (+ auth stub).
- Verifikasi: `dart format` bersih, `flutter analyze` No issues, `flutter test` 98 lulus, build Windows sukses + exe ALIVE.
- Catatan test: `FilledButton.icon`/`SegmentedButton` merender tipe internal (`_FilledButtonWithIcon`/`_SegmentedButton`) — finder test wajib lewat teks, bukan tipe tombol.

## 2026-10-11 Label display tunggal + sampel menu utuh

Koreksi user: (1) label uang ganda "100000 nominal 100.000" (dua fungsi padahal satu), (2) "nasi goreng" ambigu, (3) minta saran tambahan — approved semua.

- `displayLabel` uang: `Rp 100000 - Nominal 100.000` → `Rp 100.000` saja (via `NumberFormatId.rupiah`; label sampel redundan dibuang dari 3 sampel uang di kedua sumber). Field `label` tetap ada (kontrak Firestore) tapi tak lagi diisi redundan.
- `displayLabel` teks: newline → `·` (baris ringkas satu baris; teks penuh multiline tetap via `ocrText` di detail — detail tidak diubah karena sudah benar).
- Sampel menu: `NASI GORENG\nRp15.000` → `AYAM GORENG — Rp15.000` (satu item utuh).
- Test baru `detection_label_test.dart` (9 test: format titik, tanpa ganda, strip, normalisasi, potong 80, null). Test sharing tak terpengaruh (data sendiri).
- Verifikasi: format bersih, analyze No issues, test **158 lulus**, golden home + riwayat di-regenerate (teks berubah, PNG diinspeksi), build Windows sukses + smoke ALIVE.

## 2026-10-11 Refactor kasat mata Beranda (hero berlapis, bento berikon, aktivitas kartu)

Koreksi user: H1–H5 terlalu kecil secara visual ("kayak ga berubah"). Investigasi membuktikan kode berubah + ter-commit, dan jalur run user benar (launch.json → main simulation → fake data utuh) — masalahnya kalibrasi batch terlalu timid. Refactor ini menyentuh yang kasat mata.

- Hero berlapis: ring baterai besar DIHAPUS dari Hero (satu-satunya ring besar kini di tab Perangkat — tidak ada dua signature bersaing); diganti strip 3 stat (status + baterai % + jam sinkron, divider hairline); tombol dua kolom → bertingkat full-width (primer label penuh + sekunder), target 48, tanpa wrap/ellipsis.
- Bento: slot `icon` baru (lingkaran tonal + label): Menunggu (warn), Akurasi (ok), Sinkron (default), Hari ini (default). Mini-bars DITOLAK sadar: tanpa data historis = memalsukan data (AI slop).
- Aktivitas: thumb 48 rounded + StatusDot menempel + label SemiBold + chevron (terbaca sebagai kartu mini, bukan daftar pengaturan).
- Test: golden home di-regenerate + PNG diinspeksi; assertion strip/bento/aktivitas baru; test lama label pendek dihapus. Pelajaran: test online wajib lastSeen segar (konektivitas dihitung ulang vs jam nyata); baca nomor baris error dengan teliti (textContaining vs golden mismatch).
- Verifikasi: format bersih, analyze No issues, test **152 lulus**, `flutter clean` + build Windows dari nol sukses + smoke ALIVE (exe 22:30 dijamin versi HEAD).

## 2026-10-11 H3/H5/H4 Beranda: sinyal, tombol offline, empty, subjudul

- H3: `StatusDot` avatar dibungkus `ExcludeSemantics` (chip berlabel tetap sumber aksesibilitas). Duplikasi lastSeen (relatif chip vs absolut tile) DIPERTAHANKAN sadar: komplementer (hitungan presisi + jam presisi), bukan duplikat murni — tidak ada `lastSyncAt` di domain, menambahnya = perubahan skema (di luar batch).
- H5: tombol Hero bertukar hierarki saat offline (QR `filled` utama, Sinkron `tonal`); empty aktivitas CTA ke Perangkat ("Hubungkan") — bukan Validasi yang juga kosong; empty Perangkat tanpa tombol "Tambah" (tidak ada alur klaim di app; tombol lama mengarah ke Validasi — salah); subjudul Beranda = nama perangkat primer (pola Perangkat); kunci `homeEmptyActivityAction` tak terpakai dihapus.
- H4: riset membuktikan tick 15-detik SUDAH ada (`myDevicesProvider` + `tickProvider`) — waktu relatif ikut rebuild, tidak basi; thumbnail media BELUM ada pipeline sama sekali di app (Riwayat pun placeholder) → pipeline media = fitur P2, bukan poles; param `singleDevice` mati dihapus.
- Test: subjudul ganda, warna QR online (secondaryContainer) vs offline (primary) via Material button aktual, golden regen. Pelajaran: `FilledButton.icon` merender tipe internal (byType gagal → predicate `is`); style widget null (dari tema) → baca Material; `find.ancestor` bisa kembar (saring `MaterialType.button`); konektivitas dihitung ulang dari lastSeen vs jam nyata — test online wajib lastSeen segar.
- Verifikasi: format bersih, analyze No issues, test **152 lulus**, build Windows sukses + smoke ALIVE (build diulang per batch).

## 2026-10-11 H2 Sampel demo jujur kapabilitas alat

Koreksi user: "Minimarket Segar" (struk belanja) dan "Pintu Keluar" (rambu jalan) menyiratkan OCR bebas sembarang teks — padahal alat hanya membaca (1) pecahan uang, (2) teks pada posisi baca normal yang dihadapkan ke kamera.

- `det-text-struk` → `det-text-menu` ("NASI GORENG / Rp15.000", label menu dihadapkan ke kamera); `det-text-rambu` → `det-text-sampul` ("PANDUAN / BELAJAR BRAILLE", sampul dihadapkan ke kamera). Di kedua sumber sampel (`monitoring_providers.dart` + `fake_detection_data_source.dart`) agar sinkron.
- Komentar batas kapabilitas di kedua `_sample()`: bukan OCR bebas — jangan contohkan rambu/reklame/dokumen tak dihadapkan.
- Test baru: sampel teks tidak mengandung kata terlarang (PINTU KELUAR/MINIMARKET/RAMBU/REKLAME).
- Verifikasi: format bersih, analyze No issues, test **149 lulus**, golden yang memuat teks demo di-regenerate, build Windows sukses + smoke ALIVE.

## 2026-10-11 H1 Beranda: ritme seksi + hierarki cincin + kontras null

Penilaian audit: Beranda benar secara komponen tapi ritme pincang (8-24-12-12-12-24), ring akurasi 72 mendominasi baterai 56, dan state-null nyaris hilang di Hero (track 0.25×0.55 ≈ 0.14).

- Header Aktivitas `compact` → non-compact (top 24, sama dengan Perangkat): ritme 8-24-24-…-24.
- Ring akurasi 72→64: metrik sekunder tidak mendominasi ring baterai 56.
- Track hero 0.25→0.40: state-null (≈0.22) tetap terbaca di atas `primaryContainer`, light + dark.
- Test: assertion hierarki (semua ring ≤ 64, ada 64); golden home di-regenerate + PNG diinspeksi. Pelajaran: variabel `rings` ganda di scope test; `find.textContaining` gagal biasanya golden mismatch di baris berikut — baca nomor baris.
- Verifikasi: format bersih, analyze No issues, test **148 lulus** (tetap), build Windows sukses + smoke ALIVE.

## 2026-10-10 Refactor Beranda: hero seimbang, bento informatif, aktivitas bernilai

Permintaan user: Beranda polos/AI-slop — refactor seprofesional mungkin (proporsi, ritme, nilai tiap widget).

- H1 Hero seimbang: avatar 48→56 (token), StatusDot 14→12, ring 64→56 + caption "Baterai" dihapus total (ring + angka saja; label aksesibilitas dari LensRing internal, tanpa Semantics ganda yang menggabungkan label); InkWell dalam radius 28. Baris info kini 56 vs 56.
- H2 Bento: `IntrinsicHeight` + stretch (dua tile atas selalu sama tinggi); ring akurasi 56→72 + footer mikro ("dari N validasi" / "Belum ada validasi"); tile Sinkron jadi jam absolut `RelativeTime.timeAndDate` ("14.32 · 10 Okt" — duplikasi relatif dengan chip Hero hilang); tile Hari ini + footer breakdown ("3 uang · 2 teks", dihitung lokal); `BentoTile.footer` slot baru (labelSmall 1 baris).
- H3 Aktivitas: sumber 5 terbaru semua status (bukan pending saja); chip `#N` → chip status validasi (Cocok/Tidak/…); ikon kategori uang/teks ganti ikon generik; subjudul `conf · waktu` (nama perangkat disembunyikan bila 1 perangkat); tap → detail pembacaan (push); empty khusus Beranda (ikon + teks + tombol ke Validasi) ganti copy Validasi.
- H4 Ritme: Hero top 0→8, Bento top 12→24 (ritme 8-24-12-24); angka mentah ke token.
- l10n baru 6 kunci (regen via `flutter build bundle` — gen-l10n/analyze tidak regen).
- Test: update golden home+device (ring 56, tanpa caption) + PNG diinspeksi; assertion baru (jam absolut, breakdown, footer, chip status); grup BatteryRing di lens_ring_test (tanpa caption + semantik null). Pelajaran: `find.textContaining` gagal bukan karena teks hilang melainkan golden mismatch di baris berikutnya — baca nomor baris dengan teliti; Semantics bersarang menggabungkan label (jangan bungkus ganda).
- Verifikasi: format bersih, analyze No issues, test **148 lulus**, build Windows sukses + smoke ALIVE.

## 2026-10-10 Logo Google resmi sebagai aset

Laporan user: ikon tombol Google (`g_mobiledata`) bukan logo Google; logo resmi disediakan di `assets/foto/` (nama folder kurang profesional).

- Verifikasi biner: PNG 3840x3840 dengan alpha 0 di keempat sudut = transparan penuh, langsung layak pakai tanpa edit.
- Rename: `assets/foto/` → `assets/images/`, `Google_G_logo.svg.png` → `google_g_logo.png` (snake_case). Struktur kini `assets/{fonts,images}/` yang konvensional.
- Pubspec: daftarkan `assets/images/google_g_logo.png` (sebelumnya tidak ada section `assets` sama sekali — hanya fonts).
- Konstanta baru `kGoogleLogoAsset` di `app_constants.dart` (+ komentar larangan memakai `g_mobiledata` sebagai logo).
- Tombol Google memakai `Image.asset` 20dp + `cacheWidth/cacheHeight 80` (sumber 3840px tidak dimuat penuh) + `semanticLabel` l10n untuk screen reader.
- Test: logo aset tampil tepat 1x, `g_mobiledata` hilang total. Pelajaran test: `OutlinedButton.icon` merender tipe internal (temuan lama yang sama seperti `FilledButton.icon`) dan `cacheWidth` membungkus provider dalam `ResizeImage` — predicate harus mengupas `ResizeImage.imageProvider`.
- Verifikasi: format bersih, analyze No issues, test **144 lulus** (tetap), build Windows sukses + smoke ALIVE.

## 2026-10-10 Login profesional: daftar + tamu + hero

Laporan user: halaman login terlalu polos; Google langsung masuk tanpa pilih akun; minta alur profesional (tamu bebas, daftar bagi yang belum punya akun) mengikuti referensi tanpa meniru 100% dan tanpa Apple.

- Layar baru: `LoginHero` (LensRing focusing 88 + SIGAP-NETRA + kartu 3 poin nilai), judul "Selamat datang kembali", `AuthTextField` (label di atas field pil + toggle intip sandi + error inline), tombol Masuk penuh, `OrDivider`, tombol Google outlined, "Lanjutkan sebagai tamu", link "Belum punya akun? Daftar", footer privasi. `login_form.dart` lama dihapus.
- Sheet daftar (`SignUpSheet`, bottom sheet radiusSheet): Nama opsional + Email + Kata sandi + Konfirmasi; validasi berlapis (field + use case); error Firebase tampil di dalam sheet.
- Domain: `AuthRepository` + `signUpWithEmail`/`signInAnonymously`; use case `SignUpWithEmail` (email valid + min 6 + konfirmasi cocok) dan `SignInAnonymously`; `isValidEmail` bersama; `SignInWithEmail` kini menolak format salah dengan kunci l10n.
- Data: `FirebaseAuthDataSource` + create user (isi displayName) / signInAnonymously; `AuthRepositoryImpl` + fake mengikuti (tamu = `guest-demo` tanpa email). PERLU: aktifkan provider Anonymous di Firebase console.
- Header akun Pengaturan: identitas utama = displayName → email tersamar → UID (tamu).
- l10n baru ±20 kunci (ID). Regen via `flutter build bundle` (catatan: `flutter gen-l10n` menolak karena l10n.yaml; regen otomatis test/analyze tidak selalu jalan).
- Test: use case (email/daftar/tamu, 16 lulus di file domain), widget login (hero, validasi, sheet buka/tolak/berhasil, tamu) + golden light/dark baru (PNG diinspeksi). Stub auth di test validasi ditambah 2 method.
- Verifikasi: format bersih, analyze No issues, test **144 lulus**, build Windows sukses + smoke ALIVE.

## 2026-10-10 UI/UX menyeluruh: pintu Pengaturan tunggal + poles 4 tab

Laporan user: (1) kartu Akun & Pengaturan muncul di 3 tab (ramai), (2) lanjutkan peningkatan UI/UX per halaman secara profesional.

- Batch A (Pengaturan tunggal): widget bersama baru `core/widgets/settings_gear_button.dart` (ikon gear → `SettingsPath().push()`); gear dipasang di app bar 4 tab (Beranda, Validasi, Riwayat, Perangkat); `AccountSettingsCard` dihapus dari 3 tab + file dihapus (tidak ada test yang memakainya); seksi Akun di Pengaturan dilebur menjadi `_AccountHeader` (avatar inisial 24 + email tersamar + Keluar, tanpa judul seksi ganda); `_SectionTitle(isFirst)` menghapus dobel 32px; subtitle mode pengembang tidak lagi paksa 3 baris (`'\n'` → `' · '`).
- Batch B (Beranda + Perangkat): Hero bisa di-tap → detail (InkWell + chevron, konsisten dengan kepala Perangkat); `StatusChip` teks dibungkus `Flexible` + ellipsis (label panjang tidak dorong layout 360dp); `_SmallValue` bento maxLines 1 (dua tile sejajar); `Divider` aktivitas pakai token + endIndent; widget bersama baru `core/widgets/filter_chip_row.dart` (`FilterChipRow<T>` generik) dipakai di Perangkat + Log koneksi (opsi Info yang hilang kini ada di Log); literal off-grid → token (`SizedBox 2` → spaceXs, `EdgeInsets.all(6)` → spaceSm, konektor 20 → spacePage).
- Batch C (Validasi + Riwayat): token tipografi baru (`displayLabelSize 24`, `displayLabelMaxLines 4`, `letterSpacingLabel/Brand`); ukuran label bacaan disamakan 24 di Validasi (26) + Detail riwayat + maxLines 4; letterSpacing splash/login/detail via token; baris meta Riwayat full l10n (`historyConfidenceValue`, `historyDistanceValue` baru — regen otomatis via analyze).
- Ditunda sadar: `OfflineBanner` tidak dipasang (butuh sinyal `isFromCache` nyata; simulasi tidak punya); `StatusPill` tidak dihapus (hanya `StatusPillData`/enum yang dipakai — hapus file = rename lintas 10 file, risiko > manfaat); `DeviceCard` mati + layar yatim lain dicatat untuk batch hapus kode mati.
- Test: gear di 4 tab + kartu hilang + header akun (`navigation_back_test.dart`, 13 lulus di file itu); golden 3 tab di-regenerate + PNG diinspeksi.
- Verifikasi: format bersih, analyze No issues, test **127 lulus**, golden Riwayat berubah sesuai ekspektasi (1.52% — teks meta baru), build Windows sukses + smoke ALIVE.

## 2026-10-10 P0 navigasi kembali + chip dempet + detail yatim

Laporan user: (1) chip severity Perangkat (Semua/Info/Peringatan/Gangguan) terlalu dempet, (2) QR Wi-Fi & Pengaturan tanpa tombol back (terjebak), (3) Pengaturan di 3 tab terlalu ramai, plus audit menyeluruh.

- Navigasi (kritis): semua helper memakai `.go()` (replace, stack hilang) → AppBar polos tanpa `leading` → back = keluar aplikasi; Log koneksi dari Perangkat paling parah (bottom-nav hilang + terjebak). Perbaikan: widget bersama baru `core/widgets/back_app_bar.dart` (`BackAppBar`: `BackButton` eksplisit + guard `canPop()` → fallback route induk bila deep-link); method `push()` ditambahkan ke `DeviceWifiPath/DeviceCommandsPath/ConnectionLogsPath/DeviceDetailPath/SettingsPath` (+ helper baru `HistoryDetailPath`); 8 pemanggil layar anak `.go()` → `.push()` (Beranda→QR, Beranda→Perintah, Perangkat→QR/Kontrol/Log, Commands→QR, kartu akun→Pengaturan); `BackAppBar` dipasang di 6 layar (wifi, perintah, log, pengaturan, detail, detail riwayat) dengan fallback `/perangkat` (Pengaturan → `/beranda`, detail riwayat → `/riwayat`).
- Chip dempet (konkret): 3 Wrap filter tanpa `runSpacing` (baris 2 jarak 0) → tambah `runSpacing: spaceSm` di Perangkat, Log koneksi, Riwayat.
- Detail yatim: `DeviceDetailScreen` + `DeviceDetailPath` terdaftar tapi tidak terjangkau UI → `_DeviceHead` kini `Material+InkWell` (tap → detail via push) + chevron; chip aksi detail juga diganti ke path helper + ikon `hub_outlined` (sebelumnya label Event/Koneksi pakai ikon `sync_alt` — salah makna).
- Test: `test/core/navigation_back_test.dart` (7 test: BackButton di 4 layar anak, runSpacing 2 Wrap filter, chevron/tap detail). `shared_preferences` sudah di dependencies (dipakai langsung untuk mock, tanpa tambah package).
- Verifikasi: format bersih, analyze No issues, test **121 lulus**, golden Perangkat di-regenerate (struktur InkWell + chevron), build Windows sukses + smoke ALIVE (LNK1168 sempat terjadi karena exe lama masih jalan — dimatikan lalu build ulang).

## 2026-10-09 Fix warna chip + unifikasi ring baterai (Beranda ↔ Perangkat)

Laporan user: (1) warna font putih menyatu background di tab **Perangkat & Riwayat**, (2) ring baterai Beranda berbeda dengan ring di tab Perangkat.

- Akar masalah warna chip ketemu lewat audit runtime: label chip tidak pernah punya `Text.style.color` (selalu `null`) karena warnanya diwariskan lewat `DefaultTextStyle` internal chip. Tanpa `chipTheme.labelStyle` eksplisit, warna itu jatuh ke warisan sekitar → tampak putih di kartu terang. Perbaikan permanen di `app_theme.dart`: `chipTheme` eksplisit (background `surfaceContainerLow`, selected `secondaryContainer`, `labelStyle` dengan `WidgetStateColor.resolveWith` → disabled `onSurface` .38 / selected `onSecondaryContainer` / default `onSurfaceVariant`; `iconTheme` eksplisit). Terbukti: warna efektif sekarang `rgb(71,70,79)` (default) dan `rgb(26,26,44)` (selected) — gelap.
- Ring baterai: widget bersama baru `core/widgets/battery_ring.dart` (`BatteryRing({batteryPct, diameter=64, numberColor, trackColor})`) memakai `LensRing.battery` + label "Baterai". Hero Beranda (`_BatteryRing`) dan DeviceHead Perangkat keduanya memakai widget yang sama, diameter sama 64; satu-satunya beda yang sah = warna angka menyesuaikan konteks Hero `primaryContainer` (`onPrimaryContainer`).
- Bukti visual (bukan tebakan): golden test baru untuk 3 tab — `test/features/{devices,history,home}/.../*_tab_golden_test.dart` + PNG di `*/goldens/`. File PNG diinspeksi manual.
- Regression test: teks chip wajib luminance < 0.5 (baca warna efektif = `Text.style?.color ?? DefaultTextStyle.of(element).style.color`, resolve `WidgetStateColor`); `BatteryRing` wajib diameter 64 + `batteryPct` sama; angka Hero = `onPrimaryContainer`.
- Audit menyeluruh 3 tab (Beranda/Perangkat/Riwayat) terhadap semua `Text` tampak: satu-satunya teks terang = label tombol bermaterial indigo (`FilledButton` putih di atas indigo) — benar, bukan bug.
- Verifikasi: format bersih, `flutter analyze` No issues, `flutter test` **114 lulus** (dari 105), `flutter build windows --debug` sukses + exe ALIVE.
- Catatan teknis: `matchesGoldenFile()` resolusi path relatif **file test** (`../goldens/...`), sedangkan `Directory()/File()` relatif **cwd** — beda; `expect()` tidak mempromosi `Color?` jadi non-null (perlu `!`).

## 2026-10-09 Polish presentasi (header rapat, kartu akun, baterai, warna)

Laporan user + screenshot: (1) header terdorong ke bawah di semua tab, (2) avatar "D" menggantung, (3) ring baterai terlihat rusak, (4) teks putih tab Perangkat, plus tombol "Sinkronkan sekarang" wrap dua baris.

- App bar rapat: `LargeTitleScaffold` default `SliverAppBar` biasa ±64 (judul 20/SemiBold); varian `.large` dipertahankan. Konten naik ±90px di 4 tab.
- Avatar app bar dihapus total (param `avatar` dihapus dari scaffold; class `_SettingsAvatar` mati dihapus di 3 layar). Pengganti: `AccountSettingsCard` bersama (inisial + email tersamar + tombol Pengaturan) di Beranda, Riwayat, Perangkat. `maskEmail` dipindah ke `core/utils/mask_email.dart` (hapus duplikat settings).
- Baterai: `LensRing.battery` factory (warna adaptif ok≥30/warn≥15/bad dari `StatusColors` tema via `BatteryAdaptiveLevel`; null → 4 segmen mata angin + ikon, bukan cincin abu penuh); Hero + DeviceHead pakai factory; demo `batteryPct: 82` (jelas demo).
- Tombol Hero: label `homeSyncShort` "Sinkronkan" satu baris (test mengunci).
- `_NoDeviceState` teks ke `onPrimaryContainer` + hairline.
- Bug laten ditemukan test: `LensRing._controller` lazy → crash "deactivated ancestor" saat dispose; diperbaiki ke initState.
- Audit warna: login, history swipe, validasi, settings, QR, detail, koneksi, semua widget bersama — semua pasangan container/on-container konsisten; tidak ada yang diubah selain yang di atas.
- Verifikasi: format bersih, analyze No issues, test 105 lulus, build Windows sukses + exe ALIVE.
- Catatan: factory tidak bisa `const` di test; `BatteryAdaptiveLevel` enum publik sebagai penanda internal factory.
- Catatan: `package_info_plus` belum dipakai (perlu persetujuan package); versi Tentang via `kAppVersionDisplay` sinkron manual dengan pubspec.

Tanggal: 2026-10-08

## Ringkasan saat ini

Fondasi aplikasi Flutter sudah dibuat dari nol dengan Clean Architecture berbasis fitur, Riverpod, go_router, localization Indonesia, dan mode pengembang/simulasi. `PRD.md` berisi draft ulang karena file asli rusak; `PRD_old.txt` disimpan. Dokumen sumber di `docs/` sudah dibuat: `docs/firestore_schema.md`, `docs/ui_spec.md`, dan `docs/device_protocol.md`.

Fitur yang sudah memiliki implementasi dasar:

- `auth`: entity `AppUser`, `AuthState`, repository interface, use cases, Firebase/fake data source, repository implementation, providers, dan layar login.
- `devices`: entity `Device`, `DeviceSettings`, `DeviceConnectivity`, pure `deriveConnectivity`, kontrak `DeviceRepository`, `DeviceDataSource`, Firestore/fake data source, repository implementation, providers, card widget, dan konektivitas display widget.
- `settings`: entity `DataSource` dan provider `DeveloperModeController`.
- `home`: layar Beranda dengan gradient header, ringkasan validasi/perangkat, kartu perangkat, empty/error/loading states.
- Core: theme Material 3, status colors, error models/mappers, constants, router/redirect skeleton, widgets bersama, retry policy.

Verifikasi terakhir:

- `dart format .`: selesai.
- `flutter analyze`: `No issues found!`.
- `flutter test`: `All tests passed!`.

Catatan kompatibilitas package:

- `fake_cloud_firestore` **dihapus dari `pubspec.yaml`** untuk sementara karena versi yang sesuai tidak dapat dikompilasi dengan kombinasi `cloud_firestore 6.10.0`, `firebase_core 4.15.0`, dan `flutter_riverpod/flutter SDK`. `fake_cloud_firestore >= 4.2.0` mengharuskan `meta ^1.17.0`, sedangkan Flutter SDK saat ini membatasi `meta 1.16.0`.
- Pengujian repository devices sekarang memakai `DeviceDataSource` abstraction dan `_ControlledDeviceDataSource`; mapping dokumen Firestore tetap dites langsung lewat `DeviceModel.fromData` tanpa `fake_cloud_firestore`.

## Yang masih pending

- `PRD.md` versi final dari owner produk.
- `firebase_options.dart`, project Firebase, dan credentials — belum disediakan.
- `firebase/firestore.rules` dan `firebase/firestore.indexes.json` belum dibuat karena beberapa kontrak keamanan device masih berstatus `[PERLU KONFIRMASI]` di `docs/firestore_schema.md`.
- Fitur lengkap `validation`, `history`, `events`, `commands`, `provisioning`, `sharing`, `monitoring` belum diimplementasikan penuh.
- Format payload QR Wi-Fi final harus diekstrak dari firmware/aplikasi Kotlin lama sebelum implementasi `BuildWifiQrPayload`.
- Kebijakan keamanan rules: siapa yang menulis `members`, `authUid` device, dan allow-list field payload command masih perlu keputusan owner.

## Kriteria lanjut

- `flutter analyze` lulus.
- `flutter test` lulus.
- Semua provider yang perlu menampilkan error memakai retry policy eksplisit.
- Semua data source produksi/simulasi mengikuti kontrak `DeviceDataSource`/feature skeleton yang sama.
- Setiap fitur baru mengikuti Clean Architecture: domain murni, data layer sebagai satu-satunya akses Firestore, presentation memakai providers dan 4 state UI.

## 2026-10-08 Windows run note

- `flutter build windows --debug` lulus.
- `flutter run -d windows --no-hot --no-version-check` berjalan sampai Dart VM Service naik.
- `.vscode/launch.json` ditambahkan agar VS Code memakai program/device/mode yang benar saat Run/Run Without Debugging.

### Perbaikan root cause splash macet

- Gejala: aplikasi berhenti di splash / Run Without Debugging tidak pernah sampai UI.
- Penyebab: nilai lama `developer_mode = false` di SharedPreferences membuat `resolveDataSource()` memilih `DataSource.firebase`, sehingga data source Firebase dibuat sebelum `Firebase.initializeApp()` → crash/hang diam-diam.
- Perbaikan: `lib/main.dart` — `resolveDataSource()` selalu mengembalikan `DataSource.simulation` sampai Firebase dikonfigurasi; komentar `firebase_core` dihapus dari `main.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 42 lulus, exe hasil `flutter build windows --debug` dijalankan langsung dan tetap hidup setelah 8 detik (lalu dihentikan manual).
- Log debug `windows-run-no-debug.log` sudah dihapus, tidak perlu di-commit.

### Audit l10n/privasi/arsitektur (batch ini)

- `AppFailure` dilepas dari Flutter/l10n; pesan error lewat `lib/core/widgets/failure_message.dart`.
- `placeholder_screen.dart` dihapus; semua route memakai layar nyata.
- Validasi memakai UID (`currentUserProvider?.uid`), command dibuat `CommandStatus.pending` dengan `requestedBy` UID, data demo memakai id simulasi.
- Skeleton domain baru untuk `validation`, `history`, `events`, `commands`, `provisioning` (kontrak, implementasi menyusul setelah keputusan owner).
- `maskEmail()` di Pengaturan; kunci l10n baru (`settingsSignedOutAsGuest`, `settingsAppliesAfterRestart`, `settingsDeviceUploadsReadOnly`, `deviceLocalActive/Inactive`, `validationConfidenceValue`, `historyRecognitionResult`, `historyEmptyTitle/Body`).

## 2026-10-09 Fase A — data layer (domain + data + rules)

Data layer lengkap untuk 8 fitur mengikuti pola `devices` (domain murni →
data source firebase+fake → repository impl → test tanpa `fake_cloud_firestore`):

- Fondasi: `lib/core/constants/demo_ids.dart` (`kDemoDeviceId`, `kDemoDeviceName`, `kDemoUserId`) dipakai semua fake — tidak ada lagi drift ID simulasi.
- `devices`: entity +`batteryPct` (null aman, UI wajib "-")/`members`/`createdAt`/`updatedAt`; model `_readBatteryPct` (clamp 0-100) + `_readMembers` defensif; `watchMyDevices({uid})` + filter `members.<uid>` di Firestore dan fake; provider signed-out → list kosong (bukan error).
- `monitoring`: `Detection` +`thumbnailId`/`processingMs`/`seq`; `DetectionFields` + `DetectionModel` (clamp confidence, potong OCR 500, `validationUpdate()` hanya 3 field + server timestamp); kontrak + firebase + fake + impl + `WatchLatestDetections`.
- `validation`: `ValidationSummary` (akurasi null bila kosong); kontrak per-`deviceId`; Firestore (pending query + 3x `count()`, `update()` 3 field); fake berbagi `FakeDetectionDataSource`; undo/reset menyimpan jejak (tidak di-null-kan, skema 4.2); `GetValidationSummary` ganti `GetAccuracy`.
- `history`: `DetectionPageCursor`/`DetectionPage` bebas Firestore (kursor `createdAt`+`id` → `startAfter([Timestamp])`); query filter per indeks skema §8; `limit+1` probe; delete batch deteksi+media; reset batch 100/halaman.
- `events`: `DeviceEventFields` + model (`type` mentah, daftar final `[PERLU KONFIRMASI]`); stream tanpa composite; halaman filter pakai composite `severity`+`createdAt` (indeks §8 #7).
- `commands`: entity +`payload` (unmodifiable)/`updatedAt`; `DeviceCommand.buildPayload()` murni (validasi `speak_text`/`set_volume`, tolak kosong/invalid); model `createDocument()` selalu `pending` + server timestamp; Firestore hanya `add()`; fake meniru `pending`→`acked`→`done`; `WatchCommand` singular; `sendCommand` kembalikan ID.
- `settings`: `AppPreferences` (`themeMode`, `uploadThumbnailsConsented`); kontrak + SharedPreferences impl (tanpa tulis Firestore — `settings.*` ditulis device, skema §5).
- `sharing`: `ShareReport` (tanpa ID/lokasi/email/gambar); `buildShareText()` murni; `buildShareReport()` potong OCR 500 + consent.
- `provisioning`: tetap shell — payload tidak ditebak (menunggu aplikasi Kotlin lama).
- Firebase: `firebase/firestore.rules` (deny-by-default; tulis device DITOLAK SEMUA via `isDevice()=false` sampai skema auth device diputuskan — jangan dilonggarkan tanpa owner; pengecualian update `members`/`mediaLimit` oleh owner menunggu persetujuan) + `firebase/firestore.indexes.json` (8 composite per skema §8) + `firebase.json`. Belum diuji emulator (project belum ada).
- Test baru: `detection_model`, `device_command` (+payload), `build_share_report` (golden), `validation_summary`, fake validation/history/events/commands, battery/members mapping, home signed-out. Total 93 test hijau.
- Verifikasi: `dart format` bersih, `flutter analyze` No issues, `flutter test` 93 lulus, `flutter build windows --debug` sukses + exe ALIVE (smoke-run 8 detik).
- Yang tetap `[PERLU KONFIRMASI]`: skema auth device, penulis `members`, role final, `batteryPct` hardware, enum event/command firmware, kebijakan undo/reset batch, `deviceId`/pairing, retensi, collection group lintas-perangkat.
