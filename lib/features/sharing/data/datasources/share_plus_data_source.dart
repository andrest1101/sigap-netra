import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/share_report.dart';
import '../../domain/usecases/build_share_report.dart';
import 'share_data_source.dart';

/// Sumber data berbagi berbasis `share_plus`.
///
/// Hanya mengirim teks dari [buildShareText] atau berkas CSV yang ditulis ke
/// folder sementara aplikasi: tanpa ID perangkat, tanpa lokasi, tanpa gambar.
/// Consent (OCR / data riwayat) ditangani pemanggil sebelum berkas dibangun.
class SharePlusDataSource implements ShareDataSource {
  SharePlusDataSource({
    SharePlus? sharePlus,
    Future<Directory> Function()? temporaryDirectory,
  }) : _sharePlus = sharePlus ?? SharePlus.instance,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final SharePlus _sharePlus;

  /// Pintu masuk folder tulis berkas sementara; bisa di-override di test
  /// supaya tidak menyentuh `path_provider`.
  final Future<Directory> Function() _temporaryDirectory;

  @override
  Future<void> shareReport(ShareReport report) {
    return _sharePlus.share(ShareParams(text: buildShareText(report)));
  }

  @override
  Future<void> shareCsv({
    required String content,
    required String fileName,
  }) async {
    final directory = await _temporaryDirectory();
    final file = File('${directory.path}/$fileName');
    // `flush: true`: berkas selesai ditulis sebelum share sheet membacanya.
    await file.writeAsString(content, flush: true);
    await _sharePlus.share(ShareParams(files: [XFile(file.path)]));
  }
}
