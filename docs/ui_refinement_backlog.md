# Backlog Poles UI/UX — SIGAP-NETRA App

Dokumen kerja untuk melanjutkan audit UI/UX tanpa mengulang analisis. Satu batch
diselesaikan dan diverifikasi sebelum batch berikutnya dimulai.

**Aturan batch UI:** tidak mengubah skema Firestore, rules, protokol perangkat,
atau perilaku data produk. Semua string tampil lewat `lib/l10n/app_id.arb`.
Tidak menambah package tanpa persetujuan. Jangan commit — deskripsi commit
disiapkan untuk pemilik repo.

**Status:** 26 Oktober 2026 · Batch 3 dan 4A selesai; 4B, 4C, dan U6 menunggu.

## Ringkasan

| Batch | Fokus | Status |
| ----- | ----- | ------ |
| 1 | Fondasi app bar, avatar Pengaturan, hierarki judul, golden ponsel + font nyata | ✅ Selesai |
| 2 | Unifikasi header seksi + hierarki Pengaturan / Detail perangkat / Kontrol | ✅ Selesai |
| 3 | Layar masuk, QR provisioning, sheet aman-scroll, detail gestur | ✅ Selesai |
| 4 | Navigasi layar anak, tablet/landscape, kode mati, konsistensi sisa | ⏳ Sebagian (4A selesai) |
| U6 | Audit aksesibilitas & semantik lintas layar | ⏳ Belum |

---

## Batch 1 — Fondasi app bar rapat & tipografi (selesai 20 Okt 2026)

- [x] `LargeTitleScaffold` memakai app bar **rapat** 18/SemiBold sebaris aksi;
      subjudul kontekstual 14/Regular di bawah app bar dan ikut tergulir.
      App bar menempel saat scroll tanpa mendorong konten ke bawah.
- [x] Koreksi review produk: large-title 28/Bold + baris aksi terpisah
      dibatalkan karena membuat judul turun jauh dari atas. Judul kembali ke
      toolbar atas seperti sebelum Batch 1.
- [x] Avatar Pengaturan menggantikan gear: inisial/ikon orang, lencana gear,
      target 48 dp, tooltip; dipasang di Beranda, Validasi, Riwayat, Perangkat.
- [x] `AppBarTheme.titleTextStyle` layar anak menjadi 18/SemiBold.
- [x] Plus Jakarta Sans diterapkan ke **seluruh** peran `TextTheme`, tombol,
      chip, dan label navigation bar (sebelumnya `bodySmall` dkk. jatuh ke font
      fallback).
- [x] Golden test memuat font teks dan Material Icons dari SDK; teks/ikon tidak
      lagi berupa kotak Ahem.
- [x] Golden ponsel 390×844 untuk Beranda, Riwayat, Validasi (termasuk geser),
      Perangkat, dan layar masuk; golden Perangkat 800×1400 tetap ada.
- [x] Test 360×800 pada skala teks 1,3× untuk keempat tab, plus test header
      (judul/aksi sebaris di atas, tetap menempel saat scroll, tanpa subjudul,
      skala 1,3×).
- [x] Golden deterministik: `nowProvider` + `goldenNow` tetap untuk data demo,
      bukan `DateTime.now`; tick sumbu Y teratas grafik Statistik yang terpotong
      (tampak "~") diperbaiki.

**Bukti:** lihat `progress.md` entri "Batch 1" dan jalankan
`flutter test test/core/large_title_scaffold_test.dart test/core/app_theme_test.dart`.

**Catatan yang sengaja ditunda:** tautan daftar di layar masuk 390×844 masih
rapat di tepi bawah (Batch 3); label latar geser Validasi terpotong kartu
(Batch 3). Strip stat hero Beranda sudah diperbaiki di Batch 2: hanya jam,
tanggal lengkap tetap di Bento.

---

## Batch 2 — Header seksi & hierarki layar (selesai 21 Okt 2026)

Tujuan: menghapus tiga bahasa header seksi yang berbeda dan membuat layar
pengaturan/detail terasa seperti satu produk, bukan daftar `ListTile` polos.

- [x] **Satu widget header seksi.** `SectionHeader` dipindah keluar dari
      `bento_tile.dart`; varian `page`/`inset`, aksi opsional, dan `dense`.
      Dipakai di Beranda, Perangkat, panel Statistik Riwayat, Pengaturan,
      Detail perangkat, dan Kontrol. Header privat `_SectionTitle`/`_SectionLabel`
      di tiga layar itu dihapus.
