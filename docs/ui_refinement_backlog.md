# Backlog Poles UI/UX — SIGAP-NETRA App

Dokumen kerja untuk melanjutkan audit UI/UX tanpa mengulang analisis. Satu batch
diselesaikan dan diverifikasi sebelum batch berikutnya dimulai.

**Aturan batch UI:** tidak mengubah skema Firestore, rules, protokol perangkat,
atau perilaku data produk. Semua string tampil lewat `lib/l10n/app_id.arb`.
Tidak menambah package tanpa persetujuan. Jangan commit — deskripsi commit
disiapkan untuk pemilik repo.

**Status:** 20 Oktober 2026 · Batch 1 selesai.

## Ringkasan

| Batch | Fokus | Status |
| ----- | ----- | ------ |
| 1 | Fondasi app bar, avatar Pengaturan, hierarki judul, golden ponsel + font nyata | ✅ Selesai |
| 2 | Unifikasi header seksi + hierarki Pengaturan / Detail perangkat / Kontrol | ⏳ Berikutnya |
| 3 | Layar masuk, QR provisioning, sheet aman-scroll, detail gestur | ⏳ Belum |
| 4 | Navigasi layar anak, tablet/landscape, kode mati, konsistensi sisa | ⏳ Belum |
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
(Batch 3); strip stat hero Beranda memotong tanggal menjadi "22.15 · 2..."
(Batch 2).

---

## Batch 2 — Header seksi & hierarki layar (berikutnya)

Tujuan: menghapus tiga bahasa header seksi yang berbeda dan membuat layar
pengaturan/detail terasa seperti satu produk, bukan daftar `ListTile` polos.

- [ ] **Satu widget header seksi.** `SectionHeader` di `bento_tile.dart` masih
      menyatu dengan padding halaman; Pengaturan memakai `_SectionTitle` privat
      dan Detail perangkat memakai `_SectionLabel` privat. Satukan ke satu API
      (`SectionHeader` dengan varian `page`/`inset`, aksi opsional, dense) dan
      pakai di Beranda, Perangkat, Riwayat (header hari tetap boleh khusus),
      Pengaturan, Detail perangkat, dan Kontrol.
- [ ] **Pengaturan:** kelompokkan Privasi, Lanjutan, Akun, dan Tentang menjadi
      kartu tonal `surfaceContainerLow` + hairline; `ListTile` di dalam kartu
      dengan divider inset, leading 20/24, padding 16; hilangkan label seksi
      biru yang dobel. Header akun tetap hero `primaryContainer`.
- [ ] **Detail perangkat:** jadikan kartu "Informasi perangkat", "Privasi", dan
      "Aksi" (bukan tiga label seksi + baris telanjang). Aksi QR/Kontrol/Log
      menjadi deretan tombol yang jelas, bukan `ActionChip` mengambang.
- [ ] **Kontrol jarak jauh:** beri header "Aksi cepat" dan "Riwayat perintah";
      kelompokkan aksi ke kartu; jelaskan keadaan tanpa perangkat (tombol
      disabled + alasan), bukan deretan chip mati tanpa konteks.
- [ ] **Konsistensi jarak:** jarak antar-seksi 24, dalam kartu 12/16; tidak ada
      padding horizontal ganda antara `SectionHeader` dan body layar.
- [ ] **Strip stat hero Beranda:** "Sinkron terakhir 22.15 · 2..." terpotong di
      390 dp; ringkas jadi jam saja atau pindahkan tanggal ke baris kedua tanpa
      mengubah data. Bento di bawahnya tetap menampilkan tanggal lengkap.
- [ ] Test widget 360×800 + 1,3× untuk Pengaturan, Detail perangkat, dan
      Kontrol; golden ponsel jika perubahan visualnya besar.
- [ ] Update `docs/ui_spec.md` bila pola kartu seksi disepakati.

**Definition of done:** tidak ada header seksi privat baru; `flutter analyze`
bersih; test + golden relevan lulus; tidak menyentuh data/skema.

---

## Batch 3 — Alur masuk, QR, sheet, dan gestur

- [ ] **Layar masuk 390×844 / 360×640:** tautan "Belum punya akun? Daftar"
      menempel di tepi bawah. Jadikan form scrollable dengan bottom safe padding,
      ringkas hero pada tinggi pendek, dan pastikan CTA + link daftar terlihat
      tanpa terpotong pada 1,3×.
- [ ] **QR provisioning:** `Stepper` bawaan Material terlalu tinggi dan
      menyisakan ruang kosong; ganti dengan header langkah kustom (3 langkah,
      progres, satu langkah aktif) yang scrollable. **Jangan ubah payload QR,
      nama field, atau urutan langkah.**
- [ ] **ConfirmSheet / ConsentSheet:** `Column(mainAxisSize.min)` bisa overflow
      saat teks panjang + tinggi pendek + 1,3×. Bungkus isi dalam
      `SingleChildScrollView`, batasi tinggi ±85% layar, pertahankan tombol di
      bawah dan fokus aman pada Batal.
- [ ] **Petunjuk geser Validasi:** label "Tidak cocok"/"Cocok" di latar
      terpotong kartu sehingga hanya terlihat sebagian. Posisikan label di area
      yang benar-benar terbuka saat kartu bergeser, atau gunakan ikon + label
      pendek yang tetap terbaca.
- [ ] Periksa state kosong/error layar masuk, Validasi, Riwayat, Perangkat pada
      360 dp: CTA tidak boleh di bawah lipatan tanpa scroll.
- [ ] Test 360×640 dan 390×844 pada 1,3× untuk sheet dan login.

**Definition of done:** tidak ada overflow; alur QR tetap mengirim payload yang
sama; test 1,3× lulus.

---

## Batch 4 — Navigasi, tablet, dan pembersihan

- [ ] **Navigasi layar anak:** detail Riwayat/Perangkat, QR, Kontrol, Log, dan
      Pengaturan masih hidup di branch navigator sehingga bottom nav tetap
      terlihat. Putuskan: pertahankan (jika produk menginginkan) atau pindahkan
      ke root navigator + verifikasi Hero tetap bekerja. Jangan mengubah route
      hanya demi estetika tanpa retest back/fallback.
- [ ] **Tablet/landscape:** `DesignTokens.maxContentWidth` baru dipakai di
      layar masuk. Terapkan max-width + padding adaptif pada empat tab, detail,
      dan Pengaturan; uji 800×1280 dan landscape.
- [ ] **Kode/token mati:** hapus atau pakai `OfflineBanner`
      (`lib/core/widgets/offline_banner.dart` belum dipasang), `radiusBottomNav`,
      `SectionHeader.compact` yang tak terpakai, komentar `radiusPill` yang
      menunjuk konstanta tidak ada, dan key l10n yatim. Hati-hati: hapus hanya
      setelah `grep` seluruh `lib/` + `test/`.
- [ ] **Dokumentasi:** pastikan `docs/ui_spec.md` dan `AGENTS.md` tidak
      menyebut gear atau "Pengaturan → Koneksi" (Log koneksi ada di Perangkat);
      entri historis `progress.md` boleh tetap. Route `/pengaturan/koneksi` boleh
      tetap untuk kompatibilitas, tetapi label UI harus "Perangkat → Log
      koneksi".
- [ ] **Sisa poles:** cek ulang bayangan/hairline kartu, `Stepper` yang sudah
      diganti, dan golden penuh Perangkat setelah perubahan.
- [ ] Regenerasi golden hanya untuk perubahan yang disengaja; inspeksi PNG satu
      per satu.

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
