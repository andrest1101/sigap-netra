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
/// Sebagian item sudah divalidasi supaya demo memperlihatkan antrean Validasi,
/// akurasi, dan Riwayat yang terisi: 2 menunggu, 3 cocok, 1 tidak cocok —
/// akurasi 75% dari 4 validasi.
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
  ];
}

/// Implementasi [DetectionRepository] untuk data simulasi.
class FakeDetectionRepositoryImpl extends DetectionRepositoryImpl {
  FakeDetectionRepositoryImpl(super.dataSource, {required super.deviceNameOf});
}
