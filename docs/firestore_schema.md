# Skema Firestore - SIGAP-NETRA App

Dokumen ini adalah **satu-satunya definisi** koleksi, field, dan tipe data Cloud Firestore untuk SIGAP-NETRA App. Dart model, Security Rules (`firebase/firestore.rules`), indeks (`firebase/firestore.indexes.json`), dan kode device harus mengikuti dokumen ini.

## 0. Status dokumen

| Item | Nilai |
| --- | --- |
| Versi skema | v0.1 (draft awal) |
| Tanggal | 2026-10-08 |
| Plan Firebase | Spark (gratis), tanpa Cloud Functions, tanpa TTL policy, tanpa FCM dari server |
| Sumber kebenaran lain | `AGENTS.md` (kontrak ringkas), `PRD.md` (masih DRAFT kosong), `docs/device_protocol.md` (belum ada), `docs/ui_spec.md` (belum ada) |

**Keterbatasan sumber.** `PRD.md` saat ini hanya berisi catatan bahwa isinya belum ditulis. Referensi ke "PRD.md bagian 9 (anggaran kuota)" dan "PRD.md bagian 14 (aplikasi Kotlin lama / firmware MaixCAM)" **belum dapat diverifikasi** karena dokumen tersebut belum ada. Aplikasi Kotlin lama dan firmware MaixCAM juga belum tersedia di repo ini. Karena itu dokumen ini:

- hanya menyatakan apa yang sudah diputuskan di `AGENTS.md`;
- menandai sisanya sebagai `[PERLU KONFIRMASI]` beserta alasannya;
- tidak mengarang nilai enum atau nama field yang belum ada bukti sumbernya.

## 1. Aturan main yang tidak bisa ditawar

1. **Device adalah penulis utama.** Dokumen `devices`, `detections`, `events`, dan `media` dibuat dan diubah oleh device (MaixCAM).
2. **Hak tulis aplikasi sangat sempit.** Aplikasi (pengguna terautentikasi) hanya boleh:
   - membuat dokumen di `devices/{deviceId}/commands`;
   - memperbarui **hanya** field `validationStatus`, `validatedBy`, dan `validatedAt` pada `devices/{deviceId}/detections/{id}`;
   - menghapus dokumen `detections` beserta dokumen `media` yang terkait.
   Apapun di luar itu adalah bug dan harus ditolak Security Rules.
3. **Status online tidak pernah disimpan sebagai sumber kebenaran.** Online dihitung client-side: `now - lastSeen < 90 detik` (heartbeat device 30 detik). Tidak ada field `isOnline` atau `status` yang dipercaya.
4. **Privasi.** Tidak pernah ada video, audio, GPS/lokasi, alamat IP, MAC address, kredensial Wi-Fi, atau gambar resolusi penuh. Satu-satunya data gambar yang diizinkan adalah thumbnail JPEG dengan ukuran dasar **<= 60.000 byte**, dan hanya jika `settings.uploadThumbnails == true` (opt-in, default `false`). `ocrText` dipotong maksimal 500 karakter.
5. **Waktu.** Semua field waktu yang dipakai untuk urutan adalah `timestamp` server. Jam device tidak boleh menjadi sumber pengurutan.
6. **Integritas validasi.** `match / (match + mismatch)` hanya menghitung validasi manusia. `pending` tidak pernah dihitung dan tidak pernah diisi otomatis oleh sistem.
7. **Free tier dulu.** Setiap query yang dirancang di sini harus tetap muat dalam kuota Spark (lihat bagian 7). Query tanpa `limit()` di UI yang sering dibuka dianggap bug.

## 2. Ringkasan hierarki koleksi

```
devices/{deviceId}                          # dokumen perangkat (ditulis device; app hanya membaca)
  detections/{detectionId}                  # hasil bacaan uang / teks (dibuat device; app: update 3 field validasi, delete)
  media/{mediaId}                           # thumbnail JPEG opsional (dibuat device; app: delete)
  events/{eventId}                          # log kejadian perangkat (dibuat device)
  commands/{commandId}                      # perintah jarak jauh (dibuat app; status diubah device)
```

Semua koleksi anak bersifat **per perangkat** (nested di bawah `devices/{deviceId}`). Tidak ada koleksi global terpisah, tidak ada koleksi pengguna di luar path di atas.

Konsekuensi yang disengaja:

- Repo ini tidak melakukan query lintas perangkat secara default (tidak ada collection group). Laporan lintas perangkat harus dijawab dari sisi per perangkat atau dari data yang diekspor keluar aplikasi. [PERLU KONFIRMASI] apakah produk membutuhkan statistik lintas perangkat dalam satu layar; jika ya, diperlukan collection group `detections` beserta indeksnya, dan ini menaikkan biaya baca.
- Path harus dibangun lewat satu helper di `lib/core/constants/firestore_paths.dart`, bukan string path di dalam widget.

## 3. Matriks hak akses

