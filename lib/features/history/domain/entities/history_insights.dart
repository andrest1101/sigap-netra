import 'package:equatable/equatable.dart';

/// Jendela waktu panel Statistik (Riwayat → segmen Statistik).
///
/// Dua pilihan saja, dan keduanya dibataskan supaya biaya baca tetap kecil:
/// setiap batang grafik = satu `count()` agregat per jenis, bukan unduhan
/// dokumen (`docs/firestore_schema.md` §7.3 poin 3 dan 5).
enum HistoryWindow {
  /// 7 hari terakhir — satu batang per hari.
  week(days: 7, bucketSize: HistoryBucketSize.day),

  /// 4 minggu terakhir (28 hari) — satu batang per minggu. 28 = 4 × 7 sehingga
  /// semua batang sama panjang (tidak ada potongan hari di ujung).
  month(days: 28, bucketSize: HistoryBucketSize.week);

  const HistoryWindow({required this.days, required this.bucketSize});

  /// Panjang jendela dalam hari.
  final int days;

  /// Lebar satu batang grafik.
  final HistoryBucketSize bucketSize;

  bool get isDaily => bucketSize == HistoryBucketSize.day;
}

/// Lebar batang grafik panel Statistik.
enum HistoryBucketSize { day, week }

/// Rentang waktu satu batang grafik: `[start, end)` di waktu lokal.
class InsightRange extends Equatable {
  const InsightRange({required this.start, required this.end});

  /// Awal rentang, inklusif (tengah malam lokal).
  final DateTime start;

  /// Akhir rentang, eksklusif (tengah malam lokal hari berikutnya).
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);

  @override
  List<Object?> get props => [start, end];
}

/// Satu batang grafik: jumlah pembacaan uang dan teks pada [range].
class InsightBucket extends Equatable {
  const InsightBucket({
    required this.range,
    required this.money,
    required this.text,
  });

  const InsightBucket.empty(this.range) : money = 0, text = 0;

  final InsightRange range;
  final int money;
  final int text;

  int get total => money + text;

  @override
  List<Object?> get props => [range, money, text];
}

/// Ringkasan agregat Riwayat untuk satu [HistoryWindow].
///
/// Semua angka berasal dari `count()` di server (atau padanannya di sumber
/// data simulasi) — tidak ada dokumen pembacaan yang diunduh untuk panel ini.
class HistoryInsights extends Equatable {
  const HistoryInsights({
    required this.window,
    required this.buckets,
    required this.matched,
    required this.mismatched,
    required this.pending,
  });

  final HistoryWindow window;

  /// Urut lama → baru (kiri → kanan grafik).
  final List<InsightBucket> buckets;

  /// Validasi manusia di dalam jendela: cocok, tidak cocok, belum diperiksa.
  final int matched;
  final int mismatched;
  final int pending;

  int get money => buckets.fold(0, (sum, bucket) => sum + bucket.money);

  int get text => buckets.fold(0, (sum, bucket) => sum + bucket.text);

  int get total => money + text;

  /// Total validasi manusia (cocok + tidak cocok) — dasar persentase akurasi.
  int get decided => matched + mismatched;

  /// Akurasi pembulatan bulat, atau null bila belum ada validasi sama sekali.
  ///
  /// Selalu `cocok / (cocok + tidak cocok)` — tidak pernah menghitung
  /// pembacaan yang belum diperiksa sebagai "benar" (integritas validasi).
  int? get accuracyPercent =>
      decided == 0 ? null : (matched * 100 / decided).round();

  /// Rata-rata pembacaan per hari pada jendela ini.
  double get averagePerDay => total / window.days;

  bool get isEmpty => total == 0;

  @override
  List<Object?> get props => [window, buckets, matched, mismatched, pending];
}

/// Awal hari (tengah malam lokal) untuk [value].
DateTime startOfLocalDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Tengah malam lokal [daysOffset] hari dari [base].
///
/// Memakai konstruktor `DateTime` (bukan `add(Duration(days: 1))`) supaya
/// pergeseran tetap jatuh tepat di tengah malam lokal di zona dengan DST.
DateTime _localDayStart(DateTime base, int daysOffset) =>
    DateTime(base.year, base.month, base.day + daysOffset);

/// Rentang batang untuk [window] yang berakhir di hari [now].
///
/// Batang terakhir selalu **berakhir besok tengah malam** (hari ini ikut
/// dihitung), dan batang pertama mulai dari tengah malam lokal — pagar
/// setengah terbuka `[start, end)` dipakai konsisten di data layer.
List<InsightRange> insightWindowRanges({
  required DateTime now,
  required HistoryWindow window,
}) {
  final start = _localDayStart(now, -(window.days - 1));
  final end = _localDayStart(now, 1);
  final span = switch (window.bucketSize) {
    HistoryBucketSize.day => 1,
    HistoryBucketSize.week => 7,
  };

  // Dibangun dari belakang: batang terakhir = 7 hari terakhir yang berakhir
  // hari ini, bukan minggu kalender yang bisa terpotong di kedua ujung.
  final ranges = <InsightRange>[];
  var cursor = end;
  while (cursor.isAfter(start)) {
    final bucketStart = _localDayStart(cursor, -span);
    ranges.insert(
      0,
      InsightRange(
        start: bucketStart.isBefore(start) ? start : bucketStart,
        end: cursor,
      ),
    );
    cursor = bucketStart;
  }
  return ranges;
}
