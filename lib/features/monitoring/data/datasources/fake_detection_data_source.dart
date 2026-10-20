import 'dart:async';

import '../../../../core/constants/demo_ids.dart';
import '../../domain/entities/detection.dart';
import '../../domain/repositories/detection_repository.dart';
import '../repositories/detection_repository_impl.dart';
import 'detection_data_source.dart';

/// Sumber data pembacaan simulasi untuk mode pengembang.
///
/// Data disimpan in-memory dan hilang saat aplikasi ditutup, sesuai sifat
/// simulasi. Dipakai juga sebagai dasar demo Validasi dan Riwayat sampai
/// repository production terhubung ke Firestore.
class FakeDetectionDataSource implements DetectionDataSource {
  final StreamController<List<Detection>> _controller =
      StreamController<List<Detection>>.broadcast();

  List<Detection> _items = _sample();

  /// Isi saat ini, dipakai fake data sources lain yang berbagi penyimpanan
  /// (mis. validasi) dan dipakai test.
  List<Detection> get itemsForTest => List<Detection>.unmodifiable(_items);

  void _emit() {
    _controller.add(List<Detection>.unmodifiable(_items));
  }

  /// Mengganti seluruh isi simulasi, dipakai test dan demo reset.
  void replaceAll(List<Detection> items) {
    _items = List<Detection>.of(items);
    _emit();
  }

