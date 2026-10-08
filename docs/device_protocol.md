# Protokol Perangkat - SiGap Netra

Dokumen ini menjelaskan bagaimana perangkat Sipeed MaixCAM (MaixPy / Python)
berkomunikasi dengan Cloud Firestore lewat REST API, dan bagaimana kredensial
Wi-Fi dikirim ke perangkat lewat QR code.

Status dokumen: DRAFT. Sebagian hal belum diputuskan dan ditandai
`[PERLU KONFIRMASI]`. Dokumen ini tidak boleh dipakai sebagai spesifikasi final
sebelum owner mengonfirmasi poin di bagian 11.

Dokumen terkait:

- `AGENTS.md` - prinsip produk, aturan git, batasan.
- `PRD.md` - masih DRAFT/KOSONG. Anggaran kuota resmi belum ada di sana.
- `docs/firestore_schema.md` - definisi tunggal collection, field, dan tipe.
- `firebase/firestore.rules` - otorisasi.
- `device/AGENTS.md` - aturan tambahan untuk kode di `device/`.

Semua fakta API di bawah diverifikasi terhadap discovery document resmi
Firestore v1 (`https://firestore.googleapis.com/$discovery/rest?version=v1`).
Hal yang tidak terverifikasi atau belum diputuskan ditandai eksplisit.

---

## 1. Prinsip: keselamatan offline dulu

Aturan utama produk (AGENTS.md bagian 3): **fungsi inti perangkat (deteksi lalu
bicara) WAJIB berjalan dengan nol internet.** Cloud hanya telemetri dan monitoring.

Konsekuensi teknis yang mengikat desain protokol:

1. **Tidak ada perintah yang boleh memblokir jalur bicara.** Pembacaan QR Wi-Fi,
   heartbeat, upload deteksi, dan polling perintah adalah proses latar.
   Kegagalan semua proses jaringan tidak boleh menghentikan `detector`, `ocr`,
   `lidar`, `fusion`, atau `audio`.
2. **Tidak ada dependensi cloud untuk keputusan keselamatan.** Ambang jarak
   LiDAR, ambang confidence YOLO, dan pemotongan teks OCR adalah keputusan lokal
   di perangkat, bukan hasil query Firestore.
3. **Perangkat harus bisa hidup tanpa kredensial cloud yang valid.** Kredensial
   yang hilang atau kedaluwarsa hanya menurunkan kemampuan telemetri, bukan
   fungsi utama.
4. **Perangkat boleh gagal dengan diam.** Kesalahan jaringan tidak boleh
   menghasilkan suara berulang atau mengganggu pengguna.
5. **Cloud bukan sumber kebenaran untuk keputusan.** Jam perangkat tidak
   dipercaya untuk pengurutan maupun penentuan status online (lihat bagian 2).

Tidak ada fitur baru yang boleh memasukkan cloud ke jalur critical path. Setiap
fitur yang bergantung pada cloud harus punya fallback lokal.

---

## 2. Kontrak `lastSeen` dan heartbeat

### 2.1 Nilai kontrak

| Parameter | Nilai | Sumber |
| --- | --- | --- |
| Interval heartbeat | 30 detik | AGENTS.md bagian 7 |
| Ambang "online" | 90 detik | AGENTS.md bagian 7 |
| Perhitungan | Client-side, di app | AGENTS.md bagian 7 |
| Sumber kebenaran | Waktu server, bukan jam perangkat | AGENTS.md bagian 7 |

Perangkat dianggap **online** bila `now - lastSeen < 90 detik`. Ambang 90 detik
memberi ruang untuk tiga heartbeat yang hilang (dua heartbeat hilang = 60 detik,
masih dianggap online).

### 2.2 Siapa yang menulis `lastSeen`

`devices/{deviceId}` **hanya boleh ditulis oleh perangkat** (AGENTS.md bagian 7).
App tidak pernah menulis field heartbeat.

Ada dua kandidat implementasi yang **harus dipilih owner**.

**Opsi A - `lastSeen` sebagai server timestamp.**
Perangkat menulis `lastSeen` memakai nilai waktu server.

**Opsi B - `lastSeen` sebagai jam perangkat.**
Perangkat menulis waktu lokal ISO-8601 milidetik sebagai `timestampValue`.

Perbedaan penting:

- Opsi A membutuhkan server transform. `PATCH` biasa **tidak bisa** menulis
  server timestamp. Yang bisa adalah endpoint `documents:commit` dengan `Write`
  berisi `transform` atau `updateTransforms` dan `setToServerValue: REQUEST_TIME`.
  Ini menambah satu request per heartbeat.
- Opsi B murahan dan satu request, tetapi jam perangkat bisa menyimpang jauh
  sehingga status online bisa salah (false online maupun false offline).

**Rekomendasi teknis, belum diputuskan: pakai Opsi A, dan sekaligus bersandarkan
perhitungan status online pada `Document.updateTime`.**

Alasannya:

- `Document.updateTime` adalah field yang dihasilkan server pada setiap dokumen
  Firestore, selalu tersedia di respons REST, dan tidak perlu ditulis eksplisit.
- Tidak ada field yang bisa dimanipulasi oleh perangkat yang salah jam.
- Satu `PATCH` sederhana per heartbeat sudah cukup, tanpa perlu `commit`.
- `updateTime` juga naik saat perangkat menulis dokumen lain, misalnya status
  perintah, yang memang bukti perangkat hidup.

Konsekuensi dari andalkan `updateTime`:

- `updateTime` adalah batas atas kesegaran, bukan deteksi heartbeat khusus.
- Bila perangkat hanya membaca, misalnya polling perintah tanpa menulis apa pun,
  `updateTime` tidak naik. Karena itu heartbeat berkala tetap wajib ditulis.
- `updateTime` juga naik bila orang lain menulis dokumen `devices/{deviceId}`.
  Rules sebaiknya melarang app menulis dokumen device agar sinyal ini tetap
  bersih. [PERLU KONFIRMASI]

Pertanyaan untuk owner:

- Opsi A atau Opsi B?
- Jika Opsi A: apakah satu `commit` tambahan per heartbeat setiap 30 detik
  diterima di sisi kuota dan latency?

### 2.3 Bentuk heartbeat

Endpoint dan bentuk request ada di bagian 4.1 dan 4.4.1.

Batasan yang harus dihormati:

- Heartbeat **tidak boleh** berisi data pengguna, gambar, atau lokasi.
- Heartbeat hanya boleh berisi field status atau teknis yang disetujui di
  `docs/firestore_schema.md`. Daftar field persisnya belum ditetapkan.
  [PERLU KONFIRMASI]
- Bila `lastSeen` sudah terisi dan berumur kurang dari 30 detik, heartbeat
  berikutnya boleh dilewati. Ini mencegah ledakan write setelah perangkat lama
  offline lalu tersambung kembali.

### 2.4 Beban kuota heartbeat

Heartbeat 30 detik berarti **2.880 write per hari per perangkat** bila `lastSeen`
ditulis setiap 30 detik. Kuota free tier adalah 20.000 write per hari dan 50.000
read per hari.

