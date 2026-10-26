import '../../../../core/constants/app_constants.dart';
import '../../../monitoring/domain/entities/detection.dart';

/// Memilih pembacaan baru yang layak dinotifikasikan.
///
/// Dua pagar menjaga agar notifikasi tetap berguna dan tidak membanjiri:
/// pembacaan yang lebih tua dari [maxAge] diabaikan (mis. antrean offline yang
/// baru tersinkron), dan jumlahnya dibatasi [maxCount] per emisi. Hasil
/// diurutkan dari yang terbaru; pemanggil membaliknya bila ingin notifikasi
/// terbaru tampil paling akhir.
List<Detection> selectNotifiableDetections(
  List<Detection> candidates, {
  required DateTime now,
  Duration maxAge = kNotificationFreshness,
  int maxCount = kNotificationMaxPerBatch,
}) {
  if (maxCount <= 0) return const <Detection>[];

  final fresh = <Detection>[
    for (final detection in candidates)
      if (now.difference(detection.createdAt) <= maxAge) detection,
  ];

  fresh.sort((a, b) {
    final byTime = b.createdAt.compareTo(a.createdAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });

  return fresh.take(maxCount).toList(growable: false);
}
