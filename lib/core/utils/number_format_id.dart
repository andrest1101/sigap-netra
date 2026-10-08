import 'package:intl/intl.dart';

/// Fungsi murni untuk format angka dan mata uang gaya Indonesia.
///
/// Memakai locale `id` sehingga pemisah ribuan titik dan desimal koma,
/// misalnya `Rp 10.000,00`. Nilai uang dari device dapat datang sebagai
/// integer (nominal rupiah penuh) maupun double (nominal pecahan untuk
/// mata uang asing), jadi keduanya diterima.
abstract final class NumberFormatId {
  static final NumberFormat _integer = NumberFormat.decimalPattern('id');
  static final NumberFormat _twoDecimals = NumberFormat('#,##0.00', 'id');
  static final NumberFormat _percent = NumberFormat('#,##0', 'id');

  /// Bilangan bulat dengan pemisah ribuan, misalnya `10.000`.
  static String integer(int value) => _integer.format(value);

  /// Angka desimal dengan dua digit, misalnya `10.000,00`.
  static String decimal(num value) => _twoDecimals.format(value);

  /// Nominal uang tanpa simbol mata uang.
  static String amount(num value) {
    if (value == value.roundToDouble()) {
      return _integer.format(value.toInt());
    }
    return _twoDecimals.format(value);
  }

  /// Nominal uang untuk mata uang rupiah.
  static String rupiah(num value) => 'Rp ${amount(value)}';

  /// Persentase bulat, misalnya `85`.
  static String percent(num value) => _percent.format(value.round());

  /// Persentase dengan tanda persen, misalnya `85%`.
  static String percentWithSign(num value) => '${percent(value)}%';
}
