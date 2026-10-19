# SIGAP-NETRA App

Aplikasi pendamping (*companion*) untuk **kacamata pintar SIGAP-NETRA** — perangkat bantu tunanetra yang membaca **uang** (YOLOv11) dan **teks/menu** (OCR) lalu menyebutkan hasilnya lewat headset. Aplikasi ini dipakai oleh **pendamping / keluarga / peneliti / pengembang** (bukan pengguna tunanetra) untuk:

- memantau status alat dan bacaan baru dari jaringan mana pun (realtime);
- **memvalidasi** bacaan (Cocok / Tidak cocok) sebagai data kebenaran lapangan;
- menelusuri riwayat dan statistik akurasi;
- mengirim kredensial Wi-Fi ke alat lewat **QR code**;
- mengontrol alat dari jauh (sinkron, ucapkan teks, volume, restart);
- membagikan ringkasan hasil.

Ini adalah **refactor dari aplikasi Kotlin lama** (isi & fungsi sama, UI lebih profesional — identitas visual v3 "Lensa", Material 3, terang-saja, Bahasa Indonesia) plus fitur lintas jaringan baru.

## Dokumentasi (sumber kebenaran)

| Dokumen | Isi |
| --- | --- |
| `PRD.md` | Apa yang dibangun, prioritas P0/P1/P2, acceptance criteria, roadmap |
| `AGENTS.md` | Aturan kerja untuk kontributor & agen AI (arsitektur, privasi, git) |
| `docs/ui_spec.md` | Spesifikasi UI per layar (sumber kebenaran tampilan) |
| `docs/firestore_schema.md` | Definisi tunggal koleksi, field, dan tipe data Firestore |
| `docs/device_protocol.md` | Cara MaixCAM berkomunikasi dengan Firestore (REST) + QR Wi-Fi |
| `progress.md` | Jurnal pekerjaan selesai (entri terbaru di atas) |

## Menjalankan

Prasyarat: Flutter (stable) dengan Dart 3.8+.

```bash
flutter pub get
flutter run
```

**Mode simulasi (tanpa Firebase & tanpa perangkat):** nyalakan **Mode pengembang** di layar Pengaturan. Seluruh data layer memakai `fake_*_data_source.dart` sehingga aplikasi bisa dipakai apa adanya.

**Mode Firebase:** repo ini belum menyertakan `firebase_options.dart` (dibuat per project). Jalankan `flutterfire configure` untuk project Firebase Anda (plan Spark cukup), lalu deploy rules + indeks:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

> `firebase_options.dart`, `google-services.json`, dan `GoogleService-Info.plist` adalah identifier, bukan rahasia — keamanan bersandar pada `firebase/firestore.rules`. **Jangan pernah commit** kredensial alat (`device/config.py`), service-account JSON, atau file `.env`.

## Test

```bash
flutter test
```

Test Security Rules lewat emulator Firestore — **25 test** (butuh `firebase` CLI + **Java 21+**; `firebase-tools` 15 menolak Java di bawah 21):

```bash
cd firebase/tests && npm install && cd ../..
firebase emulators:exec --only firestore --project demo-sigap-netra "node --test firebase/tests/rules.test.mjs"
```

## Struktur

```
lib/
├── core/        # konstanta, error, router, tema, widget bersama
├── l10n/        # app_id.arb — semua string UI Bahasa Indonesia
└── features/    # per fitur: domain/ (murni) ← data/ (Firestore) → presentation/ (Riverpod)
device/          # klien cloud MaixCAM (sigap_cloud.py) + config.example.py
firebase/        # firestore.rules, firestore.indexes.json, tests/ (rules emulator)
docs/            # spesifikasi UI, skema data, protokol perangkat
```

Arsitektur: **Clean Architecture per fitur** — `presentation → domain ← data`; domain tidak mengimpor Flutter/Firebase. State management: **Riverpod**. Navigasi: **go_router**. Semua string UI ada di `lib/l10n/app_id.arb` (tidak ada yang hardcode di widget).