| Skenario per hari | 1 perangkat | 3 perangkat | 5 perangkat |
| --- | --- | --- | --- |
| Heartbeat 30 detik | 2.880 | 8.640 | 14.400 |
| Heartbeat 60 detik | 1.440 | 4.320 | 7.200 |
| Heartbeat 120 detik | 720 | 2.160 | 3.600 |

Porsi dari kuota 20.000 write per hari: heartbeat 30 detik menghabiskan sekitar 14
persen dengan satu perangkat, dan lebih dari 100 persen pada tujuh perangkat.

Heartbeat adalah penyumbang write terbesar, bukan deteksi. Ini harus dibahas
dengan owner:

- `docs/firestore_schema.md` bagian 7.2 merekomendasikan menulis `lastSeen`
  **tidak lebih cepat dari 60 detik**, tetap di bawah ambang 90 detik.
- Heartbeat 120 detik membuat ambang 90 detik tidak bisa dipakai apa adanya,
  karena perangkat akan berkedip online dan offline. Memilihnya memerlukan
  hysteresis di `deriveConnectivity`, dan itu perubahan kontrak.
- Interval 30 detik berasal dari AGENTS.md bagian 7, sedangkan rekomendasi skema
  menyebut 60 detik. **Perbedaan ini harus diputuskan owner.** [PERLU KONFIRMASI]
- Jumlah perangkat aktif yang harus didukung simultan juga belum ditetapkan, dan
  parameter itu menentukan biaya utama. [PERLU KONFIRMASI]
- Anggaran kuota resmi di PRD bagian 9 belum ada karena PRD masih DRAFT.
  [PERLU KONFIRMASI]

---

## 3. Autentikasi perangkat (BELUM DIPUTUSKAN)

Bagian ini sengaja tidak punya jawaban final. Semua opsi punya konsekuensi
keamanan, operasional, atau kuota yang berbeda. Pilihan akhir harus dikonfirmasi
owner.

### 3.1 Konteks

- MaixCAM menjalankan MaixPy (Python). **Tidak ada Firebase SDK resmi untuk
  MaixPy.**
- Perangkat harus otentikasi ke Firestore REST memakai OAuth 2.0 bearer token.
- Plan yang dipilih adalah Spark (free). Cloud Functions tidak boleh digunakan
  tanpa persetujuan owner.

### 3.2 Opsi yang tersedia

| Opsi | Mekanisme | Kelebihan | Risiko dan konsekuensi |
| --- | --- | --- | --- |
| **A. Service account email plus private key di perangkat** | Perangkat membuat JWT (RS256) sendiri lalu menukar access token ke `https://oauth2.googleapis.com/token` dengan `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer` dan scope `https://www.googleapis.com/auth/datastore`. Setiap request memakai header `Authorization: Bearer`. | Standar dan didokumentasi Google. Mudah direvoke. | Private key tersimpan di perangkat yang hilang atau dicuri berarti kebocoran. Signing RS256 butuh pustaka kripto di MaixPy yang belum tentu ada. Menempelkan satu key service account yang sama ke banyak perangkat. |
| **B. Service account per perangkat** | Sama seperti A, tetapi satu akun khusus per unit, dengan daftar device yang boleh diakses. | Kompromi satu unit tidak membuka semua data. Hak akses bisa dibatasi per unit. | Lebih banyak akun yang harus dikelola. Provisioning lebih repot. Aturan device harus konsisten dengan rules. |
| **C. API key saja tanpa OAuth** | Menambahkan `key=<WEB_API_KEY>` pada REST call. | Tidak ada private key di perangkat. Implementasi paling sederhana. | Akses menjadi tidak terautentikasi. Rules harus mengizinkan akses tanpa login sehingga data anggota tidak bisa dilindungi dengan benar. Tidak sesuai prinsip deny-by-default (AGENTS.md bagian 9). Tidak direkomendasikan. |
| **D. Token access yang direfresh di luar perangkat** | Mesin PC atau telepon menukar JWT dan menulis access token berumur pendek ke perangkat lewat file lokal atau QR. | Tidak ada private key di perangkat. Signing terjadi di mesin yang punya pustaka kripto. | Butuh proses di luar perangkat untuk refresh. Token bisa kedaluwarsa saat perangkat tanpa pengawasan. Menambah komponen operasional. |
| **E. Relay di server sendiri** | Perangkat bicara ke endpoint milik sendiri yang menjembatani ke Firestore. | Perangkat tidak memegang kredensial Google sama sekali. | Memerlukan layanan yang berjalan terus (server, PC, atau VPS). Bertentangan dengan rencana free tier dan menambah permukaan serang. Tidak direkomendasikan tanpa persetujuan owner. |

Catatan tambahan per opsi:

- Opsi C memerlukan konfirmasi apakah Firebase masih mengizinkan pola ini, dan
  bagaimana rules akanmehprevent akses data anggota. [PERLU KONFIRMASI]
- Opsi A dan B memerlukan konfirmasi apakah MaixPy sudah punya pustaka RSA yang
  bisa menandatangani JWT, dan boleh installsikan paket di perangkat atau tidak.
  [PERLU KONFIRMASI]

### 3.3 Aturan yang berlaku pada semua opsi

- **Private key, service-account JSON, dan refresh token tidak boleh masuk repo.**
  Hanya `device/config.example.py` yang di-commit (AGENTS.md bagian 9). File
  kredensial asli harus masuk `.gitignore`.
- Device **tidak boleh** menulis password Wi-Fi, token, atau kredensial apa pun ke
  Firestore.
- Otorisasi harus membedakan **device** dari **app member**. Device dikenali lewat
  identitas OAuth-nya, app member lewat UID Firebase Auth.
  `docs/firestore_schema.md` bagian 3 sudah membedakan keduanya di matriks hak
  akses, dan bagian 6 mendefinisikan `members` sebagai map uid ke role. Yang
  **belum ada** adalah cara rules mengenali identitas device secara spesifik dan
  mengikatnya ke `deviceId` yang benar, sehingga satu device tidak bisa menulis
  dokumen device lain. [PERLU KONFIRMASI]
- Device hanya boleh menulis path di bawah `devices/{deviceId}/miliknya sendiri`,
  ditambah dokumen `devices/{deviceId}` itu sendiri. Tidak ada koleksi global
  di luar hierarki itu, jadi tidak ada path lain yang boleh disentuh.
- Device **tidak boleh** menulis map `members` maupun `mediaLimit`. Berdasarkan
  skema, keduanya ditulis oleh App. Map `members` sendiri masih jadi pertanyaan
  terbuka di skema bagian 6, karena aturan hak tulis di AGENTS.md tidak
  menyertakannya. [PERLU KONFIRMASI]

### 3.4 Yang harus dikonfirmasi owner

- Pilih Opsi A, B, C, D, atau E.
- Apakah private key boleh berada di perangkat (Opsi A dan B), atau ditolak
  karena risiko kebocoran?
- Berapa masa berlaku access token yang akan dipakai perangkat, dan bagaimana
  cara perangkat mengambil token baru tanpa campur adegan UI pengguna?

---

## 4. Kontrak REST Firestore