| Path | Device | Anggota (member) | Non-anggota | Catatan peran lain |
| --- | --- | --- | --- | --- |
| `devices/{deviceId}` | create, update field telemetry | read | deny | update `members` dan `mediaLimit` hanya oleh owner (lihat bagian 6) |
| `devices/{deviceId}/detections/{id}` | create, update kecuali field validasi | read | deny | create: deny; update: hanya 3 field validasi; delete: ya |
| `devices/{deviceId}/media/{id}` | create | read | deny | create/update: deny; delete: ya |
| `devices/{deviceId}/events/{id}` | create | read | deny | create/update/delete: deny |
| `devices/{deviceId}/commands/{id}` | read, update `status`/`updatedAt`/`resultNote` | read | deny | create: ya; update/delete: deny |

## 4. Koleksi dan field

### 4.1 `devices/{deviceId}`

Satu dokumen per perangkat. ID dokumen adalah `deviceId`.

[PERLU KONFIRMASI] Format dan sumber `deviceId`. Belum ada sumber apakah ID dipilih perangkat saat pairing (QR), dihasilkan perangkat saat boot pertama, atau ditetapkan aplikasi. Konsekuensi: ID harus stabil dan tidak pernah berubah karena dipakai sebagai path dokumen anak.

| Field | Tipe | Sumber | Wajib | Deskripsi |
| --- | --- | --- | --- | --- |
| `deviceId` | string (ID dokumen) | Device | Ya | Path adalah sumber kebenaran. Bila device juga menulis field ini di dalam body, nilainya harus sama dengan ID dokumen. [PERLU KONFIRMASI] apakah body perlu menyimpan ulang `deviceId`. |
| `name` | string | Device | Ya | Nama tampilan untuk companion. [PERLU KONFIRMASI] siapa yang boleh mengubah nama. Default-nya device (agar sesuai aturan hak tulis), tetapi produk mungkin ingin rename dari app; bila begitu, aturan hak tulis harus diperluas secara eksplisit. |
| `model` | string | Device | Ya | Model perangkat. [PERLU KONFIRMASI] nilai literal yang dipakai device, karena belum ada sumber firmware. |
| `firmwareVersion` | string | Device | Tidak | Versi firmware atau software yang berjalan, ditulis saat boot. |
| `wifiSsid` | string | Device | Ya | SSID yang sedang dipakai device; dipakai untuk troubleshooting koneksi. [PERLU KONFIRMASI] boleh ditampilkan di UI dan disimpan di log, karena SSID bisa memuat nama pribadi atau alamat. |
| `lastSeen` | timestamp (server) | Device | Ya | Heartbeat. Dasar perhitungan online client-side (ambang 90 detik). Tidak boleh dipakai untuk urutan riwayat. |
| `bootCount` | int | Device | Tidak | Jumlah kali boot sejak factory reset; berguna untuk membedakan restart dari crash. |
| `batteryPct` | int (0-100) atau null | Device | Tidak | **Belum dikonfirmasi hardware.** Tim mechanical/electrical tidak mengonfirmasi adanya baterai atau cara pengukurannya, jadi jangan diasumsikan ada field ini. [PERLU KONFIRMASI] |
| `settings` | map | Device | Ya | Map pengaturan, rincian di bagian 5. |
| `members` | map (uid -> role) | App (owner) | Ya | Keanggotaan perangkat, rincian di bagian 6. Default: satu entri owner. |
| `createdAt` | timestamp (server) | Device | Ya | Waktu dokumen dibuat (server, bukan jam device). |
| `updatedAt` | timestamp (server) | Device | Ya | Waktu tulis terakhir oleh device (server). |
| `mediaLimit` | int | App (owner) | Tidak | Batas jumlah atau ukuran dokumen `media` per perangkat, untuk menjaga kuota penyimpanan. [PERLU KONFIRMASI] apakah field ini benar-benar dipakai; bila ya, default-nya belum ditetapkan. |

Field yang **tidak boleh** ada di dokumen ini (bertentangan dengan aturan 1.4): `location`, `gps`, `ip`, `macAddress`, `wifiPassword`, `serialNumber`, `bearerToken`, `firebaseToken`, dan sejenisnya. [PERLU KONFIRMASI] apakah nomor seri perlu disimpan untuk dukungan teknis; bila ya, harus diminta persetujuan owner lebih dulu.

Field yang sengaja tidak ada:

- `isOnline` atau `status`: status online dihitung client-side, tidak disimpan.
- `schemaVersion`: [PERLU KONFIRMASI] apakah perlu versi skema di dokumen untuk mendeteksi device dengan firmware lama. Bila perlu, nilainya harus ditetapkan pemilik proyek, bukan device, agar device tidak bisa mengubah aturan main sendiri.

### 4.2 `devices/{deviceId}/detections/{detectionId}`

Satu dokumen per hasil bacaan (uang atau teks). Dokumen dibuat oleh device saat pembacaan selesai.

[PERLU KONFIRMASI] Format `detectionId`. Pilihan yang masuk akal adalah ID acak yang dihasilkan device, atau ID deterministik dari timestamp dan penghitung. Keduanya harus memenuhi syarat format path Firestore (tanpa `/`, panjang wajar). Belum ada sumber, jadi jangan mengarang formatnya.

