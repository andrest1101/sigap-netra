/// Sumber data aktif untuk seluruh aplikasi.
///
/// Domain menentukan sendiri apa yang dibutuhkan tanpa tahu sumber datanya.
enum DataSource {
  /// Cloud Firestore sungguhan.
  firebase,

  /// Data simulasi in-memory untuk pengembangan dan demo.
  simulation;

  /// Label siap tampil untuk UI Pengaturan. String akhir tetap lewat l10n;
  /// enum ini hanya menyimpan nilai yang stabil untuk logika dan pengujian.
  String get storageKey => name;
}