### 4.1 Base URL dan endpoint

Base URL dari discovery document v1:

```
https://firestore.googleapis.com/v1
```

Endpoint yang relevan untuk perangkat:

| Operasi | HTTP | Path |
| --- | --- | --- |
| Baca satu dokumen | `GET` | `/v1/{document.name}` |
| Tulis atau upsert satu dokumen | `PATCH` | `/v1/{document.name}` |
| Buat dokumen dengan ID tertentu | `POST` | `/v1/{parent}/{collectionId}?documentId={id}` |
| Batch read | `POST` | `/v1/{database}/documents:batchGet` |
| Query satu kali | `POST` | `/v1/{parent}:runQuery` |
| Batch write atomik | `POST` | `/v1/{database}/documents:commit` |
| List subcollection | `GET` | `/v1/{parent}/{collectionId}` |

Bentuk `document.name`:

```
projects/{projectId}/databases/(default)/documents/devices/{deviceId}
projects/{projectId}/databases/(default)/documents/devices/{deviceId}/detections/{detectionId}
projects/{projectId}/databases/(default)/documents/devices/{deviceId}/media/{mediaId}
projects/{projectId}/databases/(default)/documents/devices/{deviceId}/events/{eventId}
projects/{projectId}/databases/(default)/documents/devices/{deviceId}/commands/{commandId}
```

`{projectId}` adalah placeholder. Nilai sebenarnya harus diisi owner dan hanya
muncul sebagai placeholder di `device/config.example.py`. [PERLU KONFIRMASI]

### 4.2 Batasan penting: `listen` tidak tersedia lewat REST

Discovery document v1 menyatakan untuk method `listen`:

> This method is only available via gRPC or WebChannel (not REST).

Artinya **perangkat tidak bisa memakai Firestore realtime listener**. Perangkat
harus melakukan polling periodik memakai `runQuery` atau `batchGet`. Ini fakta
API, bukan pilihan desain.

App (Flutter) tetap memakai SDK resmi dan `snapshots()` seperti biasa.
Keterbatasan ini hanya berlaku untuk perangkat.

Interval polling perintah harus ditetapkan agar tidak memboroskan kuota read.
[PERLU KONFIRMASI]

### 4.3 Encoding nilai (tipe `Value`)

Firestore REST memakai JSON dengan pembungkus tipe eksplisit. Tipe yang relevan,
diambil dari schema `Value` pada discovery document v1:

| Tipe | Bentuk JSON | Catatan |
| --- | --- | --- |
| String | `{"stringValue": "..."}` | |
| Integer | `{"integerValue": "42"}` | Diserialisasi sebagai **string**, bukan angka JSON. |
| Double | `{"doubleValue": 42.5}` | Dikirim sebagai representasi string float. |
| Boolean | `{"booleanValue": true}` | |
| Null | `{"nullValue": null}` | |
| Timestamp | `{"timestampValue": "2026-01-01T00:00:00.000000Z"}` | RFC-3339, presisi mikrodetik. |
| Bytes | `{"bytesValue": "<base64>"}` | Dipakai untuk thumbnail JPEG. |
| Array | `{"arrayValue": {"values": [...]}}` | |
| Map | `{"mapValue": {"fields": {"k": {...}}}}` | |

Contoh satu field:

```json
{
  "fields": {
    "lastSeen": { "timestampValue": "2026-01-01T00:00:00.000000Z" }
  }
}
```

Gotcha implementasi yang harus diuji di perangkat: `integerValue` dan
`doubleValue` datang sebagai string. Parser Python tidak boleh mengasumsikan
tipe angka secara buta. Tulis parser dan unit test-nya di
`device/tests/test_firebase_client.py`.

Batas ukuran `bytesValue` pada Standard edition, dari discovery document: nilai
tidak boleh melebihi **1 MiB - 89 byte**. Batas aplikasi kita lebih ketat
(thumbnail maksimal 60 KB), jadi aman.

### 4.4 Bentuk dokumen per collection

**Definisi field, tipe, dan enum di `docs/firestore_schema.md` adalah sumber
kebenaran.** Tabel di bawah hanya rangkuman dari sudut pandang perangkat, yaitu
field mana yang boleh ditulis perangkat dan bagaimana cara menulisnya lewat REST.
Kalau tabel di sini berbeda dengan `docs/firestore_schema.md`, maka yang
benar adalah skema dan dokumen ini yang salah.

Kolom "Penulis" menunjukkan siapa yang boleh menulis. Aturan di
`firebase/firestore.rules` harus menegakkan kolom ini; kode tidak dianggap
pengaman.

PENTING: nama field di bawah mengikuti skema, tetapi **belum diverifikasi
terhadap firmware yang sudah ada**. AGENTS.md bagian 3 melarang mengarang nama
field. Semua nama yang ditandai di skema dengan `[PERLU KONFIRMASI]` harus
dicocokkan dengan aplikasi Kotlin lama atau firmware sebelum dipakai. Lihat
bagian 10.

#### 4.4.1 `devices/{deviceId}` - ditulis HANYA oleh perangkat

| Field | Tipe | Penulis | Keterangan dari sisi device |
| --- | --- | --- | --- |
| `deviceId` | string (ID dokumen) | Device | Path adalah sumber kebenaran. Bila ditulis di body, nilainya harus sama dengan ID dokumen. |
| `name` | string | Device | Nama tampilan untuk companion. |
| `model` | string | Device | Nilai literal belum ada sumber. [PERLU KONFIRMASI] |
| `firmwareVersion` | string | Device | Ditulis saat boot. |
| `wifiSsid` | string | Device | **SSID saja, tanpa password.** |
| `lastSeen` | timestamp (server) | Device | Heartbeat. Lihat bagian 2. |
| `bootCount` | integer | Device | Jumlah boot sejak factory reset. |
| `batteryPct` | integer 0-100 atau null | Device | Jangan diasumsikan ada; keberadaan baterai belum dikonfirmasi tim hardware. [PERLU KONFIRMASI] |
| `settings` | map | Device | Lihat bagian 4.6. |
| `createdAt` | timestamp (server) | Device | |
| `updatedAt` | timestamp (server) | Device | |

Ditulis oleh App, bukan device:

| Field | Tipe | Penulis | Keterangan |
| --- | --- | --- | --- |
| `members` | map (uid ke role) | App (owner) | Keanggotaan perangkat. Pengecualian terhadap aturan hak tulis app; perlu persetujuan owner. [PERLU KONFIRMASI] |
| `mediaLimit` | integer | App (owner) | Batas `media` per perangkat. [PERLU KONFIRMASI] |

Field yang **tidak boleh** ada di dokumen ini: `location`, `gps`, `ip`,
`macAddress`, `wifiPassword`, `serialNumber`, `bearerToken`, `firebaseToken`, dan
sejenisnya. Field `isOnline` atau `status` juga sengaja tidak ada karena status
online dihitung client-side.

Catatan device: **jangan menulis alamat IP.** Field `ip` justru dilarang oleh
skema, meski terlihat berguna untuk troubleshooting.

