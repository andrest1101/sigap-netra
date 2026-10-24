import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/demo_ids.dart';
import '../../../monitoring/data/datasources/fake_detection_data_source.dart';
import '../../domain/entities/media_thumbnail.dart';
import 'media_data_source.dart';

/// Aset dummy demonstrasi (bukan hasil bacaan alat).
///
/// Hanya dua pecahan uang yang punya foto demo; item lain sengaja tanpa
/// thumbnail agar panel "tanpa gambar" tetap teruji dan tidak ada gambar
/// prosedural yang mudah terbaca sebagai gambar rusak. Masing-masing JPEG
/// ≤ 200 KB — di bawah batas privasi.
const String kDemoMoney100kAsset = 'assets/images/demo_money_100k.jpg';
const String kDemoMoney50kAsset = 'assets/images/demo_money_50k.jpg';

/// Peta thumbnailId demo → aset dummy.
const Map<String, String> kDemoAssetThumbnails = {
  'det-money-100k': kDemoMoney100kAsset,
  'det-money-50k': kDemoMoney50kAsset,
};

/// Sumber data thumbnail simulasi: hanya dummy dari aset.
class FakeMediaDataSource implements MediaDataSource {
  FakeMediaDataSource(this._detections);

  final FakeDetectionDataSource _detections;

  /// Cache memori sesi: muat sekali per ID, pakai ulang selama sesi.
  final Map<String, MediaThumbnail> _cache = {};

  /// Membuang satu entri cache (dipanggil setelah deteksi dihapus).
  ///
  /// Tanpa ini bytes thumbnail ID yang dihapus tetap hidup di memori dan
  /// bisa tampil basi bila ID dipakai ulang.
  void evict(String thumbnailId) => _cache.remove(thumbnailId);

  @override
  Future<MediaThumbnail?> getThumbnail({
    required String deviceId,
    required String thumbnailId,
  }) async {
    if (deviceId != kDemoDeviceId || thumbnailId.isEmpty) return null;
    final asset = kDemoAssetThumbnails[thumbnailId];
    if (asset == null) return null;
    final known = _detections.itemsForTest.any(
      (item) => item.thumbnailId == thumbnailId,
    );
    if (!known) return null;
    final cached = _cache[thumbnailId];
    if (cached != null) return cached;
    final thumbnail = await _demoAsset(deviceId, thumbnailId, asset);
    if (thumbnail == null) return null;
    if (thumbnail.imageBytes.length > kMaxThumbnailBytes) return null;
    _cache[thumbnailId] = thumbnail;
    return thumbnail;
  }

  /// Memuat dummy dari aset; null bila aset hilang/rusak.
  Future<MediaThumbnail?> _demoAsset(
    String deviceId,
    String thumbnailId,
    String asset,
  ) async {
    try {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List();
      if (bytes.isEmpty) return null;
      return MediaThumbnail(
        deviceId: deviceId,
        mediaId: thumbnailId,
        imageBytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }
}
