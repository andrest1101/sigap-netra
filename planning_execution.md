# Planning Execution — Integrasi Hardware SIGAP-NETRA

> Runbook assembly langsung ke hardware. File ini sumber kebenaran status integrasi.
> Bedakan dengan `progress.md` (jurnal dev UI): file ini hanya soal hardware ↔ cloud ↔ app.
>
> **Project:** `sigap-netra` (ID) · **Project number:** `409661614037`
> **Device ID usulan:** `sigap-maixcam-01` (tetap setelah dipakai — **menunggu
> konfirmasi eksplisit owner** sebelum Fase 3.5 & 4.5)
> **Baterai:** belum ada → `batteryPct: null` tampil `–` (jujur, bukan placeholder)

## Legenda status

| Status | Arti |
| --- | --- |
| `TODO` | Belum dikerjakan |
| `DOING` | Sedang dikerjakan |
| `DONE-UNVERIFIED` | Owner klaim selesai, bukti ditempel, menunggu cek asisten |
| `DONE-VERIFIED` | Asisten sudah verifikasi bukti, sah selesai |

Aturan: status `DONE` tanpa bukti = belum done. Secret (password/token/UID alat)
**tidak ditulis di file ini** — cukup tulis "tersimpan di alat".

## Fase 1 — Firebase console (owner: kamu)

| # | Task | Status | Bukti |
| --- | --- | --- | --- |
| 1.1 | Auth Email/Password + Google aktif | DONE-VERIFIED | Screenshot 13 Okt 2026, keduanya Enabled |
| 1.2 | Buat user alat (`emailkamu+sigap-device01@...`) via Users → Add user | TODO | Paste UID alat ke § Log paste-back |
| 1.3 | (fallback) Buat owner via Email/Password di console — hanya bila jalur Google tidak dipakai | TODO | Paste UID owner ke § Log paste-back |
| 1.4 | Test hotspot besok ada internet (`firestore.googleapis.com` reachable) | TODO | Tulis OK/gagal + dari jaringan apa |

> **Jalur owner:** utama = login Google sekali di HP saat Fase 3.4 (UID owner
> lahir dari situ). Console (`1.3`) hanya fallback — jangan buat dua owner.

## Fase 2 — Kontrak authUid (asisten, di repo ini)

Skema auth device: akun Auth khusus per alat + field `authUid` di dokumen
`devices/{id}` + `isDevice()` di rules membaca UID itu. Perubahan 5 file
sekaligus (wajib AGENTS.md §7): `docs/firestore_schema.md`,
`firebase/firestore.rules`, `docs/device_protocol.md` (§3 + §11),
`lib/.../device.dart` (entity), `lib/.../device_model.dart` + test.

| # | Task | Status | Bukti |
| --- | --- | --- | --- |
| 2.1 | Tambah `authUid` ke skema + rules + protokol | DONE-VERIFIED | `flutter analyze` bersih 13 Okt |
| 2.2 | Tambah `authUid` ke entity + model + test | DONE-VERIFIED | 163 test lulus 13 Okt |
| 2.3 | Deploy rules + indexes (`firebase deploy --only firestore`) | TODO | Perintah di § Perintah copy-paste |

## Fase 3 — App Android (gabungan)

| # | Task | Status | Bukti |
| --- | --- | --- | --- |
| 3.1 | `Firebase.initializeApp()` aman-gagal di `main.dart` (tanpa `firebase_options.dart` tetap jalan simulasi) | DONE-VERIFIED | Stub melempar → simulasi; 163 test lulus |
| 3.2 | `flutterfire configure` (project `sigap-netra`) → `google-services.json` | TODO | Owner run, paste output |
| 3.3 | Build APK debug | DONE-VERIFIED | `flutter build apk --debug` sukses 15 Okt (NDK 27 + minSdk 23) |
| 3.4 | Login owner di HP → mode Firebase aktif | TODO | UID owner muncul di console Users |
| 3.5 | Buat dokumen `devices/sigap-maixcam-01` manual via console (bypass rules) | TODO | Screenshot dokumen di console |
| 3.6 | App cloud-ready: satu graf repository di `main.dart` (simulasi/Firebase) + QR payload format lama terender | DONE-VERIFIED | 169 test lulus + analyze bersih 15 Okt |

Isi dokumen bootstrap 3.5 (field persis, tanpa tambahan):

```json
{
  "name": "Kacamata Cerdas 01",
  "model": "MaixCAM SG2002",
  "firmwareVersion": "v1.2.0-sg2002",
  "wifiSsid": "-",
  "authUid": "<UID-ALAT-DARI-1.2>",
  "members": { "<UID-OWNER-DARI-1.3>": "owner" },
  "settings": { "uploadThumbnails": false, "uploadText": false },
  "lastSeen": "<server timestamp: pakai tombol tambah timestamp di console>",
  "createdAt": "<server timestamp>",
  "updatedAt": "<server timestamp>"
}
```

## Fase 4 — Firmware alat (gabungan)

Asisten tulis `device/sigap_cloud.py` + `device/config.example.py` di repo ini.
Owner flash via MaixVision/SSH + isi `device/config.py` **di alat saja**
(tidak pernah commit).

