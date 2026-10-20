import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/app_constants.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/media/data/datasources/fake_media_data_source.dart';
import 'package:sigap_netra_app/features/monitoring/data/datasources/fake_detection_data_source.dart';

void main() {
  FakeMediaDataSource graph() {
    TestWidgetsFlutterBinding.ensureInitialized();
    return FakeMediaDataSource(FakeDetectionDataSource());
  }

  group('FakeMediaDataSource', () {
    test('dua dummy aset uang di bawah 60 KB dan bytes berbeda', () async {
      final media = graph();
      final money100k = await media.getThumbnail(
        deviceId: kDemoDeviceId,
        thumbnailId: 'det-money-100k',
      );
      final money50k = await media.getThumbnail(
        deviceId: kDemoDeviceId,
        thumbnailId: 'det-money-50k',
      );

      expect(money100k, isNotNull);
      expect(money50k, isNotNull);
      expect(
        money100k!.imageBytes.length,
        lessThanOrEqualTo(kMaxThumbnailBytes),
      );
      expect(
        money50k!.imageBytes.length,
        lessThanOrEqualTo(kMaxThumbnailBytes),
      );
      // Dua pecahan berbeda = dua foto berbeda, bukan satu gambar dipakai
      // ulang.
      expect(money100k.imageBytes, isNot(money50k.imageBytes));
    });

    test('evict membuang cache thumbnail yang dihapus', () async {
      final media = graph();
      final first = await media.getThumbnail(
        deviceId: kDemoDeviceId,
        thumbnailId: 'det-money-100k',
      );
      media.evict('det-money-100k');
      final second = await media.getThumbnail(
        deviceId: kDemoDeviceId,
        thumbnailId: 'det-money-100k',
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(identical(first, second), isFalse);
    });

    test('ID tanpa aset / device salah / id kosong menjadi null', () async {
      final media = graph();

      // `det-text-menu` sengaja tidak punya foto demo: jangan mengarang
      // gambar prosedural yang terlihat seperti gambar rusak.
      expect(
        await media.getThumbnail(
          deviceId: kDemoDeviceId,
          thumbnailId: 'det-text-menu',
        ),
        isNull,
      );
      expect(
        await media.getThumbnail(
          deviceId: kDemoDeviceId,
          thumbnailId: 'tidak-ada',
        ),
        isNull,
      );
      expect(
        await media.getThumbnail(deviceId: 'lain', thumbnailId: 'det-100k'),
        isNull,
      );
      expect(
        await media.getThumbnail(deviceId: kDemoDeviceId, thumbnailId: ''),
        isNull,
      );
    });

    test('cache memori: panggilan kedua memakai instance sama', () async {
      final media = graph();
      final first = await media.getThumbnail(
        deviceId: kDemoDeviceId,
        thumbnailId: 'det-money-50k',
      );
      final second = await media.getThumbnail(
        deviceId: kDemoDeviceId,
        thumbnailId: 'det-money-50k',
      );

      expect(identical(first, second), isTrue);
    });
  });
}
