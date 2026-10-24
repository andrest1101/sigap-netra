import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/app_constants.dart';
import 'package:sigap_netra_app/features/media/data/models/media_model.dart';

void main() {
  const deviceId = 'simulasi-maixcam-1';
  const mediaId = 'det-money-100k';

  String encode(List<int> bytes) => base64Encode(bytes);

  Map<String, dynamic> doc(List<int> bytes) => {
    MediaFields.mime: MediaFields.mimeJpeg,
    MediaFields.size: bytes.length,
    MediaFields.bytes: encode(bytes),
  };

  group('MediaModel.fromData defensif', () {
    test('dokumen valid dipetakan ke entity', () {
      final bytes = List<int>.generate(64, (i) => i % 256);
      final thumbnail = MediaModel.fromData(
        data: doc(bytes),
        deviceId: deviceId,
        mediaId: mediaId,
      );

      expect(thumbnail, isNotNull);
      expect(thumbnail!.deviceId, deviceId);
      expect(thumbnail.mediaId, mediaId);
      expect(thumbnail.imageBytes, bytes);
    });

    test('thumbnail hingga 200 KB diterima', () {
      final bytes = List<int>.filled(kMaxThumbnailBytes, 7);
      final thumbnail = MediaModel.fromData(
        data: doc(bytes),
        deviceId: deviceId,
        mediaId: mediaId,
      );

      expect(thumbnail, isNotNull);
      expect(thumbnail!.imageBytes.length, kMaxThumbnailBytes);
    });

    test('data null menjadi null (tanpa gambar)', () {
      expect(
        MediaModel.fromData(data: null, deviceId: deviceId, mediaId: mediaId),
        isNull,
      );
    });

    test('mime salah menjadi null', () {
      final bytes = List<int>.filled(16, 1);
      final data = doc(bytes)..[MediaFields.mime] = 'image/png';

      expect(
        MediaModel.fromData(data: data, deviceId: deviceId, mediaId: mediaId),
        isNull,
      );
    });

    test('size nol atau lewat 200 KB menjadi null', () {
      final bytes = List<int>.filled(16, 1);
      final zero = doc(bytes)..[MediaFields.size] = 0;
      final over = doc(bytes)..[MediaFields.size] = kMaxThumbnailBytes + 1;
      final notInt = doc(bytes)..[MediaFields.size] = '100';

      for (final data in [zero, over, notInt]) {
        expect(
          MediaModel.fromData(data: data, deviceId: deviceId, mediaId: mediaId),
          isNull,
        );
      }
    });

    test('base64 kosong, rusak, atau lewat batas menjadi null', () {
      final bytes = List<int>.filled(16, 1);
      final empty = doc(bytes)..[MediaFields.bytes] = '';
      final broken = doc(bytes)..[MediaFields.bytes] = '!!!bukan-base64!!!';
      final tooLong = doc(bytes)
        ..[MediaFields.bytes] = 'a' * (kMaxThumbnailBase64Length + 1);

      for (final data in [empty, broken, tooLong]) {
        expect(
          MediaModel.fromData(data: data, deviceId: deviceId, mediaId: mediaId),
          isNull,
        );
      }
    });

    test('hasil decode kosong atau lewat 200 KB menjadi null', () {
      final emptyDoc = {
        MediaFields.mime: MediaFields.mimeJpeg,
        MediaFields.size: 10,
        MediaFields.bytes: encode(const <int>[]),
      };
      // Size tercatat kecil tapi bytes asli > 200 KB: tetap ditolak.
      final bigBytes = List<int>.filled(kMaxThumbnailBytes + 1, 7);
      final bigDoc = {
        MediaFields.mime: MediaFields.mimeJpeg,
        MediaFields.size: 100,
        MediaFields.bytes: encode(bigBytes),
      };

      expect(
        MediaModel.fromData(
          data: emptyDoc,
          deviceId: deviceId,
          mediaId: mediaId,
        ),
        isNull,
      );
      expect(
        MediaModel.fromData(data: bigDoc, deviceId: deviceId, mediaId: mediaId),
        isNull,
      );
    });
  });
}