#### 4.4.2 `devices/{deviceId}/detections/{detectionId}` - dibuat HANYA oleh perangkat

| Field | Tipe | Penulis | Keterangan dari sisi device |
| --- | --- | --- | --- |
| `type` | string enum `money` atau `text` | Device | Wajib. |
| `label` | string atau null | Device | `money`: nominal yang dikenali model. `text`: ringkasan singkat bila ada. [PERLU KONFIRMASI] daftar kelas dan nominal. |
| `amount` | integer atau null | Device | `money`: ya. `text`: null. [PERLU KONFIRMASI] satuan dan daftar nilai. |
| `currency` | string | Device | Kode mata uang, misalnya `IDR`. [PERLU KONFIRMASI] |
| `confidence` | double 0.0 sampai 1.0 | Device | Ambang untuk "cukup untuk diucapkan" ada di sisi device dan belum dikonfirmasi. |
| `distanceCm` | integer atau **null** | Device | TF-Luna dalam sentimeter. `null` bila sensor tidak terpasang atau bacaan gagal. |
| `ocrText` | string maks 500 karakter atau null | Device | `text`: ya. `money`: null. [PERLU KONFIRMASI] apakah device atau app yang memotong sebagai sumber kebenaran. |
| `thumbnailId` | string atau null | Device | ID dokumen `media`. `null` bila opt-in mati atau thumbnail gagal. |
| `createdAt` | timestamp (server) | Device | **Satu-satunya dasar pengurutan riwayat.** |
| `validationStatus` | string enum `pending`, `match`, `mismatch` | Device (nilai awal `pending` saja) / App (perubahan) | Device hanya boleh menulis `pending` saat membuat dokumen. |
| `validatedBy` | string (uid) atau null | **App saja** | |
| `validatedAt` | timestamp (server) | **App saja** | |

Aturan:

- Device **tidak boleh** membuat, mengubah, atau menghapus `validatedBy` dan
  `validatedAt`, dan **tidak boleh** mengubah `validationStatus` dari `pending`.
- App **hanya boleh** memperbarui tiga field validasi, dan menghapus dokumen
  deteksi beserta `media` terkait.
- Tidak ada field untuk audio, video, koordinat, atau skor YOLO multi-box.

#### 4.4.3 `devices/{deviceId}/media/{mediaId}` - dibuat HANYA oleh perangkat

| Field | Tipe | Penulis | Keterangan dari sisi device |
| --- | --- | --- | --- |
| `mediaId` | string (ID dokumen) | Device | Saran skema: sama dengan `detectionId`. [PERLU KONFIRMASI] |
| `bytes` | string (base64) | Device | Data JPEG. Batas keras panjang string **81.920 karakter**. |
| `mime` | string | Device | Hanya `image/jpeg`; nilai lain ditolak rules. |
| `size` | integer | Device | Ukuran JPEG **sebelum** base64, dalam byte. Wajib `<= 60000`. |
| `createdAt` | timestamp (server) | Device | |

Aturan:

- **Hanya boleh dibuat bila `settings.uploadThumbnails` bernilai `true`.**
  Default `false`.
- Device harus resize sendiri sebelum menulis. Firestore tidak memotong.
- Batas 60 KB **wajib ditegakkan rules**, bukan hanya kode device. Rules
  memeriksa `size`, panjang `bytes`, dan `mime`, tapi tidak bisa memverifikasi
  bahwa `bytes` benar-benar JPEG yang valid.
- Tidak boleh ada video, audio, atau frame mentah.
- App boleh menghapus dokumen `media` saat menghapus deteksi.

#### 4.4.4 `devices/{deviceId}/events/{eventId}` - dibuat HANYA oleh perangkat

| Field | Tipe | Penulis | Keterangan dari sisi device |
| --- | --- | --- | --- |
| `eventId` | string (ID dokumen) | Device | ID acak, misalnya dengan prefix `evt_`. [PERLU KONFIRMASI] format. |
| `type` | string enum | Device | Kandidat skema: `boot`, `wlan_connected`, `wlan_disconnected`, `auth_failed`, `command_received`, `command_failed`, `config_changed`, `storage_low`, `sensor_error`. [PERLU KONFIRMASI] daftar final. |
| `severity` | string enum `info`, `warning`, `error` | Device | Untuk warna status di UI. |
| `message` | string maks 200 karakter | Device | Ringkasan teknis. [PERLU KONFIRMASI] panjang final dan apakah perlu multibahasa. |
| `createdAt` | timestamp (server) | Device | Dasar pengurutan. |

Aturan:

- Event **tidak boleh** memuat isi `resultNote` perintah, SSID lengkap, email akun
  device, atau kredensial apa pun.
- Event ditulis hanya untuk kondisi tidak normal. Deteksi normal **tidak boleh**
  memicu event, agar kuota baca dan tulis tidak habis.

#### 4.4.5 `devices/{deviceId}/commands/{commandId}` - dibuat oleh App, status di-update oleh Device

| Field | Tipe | Penulis | Keterangan dari sisi device |
| --- | --- | --- | --- |
| `commandId` | string (ID dokumen) | App | Dibuat aplikasi, bukan device. |
| `type` | string enum | App | Lihat tabel payload di bawah. |
| `payload` | map | App | Device **hanya membaca**. |
| `status` | string enum `pending`, `sent`, `acked`, `done`, `failed` | App (create dengan `pending`) / Device (transisi) | Device hanya boleh maju satu arah. |
| `requestedBy` | string (uid) | App | Device **hanya membaca**. |
| `createdAt` | timestamp (server) | App | Device mengambil antrean berdasarkan urutan ini. |
| `updatedAt` | timestamp (server) | Device | |
| `resultNote` | string atau null | Device | Ringkas dan tanpa rahasia. |

Device **hanya boleh mengubah** `status`, `updatedAt`, dan `resultNote`. Device
tidak boleh mengubah `type`, `payload`, `requestedBy`, atau `createdAt`.
Device **tidak boleh menghapus** dan **tidak boleh membuat** perintah.

Tidak ada field `expiresAt` karena TTL tidak tersedia di Spark. Masa berlaku
perintah, bila dibutuhkan, dicek client-side dan ditandai `failed` oleh device.

### 4.5 Bentuk dan isi `payload` perintah

Tabel ini mengikuti skema. Device **hanya membaca** `payload`.

| `type` | Field payload | Tipe | Aturan dari sisi device |
| --- | --- | --- | --- |
| `sync_now` | tidak ada | map kosong | Device mengirim telemetry segera. |
| `speak_text` | `text` | string | Device membacakan teks. [PERLU KONFIRMASI] batas panjang, usulan 200 karakter. |
| `set_volume` | `level` | integer 0 sampai 100 | [PERLU KONFIRMASI] skala volume yang benar-benar didukung audio path perangkat. |
| `restart` | tidak ada | map kosong | Device restart. |
| `reprovision` | tidak ada | **wajib kosong** | Kredensial Wi-Fi **tidak pernah** ditulis ke Firestore. Device melihat perintah ini sebagai permintaan memulai mode pairing QR, lalu menulis `resultNote` tanpa kredensial. |