- [x] **Pengaturan:** header akun hero `primaryContainer` + tiga kartu tonal
      `surfaceContainerLow` + hairline (Privasi dan data, Lanjutan, Tentang);
      `ListTile` di dalam kartu dengan divider inset 16, leading 36, padding 16;
      label seksi biru yang dobel dihapus. Teks penjelas panjang memakai lebar
      penuh di bawah saklar, bukan subtitle yang terhimpit switch.
- [x] **Detail perangkat:** kartu "Informasi perangkat", "Privasi dan data", dan
      "Aksi" (bukan tiga label seksi + baris telanjang). Aksi QR/Kontrol/Log
      menjadi `ActionTile` yang jelas, bukan `ActionChip` mengambang.
- [x] **Kontrol jarak jauh:** header "Aksi cepat" dan "Riwayat perintah";
      aksi dikelompokkan ke kartu; keadaan tanpa perangkat dijelaskan (notice +
      tombol Buka Perangkat + semua aksi nonaktif dengan ikon kunci).
- [x] **Konsistensi jarak:** jarak antar-seksi 24, dalam kartu 12/16; tidak ada
      padding horizontal ganda antara `SectionHeader` dan body layar.
- [x] **Strip stat hero Beranda:** hanya jam (`RelativeTime.timeOnly`) di strip;
      tanggal lengkap tetap di Bento. Label semantik stat ditambahkan.
- [x] Test widget 360×800 + 1,3× untuk Pengaturan, Detail perangkat, dan
      Kontrol; test tanpa perangkat untuk Kontrol; golden ponsel baru untuk
      ketiga layar, golden Beranda diperbarui untuk jam saja, dan golden
      Statistik diperbarui untuk header 16/SemiBold.
- [x] Update `docs/ui_spec.md` dengan pola `SectionHeader`/`SectionCard`/
      `ActionTile` dan struktur tiga layar.

**Definition of done:** tidak ada header seksi privat baru; `flutter analyze`
bersih; test + golden relevan lulus; tidak menyentuh data/skema.

**Bukti (21 Okt 2026):** `dart format .` bersih (206 file, 0 berubah);
`flutter analyze` No issues; `flutter test` **300 lulus**. Golden
`settings_phone_light.png`, `device_detail_phone_light.png`,
`commands_phone_light.png`, `home_tab_light.png`, dan
`history_stats_light.png` diinspeksi manual; tampilan 360×800 @1,3× juga
diperiksa. Tanpa perubahan schema/rules/device atau package.

---

## Batch 3 — Alur masuk, QR, sheet, dan gestur (selesai 21 Okt 2026)

- [x] **Layar masuk 390×844 / 360×640:** tautan "Belum punya akun? Daftar"
      menempel di tepi bawah. Jadikan form scrollable dengan bottom safe padding,
      ringkas hero pada tinggi pendek, dan pastikan CTA + link daftar terlihat
      tanpa terpotong pada 1,3×.
- [x] **QR provisioning:** `Stepper` bawaan Material terlalu tinggi dan
      menyisakan ruang kosong; ganti dengan header langkah kustom (3 langkah,
      progres, satu langkah aktif) yang scrollable. **Jangan ubah payload QR,
      nama field, atau urutan langkah.**
- [x] **ConfirmSheet / ConsentSheet:** `Column(mainAxisSize.min)` bisa overflow
      saat teks panjang + tinggi pendek + 1,3×. Bungkus isi dalam
      `SingleChildScrollView`, batasi tinggi ±85% layar, pertahankan tombol di
      bawah dan fokus aman pada Batal.
- [x] **Petunjuk geser Validasi:** label "Tidak cocok"/"Cocok" di latar
      terpotong kartu sehingga hanya terlihat sebagian. Label kini menjadi pil
      mengambang di atas kartu; latar status hanya ikon.
- [x] Periksa state kosong/error layar masuk, Validasi, Riwayat, Perangkat pada
      360 dp: CTA tidak boleh di bawah lipatan tanpa scroll.
- [x] Test 360×640 dan 390×844 pada 1,3× untuk sheet dan login.
- [x] **Pengaturan / navigation bar Android:** baris Tentang/versi tertutup
      navigation bar meski sudah digulir. Body dibungkus `SafeArea` bawah +
      padding minimum, dan diuji pada 360×800 @1,3× dengan inset 48 dp.

