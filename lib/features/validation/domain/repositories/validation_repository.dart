import '../../../monitoring/domain/entities/detection.dart';

/// Kontrak repository validasi pada domain.
///
/// Repository konkret untuk Firestore belum diimplementasikan karena
/// kontrak security/rules device dan peran anggota masih berstatus
/// `[PERLU KONFIRMASI]` di `docs/firestore_schema.md`.
abstract interface class ValidationRepository {
  /// Memantau antrean pembacaan dengan status `pending`.
  Stream<List<Detection>> watchPendingDetections({int limit = 20});

  /// Menghitung akurasi manusia: `match / (match + mismatch)`.
  Future<double?> getValidationAccuracy({int limit = 1000});

  /// Mengajukan validasi satu pembacaan.
  Future<void> submitValidation({
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  });

  /// Mengembalikan pembacaan ke status `pending` bila kebijakan pembatalan
  /// sudah dikonfirmasi.
  Future<void> undoValidation({required String detectionId});
}
