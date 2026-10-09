# PRD — SIGAP-NETRA App (Pendamping: Monitoring, Validasi, Provisioning)

|                          |                                                                                                            |
| ------------------------ | ---------------------------------------------------------------------------------------------------------- |
| **Produk**               | SIGAP-NETRA — kacamata cerdas untuk tunanetra                                                              |
| **Dokumen ini mencakup** | Aplikasi Flutter _companion_ (refactor dari aplikasi Kotlin) + lapisan cloud + klien telemetri di MaixCAM  |
| **Versi / tanggal**      | 1.1 — 8 Oktober 2026 (menggantikan 1.0; menambahkan fitur dari aplikasi lama: Validasi, Riwayat, QR Wi-Fi) |
| **Owner**                | Andre (divisi programming)                                                                                 |
| **Pendamping dokumen**   | `docs/ui_spec.md` (UI) · `docs/firestore_schema.md` (data) · `docs/device_protocol.md` (alat ↔ cloud)      |
| **Status**               | Draft siap eksekusi. ⚠️ = **perlu verifikasi** ke tim/hardware/kode lama sebelum dibangun.                 |

---

## 1. Ringkasan

Alat SIGAP-NETRA sudah berfungsi dan membaca **uang** (YOLO) serta **menu/teks** (OCR) lalu menyebutkannya lewat suara. Aplikasi Kotlin lama dipakai pendamping untuk memantau alat, **memvalidasi** hasil bacaan (Cocok / Tidak cocok), melihat riwayat, dan **menyambungkan alat ke Wi-Fi lewat QR** — tetapi hanya jalan dalam jaringan yang sama.

Rilis ini membangun ulang aplikasi dengan **Flutter** dan menambah kemampuan lintas jaringan:

1. **Lintas jaringan & realtime** — alat di rumah user, pendamping/tim memantau dari mana saja.
2. **Fungsi lama dipertahankan** — Beranda, Validasi, Riwayat, Pengaturan, QR Wi-Fi.
3. **Tampilan lebih profesional** (Material 3, Netra Indigo `#4A47D6`, mode gelap) — isi dan fungsi tetap.
4. **Fitur baru:** log error/baterai realtime, kontrol jarak jauh, share hasil ke media sosial, statistik.
5. **Validasi = data kebenaran lapangan** (_ground truth_) untuk mengukur akurasi model dan memutuskan kapan dataset perlu diperbarui.

## 2. Kondisi Saat Ini (As-Is)

- Perangkat: Sipeed MaixCAM (RISC-V C906 1 GHz, NPU 1 TOPS, RAM 256 MB, WiFi 6 + BLE 5.4, OS dari TF card) + LiDAR TF-Luna (0,2–8 m, FoV 2°, UART) + YOLOv11 on-device (dataset Roboflow) + OCR untuk teks/menu ⚠️ + suara ke headset.
- Aplikasi lama (Kotlin): 4 tab — Beranda, Validasi, Riwayat, Pengaturan. Alat terhubung lewat **hotspot ponsel**; pendamping menunjukkan **QR** ke kamera alat; ada tombol _Sinkronkan_ dan _Tarik Rekaman_; rekaman berisi gambar, nilai bacaan, confidence, jarak, waktu proses.
- Catatan lama menyebut komunikasi **MQTT** ke perangkat; keputusan di dokumen ini berbeda (lihat D2).
- Anggota programming baru masuk setelah alat jadi → **Fase 0 (discovery)** wajib (§14).

## 3. Prinsip Desain

1. **Safety first, cloud second.** Fungsi inti alat (deteksi/baca → suara) tetap jalan tanpa internet. Cloud hanya untuk telemetri, validasi, dan monitoring.
2. **Privasi.** Tidak ada video, rekaman suara, atau lokasi. **Gambar hanya berupa thumbnail kecil dari pembacaan uang/teks, dan hanya bila diaktifkan dengan persetujuan** (opt-in). Teks hasil OCR bisa memuat info pribadi → dibatasi 500 karakter, retensi 30 hari, peringatan saat share.
3. **Hemat biaya.** Dana BHP terbatas → **Firebase Spark (gratis)**; tanpa server sendiri, tanpa Cloud Functions, tanpa hardware baru kecuali yang benar-benar perlu.
4. **Kompatibel dengan alat yang ada.** Jangan mengubah perilaku firmware yang sudah jalan (format QR, nama kelas) tanpa disepakati.
5. **Sederhana dulu.** Satu jalur data, satu database, satu aplikasi.

