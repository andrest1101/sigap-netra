import '../../../monitoring/domain/entities/detection.dart';

/// Memisahkan pembacaan yang benar-benar baru dari backlog awal.
///
/// Stream Firestore selalu mengirim seluruh jendela pembacaan terbaru, bukan
/// satu event "baru". Emisi pertama karena itu hanya menandai ID sebagai sudah
/// dikenal; notifikasi hanya untuk ID yang muncul setelahnya. Emisi ulang
/// (mis. saat status validasi berubah) tidak menghasilkan notifikasi.
class NewDetectionTracker {
  NewDetectionTracker({this.maxRememberedIds = 500})
    : assert(maxRememberedIds > 0);

  /// Batas memori ID agar aplikasi yang berjalan lama tidak tumbuh tanpa henti.
  ///
  /// Jendela query hanya 100 pembacaan, jadi 500 ID jauh lebih dari cukup;
  /// bila ID lama terbuang, pembacaan itu juga sudah keluar dari jendela.
  final int maxRememberedIds;

  final Set<String> _seenIds = <String>{};
  bool _primed = false;

  /// Apakah emisi pertama sudah pernah diproses.
  bool get isPrimed => _primed;

  /// Mengembalikan pembacaan baru pada [detections], urutan mengikuti input.
  ///
  /// Pemanggilan pertama mengembalikan daftar kosong dan menyiapkan penanda.
  List<Detection> track(List<Detection> detections) {
    if (!_primed) {
      _primed = true;
      _remember(detections);
      return const <Detection>[];
    }

    final newDetections = <Detection>[];
    for (final detection in detections) {
      if (_seenIds.add(detection.id)) {
        newDetections.add(detection);
      }
    }
    _trim();
    return newDetections;
  }

  /// Melupakan seluruh ID, dipakai saat perangkat atau toggle berganti.
  void reset() {
    _seenIds.clear();
    _primed = false;
  }

  void _remember(List<Detection> detections) {
    for (final detection in detections) {
      _seenIds.add(detection.id);
    }
    _trim();
  }

  void _trim() {
    while (_seenIds.length > maxRememberedIds) {
      _seenIds.remove(_seenIds.first);
    }
  }
}
