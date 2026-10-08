/// Mematikan retry otomatis Riverpod.
///
/// Riverpod 3 secara bawaan mencoba ulang provider yang error dengan
/// exponential backoff. Akibatnya state error tidak pernah sampai ke UI:
/// pengguna tidak pernah melihat tombol "Coba lagi".
///
/// Kita memilih menampilkan error yang jujur dan menyerahkan pemulihan ke
/// pengguna. Pakai ini pada setiap provider yang presentasinya sudah punya
/// state `AsyncValue.when` lengkap.
Duration? noRetry(int retryCount, Object error) => null;

/// Retry dengan jeda tetap dan batas percobaan.
///
/// Berguna untuk error yang diperkirakan sementara (koneksi terputus
/// sebentar) sehingga tidak perlu pengguna menekan tombol.
Duration? retryBriefly(int retryCount, Object error) =>
    retryCount >= 3 ? null : const Duration(seconds: 5);
