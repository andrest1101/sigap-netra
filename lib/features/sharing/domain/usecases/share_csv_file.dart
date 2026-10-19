import '../repositories/share_repository.dart';

/// Membagikan berkas CSV (ekspor Riwayat) lewat share sheet sistem.
///
/// Berkas ditulis ke folder sementara aplikasi oleh data layer; use case ini
/// menjaga lapisan presentasi tetap bebas dari `dart:io` dan `share_plus`.
class ShareCsvFileUseCase {
  const ShareCsvFileUseCase(this._repository);

  final ShareRepository _repository;

  Future<void> call({required String content, required String fileName}) {
    return _repository.shareCsv(content: content, fileName: fileName);
  }
}