| Field | Tipe | Sumber | Wajib | Deskripsi |
| --- | --- | --- | --- | --- |
| `type` | string enum `money` atau `text` | Device | Ya | Jenis bacaan. Enum berasal dari `AGENTS.md` bagian 6 (fitur `monitoring` dan `history`). |
| `label` | string atau null | Device | `money`: ya; `text`: opsional | money: nominal yang dikenali model. text: ringkasan pendek hasil bacaan bila ada. [PERLU KONFIRMASI] daftar kelas dan nominal yang dipakai device, karena berasal dari aplikasi Kotlin lama yang belum tersedia. |
| `amount` | number (int) atau null | Device | `money`: ya; `text`: null | Nilai uang dalam satuan mata uang. [PERLU KONFIRMASI] satuan dan daftar nilai yang dipakai device. |
| `currency` | string | Device | Ya | Kode mata uang, misalnya `IDR`. [PERLU KONFIRMASI] apakah device boleh mengirim kode mata uang lain. |
| `confidence` | double (0.0 sampai 1.0) | Device | Ya | Keyakinan model. Ambang keyakinan yang dipakai untuk memutuskan "cukup untuk diucapkan" ada di sisi device dan belum dikonfirmasi; angka ambangnya bukan bagian skema ini. |
| `distanceCm` | int atau **null** | Device | Tidak | Jarak dari sensor LiDAR TF-Luna dalam sentimeter. `null` bila sensor tidak terpasang, bacaan gagal, atau nilai di luar jangkauan. Penting: map dengan nilai null harus ditangani di model (lihat `AGENTS.md` bagian 11). |
| `ocrText` | string (maks 500 karakter) atau null | Device | `text`: ya; `money`: null | Teks hasil OCR yang sudah dipotong device, dan tetap dipotong lagi di sisi app sebagai pengaman. [PERLU KONFIRMASI] apakah device atau app yang melakukan pemotongan sebagai sumber kebenaran. |
| `thumbnailId` | string atau null | Device | Tidak | ID dokumen di `media` yang berisi thumbnail. `null` bila `settings.uploadThumbnails` false atau thumbnail gagal dibuat. App memuat gambar lewat ID ini, tidak pernah lewat query. |
| `validationStatus` | string enum `pending`, `match`, `mismatch` | Device (nilai awal `pending`) / App (perubahan) | Ya | Status validasi manusia. Device hanya boleh menulis `pending` saat membuat dokumen. |
| `validatedBy` | string (uid) atau null | App | Tidak | UID pengguna yang melakukan validasi atau pembatalan validasi. `null` saat `pending`. Tidak boleh dikosongkan saat validasi dicabut supaya jejaknya tetap terlihat. [PERLU KONFIRMASI] apakah produk ingin menyimpan jejak pembatalan atau benar-benar mengosongkan field ini. |
| `validatedAt` | timestamp (server) | App | Tidak | Waktu validasi atau pembatalan. Wajib ada setiap kali `validationStatus` berubah. |
| `createdAt` | timestamp (server) | Device | Ya | Waktu bacaan tercatat, memakai jam server saat dokumen dibuat. Satu-satunya dasar pengurutan riwayat. |

Tidak ada field untuk audio atau klip suara, frame video, koordinat, atau skor YOLO mentah multi-box. Bila device butuh data debug, [PERLU KONFIRMASI] apakah metadata non-gambar (misalnya `detectionMs` atau `deviceTs`) boleh disimpan; `deviceTs` hanya boleh untuk diagnostik dan tidak boleh dipakai untuk mengurutkan.

### 4.3 `devices/{deviceId}/media/{mediaId}`

Thumbnail opsional. Koleksi ini tidak pernah di-query dengan filter atau `orderBy`: app hanya melakukan lookup satu dokumen (`media/{thumbnailId}`) saat kartu membutuhkannya, lalu menyimpan hasilnya di memori.

[PERLU KONFIRMASI] Kesesuaian ID. Saran implementasi: `mediaId` sama dengan `detectionId`. Dengan begitu penghapusan satu bacaan cukup menghapus dua dokumen tanpa query pencarian, dan tidak ada kemungkinan thumbnail yatim. Perlu dikonfirmasi apakah device bisa memakai ID yang sama untuk dua dokumen.

| Field | Tipe | Sumber | Wajib | Deskripsi |
| --- | --- | --- | --- | --- |
| `mediaId` | string (ID dokumen) | Device | Ya | Lihat catatan di atas. |
| `bytes` | string (base64) | Device | Ya | Data JPEG sebagai base64. Batas keras: panjang string maksimal 81.920 karakter, karena 60.000 byte menjadi sekitar 80.000 karakter setelah base64. |
| `mime` | string | Device | Ya | Hanya `image/jpeg` yang diizinkan; nilai lain ditolak rules. |
| `size` | int | Device | Ya | Ukuran file JPEG **sebelum** base64, dalam byte. Wajib `<= 60000`; rules memeriksa field ini dan panjang `bytes`. |
| `createdAt` | timestamp (server) | Device | Ya | Waktu dokumen dibuat. |

