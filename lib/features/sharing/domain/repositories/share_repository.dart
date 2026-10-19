import '../entities/share_report.dart';

/// Kontrak repository berbagi pada domain.
abstract interface class ShareRepository {
  /// Membagikan laporan lewat share sheet sistem.
  Future<void> shareReport(ShareReport report);

  /// Menulis [content] sebagai berkas sementara [fileName], lalu membagikan
  /// berkas itu lewat share sheet sistem.
  Future<void> shareCsv({required String content, required String fileName});
}
