import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

/// Fungsi murni untuk memformat waktu relatif dalam Bahasa Indonesia.
///
/// Sengaja tidak menerima objek `BuildContext`: pesan l10n diteruskan sebagai
/// parameter agar fungsi ini mudah diuji tanpa widget tree.
abstract final class RelativeTime {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy', 'id');
  static final DateFormat _dateTimeFormat = DateFormat(
    'd MMM yyyy, HH:mm',
    'id',
  );

  /// Menampilkan waktu relatif untuk [timestamp].
  ///
  /// Mengembalikan `timeNever` bila [timestamp] null. Lebih lama dari 7 hari
  /// akan ditampilkan sebagai tanggal absolut agar teks tidak terlalu ambigu.
  static String format(
    DateTime? timestamp,
    DateTime now, {
    required AppLocalizations l10n,
  }) {
    if (timestamp == null) return l10n.timeNever;

    final difference = now.difference(timestamp);

    if (difference.isNegative) {
      return _dateTimeFormat.format(timestamp);
    }

    if (difference.inSeconds < 60) return l10n.timeJustNow;
    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    }
    if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    }

    return _dateFormat.format(timestamp);
  }

  /// Format tanggal absolut untuk detail dan riwayat.
  static String date(DateTime value) => _dateFormat.format(value);

  /// Format tanggal dan jam absolut.
  static String dateTime(DateTime value) => _dateTimeFormat.format(value);
}
