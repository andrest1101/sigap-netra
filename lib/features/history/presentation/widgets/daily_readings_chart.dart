import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/history_insights.dart';

/// Grafik batang bertumpuk panel Statistik: pembacaan **uang** vs **teks**
/// per hari (jendela 7 hari) atau per minggu (jendela 4 minggu).
///
/// Digambar sendiri, bukan `fl_chart`: `fl_chart` pernah dipasang di pubspec
/// (^1.1.0) tetapi tidak dapat dikompilasi dengan Flutter 3.32 (butuh
/// `vector_math` ≥ 2.2 sementara SDK memaku 2.1.4) dan sudah **dihapus** dari
/// dependensi. Grafik ini hanya butuh satu bentuk batang bertumpuk — jauh
/// lebih ringan daripada menarik satu paket grafik penuh. Tinggi batang,
/// warna, dan label mengikuti token desain v3 apa adanya.
///
/// Warna memakai peran brand — `primary` untuk uang, `tertiary` untuk teks —
/// bukan warna status: komposisi jenis bacaan bukan status keberhasilan.
/// Angka per batang datang dari agregasi `count()` server, bukan unduhan
/// dokumen (`docs/firestore_schema.md` §7.3 poin 3 dan 5).
///
/// Aksesibilitas: seluruh grafik dibungkus satu label ringkas ("… pembacaan
/// dalam … hari terakhir") dan isi grafik dikeluarkan dari pohon semantik —
/// batang tidak dapat dibaca satu per satu oleh pembaca layar, jadi angkanya
/// diringkas, bukan dibacakan bertumpuk.
class DailyReadingsChart extends StatelessWidget {
  const DailyReadingsChart({required this.insights, super.key});

  final HistoryInsights insights;

  /// Tinggi area batang (tanpa ruang angka di atas batang).
  static const double _plotHeight = 140;

  /// Ruang angka total di atas setiap batang.
  static const double _valueLabelHeight = 16;

  /// Lebar kolom label sumbu Y.
  static const double _axisWidth = 32;

  static final DateFormat _weekday = DateFormat('E', 'id');
  static final DateFormat _dayMonth = DateFormat('d MMM', 'id');

  /// Tangga sumbu Y: puncak + jarak garis, keduanya bilangan bulat.
  ///
  /// Dipakai agar label kiri selalu angka utuh (bukan 12,5 hasil pembagian
  /// otomatis) dan garis bantu tidak terlalu rapat untuk nilai besar.
  static const List<({int max, int interval})> _axisLadder = [
    (max: 5, interval: 5),
    (max: 10, interval: 5),
    (max: 20, interval: 10),
    (max: 50, interval: 10),
    (max: 100, interval: 25),
    (max: 200, interval: 50),
    (max: 500, interval: 100),
    (max: 1000, interval: 250),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final buckets = insights.buckets;
    final peak = buckets.fold(
      0,
      (max, bucket) => bucket.total > max ? bucket.total : max,
    );
    // Panel kosong sudah ditangani pemanggil lewat empty state; grafik tanpa
    // data cukup tidak digambar.
    if (peak == 0) return const SizedBox.shrink();

    final axis = _axisFor(peak);
    final isDaily = insights.window.isDaily;
    final barWidth = isDaily ? 20.0 : 36.0;
    final ticks = [
      for (var value = axis.interval; value <= axis.max; value += axis.interval)
        value,
    ];

    return Semantics(
      container: true,
      label: l10n.historyStatsChartSemantics(
        insights.total,
        insights.window.days,
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _plotHeight + _valueLabelHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: _axisWidth,
                    height: _plotHeight + _valueLabelHeight,
                    child: Stack(
                      children: [
                        for (final tick in ticks)
                          Positioned(
                            right: DesignTokens.spaceSm,
                            // Label duduk di tengah garis bantunya.
                            bottom:
                                _valueLabelHeight +
                                tick / axis.max * _plotHeight -
                                7,
                            child: Text(
                              NumberFormatId.integer(tick),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        for (final tick in ticks)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom:
                                _valueLabelHeight +
                                tick / axis.max * _plotHeight,
                            child: Container(
                              height: 1,
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final bucket in buckets)
                              Expanded(
                                child: _Bar(
                                  bucket: bucket,
                                  axisMax: axis.max,
                                  width: barWidth,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Row(
              children: [
                const SizedBox(width: _axisWidth),
                for (final bucket in buckets)
                  Expanded(
                    child: Text(
                      isDaily
                          ? _weekday.format(bucket.range.start)
                          : _dayMonth.format(bucket.range.start),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static ({int max, int interval}) _axisFor(int peak) {
    for (final step in _axisLadder) {
      if (peak <= step.max) return step;
    }
    // Nilai di luar tangga (mis. > 1.000 pembacaan dalam satu minggu): pakai
    // puncak apa adanya agar batang tertinggi tidak terpotong.
    return (max: peak, interval: (peak / 4).ceil().clamp(1, peak));
  }
}

/// Satu batang bertumpuk: uang di bawah, teks di atasnya, ujung membulat.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.bucket,
    required this.axisMax,
    required this.width,
  });

  final InsightBucket bucket;
  final int axisMax;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final money = bucket.money;
    final text = bucket.text;
    final total = bucket.total;
    // Batang sekecil apa pun tetap terlihat (min 4 px) supaya hari dengan satu
    // pembacaan tidak tampak seperti hari kosong.
    final height = total == 0
        ? 0.0
        : (total / axisMax * DailyReadingsChart._plotHeight).clamp(
            4.0,
            DailyReadingsChart._plotHeight,
          );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: DailyReadingsChart._valueLabelHeight,
          child: total == 0
              ? null
              : Center(
                  child: Text(
                    NumberFormatId.integer(total),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
        ),
        SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Column(
              // `stretch`: `ColoredBox` tanpa anak menyusut jadi nol pada
              // sumbu lintang yang longgar — batang akan tak terlihat.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (text > 0)
                  Expanded(
                    flex: text,
                    child: ColoredBox(color: colorScheme.tertiary),
                  ),
                if (money > 0)
                  Expanded(
                    flex: money,
                    child: ColoredBox(color: colorScheme.primary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
