/// ID demo untuk fake data sources dan test.
///
/// Bukan format `deviceId`/UID Firestore final dan tidak boleh dipakai sebagai
/// sumber kebenaran pairing. Satu konstanta dipakai bersama agar join/filter
/// lintas fitur simulasi tidak gagal diam-diam karena ID berbeda.
library;

/// Perangkat demo lokal untuk seluruh fake data sources.
const String kDemoDeviceId = 'simulasi-maixcam-1';

/// Nama tampilan perangkat demo lokal.
const String kDemoDeviceName = 'Kacamata Kamar';

/// UID pengguna demo lokal untuk seluruh fake data sources.
const String kDemoUserId = 'simulasi-user-1';
