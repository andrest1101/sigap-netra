import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/demo_ids.dart';
import '../../../monitoring/data/datasources/fake_detection_data_source.dart';
import '../../domain/entities/media_thumbnail.dart';
import 'media_data_source.dart';

/// Aset dummy demonstrasi (bukan hasil bacaan alat).
///
/// Hanya untuk item 100rb agar kartu Validasi/Riwayat terlihat hidup saat
/// demo. JPEG ±55 KB — di bawah batas privasi 60 KB.
const String kDemoMoney100kAsset = 'assets/images/demo_money_100k.jpg';

/// Sumber data thumbnail simulasi: dummy 100rb dari aset + prosedural kecil.
///
/// Item `det-money-100k` memakai foto dummy Google dari aset; item lain yang
/// punya `thumbnailId` memakai bytes PNG prosedural (96x72, tanpa biner di
/// repo). Item tanpa `thumbnailId` tetap null (panel "tanpa gambar"), sama
/// seperti produksi saat opt-in mati.
class FakeMediaDataSource implements MediaDataSource {
  FakeMediaDataSource(this._detections);

  final FakeDetectionDataSource _detections;

  /// Cache memori sesi: bangkitkan sekali per ID, pakai ulang selama sesi.
  final Map<String, MediaThumbnail> _cache = {};

  @override
  Future<MediaThumbnail?> getThumbnail({
    required String deviceId,
    required String thumbnailId,
  }) async {
    if (deviceId != kDemoDeviceId || thumbnailId.isEmpty) return null;
    final known = _detections.itemsForTest.any(
      (item) => item.thumbnailId == thumbnailId,
    );
    if (!known) return null;
    final cached = _cache[thumbnailId];
    if (cached != null) return cached;
    final thumbnail = thumbnailId == 'det-money-100k'
        ? await _demoMoney100k(deviceId, thumbnailId)
        : MediaThumbnail(
            deviceId: deviceId,
            mediaId: thumbnailId,
            imageBytes: buildDemoThumbnailBytes(thumbnailId),
          );
    if (thumbnail == null) return null;
    if (thumbnail.imageBytes.length > kMaxThumbnailBytes) return null;
    _cache[thumbnailId] = thumbnail;
    return thumbnail;
  }

  /// Memuat dummy 100rb dari aset; null bila aset hilang/rusak.
  Future<MediaThumbnail?> _demoMoney100k(
    String deviceId,
    String thumbnailId,
  ) async {
    try {
      final data = await rootBundle.load(kDemoMoney100kAsset);
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

/// Membangun bytes PNG 96x72 deterministik dari ID thumbnail.
///
/// Palet 4 warna + pola garis diagonal per hash ID: cukup terlihat sebagai
/// "foto hasil bacaan" di kartu kecil tanpa mengklaim foto uang asli.
/// Pure Dart tanpa package tambahan (writer PNG minimal: signature + IHDR +
/// IDAT zlib-stored + IEND).
Uint8List buildDemoThumbnailBytes(String thumbnailId) {
  const width = 96;
  const height = 72;
  final hash = thumbnailId.codeUnits.fold<int>(
    0,
    (a, c) => (a * 31 + c) & 0xFF,
  );
  // Empat palet hangat bergantian per ID: krem, hijau uang, biru teks, ungu.
  const palettes = [
    [0xF5, 0xE6, 0xC8, 0x2E, 0x7D, 0x4F, 0x1E, 0x9E, 0x63, 0x4A, 0x47, 0xD6],
    [0xE8, 0xF5, 0xE9, 0x1B, 0x5E, 0x20, 0x2E, 0x7D, 0x32, 0xF5, 0xA5, 0x24],
    [0xE3, 0xF2, 0xFD, 0x0D, 0x47, 0xA1, 0x15, 0x65, 0xC0, 0xFF, 0x8F, 0x00],
    [0xF3, 0xE5, 0xF5, 0x4A, 0x14, 0x8C, 0x7B, 0x1F, 0xA2, 0xFF, 0xC1, 0x5A],
  ];
  final palette = palettes[hash % palettes.length];

  // Baris mentah: filter-byte 0 + RGB per piksel.
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    for (var x = 0; x < width; x++) {
      // Latar bergradasi vertikal + garis diagonal + bingkai gelap.
      final band = ((x + y + hash) ~/ 12) % 4;
      final edge = x < 3 || y < 3 || x >= width - 3 || y >= height - 3
          ? 3
          : band;
      final o = edge * 3;
      var r = palette[o], g = palette[o + 1], b = palette[o + 2];
      // Sorotan tengah: simulasi fokus kamera pada objek bacaan.
      final dx = x - width / 2, dy = y - height / 2;
      if (dx * dx / 900 + dy * dy / 500 < 1) {
        r = 0xFF - ((0xFF - r) ~/ 2);
        g = 0xFF - ((0xFF - g) ~/ 2);
        b = 0xFF - ((0xFF - b) ~/ 2);
      }
      raw.add([r, g, b]);
    }
  }
  final rawBytes = raw.toBytes();
  final idat = _zlibStored(rawBytes);

  BytesBuilder chunk(String type, List<int> data) {
    final out = BytesBuilder();
    final len = data.length;
    out.add([
      (len >> 24) & 0xFF,
      (len >> 16) & 0xFF,
      (len >> 8) & 0xFF,
      len & 0xFF,
    ]);
    final typeBytes = type.codeUnits;
    out.add(typeBytes);
    out.add(data);
    out.add(_crc32([...typeBytes, ...data]));
    return out;
  }

  final png = BytesBuilder();
  png.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  png.add(
    chunk('IHDR', [
      0, 0, 0, width, 0, 0, 0, height,
      8, // bit depth
      2, // truecolor
      0, 0, 0, // compression, filter, interlace
    ]).toBytes(),
  );
  png.add(chunk('IDAT', idat).toBytes());
  png.add(chunk('IEND', const []).toBytes());
  return png.toBytes();
}

/// Kompresor zlib minimal (blok stored tanpa kompresi).
///
/// PNG decoder menerima blok `stored` valid — ukuran ~20 KB untuk 96x72,
/// jauh di bawah batas 60 KB. Tanpa package tambahan.
List<int> _zlibStored(Uint8List raw) {
  final out = BytesBuilder();
  // Header zlib: CMF=0x78 (deflate 32K), FLG=0x01 (check bits + no preset).
  out.add([0x78, 0x01]);
  var offset = 0;
  while (offset < raw.length) {
    final end = (offset + 0xFFFF).clamp(0, raw.length);
    final block = raw.sublist(offset, end);
    final last = end >= raw.length;
    out.addByte(last ? 0x01 : 0x00);
    final len = block.length;
    out.add([
      len & 0xFF,
      (len >> 8) & 0xFF,
      (~len) & 0xFF,
      ((~len) >> 8) & 0xFF,
    ]);
    out.add(block);
    offset = end;
  }
  final adler = _adler32(raw);
  out.add([
    (adler >> 24) & 0xFF,
    (adler >> 16) & 0xFF,
    (adler >> 8) & 0xFF,
    adler & 0xFF,
  ]);
  return out.toBytes();
}

int _adler32(List<int> data) {
  var a = 1, b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  return (b << 16) | a;
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

List<int> _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  crc ^= 0xFFFFFFFF;
  return [
    (crc >> 24) & 0xFF,
    (crc >> 16) & 0xFF,
    (crc >> 8) & 0xFF,
    crc & 0xFF,
  ];
}
