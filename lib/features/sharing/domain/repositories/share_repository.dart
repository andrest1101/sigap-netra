import '../entities/share_report.dart';

/// Kontrak repository berbagi pada domain.
abstract interface class ShareRepository {
  /// Membagikan laporan lewat share sheet sistem.
  Future<void> shareReport(ShareReport report);
}
