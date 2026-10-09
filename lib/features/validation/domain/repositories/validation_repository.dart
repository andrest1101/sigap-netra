import '../../../monitoring/domain/entities/detection.dart';
import 'validation_summary.dart';

/// Kontrak repository validasi pada domain.
///
/// Tulis app ke Firestore dibatasi pada tiga field: `validationStatus`,
/// `validatedBy`, `validatedAt` (`docs/firestore_schema.md` bagian 1).
/// `validatedBy`/`validatedAt` tidak boleh dikosongkan saat validasi dicabut
/// supaya jejaknya tetap terlihat (skema bagian 4.2).
abstract interface class ValidationRepository {
  /// Memantau antrean pembacaan dengan status `pending`, terbaru dulu.
  ///
  /// Selalu per perangkat: schema tidak memakai collection group lintas
  /// perangkat (`docs/firestore_schema.md` bagian 2).
  Stream<List<Detection>> watchPendingDetections({
    required String deviceId,
    int limit = 20,
  });

  /// Menghitung akurasi manusia satu perangkat: `match / (match + mismatch)`.
  ///
  /// Implementasi Firestore memakai agregasi `count()` per status sesuai
  /// skema bagian 7.3, bukan mengunduh dokumen.
  Future<ValidationSummary> getValidationSummary({required String deviceId});

  /// Mengajukan validasi satu pembacaan.
  ///
  /// [status] hanya boleh `match` atau `mismatch`; `pending` bukan hasil
  /// validasi melainkan pembatalan (lihat [undoValidation]).
  Future<void> submitValidation({
    required String deviceId,
    required String detectionId,
    required ValidationStatus status,
    required String? validatedBy,
  });

  /// Mengembalikan pembacaan ke status `pending` dengan tetap menyimpan
  /// [validatedBy] sebagai jejak pembatalan.
  Future<void> undoValidation({
    required String deviceId,
    required String detectionId,
    required String? validatedBy,
  });
}