Aturan `reprovision` yang penting: perintah ini **tidak boleh** pernah
membawa SSID, password, atau token dalam `payload` maupun `resultNote`. Jika
ada kebutuhan masa depan untuk menulis SSID saja, perlu persetujuan owner
eksplisit.

### 4.6 `settings` pada dokumen device

| Field | Tipe | Penulis | Keterangan |
| --- | --- | --- | --- |
| `settings.uploadThumbnails` | boolean | Device | Opt-in thumbnail. **Default `false`.** Nama kunci ini sudah ditetapkan AGENTS.md dan tidak boleh diganti. |
| `settings.uploadText` | boolean | Device | Opt-in pengiriman `ocrText` ke cloud. Default [PERLU KONFIRMASI]. Default aman adalah `false`, tetapi jika aplikasi Kotlin lama selalu mengirim teks, ini berbeda dan harus dikonfirmasi sebelum kompatibilitas rusak. |

Map `settings` sengaja dibuat kecil. Jangan menambah pengaturan perangkat di
sini tanpa persetujuan owner, karena setiap field baru adalah kontrak baru dengan
firmware.

Perangkat harus menulis kedua key itu secara eksplisit, termasuk saat bernilai
`false`, supaya reader tidak perlu menebak key yang hilang.

### 4.7 Batching dan `commit`

Endpoint `documents:commit` menjalankan banyak tulisan secara atomik dalam satu
request. Ini berguna untuk menggabungkan heartbeat dengan flush deteksi tertunda
dalam satu panggilan, sehingga HTTP round trip berkurang. Kuota tetap dihitung
per dokumen, bukan per request.

Batas jumlah operasi per `commit` harus dipastikan terhadap dokumentasi resmi
sebelum diimplementasikan. Nilai yang sering beredar adalah 500, tetapi harus
diverifikasi. [PERLU KONFIRMASI]

Batas ukuran request dan nilai Firestore juga harus diambil dari dokumentasi
resmi atau probe script di perangkat, bukan dari asumsi. [PERLU KONFIRMASI]

Untuk implementasi awal, gunakan `PATCH` atau `createDocument` per dokumen,
bukan `batchWrite`, karena `batchWrite` tidak atomik dan menambah beban parsing
di MaixPy. [PERLU KONFIRMASI] setelah benchmark di perangkat.

---

## 5. Provisioning Wi-Fi lewat QR code

### 5.1 Status: FORMAT FINAL BELUM DIKETAHUI

**Payload QR Wi-Fi final tidak boleh dibuat karangan.** AGENTS.md bagian 3 dan
bagian 13 melarang hal tersebut, karena format payload adalah bagian dari
kontrak dengan perangkat yang sudah ada. Format ini **wajib diekstrak dari
aplikasi Kotlin lama atau firmware** yang dirujuk PRD bagian 14.

PRD.md saat ini masih DRAFT dan tidak memuat PRD asli maupun bahan bagian 14.
Sumber kode Kotlin lama dan firmware tidak tersedia di repo ini.

Sebelum ada konfirmasi, **dilarang** menulis payload QR di app, dan use case
`BuildWifiQrPayload` pada feature `provisioning` harus menunggu format final.

### 5.2 Yang harus dikonfirmasi sebelum menentukan format

1. **Format apa yang dipindai perangkat?** Teks biasa bergaya `WIFI:`,
   JSON, URL, atau base64?
2. **Apakah perangkat sudah punya parser QR bawaan MaixPy, atau perlu kita
   tulis?** [PERLU KONFIRMASI] Jangan diasumsikan ada parser.
3. **Nama field apa yang diharapkan parser perangkat?** Misalnya `ssid`, `pass`,
   `security`, `hidden`, atau `country`. [PERLU KONFIRMASI]
4. **Delimiter dan urutan apa yang dipakai?** [PERLU KONFIRMASI]
5. **Adakah field tambahan yang wajib?** Contoh `deviceId`, `token`, `expiresAt`,
   atau `otp`. [PERLU KONFIRMASI] Jangan karang field untuk otorisasi.
6. **Apakah payload dienkripsi atau ditandatangani?** [PERLU KONFIRMASI]
7. **Berapa lama QR valid?** Apakah ada masa berlaku? [PERLU KONFIRMASI]
8. **Bagaimana kegagalan parsing ditampilkan ke pengguna?** [PERLU KONFIRMASI]

### 5.3 Placeholder struktur payload (BELUM FINAL)

Struktur di bawah **hanya placeholder untuk diskusi dan review**. **Setiap nilai
ditandai `??`.** Struktur ini **bukan format final** dan **tidak boleh** dipakai
di kode maupun di golden test.

```json
{
  "formatVersion": "??",
  "ssid": "??",
  "password": "??",
  "security": "??",
  "hidden": "??",
  "country": "??",
  "deviceId": "??",
  "issuedAt": "??",
  "expiresAt": "??",
  "signature": "??"
}
```

Yang dapat disimpulkan dari struktur placeholder:

- Ada kredensial Wi-Fi di dalamnya. Kredensial ini **tidak boleh** disimpan
  permanen setelah dipakai. Feature `provisioning` mensyaratkan password tidak
  pernah dipersistensi.
- Ada kemungkinan field otorisasi seperti `signature` atau `otp`, agar QR tidak
  bisa dipakai orang lain untuk mengganti Wi-Fi. [PERLU KONFIRMASI] Mekanisme
  jangan dikarang.

### 5.4 Aturan yang berlaku terlepas dari format final

- Password Wi-Fi **tidak boleh** masuk log, event Firestore, atau pesan error di
  app maupun di perangkat.
- QR hanya ditampilkan di layar app, tidak pernah disimpan ke galeri atau log.
- Jika QR kedaluwarsa atau provisioning gagal, perangkat harus memberi umpan
  balik suara yang jelas. [PERLU KONFIRMASI] Teks dan file audio yang dipakai
  tidak boleh dikarang.
- App menampilkan status "menunggu heartbeat pertama" lewat `WatchFirstHeartbeat`
  sebagai konfirmasi provisioning berhasil. Ini menyiratkan perangkat harus
  menulis `lastSeen` segera setelah Wi-Fi tersambung. [PERLU KONFIRMASI]
- Kredensial Wi-Fi **tidak pernah** masuk Firestore, termasuk lewat perintah
  `reprovision`. Sesuai skema bagian 4.5, `payload` perintah `reprovision` wajib
  kosong dan `resultNote` wajib tanpa kredensial. Perintah itu hanya memberi
  tahu perangkat untuk masuk ke mode pairing QR.
- Nomor seri perangkat juga tidak boleh dikirim lewat QR maupun Firestore. Skema
  bagian 4.1 melarang field `serialNumber` di dokumen device. [PERLU KONFIRMASI]
  apakah nomor seri perlu disimpan untuk dukungan teknis.

---

## 6. Batasan payload

Semua nilai di bagian ini **perlu konfirmasi** dan tidak boleh dianggap final.

