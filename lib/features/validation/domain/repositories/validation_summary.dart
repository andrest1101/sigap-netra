import 'package:equatable/equatable.dart';

/// Ringkasan validasi manusia: `match / (match + mismatch)`.
///
/// `pending` tidak pernah dihitung dan tidak pernah diisi otomatis oleh
/// sistem (skema bagian 1). Nilai dihitung dari agregasi `count()`, bukan
/// dari dokumen yang diunduh.
class ValidationSummary extends Equatable {
  const ValidationSummary({
    required this.matches,
    required this.mismatches,
    required this.pending,
  });

  /// Ringkasan kosong untuk state awal.
  const ValidationSummary.empty() : matches = 0, mismatches = 0, pending = 0;

  final int matches;
  final int mismatches;
  final int pending;

  /// Jumlah validasi manusia (match + mismatch).
  int get decided => matches + mismatches;

  /// Akurasi 0.0-1.0, atau null bila belum ada validasi manusia.
  double? get accuracy {
    if (decided == 0) return null;
    return matches / decided;
  }

  @override
  List<Object?> get props => [matches, mismatches, pending];
}