Catatan: yang tersimpan di `bytes` adalah data biner dalam bentuk teks base64, bukan gambar yang diunggah ke layanan lain. Batas dokumen 1 MiB jauh lebih besar dari 60 KB, sehingga batas 60 KB **wajib ditegakkan oleh rules**, bukan hanya oleh kode device. Rules tidak bisa memverifikasi bahwa `bytes` benar-benar JPEG yang valid; rules hanya memeriksa panjang, `mime`, dan `size`.

### 4.4 `devices/{deviceId}/events/{eventId}`

Log kejadian perangkat untuk halaman "Koneksi dan sinkronisasi". Ditulis hanya oleh device, dibaca hanya oleh anggota.

[PERLU KONFIRMASI] Daftar `type` dan format `message`. Enum di bawah adalah kandidat yang masuk akal untuk siklus hidup Wi-Fi, auth, dan perintah, **bukan** hasil ekstraksi dari aplikasi Kotlin lama. Jangan dibaca sebagai kontrak final.

| Field | Tipe | Sumber | Wajib | Deskripsi |
| --- | --- | --- | --- | --- |
| `eventId` | string (ID dokumen) | Device | Ya | ID acak, misalnya dengan prefix `evt_`. [PERLU KONFIRMASI] format. |
| `type` | string enum | Device | Ya | Kandidat: `boot`, `wlan_connected`, `wlan_disconnected`, `auth_failed`, `command_received`, `command_failed`, `config_changed`, `storage_low`, `sensor_error`. [PERLU KONFIRMASI] daftar final. |
| `severity` | string enum `info`, `warning`, `error` | Device | Ya | Dipakai untuk warna status di UI (abu, kuning, merah). |
| `message` | string (maks 200 karakter) | Device | Ya | Ringkasan teknis untuk companion. Harus bebas dari kredensial dan data pribadi. Batas 200 karakter adalah usulan agar log tetap ringan di kuota baca. [PERLU KONFIRMASI] panjang maksimum dan apakah teks perlu multibahasa. |
| `createdAt` | timestamp (server) | Device | Ya | Dasar pengurutan. |

Tidak boleh memuat isi `resultNote` perintah yang sensitif, SSID lengkap, atau email akun device.

### 4.5 `devices/{deviceId}/commands/{commandId}`

Antrean perintah jarak jauh. Ini satu-satunya tempat aplikasi menulis dokumen baru.

| Field | Tipe | Sumber | Wajib | Deskripsi |
| --- | --- | --- | --- | --- |
| `commandId` | string (ID dokumen) | App | Ya | ID acak, misalnya dengan prefix `cmd_`. Dibuat aplikasi, bukan device. |
| `type` | string enum `sync_now`, `speak_text`, `set_volume`, `restart`, `reprovision` | App | Ya | Daftar dari `AGENTS.md` bagian 6 (fitur `commands`). |
| `payload` | map | App | Tidak | Isi per `type`, lihat tabel di bawah. Untuk `sync_now`, `restart`, dan `reprovision`: map kosong. |
| `status` | string enum `pending`, `sent`, `acked`, `done`, `failed` | App (create dengan `pending`) / Device (transisi) | Ya | Status hanya boleh maju satu arah di sisi device: `pending` -> `sent` -> `acked` -> `done` atau `failed`. Aplikasi tidak boleh mengubah status. |
| `requestedBy` | string (uid) | App | Ya | UID pengguna yang mengirim perintah. |
| `createdAt` | timestamp (server) | App | Ya | Waktu perintah dibuat. Device mengambil antrean berdasarkan urutan ini. |
| `updatedAt` | timestamp (server) | Device | Ya | Waktu status terakhir diubah. |
| `resultNote` | string atau null | Device | Tidak | Catatan hasil eksekusi, ringkas dan tanpa rahasia. Wajib null atau kosong untuk `reprovision`. |

Isi `payload` yang diharapkan:

| `type` | Field payload | Tipe | Aturan |
| --- | --- | --- | --- |
| `sync_now` | tidak ada | map kosong | Meminta device mengirim telemetry segera. Dipakai tombol Sinkron di Beranda. |
| `speak_text` | `text` | string | Teks yang diucapkan device. [PERLU KONFIRMASI] batas panjang (usulan 200 karakter) dan apakah teks perlu validasi bahasa. |
| `set_volume` | `level` | int 0 sampai 100 | [PERLU KONFIRMASI] skala volume yang benar-benar didukung audio path perangkat. |
| `restart` | tidak ada | map kosong | Meminta restart. [PERLU KONFIRMASI] apakah perlu alasan atau audit tambahan. |
| `reprovision` | tidak ada | **wajib kosong** | Kredensial Wi-Fi **tidak pernah** ditulis ke Firestore; dikirim lewat QR code lokal (fitur `provisioning`). `payload` kosong dan `resultNote` wajib tanpa kredensial. Jika ada kebutuhan masa depan untuk menulis SSID saja, perlu [PERLU KONFIRMASI] eksplisit dari owner. |

Tidak ada field masa berlaku (`expiresAt`) karena TTL policy tidak tersedia di Spark (lihat bagian 7). Masa berlaku perintah, jika dibutuhkan, dicek client-side dan ditandai `failed` oleh device.

