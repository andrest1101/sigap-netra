/// ID notifikasi Android/iOS yang stabil untuk satu dokumen pembacaan.
///
/// `String.hashCode` dijamin dalam satu proses, tetapi tidak antar-rilis.
/// FNV-1a 31-bit memberi ID deterministik tanpa bergantung pada implementasi
/// hash Dart; hasil 0 diganti 1 karena sebagian platform memperlakukan 0
/// sebagai "tanpa ID".
int notificationIdFor(String detectionId) {
  var hash = 0x811c9dc5;
  for (final codeUnit in detectionId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  final id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}