## 4. Pengguna

| Persona                              | Kebutuhan                                                      | Pakai aplikasi?                       |
| ------------------------------------ | -------------------------------------------------------------- | ------------------------------------- |
| **Pendamping/keluarga**              | Memastikan alat aktif, memvalidasi bacaan, menyambungkan Wi-Fi | Ya (utama)                            |
| **Peneliti/pengembang** (Andre, tim) | Memantau jarak jauh, mengukur akurasi, debugging               | Ya                                    |
| **Pengguna tunanetra**               | Mendengar hasil bacaan dari alat                               | **Tidak** — antarmukanya alat + suara |

## 5. Ruang Lingkup

**In scope:** aplikasi Flutter (Android prioritas uji; iOS didukung kodenya, diverifikasi bila ada perangkat Mac), Firestore + Rules, klien telemetri MaixCAM (Python), simulator PC, validasi, QR Wi-Fi, share.

**Out of scope (rilis ini):** antarmuka untuk tunanetra, streaming video, GPS, Cloud Functions/FCM server, Firebase Storage (butuh Blaze ⚠️), retraining model kecuali Fase 0 menemukan masalah, Mode Lokal (tarik rekaman resolusi penuh lewat LAN) — P2.

## 6. Arsitektur Target & Keputusan

```
┌────────── Jaringan user (rumah / hotspot) ──────────┐       ┌─── Internet ───┐       ┌─ Mana saja ─┐
│ MaixCAM: YOLO + OCR + LiDAR + suara (OFFLINE-OK)    │ HTTPS │ Firebase Auth  │ stream│ Flutter App │
│   └ telemetry thread ───────────────────────────────┼──────►│ Firestore      │──────►│ pendamping/ │
│     heartbeat · pembacaan(+thumbnail) · event · cmd │ REST  │ (Spark/gratis) │◄──────│ peneliti    │
└─────────────────────────────────────────────────────┘       └────────────────┘ valid.│ + QR Wi-Fi  │
        ▲ QR Wi-Fi (kamera alat memindai layar ponsel pendamping)                       └─────────────┘
```

| #   | Keputusan                                                                                                | Alasan                                                                                                      | Ditinjau ulang bila                                                                  |
| --- | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| D1  | **Firestore**                                                                                            | Query terstruktur, realtime listener Flutter, kuota gratis cukup bila penulisan di-throttle                 | Kuota sering habis → Realtime Database; butuh SQL/analitik → Supabase                |
| D2  | **Tanpa MQTT** (berbeda dari catatan lama)                                                               | MQTT butuh broker + jembatan ke Firestore = butuh server. Alat bisa menulis langsung ke Firestore via HTTPS | Fase 0 menemukan firmware sudah memakai MQTT yang stabil, atau butuh command < 2 dtk |
| D3  | Alat login sebagai **akun Firebase Auth khusus perangkat**                                               | Tanpa Cloud Functions; akses dibatasi Rules                                                                 | Perangkat banyak → alur provisioning                                                 |
| D4  | Command via **polling 10 dtk**                                                                           | REST tidak punya listener sederhana                                                                         | Lihat D2                                                                             |
| D5  | Aplikasi **menulis hanya**: `commands` (buat), status validasi pada `detections`, hapus pembacaan/gambar | Satu penulis per field; Rules membatasi key                                                                 | —                                                                                    |
| D6  | **Thumbnail JPEG ≤ 60 KB di Firestore** (koleksi `media`, opt-in)                                        | Validasi butuh gambar; Firebase Storage umumnya butuh Blaze ⚠️; volume rendah (pembacaan dipicu pengguna)   | Volume naik / pindah Blaze → Storage                                                 |
| D7  | Suara tetap **di sisi alat**                                                                             | Alat mandiri tanpa internet                                                                                 | —                                                                                    |
| D8  | **QR Wi-Fi dipertahankan** sebagai satu-satunya cara memberi tahu Wi-Fi ke alat tanpa keyboard           | Fungsi lama; kini juga untuk Wi-Fi rumah                                                                    | Alat dapat BLE provisioning                                                          |
| D9  | "Tarik Rekaman" diganti **sinkron otomatis + tombol Sinkronkan sekarang** (`sync_now`)                   | Lintas jaringan; tidak perlu satu LAN                                                                       | Perlu gambar resolusi penuh → Mode Lokal (P2)                                        |