## 5. `devices/{deviceId}.settings`

| Field | Tipe | Sumber | Wajib | Deskripsi |
| --- | --- | --- | --- | --- |
| `settings.uploadThumbnails` | bool | Device | Ya | Opt-in thumbnail. **Default `false`.** Hanya bila `true`, device boleh membuat dokumen `media`. Nama kunci ini sudah ditetapkan di `AGENTS.md` dan tidak boleh diganti. |
| `settings.uploadText` | bool | Device | Ya | Opt-in pengiriman `ocrText` ke cloud. Default **[PERLU KONFIRMASI]**. Default yang aman adalah `false`, tetapi jika aplikasi Kotlin lama selalu mengirim teks, ini berbeda dan harus dikonfirmasi sebelum kompatibilitas rusak. |

Map `settings` sengaja dibuat kecil. Jangan menambah pengaturan perangkat di sini tanpa persetujuan: setiap field baru adalah kontrak baru dengan firmware.

## 6. Roles dan keanggotaan

Peran yang direncanakan: `owner`, `editor`, `viewer`.

> **[PERLU KONFIRMASI]** Daftar role final belum ditetapkan oleh owner produk. Untuk Security Rules saat ini **hanya bedakan `member` versus non-member**. Pembedaan tiga peran baru dilakukan setelah owner mengesahkan daftar perannya, nama kuncinya, dan siapa yang boleh mengganti peran siapa. Sampai itu, jangan menulis kode yang membaca `members/{uid}` sebagai sumber kebenaran peran di sisi aplikasi.

| Peran | Kewenangan yang direncanakan | Status |
| --- | --- | --- |
| `owner` | device pertama, kelola `members`, kirim semua perintah, hapus deteksi, mengubah `mediaLimit` | [PERLU KONFIRMASI] |
| `editor` | validasi (match atau mismatch), kirim perintah biasa, hapus deteksi | [PERLU KONFIRMASI] |
| `viewer` | baca saja | [PERLU KONFIRMASI] |

Masalah yang harus diputuskan (semua `[PERLU KONFIRMASI]`):

1. **Siapa menulis `members`?** Aturan hak tulis di `AGENTS.md` tidak menyertakan update map `members`, padahal keanggotaan harus bisa dibuat dari app (QR pairing atau undangan). Solusi yang paling mungkin: hanya `owner` boleh `update` field `members` dan `mediaLimit`, dan itu adalah satu-satunya pengecualian terhadap daftar hak tulis app. Perlu persetujuan owner karena ini memperluas aturan.
2. **Bagaimana anggota pertama masuk?** Apakah device yang menulis `members` berisi UID akun pairing, atau companion pertama yang menambahkan dirinya lewat QR. [PERLU KONFIRMASI]
3. **Model penyimpanan.** Saat ini `members` berupa map uid ke role. Alternatif: array `memberUids` untuk query `array-contains` yang lebih murah. [PERLU KONFIRMASI] pilihannya.
4. **Batas anggota per perangkat** (usulan maksimal 10) untuk menjaga kuota; perlu ditetapkan.

**Kendala platform yang perlu diketahui:** custom claim (`request.auth.token.*`) hanya bisa diisi dari server dengan Admin SDK. Plan Spark tidak menyediakan Cloud Functions maupun tempat aman untuk Admin SDK, sehingga role harus diekspresikan di **data Firestore**, bukan di token. Konsekuensi: siapa pun yang bisa menulis dokumen `devices` (yaitu device, atau app bila pengecualian pada poin 1 disetujui) bisa memalsukan keanggotaan, dan ini harus disadari saat menyetel rules.

## 7. Kuota free tier dan strategi

### 7.1 Batas plan Spark (Cloud Firestore)

| Sumber daya | Kuota gratis |
| --- | --- |
| Penyimpanan | 1 GiB total |
| Pembacaan dokumen | 50.000 per hari |
| Penulisan dokumen | 20.000 per hari |
| Penghapusan dokumen | 20.000 per hari |
| Transfer keluar | 10 GiB per bulan |

Catatan:

- Kuota direset setiap hari, tengah malam waktu Pasifik. Di luar kuota gratis, layanan dihentikan untuk sisa bulan (Spark tidak menambah tagihan).
- Query agregasi (`count()`) ditagih **1 baca per batch hingga 1.000 index entry** (minimum 1 baca), bukan 1 baca per dokumen.
- Snapshot (`snapshots()`) ditagih 1 baca untuk hasil awal, lalu 1 baca **per dokumen yang benar-benar berubah**. Dokumen yang tidak berubah tidak menambah biaya, dan ini alasan listener dipakai untuk monitoring near-realtime.
- Kuota gratis hanya berlaku untuk satu database Firestore per project.

### 7.2 Batas yang paling menekan: penulisan heartbeat

Heartbeat 30 detik berarti 2.880 penulisan per hari **per perangkat** bila `lastSeen` ditulis setiap 30 detik. Dengan 20.000 penulisan per hari, satu perangkat saja menghabiskan sekitar 14 persen kuota harian.

