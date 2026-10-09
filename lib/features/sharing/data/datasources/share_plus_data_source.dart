import 'package:share_plus/share_plus.dart';

import '../../domain/entities/share_report.dart';
import '../../domain/usecases/build_share_report.dart';
import 'share_data_source.dart';

/// Sumber data berbagi berbasis `share_plus`.
///
/// Hanya mengirim teks dari [buildShareText]: tanpa ID perangkat, tanpa
/// lokasi, tanpa gambar. Consent OCR ditangani pemanggil sebelum
/// [ShareReport] dibangun (lihat [buildShareReport]).
class SharePlusDataSource implements ShareDataSource {
  SharePlusDataSource({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<void> shareReport(ShareReport report) {
    return _sharePlus.share(ShareParams(text: buildShareText(report)));
  }
}