| Aspek | Nilai | Status |
| --- | --- | --- |
| Batas panjang SSID | biasanya 32 oktet pada 802.11 | [PERLU KONFIRMASI] apakah ada trimming |
| Batas panjang password | biasanya 63 karakter untuk WPA2-PSK, minimum 8 | [PERLU KONFIRMASI] |
| Encoding | UTF-8 | [PERLU KONFIRMASI] dukungan SSID non-ASCII |
| Kapitalisasi | SSID case-sensitive | [PERLU KONFIRMASI] ada atau tidaknya normalisasi |
| Panjang maksimum payload QR | bergantung pada versi QR dan tingkat koreksi galat yang dipakai | [PERLU KONFIRMASI] jangan asumsikan |
| Ukuran thumbnail | 60 KB maksimal (kebijakan produk) | Pasti dari AGENTS.md bagian 3 |
| Batas nilai Firestore | bytesValue maksimal 1 MiB - 89 byte | Pasti dari discovery document |
| Panjang `ocrText` | dipotong 500 karakter | Pasti dari AGENTS.md bagian 3 |
| Panjang pesan event | dipotong, batas belum ditetapkan | [PERLU KONFIRMASI] |

Panjang payload QR harus dihitung dengan library QR yang dipakai app
(`qr_flutter`) lalu dibandingkan dengan apa yang benar-benar bisa dipindai
perangkat. Jangan menebak, ujilah di perangkat. [PERLU KONFIRMASI]

---

## 7. Backoff, retry, dan ketahanan jaringan

### 7.1 Prinsip

- Semua request jaringan wajib punya timeout. Tidak ada request yang boleh
  memblokir loop utama deteksi.
- Retry hanya untuk error transient. Error otentikasi (401) **tidak boleh**
  di-retry berulang. Jalur ini memicu refresh token sekali, lalu berhenti dengan
  pesan log.
- Antrean tertunda hanya untuk data yang boleh hilang bila perangkat mati,
  yaitu telemetri. Deteksi yang sudah diucapkan dan tidak tercatat boleh hilang.
  Lebih baik hilang daripada memblokir pengguna.

### 7.2 Exponential backoff dengan jitter

Rumus:

```
delay = min(cap, base * 2^attempt)
delay = random(0, delay)   # full jitter
```

Nilai yang disarankan, semuanya dapat disesuaikan:

| Parameter | Nilai yang disarankan |
| --- | --- |
| `base` | 2 detik |
| `cap` | 5 menit |
| Faktor pengali | 2 |
| Jitter | full jitter |

Ketentuan tambahan:

- Short circuit: satu kegagalan kredensial (401) mengunci percobaan token sampai
  `nextTokenAttemptAt`. Bukan loop retry.
- Circuit breaker sederhana: setelah N kegagalan berturut-turut, jeda otomatis
  selama `cap`. [PERLU KONFIRMASI] nilai N.
- Setiap backoff di-log tanpa isi payload. Tidak ada SSID, password, atau
  `ocrText` di log.
- Backoff hanya berlaku pada jalur jaringan. Jalur bicara tidak pernah di-backoff.

### 7.3 Pola antrean

Perangkat sebaiknya punya tiga antrean terpisah:

1. `heartbeat_queue` - satu entri, selalu menimpa yang lama.
2. `telemetry_queue` - deteksi, event, thumbnail. Boleh dijatuhkan saat penuh.
3. `command_status_queue` - perubahan status perintah. Boleh dijatuhkan setelah
   TTL tertentu karena perintah sudah selesai. [PERLU KONFIRMASI]

Aturan: `heartbeat_queue` tidak boleh menggumpil. Bila perangkat sedang offline,
`lastSeen` menjadi basi secara normal dan app menandainya offline.

---

## 8. Penghematan kuota

### 8.1 Model kuota free (Spark)

Angka dari dokumentasi resmi Firestore:

| Kuota free | Nilai |
| --- | --- |
| Stored data | 1 GiB |
| Document reads | 50.000 per hari |
| Document writes | 20.000 per hari |
| Document deletes | 20.000 per hari |
| Outbound data transfer | 10 GiB per bulan |

Kuota direset setiap hari, sekitar tengah malam waktu Pasifik. Di luar kuota
gratis, layanan dihentikan untuk sisa bulan karena Spark tidak menambah tagihan.

Catatan tambahan dari skema bagian 7.1 yang relevan untuk perangkat:

- Snapshot `snapshots()` ditagih 1 baca untuk hasil awal, lalu 1 baca per dokumen
  yang benar-benar berubah. Ini berlaku untuk app, bukan untuk perangkat.
- Query agregasi `count()` ditagih 1 baca per batch hingga 1.000 index entry.

PRD bagian 9 seharusnya memuat anggaran baca dan tulis yang lebih rinci, tetapi
PRD masih DRAFT. Angka di atas adalah angka default free tier, **bukan**
anggaran final produk. [PERLU KONFIRMASI]

### 8.2 Heartbeat versus event

Aturan operasional agar kuota tidak habis:

- **Heartbeat** hanya berisi `lastSeen` dan field teknis kecil. Satu write per
  30 detik, atau 60 detik bila owner memilih rekomendasi skema (lihat bagian
  2.4). Tidak boleh membawa data pengguna.
- **Event** hanya untuk kondisi tidak normal. Deteksi normal **tidak** menulis ke
  `events`.
- **Deteksi** menulis satu dokumen per hasil yang layak disimpan. Jangan menulis
  dokumen untuk setiap frame kamera.

### 8.3 Throttle algoritma deteksi

Deteksi boleh berbicara setiap saat, karena itu fungsi inti dan tidak boleh
di-throttle. Yang boleh di-throttle hanya **penulisan ke cloud**. Pemisahan ini
wajib dijelaskan di kode.

Pseudocode ilustratif:

```
if confidence < confidence_min:            # tidak layak disimpan
    skip_upload()
elif now - last_upload_at < min_interval:
    coalesce_into_buffer()                 # gabungkan, jangan tulis dokumen baru
elif buffer_full or now - buffer_open_at > buffer_max_age:
    flush_buffer_as_detections()
```

Parameter yang perlu dikonfirmasi:

| Parameter | Nilai yang disarankan | Status |
| --- | --- | --- |
| `confidence_min` | belum ditetapkan | [PERLU KONFIRMASI] |
| `min_interval` antar upload | 5 detik | [PERLU KONFIRMASI] |
| `buffer_max_size` | 20 deteksi | [PERLU KONFIRMASI] |
| `buffer_max_age` | 60 detik | [PERLU KONFIRMASI] |
| Perkiraan deteksi per jam pada usage nyata | belum ditetapkan | [PERLU KONFIRMASI] |

Perkiraan beban perlu dihitung dari usage nyata, bukan dari tebakan. Jika satu
perangkat menghasilkan 200 deteksi per jam dengan `min_interval` 5 detik, writer
sudah di bawah kuota. Jika burst lebih tinggi, coalescing menahan lonjakan.

Compute budget juga perlu diukur: YOLO, OCR, LiDAR, TLS, dan signing JWT berjalan
bersamaan di MaixCAM. Jika CPU tidak kuat, throttle harus diterapkan pada upload,
tidak pernah pada perilaku bicara. Kecepatan inferensi YOLO pada MaixCAM harus
diukur dengan probe script, bukan diasumsikan. AGENTS.md bagian 3 melarang asumsi
hardware. [PERLU KONFIRMASI]

