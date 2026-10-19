import '../../domain/entities/share_report.dart';

/// Kontrak sumber data berbagi pada data layer.
abstract interface class ShareDataSource {
  /// Membagikan laporan lewat share sheet sistem.
  Future<void> shareReport(ShareReport report);

  /// Menulis [content] sebagai berkas sementara bernama [fileName] di folder
  /// sementara aplikasi, lalu membuka share sheet sistem untuk berkas itu.
  ///
  /// Berkas tidak pernah diunggah ke Firestore; consent (teks pribadi pada
  /// OCR / data riwayat) ditangani pemanggil sebelum ini.
  Future<void> shareCsv({required String content, required String fileName});
}
