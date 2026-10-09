import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/detection.dart';

final detectionsProvider =
    NotifierProvider<DetectionsController, List<Detection>>(
      DetectionsController.new,
    );

/// Antrean validasi: hanya pembacaan yang belum divalidasi.
final pendingDetectionsProvider = Provider<List<Detection>>((ref) {
  return ref
      .watch(detectionsProvider)
      .where((item) => item.validationStatus == ValidationStatus.pending)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

class DetectionsController extends Notifier<List<Detection>> {
  /// Contoh UI sementara.
  ///
  /// Jangan dipakai sebagai model pagination Firestore. Contoh ini hanya
  /// untuk melihat susunan layar validasi/riwayat sampai repository
  /// production dan daftar `type` device dikonfirmasi.
  @override
  List<Detection> build() => _sample();

  void markValidated({
    required String id,
    required ValidationStatus status,
    required String? validatedBy,
  }) {
    state = [
      for (final detection in state)
        if (detection.id == id)
          detection.withValidationStatus(
            validationStatus: status,
            validatedBy: validatedBy,
            validatedAt: DateTime.now(),
          )
        else
          detection,
    ];
  }

  void reset(String id) {
    state = [
      for (final detection in state)
        if (detection.id == id)
          detection.withValidationStatus(
            validationStatus: ValidationStatus.pending,
            validatedBy: null,
            validatedAt: null,
          )
        else
          detection,
    ];
  }

  /// Menyembunyikan item untuk hapus-dengan-undo di Riwayat demo.
  ///
  /// Bukan hapus permanen: Fase 2 lanjutan memakai `DeleteDetection`
  /// (deteksi + `media`). Item dikembalikan lewat [restoreForUndo].
  void removeForUndo(String id) {
    state = [
      for (final detection in state)
        if (detection.id != id) detection,
    ];
  }

  /// Mengembalikan item yang disembunyikan [removeForUndo], di posisi
  /// terurut waktu terbaru-dulu.
  void restoreForUndo(Detection detection) {
    state = [...state, detection]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

List<Detection> _sample() {
  final now = DateTime.now();
  return [
    Detection(
      id: 'det-money-50k',
      deviceId: 'simulasi-maixcam-1',
      deviceName: 'Kacamata Kamar',
      type: DetectionType.money,
      createdAt: now.subtract(const Duration(seconds: 12)),
      amount: 50000,
      label: 'Nominal 50.000',
      confidence: 0.92,
      distanceCm: 35,
    ),
    Detection(
      id: 'det-text-menu',
      deviceId: 'simulasi-maixcam-1',
      deviceName: 'Kacamata Kamar',
      type: DetectionType.text,
      createdAt: now.subtract(const Duration(minutes: 1)),
      ocrText: 'Es Teh Manis Rp8.000, Nasi Goreng Rp25.000',
      confidence: 0.88,
      distanceCm: null,
    ),
    Detection(
      id: 'det-money-20k',
      deviceId: 'simulasi-maixcam-1',
      deviceName: 'Kacamata Kamar',
      type: DetectionType.money,
      createdAt: now.subtract(const Duration(minutes: 4)),
      amount: 20000,
      label: 'Nominal 20.000',
      confidence: 0.79,
      distanceCm: 22,
    ),
  ];
}