**Definition of done:** tidak ada overflow; alur QR tetap mengirim payload yang
sama; test 1,3× lulus.

---

## Batch 4 — Navigasi, tablet, dan pembersihan

### 4A — Pembersihan & konsistensi (selesai 26 Okt 2026)

- [x] **Kode/token mati:** 62 key l10n non-`@` tanpa referensi di `lib/` +
      `test/` dihapus dari `app_id.arb` dan generated l10n; `radiusBottomNav`
      dihapus; komentar `radiusPill` yang menunjuk konstanta tidak ada
      diperbaiki; `cupertino_icons` dihapus; `mocktail`/`firebase_auth_mocks`
      dipertahankan karena tercantum di `AGENTS.md`; `OfflineBanner`
      dipertahankan untuk U7, bukan dihapus. Lima key login
      (`loginWrongPassword` dkk.) tetap ada karena `failure_message.dart`
      merujuk getter-nya tanpa prefiks `l10n.`.
- [x] **Helper rute:** `ConnectionLogsPath(deviceId)` menghasilkan path log
      per perangkat; detail Perangkat tidak lagi memakai path mentah
      `/pengaturan/koneksi/:deviceId`.
- [x] **Dokumentasi:** README menyebut 29 test rules (bukan 25), skema naik ke
      v0.4 selaras rules v0.4, inventaris widget `ui_spec.md` memakai nama class
      yang benar, komentar thumbnail di `pubspec.yaml` menjadi 200 KB, dan
      status backlog ini disinkronkan.

**Bukti (26 Okt 2026):** `dart format .` bersih (210 file, 0 berubah setelah
format); `flutter analyze` No issues; `flutter test` **324 lulus** (dari 322;
+2 test `ConnectionLogsPath`); golden tidak berubah; `flutter build apk --debug`
sukses. Tanpa perubahan schema/rules/indexes/kode device/perilaku data.

### 4B — Tablet/landscape (belum)

- [ ] `DesignTokens.maxContentWidth` baru dipakai di layar masuk. Terapkan
      max-width + padding adaptif pada empat tab, detail, dan Pengaturan; uji
      800×1280 dan landscape.
- [ ] **Sisa poles:** cek ulang bayangan/hairline kartu, `Stepper` yang sudah
      diganti, dan golden penuh Perangkat setelah perubahan.
- [ ] Regenerasi golden hanya untuk perubahan yang disengaja; inspeksi PNG satu
      per satu.

### 4C — Navigasi layar anak (belum, butuh keputusan produk)

- [ ] Detail Riwayat/Perangkat, QR, Kontrol, Log, dan Pengaturan masih hidup di
      branch navigator sehingga bottom nav tetap terlihat. Putuskan:
      pertahankan (jika produk menginginkan) atau pindahkan ke root navigator +
      verifikasi Hero tetap bekerja. Jangan mengubah route hanya demi estetika
      tanpa retest back/fallback.

---

## U6 — Aksesibilitas lintas layar

- [ ] Audit `Semantics` header untuk setiap layar: satu judul, aksi punya label,
      ikon dekoratif di-`ExcludeSemantics`.
- [ ] Pastikan semua target sentuh ≥48 dp (avatar, chip, tombol ikon, thumbnail).
- [ ] Uji TalkBack alur: masuk → Beranda → Validasi (Cocok/Urungkan) → Riwayat →
      Detail → Pengaturan → QR. Tidak ada kontrol tanpa label.
- [ ] Kontras: cek `StatusColors` di atas `surfaceContainerLow` dan
      `primaryContainer`; jangan hanya mengandalkan warna.
- [ ] Reduced motion: pastikan fade-through, skeleton, dan Lens Ring statis;
      zoom foto tetap bisa dipakai.
- [ ] Text scale 1,3× dan 2,0× pada layar kritis; perbaiki overflow, bukan
      menyembunyikan teks.

---

## Definition of done tiap batch

1. `dart format .` bersih.
2. `flutter analyze` tanpa issue.
3. `flutter test` lulus (golden diinspeksi, bukan hanya "hijau").
4. `progress.md` diperbarui dengan apa yang berubah + angka verifikasi.
5. Deskripsi commit siap copy-paste; **tanpa** `git commit`/`push`.
