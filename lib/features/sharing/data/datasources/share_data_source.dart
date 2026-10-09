import '../../domain/entities/share_report.dart';

/// Kontrak sumber data berbagi pada data layer.
abstract interface class ShareDataSource {
  /// Membagikan laporan lewat share sheet sistem.
  Future<void> shareReport(ShareReport report);
}