**Alur final:** `MaixCAM → HTTPS REST → Firestore → Flutter (snapshots)`; kebalikannya: `Flutter → commands/validasi → Firestore → alat (polling)`.

## 7. Model Data (ringkas — sumber: `docs/firestore_schema.md`)

`devices/{id}` · `devices/{id}/detections/{id}` (kategori `money|text|object`, `value`, confidence, jarak, `processingMs`, `seq`, `validationStatus`) · `devices/{id}/media/{detectionId}` (thumbnail) · `events` · `commands`. Retensi 30 hari (TTL).

## 8. Fitur & Acceptance Criteria

Detail UI per layar ada di `docs/ui_spec.md`.

### P0 — Wajib (MVP)

| ID  | Fitur                                           | Acceptance criteria                                                                                                                                                                                                                      |
| --- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| F1  | **Login** (Email/Password + Google)             | Sesi bertahan; logout menghapus sesi; error ramah                                                                                                                                                                                        |
| F2  | **Beranda**                                     | Kartu status (online/offline, baterai atau "–", menunggu validasi, terakhir sinkron); ringkasan (menunggu, % kecocokan); 5 aktivitas terbaru realtime; online = `lastSeen` < 90 dtk                                                      |
| F3  | **QR Wi-Fi**                                    | Input SSID + password → QR tampil; password tidak disimpan; format payload **identik** dengan yang dipahami firmware ⚠️; menunggu heartbeat pertama (batas 2 menit) lalu status berubah Terhubung                                        |
| F4  | **Validasi**                                    | Antrean `pending` dengan filter Gabungan/Uang/Menu-Teks; kartu menampilkan gambar, nilai, confidence, jarak, waktu; Cocok/Tidak cocok menyimpan `validationStatus` + `validatedBy/At`; snackbar **Urungkan**; badge tab = jumlah pending |
| F5  | **Riwayat**                                     | Daftar 20/halaman, filter kategori, badge Cocok/Tidak cocok/Belum, hapus (dengan konfirmasi, juga gambar), detail, **Reset Status Validasi** (batch + konfirmasi)                                                                        |
| F6  | **Pengaturan**                                  | Tema terang/gelap/sistem; menu Koneksi & sinkronisasi; QR Wi-Fi; Mode pengembang; akun                                                                                                                                                   |
| F7  | **Log event/error** (di Koneksi & sinkronisasi) | Daftar severity berwarna, filter severity, kode + pesan                                                                                                                                                                                  |
| F8  | **Persetujuan unggah gambar**                   | Dialog consent menjelaskan data apa yang dikirim; default **mati**; pengaturan dapat dicabut kapan saja (`set_upload_thumbnails`)                                                                                                        |

### P1 — Penting

| ID  | Fitur                               | Acceptance criteria                                                                                                                                               |
| --- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| F9  | **Kontrol jarak jauh**              | `sync_now`, `ping`, volume, ambang confidence, aktif/nonaktif deteksi, restart; status `pending→acked→done/failed`; `expired` bila 60 dtk tak di-ack              |
| F10 | **Share hasil**                     | Ringkasan (teks + kartu gambar tanpa gambar asli bila consent belum diberikan) → share sheet; dialog persetujuan + peringatan teks OCR; tanpa ID perangkat/lokasi |
| F11 | **Statistik & grafik** (`fl_chart`) | Pembacaan per hari/minggu, per kategori, tren % kecocokan                                                                                                         |
| F12 | **Ekspor CSV**                      | Riwayat sesuai filter tanggal                                                                                                                                     |
| F13 | **Mode pengembang**                 | Sumber data Firebase/Simulasi (provider override), tampilkan IP/ID/versi                                                                                          |

### P2 — Nanti

Notifikasi lokal · multi-perangkat penuh · TTS di aplikasi (`flutter_tts`) · validasi otomatis (ditandai terpisah; tidak dihitung dalam % kecocokan) · Mode Lokal (tarik rekaman resolusi penuh bila API lokal firmware masih ada) · versi web · PDF · push notification (butuh Blaze).

