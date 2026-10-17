import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/app_constants.dart';

/// Memuat [kLogoMarkAsset] ke image cache global sebelum render pertama.
///
/// Di `flutter test`, dekode gambar aset berjalan di luar fake-async sehingga
/// `Image.asset` masih kosong (lingkaran putih) ketika frame golden diambil.
/// Dengan precache, `Image` menerima gambar dari cache secara sinkron dan
/// golden benar-benar memuat mark logo — bukan lingkaran kosong yang bisa
/// menyembunyikan regresi.
///
/// Panggil di setiap test yang merender mark logo ([LogoMark] langsung atau
/// lewat layar Splash/Beranda/Layar masuk/Detail perangkat), SEBELUM
/// `pumpWidget`. Bila cache sudah terisi, biayanya nol (sinkron).
Future<void> precacheLogoMark(WidgetTester tester) async {
  await tester.runAsync(() async {
    // Sama dengan `precacheImage` bawaan Flutter (hanya tanpa BuildContext).
    final ImageStream stream = const AssetImage(
      kLogoMarkAsset,
    ).resolve(ImageConfiguration.empty);
    final Completer<void> completer = Completer<void>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    await completer.future;
  });
}