### 8.4 Pembacaan

- Semua query WAJIB punya `limit`. Query tanpa `limit` bisa menghabiskan kuota read
  seketika (AGENTS.md bagian 5).
- Device tidak butuh realtime listener (bagian 4.2). Polling `commands` memakai
  `runQuery` dengan filter status dan `limit` kecil. Interval polling harus cukup
  jauh dari 30 detik heartbeat agar tidak menambah read signifikan.
  [PERLU KONFIRMASI]
- Device **tidak** perlu membaca `detections`, `media`, atau `events`. Hanya app
  yang membacanya. Ini membuat read quota untuk device hampir nol; device hanya
  membaca `commands` dan dokumen `devices/{deviceId}` miliknya sendiri.
- Firmestore TTL **tidak didukung** di Spark, jadi tidak ada auto-delete. Skema
  bagian 7.4 memberi dua opsi: device menghapus dokumen lamanya sendiri, atau app
  menghapus manual dari Riwayat lewat `DeleteDetection`.
  [PERLU KONFIRMASI] apakah device diizinkan menghapus `detections` dan `media`
  miliknya, dan dengan aturan apa.
- [PERLU KONFIRMASI] kebijakan retensi per perangkat, jumlah hari atau jumlah
  maksimum dokumen. Dengan thumbnail 60.000 byte, 1 GiB habis oleh sekitar 17.000
  thumbnail, sehingga tanpa retensi kuota penyimpanan akan habis pada perangkat
  yang aktif lama.

---

## 9. Sinkronisasi perintah (commands)

### 9.1 COMMAND_FLOW

App dan device tidak membaca status satu sama lain secara langsung. App melihat
status lewat snapshot, device melihat perintah lewat polling.

```
 APP (anggota)                    FIRESTORE                       DEVICE (MaixCAM)
    |                                 |                                |
    | 1. create commands/{id}         |                                |
    |    status = "pending" --------->|  rules: hanya anggota yang     |
    |                                 |  boleh create                 |
    |                                 |                                |
    |                                 |<-- 2. poll runQuery --------- |  interval polling,
    |                                 |    commands                  |  filter + limit
    |                                 |    where status in            |
    |                                 |      ["pending","sent"]        |
    |                                 |------------------------------>|
    |                                 |                                | 3. device melihat
    |                                 |                                |    perintah, ubah
    |                                 |                                |    status = "sent"
    |                                 |<-- 4. PATCH status="sent" ---- |
    | 5. snapshot update              |                                |
    |                                 |                                | 6. jalankan perintah
    |                                 |<-- 7. PATCH status="acked" --- |
    | 8. snapshot update              |                                |
    |                                 |                                | 9. selesai atau gagal
    |                                 |<-- 10. PATCH done / failed --- |
    | 11. snapshot update             |                                |
```

### 9.2 Transisi status

| Dari | Ke | Siapa menulis | Arti |
| --- | --- | --- | --- |
| baru | `pending` | App | Perintah dibuat, belum dilihat device. |
| `pending` | `sent` | Device | Device sudah melihat perintah. |
| `sent` | `acked` | Device | Device menerima perintah dan akan menjalankannya. |
| `acked` | `done` | Device | Perintah selesai sukses. |
| `acked` | `failed` | Device | Perintah gagal, isi `resultNote`. |

Aturan:

- Hanya device boleh menulis `sent`, `acked`, `done`, dan `failed`.
- App tidak boleh menandai perintah selesai sendiri.
- `failed` **wajib** punya `resultNote` yang berguna tapi tidak sensitif, tanpa
  SSID atau password Wi-Fi.
- Device hanya boleh mengubah `status`, `updatedAt`, dan `resultNote`.
- Device tidak boleh memindahkan status ke belakang.
- Transisi yang tidak dikenal harus diabaikan secara defensif, bukan menyebabkan
  crash.
- [PERLU KONFIRMASI] Apakah `sent` dan `acked` memang dua tahap berbeda di
  firmware yang ada, atau cukup satu tahap. Ini harus dicocokkan dengan firmware.

### 9.3 Tipe perintah

Enum tipe perintah sudah ditetapkan di `docs/firestore_schema.md` bagian 4.5:
`sync_now`, `speak_text`, `set_volume`, `restart`, dan `reprovision`. Isi
`payload` per tipe ada di bagian 4.5 dokumen ini.

`reprovision` deserves perhatian khusus: device **tidak boleh** mencari kredensial
Wi-Fi di Firestore. Perintah itu hanya memicu mode pairing QR, dan `resultNote`
wajib null atau kosong. [PERLU KONFIRMASI] batas panjang `speak_text` dan skala volume yang didukung
audio path perangkat.

Perintah yang mengubah perilaku keamanan, misalnya mengaktifkan upload thumbnail
dari jarak jauh, perlu persetujuan eksplisit di app dan tidak boleh dipicu lewat
payload bebas.

---

## 10. Backward compatibility

Aturan dari AGENTS.md bagian 3: jangan mengubah format payload Wi-Fi QR, nama
kelas, atau perilaku perangkat yang sudah ada. Semuanya harus diekstrak dari
aplikasi Kotlin lama dan firmware.

Konsekuensi praktis:

1. **Nama field Firestore adalah kontrak.** `detections`, `validationStatus`,
   `lastSeen`, `commands`, dan `status` harus cocok dengan yang sudah dipakai
   perangkat. Mengganti nama memutus perangkat yang sudah deployed.
2. **Perubahan hanya boleh aditif dan berversi.** Menambah field baru dengan
   default aman diperbolehkan. Menghapus, mengganti tipe, atau mengganti nama
   field tidak boleh tanpa migrasi yang disetujui owner.
3. **Field baru harus opsional di sisi reader.** Firmware lama tidak akan
   mengirim field baru, sehingga semua reader harus tahan terhadap field yang
   hilang.
4. **Rules harus ditulis backward compatible.** Rules baru tidak boleh menolak
   request yang dikirim firmware lama.
5. **App harus toleran terhadap dokumen lama.** Field yang hilang dipetakan ke
   default, bukan dianggap error.
6. **Perubahan schema harus memperbarui semuanya dalam satu task yang sama**
   (AGENTS.md bagian 7): `docs/firestore_schema.md`, `firebase/firestore.rules`,
   `firebase/firestore.indexes.json`, model Dart beserta test, dokumen ini, dan
   kode device bila terdampak. Perubahan harus diumumkan eksplisit.
7. **JanganSCHEDULE versi secara hard-coded sebelum ada strategi upgrade.**
   Bila `firmwareVersion` tidak bisa dipercaya, gunakan feature detection yaitu
   ada atau tidak adanya field, bukan nomor versi. [PERLU KONFIRMASI]

---

## 11. Tabel "Yang belum diputuskan"

Semua pertanyaan berikut harus dijawab owner sebelum kode yang bergantung pada
jawaban ini ditulis.

