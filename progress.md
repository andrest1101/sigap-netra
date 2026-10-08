# Progress — SiGap Netra App

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
