/// Kontrak notifikasi lokal untuk perangkat.
///
/// Presentation hanya melihat antarmuka ini; implementasi OS (Android/iOS)
/// hidup di data layer. Semua teks judul/isi maupun nama kanal dikirim oleh
/// pemanggil supaya string UI tetap berasal dari `app_id.arb`.
abstract interface class NotificationGateway {
  /// Meminta izin notifikasi ke sistem.
  ///
  /// Android 13+ menampilkan dialog izin; versi lama langsung mengembalikan
  /// `true`. `false` berarti pengguna menolak atau platform tidak mendukung.
  Future<bool> requestPermission();

  /// Menampilkan satu notifikasi.
  ///
  /// [id] harus stabil untuk satu pembacaan agar notifikasi yang sama tidak
  /// menumpuk saat stream Firestore mengirim ulang daftar.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });
}
