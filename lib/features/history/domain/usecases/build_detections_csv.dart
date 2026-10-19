import '../../../../core/utils/number_format_id.dart';
import '../../../monitoring/domain/entities/detection.dart';

/// Membangun isi berkas CSV ekspor Riwayat (fungsi murni, teruji unit).
///
/// Keputusan format (lihat `docs/ui_spec.md` §5.3 dan PRD F12):
/// - Header: `waktu;jenis;nilai;mata_uang;teks;keyakinan;jarak_cm;status`.
/// - Pemisah **titik-koma** + BOM UTF-8 di awal berkas supaya langsung rapi
///   dibuka di Excel locale Indonesia (pemisah daftar `;`, desimal `,`).
/// - `waktu` memakai jam lokal perangkat, format `yyyy-MM-dd HH:mm:ss`.
/// - `nilai` dan `keyakinan` memakai koma desimal tanpa pemisah ribuan
///   (mis. `50000`, `0,92`) agar dikenali Excel sebagai angka, bukan teks.
/// - Teks OCR dinormalkan ke satu baris (`\n`/`\r` → ` · `) supaya tidak ada
///   sel multi-baris yang menyulitkan editor/pembaca CSV sederhana.
/// - Sel yang memuat `;`, kutip ganda, atau baris baru dibungkus kutip ganda
///   dengan kutip di dalamnya digandakan (RFC 4180).
///
/// Status memakai kata yang sama dengan UI (`Menunggu`, `Cocok`,
/// `Tidak cocok`) supaya berkas bisa dibaca pendamping tanpa kamus enum.
String buildDetectionsCsv(List<Detection> detections) {
  final rows = <String>[
    _csvRow(_headerCells),
    for (final detection in detections) _csvRow(_cells(detection)),
  ];
  return '$_bom${rows.join('\r\n')}\r\n';
}

const String _bom = '\uFEFF';

const List<String> _headerCells = <String>[
  'waktu',
  'jenis',
  'nilai',
  'mata_uang',
  'teks',
  'keyakinan',
  'jarak_cm',
  'status',
];

List<String> _cells(Detection detection) {
  final isMoney = detection.type == DetectionType.money;
  // Nilai uang hanya bermakna untuk baris uang; teks tidak membawa nominal.
  final amount = isMoney ? detection.amount : null;
  return <String>[
    _timestamp(detection.createdAt.toLocal()),
    isMoney ? 'uang' : 'teks',
    amount == null ? '' : NumberFormatId.plain(amount),
    amount == null ? '' : detection.currency,
    _singleLine(detection.ocrText ?? detection.label ?? ''),
    detection.confidence == null
        ? ''
        : NumberFormatId.plain(detection.confidence!),
    detection.distanceCm == null ? '' : '${detection.distanceCm}',
    _statusLabel(detection.validationStatus),
  ];
}

String _singleLine(String value) {
  return value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', ' · ');
}

String _timestamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}-${two(time.month)}-'
      '${two(time.day)} ${two(time.hour)}:${two(time.minute)}:'
      '${two(time.second)}';
}

String _statusLabel(ValidationStatus status) {
  return switch (status) {
    ValidationStatus.pending => 'Menunggu',
    ValidationStatus.match => 'Cocok',
    ValidationStatus.mismatch => 'Tidak cocok',
  };
}

String _csvRow(List<String> cells) => cells.map(_escape).join(';');

String _escape(String value) {
  final needsQuotes =
      value.contains(';') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}