| Skenario per hari | 1 perangkat | 3 perangkat | 5 perangkat |
| --- | --- | --- | --- |
| Heartbeat 30 detik | 2.880 | 8.640 | 14.400 |
| Heartbeat 60 detik | 1.440 | 4.320 | 7.200 |
| Heartbeat 120 detik | 720 | 2.160 | 3.600 |

Catatan: heartbeat 120 detik membuat ambang 90 detik tidak bisa dipakai apa adanya (device akan berkedip online dan offline), jadi memilih 120 detik memerlukan hysteresis di `deriveConnectivity`, dan itu perubahan kontrak yang harus dikonfirmasi owner.

Rekomendasi: **tulis `lastSeen` tidak lebih cepat dari 60 detik** (tetap di bawah ambang 90 detik), dan tetapkan batas jumlah perangkat aktif yang dituju. [PERLU KONFIRMASI] berapa perangkat yang harus didukung simultan di kelas produksi, karena parameter ini menentukan biaya utama.

### 7.3 Aturan query yang mengikat

1. Setiap query di UI wajib punya `limit()`. Default: Beranda dan recent activity 10, Validasi 20, Riwayat 20 per halaman, Event 50, Command 20.
2. Riwayat memakai paginasi `startAfterDocument()`; app tidak pernah mengambil seluruh riwayat.
3. Badge dan persentase akurasi memakai `count()`, bukan download dokumen. Contoh: filter `validationStatus == 'match'` lalu `count()`.
4. Thumbnail hanya diambil per kartu yang terlihat, lewat lookup dokumen tunggal; query daftar tidak pernah download gambar.
5. Ringkasan harian memakai agregasi pada rentang `createdAt`, bukan iterasi dokumen.
6. `StreamProvider` harus `autoDispose`, dan provider `tick` (15 detik) hanya memicu penilaian konektivitas ulang di memori, bukan query baru.
7. Fan-out per detik harus dihindari: satu perangkat dengan heartbeat 60 detik dan satu listener per anggota akan menagih 1 baca per perubahan dokumen, yang masih wajar, tetapi menambah anggota berarti menambah aliran baca untuk dokumen yang sama. [PERLU KONFIRMASI] jumlah anggota maksimal per perangkat (poin 4 di bagian 6).

### 7.4 Penyimpanan dan retensi

1 GiB itu kecil. Dengan asumsi thumbnail 60.000 byte, 1 GiB habis oleh sekitar 17.000 thumbnail. Karena TTL policy **tidak didukung** di Spark, tidak ada auto-delete; opsi yang ada:

- device menghapus deteksi lamanya sendiri (device boleh menghapus dokumen miliknya sendiri) - [PERLU KONFIRMASI] apakah device diizinkan menghapus `detections` dan `media` miliknya, dan dengan aturan apa;
- atau aplikasi menghapus manual dari Riwayat (use case `DeleteDetection` sudah direncanakan).

[PERLU KONFIRMASI] kebijakan retensi per perangkat (jumlah hari atau jumlah maksimum dokumen). Tanpa ini, kuota 1 GiB akan habis pada device yang aktif lama.

## 8. Indeks yang dibutuhkan

Firestore menyediakan indeks single-field otomatis, sehingga indeks composite hanya perlu untuk kombinasi filter dengan `orderBy`. Tabel di bawah adalah daftar **final** yang harus dicerminkan persis oleh `firebase/firestore.indexes.json`. Bila perubahan skema membuat tabel ini berubah, kedua file harus diubah dalam satu changeset yang sama.

| # | Collection path | Filter | `orderBy` | Composite | Pemakai |
| --- | --- | --- | --- | --- | --- |
| 1 | `devices/{deviceId}/detections` | `validationStatus == 'pending'` | `createdAt DESC` | ya | `WatchPendingDetections` (halaman Validasi) |
| 2 | `devices/{deviceId}/detections` | `validationStatus == 'match'` | `createdAt DESC` | ya | `GetAccuracy` lewat `count()` |
| 3 | `devices/{deviceId}/detections` | `validationStatus == 'mismatch'` | `createdAt DESC` | ya | `GetAccuracy` lewat `count()` |
| 4 | `devices/{deviceId}/detections` | `type == 'money'` | `createdAt DESC` | ya | filter jenis di Riwayat |
| 5 | `devices/{deviceId}/detections` | `type == 'text'` | `createdAt DESC` | ya | filter jenis di Riwayat |
| 6 | `devices/{deviceId}/detections` | `type` plus `validationStatus` | `createdAt DESC` | ya | filter gabungan di Riwayat |
| 7 | `devices/{deviceId}/events` | `severity == 'warning'` atau `'error'` | `createdAt DESC` | ya | filter severity di layar Koneksi dan sinkronisasi |
| 8 | `devices/{deviceId}/commands` | `status == 'pending'` | `createdAt ASC` | ya | device mengambil antrean; app memantau status |

Yang **tidak** butuh composite (single-field otomatis):