### Sisi perangkat (MaixCAM)

| ID  | Kebutuhan           | Acceptance criteria                                                                                          |
| --- | ------------------- | ------------------------------------------------------------------------------------------------------------ |
| DV1 | Heartbeat 30 dtk    | `lastSeen`, `state`, baterai, versi ter-update                                                               |
| DV2 | Upload pembacaan    | Uang/teks: kirim semua dengan `seq`, `category`, `value`, `processingMs`; objek kontinu (bila ada): throttle |
| DV3 | Upload thumbnail    | Hanya bila `uploadThumbnails = true`; JPEG ≤ 60 KB; satu `commit` atomik dengan pembacaan                    |
| DV4 | Event               | Kode baku; tanpa SSID/password                                                                               |
| DV5 | Poll command 10 dtk | Ack → eksekusi → hasil; termasuk `sync_now`                                                                  |
| DV6 | Tahan offline       | Tanpa internet: baca + suara normal; antrean maks 200; sinkron saat online; tanpa crash                      |
| DV7 | Auth & token        | Login REST, refresh otomatis, backoff                                                                        |
| DV8 | Pindai QR Wi-Fi     | Parse payload, sambung, simpan lokal, event hasil ⚠️ cek dukungan QR di MaixPy                               |
| DV9 | Simulator PC        | `device/tools/simulate_device.py` (heartbeat, pembacaan + thumbnail contoh, command)                         |

## 9. Persyaratan Non-Fungsional

**Anggaran kuota Firestore Spark** (estimasi — verifikasi di tab _Usage_ ⚠️; kuota gratis harian umumnya 50 ribu baca / 20 ribu tulis / 20 ribu hapus, 1 GiB penyimpanan):

| Sumber                                                          | Estimasi per perangkat/hari              |
| --------------------------------------------------------------- | ---------------------------------------- |
| Heartbeat 30 dtk (24 jam)                                       | ≈ 2.880 tulis                            |
| Pembacaan uang/teks (≤ ~300/hari) × (detail + media)            | ≈ 600 tulis                              |
| Deteksi objek kontinu, bila ada (≤ 12/menit, ≈ 8 jam)           | ≤ ≈ 5.800 tulis                          |
| Event + command + validasi                                      | < 500 tulis                              |
| Poll command 10 dtk (24 jam)                                    | ≈ 8.640 baca                             |
| `get()` di Rules                                                | ≈ +1 baca per tulis oleh alat/pendamping |
| Antrean validasi / riwayat (20 dokumen + 20 media tiap halaman) | ≈ 40 baca per muat halaman               |

Penyimpanan thumbnail: ~300 pembacaan × ≤ 60 KB × 30 hari ≈ ≤ 540 MB bila penuh (jauh di bawah itu pada praktiknya); pantau, dan turunkan kualitas/ukuran bila perlu.

Aturan turunan: tidak menulis per frame; semua query pakai `limit`; badge/ringkasan pakai `count()`; listener `autoDispose`; gambar kartu dimuat lazy dan di-cache di memori.

**Keamanan:** Rules deny-by-default; alat hanya menulis key yang diizinkan; pendamping hanya mengubah status validasi; kredensial alat tidak di-commit; HTTPS.

**Privasi & etika:** tanpa video/suara/lokasi; gambar opt-in; retensi 30 hari; consent sebelum share; ⚠️ tanyakan ke dosen pembimbing apakah uji dengan penyandang tunanetra perlu lembar persetujuan.

**Performa:** alat → layar ≤ 5 dtk (P95, WiFi normal); telemetri tidak menurunkan FPS/latensi baca secara terukur.

**Kompatibilitas:** Android 8+; iOS sesuai kemampuan Flutter.

## 10. Jawaban Teknis untuk Pertanyaan Tim

**Dataset YOLOv11 — perlu dibuat ulang?** Tidak otomatis. Fase 0: audit dataset (kelas — mis. pecahan uang —, jumlah gambar per kelas, variasi cahaya/sudut). Gunakan **validasi pendamping sebagai pengukur akurasi lapangan**: % kecocokan per kategori/kelas, dan daftar `mismatch` sebagai kandidat data latih baru (dengan consent gambar). Latih ulang bila: % kecocokan turun/rendah pada kelas tertentu, ada kelas baru (pecahan uang baru), banyak salah baca pada kondisi tertentu (cahaya redup, uang lusuh). Pertahankan **set uji lapangan beku** yang tak pernah dipakai training. Catat versi di `devices.modelVersion`. ⚠️ Tanyakan varian model (n/s), ukuran input, dan engine OCR.

