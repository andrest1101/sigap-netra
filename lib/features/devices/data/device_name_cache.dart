/// Cache nama tampilan perangkat untuk join client-side.
///
/// Dokumen deteksi tidak menyimpan nama perangkat
/// (`docs/firestore_schema.md` bagian 4.2): nama diselesaikan dari dokumen
/// perangkat. Repository di data layer bekerja sinkron, jadi nama disimpan di
/// cache ini dan di-refresh setiap daftar perangkat berubah (lihat `app.dart`).
///
/// Mode simulasi tidak bergantung pada cache ini: fake data source selalu
/// memakai nama demo. Cache ini yang membuat mode Firebase tetap menampilkan
/// nama yang benar tanpa field duplikat di tiap dokumen.
class DeviceNameCache {
  final Map<String, String> _names = <String, String>{};

  /// Nama tampilan untuk [deviceId]; jatuh ke ID bila belum pernah terlihat.
  String resolve(String deviceId) => _names[deviceId] ?? deviceId;

  void update(String deviceId, String name) {
    if (deviceId.isEmpty || name.isEmpty) return;
    _names[deviceId] = name;
  }

  void clear() => _names.clear();
}