| # | Task | Status | Bukti |
| --- | --- | --- | --- |
| 4.1 | `device/sigap_cloud.py`: auth email/pass → heartbeat 60 dtk → tulis deteksi → poll commands | DONE-VERIFIED | Syntax + probe `_encode_value`/`_doc_name`/backoff OK |
| 4.2 | `device/config.example.py` (placeholder saja) | DONE-VERIFIED | Review, tanpa secret |
| 4.2b | **Backup file asli alat SEBELUM flash** (`main.py` + `config.py`) ke PC, folder di luar repo | TODO | Tulis "backup ada di <folder PC>" |
| 4.3 | Cek `requests` di alat: `python3 -c "import requests; print(requests.__version__)"` | TODO | Paste versi / error ke log |
| 4.4 | Flash modul ke alat (MaixVision Install App / SCP) | TODO | Log alat menunjukkan import OK |
| 4.5 | Isi `config.py` di alat (SSID, pass Wi-Fi, kredensial akun alat, deviceId) | TODO | Tulis "tersimpan di alat" saja |
| 4.6 | MaixCAM connect Wi-Fi via touchscreen Settings → WiFi (cara legacy terbukti, QR dilewati) | TODO | IP alat + SSH bisa masuk |

> **Titik hook firmware legacy** (`C:\ngoding_skuy\sigap-netra\device\main.py`) —
> jangan cari ulang dari nol saat integrasi: deteksi uang = fungsi `catat`
> (~baris 3072), hasil teks OCR = `hasil_teks` (~baris 3409), baterai =
> variabel `persen` (~baris 2311, aktif hanya setelah Fase 6). Hook hanya
> memanggil `sigap_cloud` secara fire-and-forget; jalur deteksi → bicara tetap
> berjalan tanpa cloud (safety first).

## Fase 5 — Runbook test (besok, berurutan, jangan loncat)

| Tier | Uji | Hasil yang diharapkan | Status |
| --- | --- | --- | --- |
| T0 | Alat standalone: tekan tombol, hadapkan uang | Bicara nominal via earphone, tanpa internet | TODO |
| T1 | Nyalakan `sigap_cloud.py`, buka Beranda di HP | Hero hijau Online + strip jam sinkron segar (< 90 dtk) | TODO |
| T2 | Lakukan 1 deteksi beneran | Muncul di Aktivitas terbaru sebagai `Rp ...` + chip Menunggu | TODO |
| T3 | Tekan Sinkronkan / kirim `speak_text` dari app | Log alat menunjukkan perintah dibaca + status `done` di Firestore | TODO |

**Guardrail kuota (Spark: 50k read + 20k write/hari):** heartbeat 60 dtk =
1.440 tulis/hari — aman. App memakai query ber-`limit` + agregasi `count()`
untuk badge; selama uji hanya 1 alat + 1 HP. Jangan biarkan app terbuka lama
dengan 4 tab streaming setelah uji selesai.

**Triase saat tier gagal (berhenti di tier pertama yang gagal, jangan loncat):**

- T0 gagal → masalah alat standalone (bukan internet/rules/cloud); perbaiki
  dulu, jangan lanjut.
- T1 gagal → cek `sigap_cloud.py` (login/heartbeat), rules device, dan jam
  alat (timestamp ISO ikut jam alat — `updateTime` cadangan).
- T2 gagal → cek jalur tulis deteksi (nama field, `_encode_value`) + rules
  `create` detections.
- T3 gagal → cek poll commands di alat + izin member app membuat perintah.

## Fase 6 — Baterai (ditunda sampai hardware datang)

`batteryPct: null` → UI `–`. Setelah baterai datang, butuh: jumlah sel (1S?),
titik ukur ADC (masih ADS1115 100k/51k legacy atau beda), kurva persen.
Tanpa itu mapping persen tidak ditulis (jangan memalsukan).

## Perintah copy-paste (owner)

```powershell
# Cek requests di alat (via SSH di MaixCAM)
python3 -c "import requests; print(requests.__version__)"

# Backup file asli alat SEBELUM flash (dari PC; jalur app di alat mengikuti
# hasil 4.6 — jangan menebak, lihat isi folder app di alat dulu)
scp root@<IP-ALAT>:<jalur-app-di-alat>/main.py   "D:\backup-alat\main.py"
scp root@<IP-ALAT>:<jalur-app-di-alat>/config.py "D:\backup-alat\config.py"

# Deploy rules + indexes (dari root sigap_netra_app, setelah firebase login)
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes

# Build APK debug (setelah flutterfire configure)
flutter build apk --debug
```

## Log paste-back (tempel hasil di sini)

```text
# 1.2 UID alat   :
# 1.3 UID owner  :
# 1.4 Hotspot internet: (OK/gagal — jaringan apa)
# 4.2b Backup alat: (main.py + config.py tersimpan di folder PC mana)
# 4.3 requests   : (versi / pesan error)
# 4.6 IP alat    : (SSH bisa/tidak)
# 6   deviceId   : sigap-maixcam-01 (konfirmasi eksplisit owner: OK/belum)
```

## Blocker

| Tanggal | Blocker | Dampak | Status |
| --- | --- | --- | --- |
| 2026-10-13 | UID alat + owner belum ada | Fase 2 bisa jalan, Fase 3.5 + 4.5 tertahan | OPEN |
| 2026-10-13 | `requests` di alat belum diketahui | Modul ditulis defensif (`requests` → fallback `urllib`) | OPEN |
| 2026-10-13 | Baterai belum dibeli | Fase 6 ditunda, `batteryPct: null` | OPEN |
| 2026-10-15 | deviceId `sigap-maixcam-01` belum dikonfirmasi eksplisit owner | 3.5 + 4.5 tertahan; setelah dipakai tidak boleh berubah | OPEN |
| 2026-10-15 | Kacamata masih dipakai tim PKM | Semua Fase 4–6 (flash/test/backup) tertahan | OPEN |
| 2026-10-15 | Regresi P1: perangkat dummy hilang setelah login (semua akun) | PresentasiUI tanpa alat terancam | DONE — `currentUserProvider` reaktif + fake tanpa filter uid + sampel validasi; 174 test hijau |