**Integrasi LiDAR.** Dari data lama, jarak (mis. 35 cm) berfungsi memastikan benda berada pada jarak baca yang baik — jadi cukup dilampirkan sebagai `distanceCm` pada pembacaan. Bila alat juga dipakai navigasi (rintangan), TF-Luna hanya mengukur satu titik sempit (FoV 2°): hubungkan jarak ke deteksi yang kotaknya mencakup titik arah LiDAR (butuh kalibrasi), plus peringatan jarak independen. Itu **peningkatan UX**, bukan akurasi YOLO.

**Output suara & MeloTTS.** MeloTTS didukung di MaixCAM2 (info tim), **kemungkinan besar tidak di generasi pertama** ⚠️. Alternatif offline paling andal: klip WAV yang dirender di PC (label + angka + "rupiah/meter"), disusun saat runtime. Untuk teks OCR bebas, TTS di alat diperlukan ⚠️ — cek bagaimana sistem lama melakukannya sebelum mengubah apa pun. Jalur audio fisik ke headset: konfirmasi ke tim electrical.

**Baterai %.** ⚠️ Cara alat mengukurnya belum diketahui. Jika tidak ada sensor → tidak dikirim, UI tampilkan "–". Jangan dipalsukan.

**Alat & bahan prioritas (hemat):**

| Prioritas             | Item                                    | Alasan                                 |
| --------------------- | --------------------------------------- | -------------------------------------- |
| Urgent                | TF card cadangan (merek bagus, ≥ 32 GB) | OS di TF card; rusak = alat mati       |
| Urgent                | Kabel USB-C data + sumber daya stabil   | Debug MaixCAM                          |
| Urgent                | Hotspot HP (sudah ada)                  | Uji lintas jaringan + QR Wi-Fi, gratis |
| Disarankan            | Adaptor USB-to-TTL                      | Uji TF-Luna terpisah                   |
| Bila audio bermasalah | Adaptor audio USB / speaker kecil       | Konfirmasi electrical dulu             |
| Tidak perlu           | MaixCAM2, VPS, broker MQTT berbayar     | Tidak dibutuhkan arsitektur ini        |

Cloud: Firebase Spark = Rp 0.

## 11. Ide Peningkatan Berikutnya

1. Validasi otomatis berbasis ambang confidence (ditandai terpisah dari validasi manusia).
2. Laporan akurasi per kelas dari data validasi → ekspor daftar `mismatch` untuk retraining Roboflow.
3. Peringatan baterai rendah/offline (notifikasi lokal, lalu push bila Blaze disetujui).
4. TTS di aplikasi untuk pendamping; versi web untuk laptop peneliti.
5. Pembaruan model OTA lewat URL (mis. GitHub Release + checksum).
6. Multi-perangkat dan pairing mandiri.

## 12. Risiko & Mitigasi

| Risiko                                  | Dampak                     | Mitigasi                                                                       |
| --------------------------------------- | -------------------------- | ------------------------------------------------------------------------------ |
| Format QR/protokol lama tidak diketahui | Alat tidak bisa tersambung | Ambil dari kode Kotlin di Fase 0; uji dengan alat sungguhan sebelum rilis      |
| API MaixPy/hardware berbeda dari asumsi | Waktu hilang               | Probe script di perangkat; baca dokumentasi resmi                              |
| Gambar/teks OCR memuat data pribadi     | Privasi                    | Opt-in, thumbnail kecil, retensi 30 hari, batas 500 karakter, peringatan share |
| Jam alat tidak akurat                   | Urutan kacau               | Server timestamp `REQUEST_TIME`                                                |
| Kuota/penyimpanan gratis habis          | Data berhenti              | Throttle, `limit`, `count()`, pantau Usage, turunkan kualitas thumbnail        |
| Jaringan user tidak stabil              | Data tertunda              | Antrean offline terbatas; core tetap jalan                                     |
| Kredensial alat bocor                   | Data palsu                 | `config.py` di `.gitignore`; Rules membatasi key; rotasi password              |
| Salah ketuk saat validasi               | Metrik akurasi salah       | Snackbar Urungkan; `validatedAt` tercatat                                      |
| Baterai tidak terukur                   | Fitur menyesatkan          | Tampilkan "–"                                                                  |

