import 'package:equatable/equatable.dart';

/// Laporan hasil pembacaan yang siap dibagikan.
///
/// Privasi: tidak pernah memuat ID perangkat, lokasi, email, atau gambar
/// asli. Teks OCR dibatasi 500 karakter dan hanya disertakan bila pengguna
/// menyetujui dialog consent (PRD F10).
class ShareReport extends Equatable {
  const ShareReport({
    required this.title,
    required this.lines,
    this.ocrExcerpt,
  });

  /// Judul laporan, mis. jenis pembacaan + waktu.
  final String title;

  /// Baris-baris ringkasan (nilai, confidence, jarak, status validasi).
  final List<String> lines;

  /// Kutipan OCR yang sudah dipotong maksimal 500 karakter, atau null bila
  /// pengguna tidak menyetujui penyertaan teks.
  final String? ocrExcerpt;

  @override
  List<Object?> get props => [title, lines, ocrExcerpt];
}
