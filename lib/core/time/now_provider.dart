import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sumber waktu tunggal untuk tampilan relatif dan perhitungan status.
///
/// Produksi memakai `DateTime.now`; test dan golden dapat menggantinya dengan
/// waktu tetap agar teks relatif/absolut tidak berubah antar-jalan.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