## 13. Roadmap (selaras Gantt PBL; sesuaikan bila jadwal PKM berbeda)

| Minggu  | Tanggal       | Fokus                                         | Output                                                                                                |
| ------- | ------------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| M4–M5   | 2–15 Okt      | **Fase 0 Discovery** + 4.1.1 Riset arsitektur | Checklist §14 terjawab; Firebase project; schema + rules; `flutter create`; design system (tema Netra Indigo) |
| M6–M7   | 16–29 Okt     | 4.1.2 Sinkron cloud                           | Klien telemetri alat (DV1–DV7, DV9); F1, F2, F6 (dasar), F7                                           |
| M8      | 30 Okt–5 Nov  | 4.1.3 Uji realtime + 4.2.1 riset share        | **Uji lintas jaringan**; F3 (QR Wi-Fi) + DV8; F4 Validasi + F8 consent + DV3; ukur latensi/kuota      |
| M9      | 6–12 Nov      | 4.2.2 Implementasi share                      | F5 Riwayat penuh; F9 kontrol jarak jauh; F10 Share                                                    |
| M10     | 13–19 Nov     | 4.2.3 Uji share + 4.3.1 integrasi             | F11 statistik; F12 CSV; integrasi ke sistem utama                                                     |
| M11     | 20–26 Nov     | 4.3.2 Optimasi                                | Kuota/baterai/FPS; polesan UI; bug fix                                                                |
| M12–M14 | 27 Nov–17 Des | Pengujian & dokumentasi                       | Uji end-to-end, user testing, laporan                                                                 |

Catatan: cakupan M8 padat (QR + Validasi + thumbnail). Bila terlalu ketat, geser F5 detail/F9 ke M9–M10 dan jaga **F3 + F4** tetap di M8.

## 14. Fase 0 — Checklist Discovery

**Dari kode aplikasi Kotlin lama dan firmware (wajib diambil, jangan ditebak):**

1. **Format payload QR Wi-Fi** persis seperti yang dibuat aplikasi dan dipahami firmware.
2. API lokal alat (endpoint "Tarik Rekaman"/"Sinkron", format JSON, autentikasi) — untuk Mode Lokal P2 dan untuk memahami field.
3. Skema data lokal (field, satuan jarak/waktu, nama kelas uang, nilai `conf`), cara validasi disimpan.
4. Apakah firmware sudah memakai MQTT? Broker apa?

**Dari tim / alat:** 5. Varian YOLO, ukuran input, FPS, kelas; engine OCR dan cara teks dibacakan. 6. Jalur audio fisik ke headset; asal "suara AI". 7. Cara baterai dibaca (ada sensor?) dan sumber daya. 8. Posisi TF-Luna terhadap kamera. 9. Versi MaixPy/firmware; dukungan pemindaian QR dan encode JPEG. 10. Apa yang dimaksud "Uji kamera" pada Mode Pengembang lama? 11. Akun Firebase/Google proyek (gunakan akun tim, bukan pribadi tunggal). 12. Ketentuan kampus/PKM soal consent data pengguna disabilitas.

## 15. Definition of Done

- `flutter analyze` + `flutter test` bersih; Rules lolos uji emulator (termasuk: pendamping tidak bisa mengubah field selain status validasi).
- Uji lintas jaringan: alat di jaringan A, aplikasi di jaringan B, pembacaan muncul ≤ 5 dtk; QR Wi-Fi berhasil menyambungkan alat.
- Alat tetap membaca dan berbicara saat internet diputus dan sinkron kembali saat pulih.
- Gambar tidak terkirim saat `uploadThumbnails = false` (diuji).
- Kuota harian tercatat dan < 50% batas gratis.
- `progress.md` dan `docs/*` diperbarui; tidak ada kredensial di repo.

**Metrik sukses:** latensi P95 ≤ 5 dtk · heartbeat diterima ≥ 95% saat alat menyala dan online · 0 kasus pembacaan/suara terhenti akibat jaringan · % kecocokan terukur per kategori.
