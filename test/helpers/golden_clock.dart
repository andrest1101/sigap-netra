/// Waktu tetap untuk semua golden yang menampilkan tanggal/jam relatif.
///
/// Dipilih Selasa, 20 Oktober 2026, 22.15 agar data demo 27 hari tetap jatuh
/// pada tanggal yang sama di setiap mesin. Golden harus deterministik: jangan
/// memakai `DateTime.now()` langsung di test golden.
final goldenNow = DateTime(2026, 10, 20, 22, 15);