  @override
  Stream<List<Detection>> watchLatestDetections({
    required String deviceId,
    required String deviceName,
    int limit = 10,
  }) {
    if (deviceId != kDemoDeviceId) {
      return Stream<List<Detection>>.value(const <Detection>[]);
    }
    final sorted = _sorted(_items).take(limit).toList(growable: false);
    return Stream<List<Detection>>.multi((controller) {
      controller.add(sorted);
      final subscription = _controller.stream.listen((items) {
        controller.add(_sorted(items).take(limit).toList(growable: false));
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<Detection?> watchDetection({
    required String deviceId,
    required String deviceName,
    required String detectionId,
  }) {
    if (deviceId != kDemoDeviceId) {
      return Stream<Detection?>.value(null);
    }

    Detection? current() {
      for (final item in _items) {
        if (item.id == detectionId) return item;
      }
      return null;
    }

    return Stream<Detection?>.multi((controller) {
      controller.add(current());
      final subscription = _controller.stream.listen((_) {
        controller.add(current());
      });
      controller.onCancel = subscription.cancel;
    });
  }

  static List<Detection> _sorted(List<Detection> items) {
    final sorted = List<Detection>.of(items);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  void dispose() {
    _controller.close();
  }
}

/// Daftar contoh awal untuk pengembangan UI: HANYA uang dan teks OCR.
///
/// Kacamata SIGAP-NETRA hanya membaca DUA hal: (1) pecahan uang (YOLO),
/// (2) teks pada posisi baca normal — label/menu/sampul yang dihadapkan ke
/// kamera dari jarak dekat. BUKAN OCR bebas: contoh JANGAN berupa rambu
/// jalan, papan reklame, atau dokumen yang tidak dihadapkan ke kamera.
/// Jangan menambah contoh selain dua jenis ini.
///
/// Struktur data demo:
/// - 6 bacaan **hari ini** (relatif ke `now`, jadi "aktivitas terbaru"
///   Beranda selalu terlihat hidup): 2 menunggu, 3 cocok, 1 tidak cocok.
/// - [_pastDetections]: 27 hari ke belakang dari [_pastDayPattern] supaya
///   panel Statistik dan paginasi Riwayat punya data nyata untuk dihitung —
///   bukan grafik kosong.
List<Detection> _sample() {
  final now = DateTime.now();
  return [
    Detection(
      id: 'det-money-100k',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.money,
      createdAt: now.subtract(const Duration(seconds: 12)),
      amount: 100000,
      confidence: 0.95,
      distanceCm: 30,
      thumbnailId: 'det-money-100k',
    ),
    Detection(
      id: 'det-money-50k',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.money,
      createdAt: now.subtract(const Duration(minutes: 1)),
      amount: 50000,
      confidence: 0.92,
      distanceCm: 35,
      thumbnailId: 'det-money-50k',
      validationStatus: ValidationStatus.match,
      validatedBy: kDemoUserId,
      validatedAt: now.subtract(const Duration(seconds: 40)),
    ),
    Detection(
      id: 'det-text-menu',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.text,
      createdAt: now.subtract(const Duration(minutes: 2)),
      // Satu item menu utuh (bukan dua baris ambigu): label yang
      // dihadapkan ke kamera dari jarak baca normal.
      ocrText: 'AYAM GORENG — Rp15.000',
      confidence: 0.9,
      distanceCm: 25,
      // Sengaja TANPA thumbnail: demo foto hanya tersedia untuk dua pecahan
      // uang. Item teks memakai panel "tanpa gambar" yang jujur, bukan gambar
      // prosedural yang mudah terbaca sebagai gambar rusak.
      validationStatus: ValidationStatus.match,
      validatedBy: kDemoUserId,
      validatedAt: now.subtract(const Duration(minutes: 1, seconds: 30)),
    ),
    Detection(
      id: 'det-money-10k',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.money,
      createdAt: now.subtract(const Duration(minutes: 3)),
      amount: 10000,
      confidence: 0.88,
      distanceCm: 28,
      validationStatus: ValidationStatus.mismatch,
      validatedBy: kDemoUserId,
      validatedAt: now.subtract(const Duration(minutes: 2, seconds: 30)),
    ),
    Detection(
      id: 'det-text-sampul',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.text,
      createdAt: now.subtract(const Duration(minutes: 4)),
      ocrText: 'PANDUAN\nBELAJAR BRAILLE',
      confidence: 0.86,
      distanceCm: null,
      // Sengaja TANPA thumbnail: demo panel "tidak diunggah" tetap hidup
      // (opt-in mati / upload gagal) di samping kartu bergambar.
    ),
    Detection(
      id: 'det-money-20k',
      deviceId: kDemoDeviceId,
      deviceName: kDemoDeviceName,
      type: DetectionType.money,
      createdAt: now.subtract(const Duration(minutes: 5)),
      amount: 20000,
      confidence: 0.9,
      distanceCm: 32,
      validationStatus: ValidationStatus.match,
      validatedBy: kDemoUserId,
      validatedAt: now.subtract(const Duration(minutes: 4, seconds: 30)),
    ),
    ..._pastDetections(now),
  ];
}

/// Pola bacaan 27 hari ke belakang: indeks 0 = kemarin.
///
/// (uang, teks, tidak cocok) per hari. Ada hari bernilai nol dengan sengaja:
/// alat memang tidak dipakai setiap hari, dan panel Statistik harus
/// memperlihatkan jeda itu apa adanya — bukan grafik rata buatan.
const List<(int, int, int)> _pastDayPattern = [
  (4, 2, 0), // kemarin
  (5, 1, 0),
  (3, 2, 1),
  (0, 0, 0), // tidak dipakai
  (4, 1, 0),
  (6, 2, 1),
  (5, 1, 0),
  (4, 2, 0),
  (3, 1, 0),
  (0, 0, 0),
  (5, 2, 1),
  (4, 1, 0),
  (6, 1, 0),
  (3, 1, 0),
  (5, 1, 1),
  (0, 0, 0),
  (4, 2, 0),
  (6, 1, 0),
  (3, 1, 0),
  (4, 2, 1),
  (2, 1, 0),
  (3, 1, 0),
  (0, 0, 0),
  (4, 1, 0),
  (3, 1, 1),
  (0, 0, 0),
  (3, 0, 0),
];

/// Bacaan 27 hari terakhir untuk demo, dibangkitkan dari [_pastDayPattern].
///
/// Deterministik (tanpa acak) supaya golden test dan angka panel Statistik
/// stabil, dan jam-nya dipatok ke tanggal (`today - n`) supaya pengelompokan
/// per hari tidak berubah tergantung jam test dijalankan. Semua entri sudah
/// diperiksa pendamping: hanya bacaan hari ini yang masih menunggu validasi.
/// Tanpa thumbnail — media demo hanya ada untuk beberapa item hari ini, dan
/// baris tanpa gambar memang keadaan nyata saat opt-in thumbnail mati.
List<Detection> _pastDetections(DateTime today) {
  const amounts = [100000, 50000, 20000, 10000, 5000, 2000, 1000];
  const labels = [
    'NASI GORENG — Rp18.000',
    'MIE AYAM — Rp12.000',
    'ES TEH MANIS — Rp5.000',
    'SUSU KOTAK 250 ML',
    'MADU 500 ML',
    'TISU 250 LEMBAR',
  ];
  const confidences = [0.94, 0.9, 0.87, 0.95, 0.92, 0.85, 0.89];

  final items = <Detection>[];
  var pick = 0;
  for (var index = 0; index < _pastDayPattern.length; index++) {
    final (money, text, mismatch) = _pastDayPattern[index];
    final daysAgo = index + 1;
    for (var i = 0; i < money + text; i++) {
      final isMoney = i < money;
      final createdAt = DateTime(
        today.year,
        today.month,
        today.day - daysAgo,
        8 + ((daysAgo * 3 + i * 2) % 11),
        (daysAgo * 7 + i * 17) % 60,
      );
      items.add(
        Detection(
          id: 'det-history-$daysAgo-$i',
          deviceId: kDemoDeviceId,
          deviceName: kDemoDeviceName,
          type: isMoney ? DetectionType.money : DetectionType.text,
          createdAt: createdAt,
          amount: isMoney ? amounts[pick % amounts.length] : null,
          ocrText: isMoney ? null : labels[pick % labels.length],
          confidence: confidences[pick % confidences.length],
          distanceCm: 20 + (pick * 3) % 25,
          validationStatus: i < mismatch
              ? ValidationStatus.mismatch
              : ValidationStatus.match,
          validatedBy: kDemoUserId,
          validatedAt: createdAt.add(const Duration(minutes: 2)),
        ),
      );
      pick++;
    }
  }
  return items;
}

/// Implementasi [DetectionRepository] untuk data simulasi.
class FakeDetectionRepositoryImpl extends DetectionRepositoryImpl {
  FakeDetectionRepositoryImpl(super.dataSource, {required super.deviceNameOf});
}