| # | Topik | Pertanyaan | Dampak | Status |
| --- | --- | --- | --- | --- |
| 1 | Autentikasi device | Opsi A, B, C, D, atau E? | Seluruh lapisan keamanan REST | BELUM |
| 2 | Opsi auth | Private key boleh berada di perangkat? | Risiko kebocoran kredensial | BELUM |
| 3 | Opsi auth | MaixPy punya pustaka RSA untuk signing JWT? Boleh memasang paket? | Kelayakan Opsi A dan B | BELUM |
| 4 | Opsi auth | API key saja ditolak? | Rules dan keamanan data | BELUM |
| 5 | `projectId` | ID project Firebase yang sebenarnya | Base URL semua request | BELUM |
| 6 | Nama field | Cocokkan nama field skema dengan aplikasi Kotlin lama atau firmware | Kompatibilitas firmware | BELUM |
| 7 | QR payload | Format FINAL QR Wi-Fi dari aplikasi Kotlin lama atau firmware | Feature `provisioning` | BELUM |
| 8 | QR payload | Field tambahan seperti signature, otp, atau expiresAt? | Keamanan provisioning | BELUM |
| 9 | Batas payload | Batas panjang SSID, password, QR, encoding, kapitalisasi | UI QR dan parser | BELUM |
| 10 | Heartbeat | Opsi A server transform atau Opsi B jam perangkat? | Biaya dan kebenaran status online | BELUM |
| 11 | Kuota | Heartbeat 30 detik (AGENTS.md) atau 60 detik (rekomendasi skema 7.2)? | Skala jumlah perangkat | BELUM |
| 12 | Kuota | Berapa perangkat aktif simultan yang harus didukung? | Biaya write utama | BELUM |
| 13 | Kuota | PRD bagian 9 belum ada, anggaran resmi perlu ditulis | Semua angka kuota | BELUM |
| 14 | Polling perintah | Interval polling `commands` yang disepakati | Read quota | BELUM |
| 15 | Throttle | Nilai `confidence_min`, `min_interval`, `buffer_max_size`, `buffer_max_age` | Write quota dan UX cloud | BELUM |
| 16 | Events | Daftar final tipe `events` (skema sudah memberi kandidat) | Write quota dan UI | BELUM |
| 17 | Events | Panjang maksimum `message`, dan apakah perlu multibahasa | Write quota | BELUM |
| 18 | Commands | Apakah `sent` dan `acked` dua tahap nyata di firmware | Alur remote control | BELUM |
| 19 | Commands | Batas panjang `speak_text` dan skala volume audio yang didukung | Alur remote control | BELUM |
| 20 | Rules | Aturan rules apa yang menegakkan `size <= 60000`, `mime`, dan panjang `bytes` | Keamanan data | BELUM |
| 21 | Otorisasi | Bagaimana rules mengenali identitas device dan mengikatnya ke `deviceId` yang benar | Otorisasi lintas perangkat | BELUM |
| 22 | Otorisasi | Siapa menulis `members`, dan apakah owner boleh mengubahnya? | Keanggotaan perangkat | BELUM |
| 23 | Otorisasi | Batas anggota per perangkat, dan model map versus array | Beban baca dan aturan | BELUM |
| 24 | Retention | Apakah device boleh menghapus `detections` dan `media` miliknya sendiri? | Stored data 1 GiB | BELUM |
| 25 | Retention | Kebijakan retensi per perangkat, jumlah hari atau jumlah dokumen | Stored data 1 GiB | BELUM |
| 26 | Battery | Apakah ada pengukuran baterai di perangkat? | Field `batteryPct` | BELUM |
| 27 | Lokasi | Nomor seri perlu disimpan untuk dukungan teknis? | Kebijakan privasi | BELUM |
| 28 | MaixPy | Parser QR bawaan MaixPy tersedia? Perlu library apa? | Bagian 5 | BELUM |
| 29 | Performa | Benchmark YOLO, OCR, TLS, dan JWT di MaixCAM | Throttle di bagian 8.3 | BELUM |
| 30 | `commit` | Batas resmi jumlah Write per permintaan `commit` | Implementasi batch | BELUM |
| 31 | Upgrade | Strategi upgrade firmware dan deteksi versi | Bagian 10 | BELUM |
| 32 | Settings | Default `settings.uploadText`, `false` atau selalu kirim seperti aplikasi lama | Privasi dan kompatibilitas | BELUM |

Poin 6, 16, 18, 22, 24, dan 27 juga tercatat sebagai `[PERLU KONFIRMASI]` di
`docs/firestore_schema.md`. Jawabannya harus konsisten antara kedua dokumen.

---

## 12. Lampiran: endpoint yang dipakai device

Device hanya boleh memakai operasi berikut. Setiap operasi wajib punya timeout,
backoff, dan log tanpa data sensitif.

| Tujuan | Operasi | Catatan |
| --- | --- | --- |
| Heartbeat | `PATCH v1/{document.name}` dengan update mask `lastSeen` | Lihat bagian 2 untuk Opsi A dan B. |
| Tulis dokumen device | `PATCH` dengan update mask field telemetry | Hanya saat boot atau saat ada perubahan konfigurasi, bukan tiap heartbeat. |
| Tulis deteksi | `PATCH` atau `createDocument` ke `detections/{id}` | Device membuat `validationStatus` bernilai `pending`. |
| Tulis thumbnail | `PATCH` atau `createDocument` ke `media/{id}` | Hanya bila `settings.uploadThumbnails` true. |
| Tulis event | `createDocument` ke `events/{id}` | Hanya kondisi tidak normal. |
| Baca perintah | `POST v1/{database}/documents:runQuery` pada `commands` dengan filter `status` dan `limit` | Tidak ada listener REST, bagian 4.2. |
| Update status perintah | `PATCH` dengan update mask `status`, `updatedAt`, `resultNote` | Hanya device. |
| Hapus deteksi lama | `DELETE` pada `detections/{id}` dan `media/{id}` miliknya | [PERLU KONFIRMASI] apakah diizinkan untuk device. |
| Ambil access token | `POST https://oauth2.googleapis.com/token` | Hanya untuk Opsi A, B, atau D. |

Setiap operasi wajib punya:

- timeout yang jelas
- retry dengan backoff dan jitter (bagian 7)
- log yang tidak memuat kredensial atau data pengguna
- jalur gagal yang **tidak** mengganggu fungsi bicara

Saat menulis `lastSeen` dengan Opsi A, nilai server timestamp tidak bisa dikirim
lewat `PATCH` biasa. Gunakan `documents:commit` dengan satu `Write` berisi
`transform` atau `updateTransforms` dengan `setToServerValue: REQUEST_TIME`. Ini
membuat satu request tambahan per heartbeat, dan itulah alasan Opsi B tetap
dipertimbangkan. [PERLU KONFIRMASI]

---

Dokumen ini tidak boleh dianggap final sebelum bagian 11 selesai. Setiap kali
owner menjawab pertanyaan di bagian 11, perbarui dokumen ini,
`docs/firestore_schema.md`, `firebase/firestore.rules`, dan kode device dalam satu
task yang sama, lalu umumkan perubahannya.
