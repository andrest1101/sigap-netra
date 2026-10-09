import '../../../../core/constants/app_constants.dart';
import '../../../monitoring/domain/entities/detection.dart';
import '../entities/share_report.dart';
import '../repositories/share_repository.dart';

/// Fungsi murni: membangun teks bagikan dari [ShareReport].
///
/// Tanpa ID perangkat, tanpa lokasi, tanpa email. Dipisah dari use case agar
/// bisa diuji sebagai golden test tanpa `share_plus`.
String buildShareText(ShareReport report) {
  final buffer = StringBuffer()..writeln(report.title);
  for (final line in report.lines) {
    buffer.writeln(line);
  }
  final excerpt = report.ocrExcerpt;
  if (excerpt != null && excerpt.isNotEmpty) {
    buffer.writeln(excerpt);
  }
  return buffer.toString().trimRight();
}

/// Fungsi murni: membangun [ShareReport] dari satu [Detection].
///
/// [includeOcrText] hanya true bila pengguna menyetujui dialog consent.
/// Teks OCR selalu dipotong maksimal [kMaxSharedTextLength] sebagai pengaman.
ShareReport buildShareReport(
  Detection detection, {
  required String title,
  required List<String> lines,
  required bool includeOcrText,
}) {
  final raw = detection.ocrText;
  final excerpt = includeOcrText && raw != null && raw.isNotEmpty
      ? (raw.length <= kMaxSharedTextLength
            ? raw
            : raw.substring(0, kMaxSharedTextLength))
      : null;
  return ShareReport(title: title, lines: lines, ocrExcerpt: excerpt);
}

/// Kontrak pembagian laporan lewat share sheet sistem.
class ShareReportUseCase {
  const ShareReportUseCase(this._repository);

  final ShareRepository _repository;

  /// Membagikan [report] setelah pemanggil memastikan consent bila perlu.
  Future<void> call(ShareReport report) {
    return _repository.shareReport(report);
  }
}