- `devices` dengan filter `members.<uid> != null`, atau `memberUids array-contains` bila model array dipilih, untuk daftar perangkat milik pengguna.
- `detections` dengan `orderBy createdAt DESC` saja dan `limit(n)`, untuk recent activity.
- `detections` dengan `createdAt >= <timestamp>` dan `orderBy createdAt`, untuk ringkasan harian (satu field).
- `commands` dengan `orderBy createdAt DESC` saja, untuk riwayat perintah.
- `events` dengan `orderBy createdAt DESC` saja, untuk daftar event terbaru.
- `count()` tanpa `orderBy`.

Belum ada collection group query. Bila nanti ditambahkan `collectionGroup('detections')`, misalnya untuk statistik lintas perangkat, indeks tambahan harus dibuat dan biaya baca dievaluasi ulang.

## 9. Inventaris Security Rules

Rules berada di `firebase/firestore.rules` dengan pola deny-by-default. Kode rules penuh tidak ditulis di dokumen ini; yang dicatat adalah cakupan yang harus ada dan kasus uji yang wajib lulus di emulator.

Helper (nama final boleh berbeda, cakupannya wajib ada):

| Helper | Tanggung jawab |
| --- | --- |
| signed in | `request.auth` tidak null |
| device doc | reference ke `devices/{deviceId}` |
| is member / is owner / is editor | membaca `members` pada dokumen perangkat |
| is device | [PERLU KONFIRMASI] skema otorisasi device, lihat bagian 11 |
| valid enum | validasi nilai enum (tipe deteksi, severity, status command, peran) |
| valid thumbnail | `mime == 'image/jpeg'`, `size <= 60000`, panjang `bytes <= 81920` |
| only keys changed | `affectedKeys().hasOnly([...])` untuk membatasi update |

Aturan yang harus ada:

1. Tolak semua akses yang tidak cocok secara default, termasuk koleksi tak dikenal.
2. Baca hanya oleh anggota; non-anggota (termasuk pengguna yang hanya login) tidak bisa membaca apa pun.
3. Penulisan device hanya pada `devices`, `detections`, `events`, dan `media` miliknya sendiri, dan hanya field yang diizinkan. Device tidak boleh menyentuh `members` atau `mediaLimit`.
4. Device tidak boleh membuat dokumen `commands` dan tidak boleh mengubah `requestedBy`.
5. Anggota tidak boleh membuat `detections`, `media`, atau `events`.
6. Anggota hanya boleh `update` `detections` dengan `affectedKeys().hasOnly(['validationStatus', 'validatedBy', 'validatedAt'])`.
7. Anggota hanya boleh menghapus `detections` dan `media`; tidak boleh menghapus `devices` atau `events`.
8. Nilai enum divalidasi di rules: `validationStatus` hanya `pending`, `match`, `mismatch`; `severity` hanya `info`, `warning`, `error`; `type` command hanya dari daftar yang disepakati.
9. `validationStatus` harus bernilai `pending` saat dokumen deteksi pertama dibuat.
10. Panjang `ocrText` maksimal 500 karakter ditegakkan di rules.
11. `media` hanya boleh dibuat bila `devices/{deviceId}.settings.uploadThumbnails` bernilai `true`, dan `mime`, `size`, serta `bytes` memenuhi batas thumbnail.
12. Transisi status `commands` hanya maju satu arah dan hanya oleh device.
13. Field kredensial ditolak di mana pun: nama field yang menyerupai `password`, `token`, atau `secret` tidak boleh muncul di `commands.payload` maupun `events.message`. [PERLU KONFIRMASI] rules hanya bisa memeriksa nama field, bukan isi, jadi daftar nama field yang diizinkan harus ditetapkan eksplisit sebagai allow-list.
14. Pendaftaran anggota (`update members` oleh owner) - [PERLU KONFIRMASI] apakah ini menjadi satu-satunya pengecualian (lihat bagian 6, poin 1).

Kasus uji emulator yang wajib ada (dari `AGENTS.md` bagian 11, ditambah turunan dari aturan di atas):

- anggota bisa read semua koleksi di perangkatnya;
- non-anggota ditolak saat read;
- device hanya bisa menulis key yang diizinkan; mencoba menulis `members` ditolak;
- anggota tidak bisa membuat deteksi;
- anggota tidak bisa mengubah `label`, `amount`, atau `ocrText`;
- anggota tidak bisa menghapus `devices` atau `events`;
- `media` dengan `size` lebih dari 60.000 atau `mime` bukan `image/jpeg` ditolak;
- `media` ditolak saat `settings.uploadThumbnails` bernilai `false`;
- `ocrText` lebih dari 500 karakter ditolak;
- transisi status `commands` yang mundur ditolak;
- `payload` yang memuat nama field kredensial ditolak.

## 10. Checklist security dan privacy

Sebelum rilis, setiap item harus bisa dibuktikan lewat test emulator, review rules, atau review UI:

- [ ] Tidak ada field lokasi atau GPS di dokumen mana pun.
- [ ] Tidak ada video, audio, atau gambar resolusi penuh di Firestore.
- [ ] Thumbnail hanya JPEG, `size` maksimal 60.000 byte, hanya saat opt-in aktif.
- [ ] `ocrText` dipotong 500 karakter sebelum ditulis; UI share menampilkan peringatan data pribadi sebelum share.
- [ ] Kredensial Wi-Fi hanya lewat QR lokal; tidak pernah masuk `commands.payload`, `events.message`, atau log aplikasi.
- [ ] Tidak ada token, refresh token, atau email penuh di log aplikasi; `firebase_options.dart` diperlakukan sebagai identifier, bukan rahasia.
- [ ] Status online tidak pernah diambil dari field tersimpan.
- [ ] `validatedBy` hanya berisi UID, bukan email atau nama.
- [ ] Query non-anggota ditolak rules, dan daftar `members` bisa diaudit.
- [ ] Semua query UI punya `limit()`; tidak ada listener yang tidak `autoDispose`.
- [ ] Ada retensi untuk `detections` dan `media` agar 1 GiB tidak habis.
- [ ] Device lama yang tidak kompatibel dengan skema baru tidak ditolak rules (kompatibilitas mundur); perubahan rules harus additive atau bersamaan dengan update firmware.
- [ ] Skema ini, `firestore.rules`, `firestore.indexes.json`, model Dart beserta test, dan `docs/device_protocol.md` diubah dalam satu changeset bila ada perubahan skema.

## 11. Bagian yang perlu dikonfirmasi owner

Dikelompokkan per dampak. Setiap `[PERLU KONFIRMASI]` di dokumen ini berasal dari salah satu pertanyaan di bawah.

**A. Identitas dan pairing (paling kritis, memblokir rules)**

1. Bagaimana device terautentikasi dan dikenali oleh rules? [PERLU KONFIRMASI] Custom claim butuh Admin SDK yang tidak ada di Spark, jadi diperlukan skema berbasis data: kredensial Firebase Auth khusus per device, `authUid` di dokumen perangkat, atau daftar UID device yang disimpan di Firestore. Sumber materi aplikasi Kotlin lama belum ada, sehingga skema yang cocok dengan device lama tidak bisa dipastikan.
2. Bagaimana proses pairing pertama, dan siapa yang menulis `members` pertama kali (bagian 6)? Apakah `owner` boleh mengubah `members` sebagai satu-satunya pengecualian aturan hak tulis app?
3. Konfirmasi `deviceId`: siapa yang menetapkan, formatnya apa, dan apakah boleh berubah.

**B. Device dan firmware**

4. Daftar nilai `model` dan `firmwareVersion` yang tersedia; apakah ada field versi lain (versi app atau software, versi board) yang dibutuhkan.
5. [PERLU KONFIRMASI] Benar atau tidak adanya baterai dan pengukuran `batteryPct`. Tim mechanical/electrical belum mengonfirmasi, jadi jangan diasumsikan.
6. Apakah `bootCount` memang dibutuhkan, dan apakah device boleh menghapus `detections` atau `media` miliknya sendiri untuk retensi.
7. Nama dan nilai resmi `type` event serta batas panjang `message`.

**C. Deteksi dan validasi**

8. Daftar nominal dan kelas uang yang dipakai model, satuan mata uang, serta daftar nilai `currency` yang diizinkan.
9. Ambang `confidence` yang dipakai device, dan apakah field ini perlu ditampilkan di app.
10. `ocrText`: apakah device atau app yang memotong 500 karakter sebagai sumber kebenaran.
11. Kebijakan pembatalan validasi: `validatedBy` dan `validatedAt` disimpan sebagai jejak atau di-null-kan (bagian 4.2).
12. Format `detectionId`, dan apakah `mediaId` sama dengan `detectionId` disetujui (bagian 4.3).

**D. Kontrol jarak jauh**

13. Batas panjang `speak_text`, skala `level` untuk `set_volume`, dan apakah `restart` perlu alasan atau audit.
14. Konfirmasi bahwa `reprovision` tidak pernah membawa kredensial di Firestore, dan bentuk `payload` yang diharapkan device (sudah diasumsikan kosong, perlu konfirmasi).
15. Daftar nama field `payload` yang diizinkan per `type`, untuk allow-list rules.

**E. Kuota, retensi, dan free tier**

16. Jumlah perangkat aktif yang harus didukung simultan (bagian 7.2), yang menentukan interval heartbeat yang aman.
17. Jumlah anggota maksimal per perangkat.
18. Kebijakan retensi `detections` dan `media` (bagian 7.4), mengingat TTL tidak tersedia di Spark.
19. Apakah statistik lintas perangkat dibutuhkan; bila ya, collection group dan dampaknya ke kuota.

**F. Produk dan dokumen**

20. Konfirmasi peran final `owner`, `editor`, `viewer`, nama kuncinya, dan siapa boleh mengganti peran (bagian 6).
21. Default `settings.uploadText` (bagian 5), yang menentukan apakah kompatibilitas dengan device lama terjaga.
22. Pergantian nama `name` perangkat dari app: perlu atau tidak, karena berdampak ke aturan hak tulis.
23. Apakah `schemaVersion` diperlukan untuk mendeteksi firmware lama.
24. Isi `PRD.md` yang sebenarnya (prioritas P0/P1/P2 dan anggaran kuota yang dirujuk `AGENTS.md`) supaya dokumen ini bisa diverifikasi silang.
