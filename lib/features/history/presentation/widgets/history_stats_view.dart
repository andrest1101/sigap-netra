import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/number_format_id.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/history_insights.dart';
import '../providers/history_providers.dart';
import 'daily_readings_chart.dart';

/// Segmen **Statistik** pada tab Riwayat (P1).
///
/// Semua angka berasal dari agregasi `count()` per batang dan per status
/// (`docs/firestore_schema.md` §7.3 poin 3 dan 5) — tidak ada dokumen
/// pembacaan yang diunduh untuk panel ini, sehingga membuka Statistik tetap
/// murah di kuota Spark walau riwayat perangkat sudah panjang.
///
/// Jendela waktu sengaja hanya dua (7 hari / 4 minggu): jendela 4 minggu
/// dipotong menjadi 4 blok 7 hari agar semua batang sama panjang — tidak ada
/// batang "setengah minggu" yang membingungkan pembaca.
class HistoryStatsView extends ConsumerStatefulWidget {
  const HistoryStatsView({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<HistoryStatsView> createState() => _HistoryStatsViewState();
}

class _HistoryStatsViewState extends ConsumerState<HistoryStatsView> {
  HistoryWindow _window = HistoryWindow.week;

  @override
  Widget build(BuildContext context) {
    final key = HistoryInsightsKey(deviceId: widget.deviceId, window: _window);
    final insights = ref.watch(historyInsightsProvider(key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WindowSelector(
          window: _window,
          onChanged: (window) => setState(() => _window = window),
        ),
        insights.when(
          loading: () => const _StatsSkeleton(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceMd,
              DesignTokens.spacePage,
              0,
            ),
            child: ErrorView(
              message: _failureText(context, error),
              onRetry: () => ref.invalidate(historyInsightsProvider(key)),
            ),
          ),
          data: (data) => data.isEmpty
              ? _StatsEmpty(
                  window: _window,
                  onExtend: () => setState(() => _window = HistoryWindow.month),
                )
              : _StatsBody(insights: data),
        ),
        const SizedBox(height: DesignTokens.spaceSection),
      ],
    );
  }
}

/// Pemilih rentang: 7 hari (batang harian) atau 4 minggu (batang mingguan).
class _WindowSelector extends StatelessWidget {
  const _WindowSelector({required this.window, required this.onChanged});

  final HistoryWindow window;
  final ValueChanged<HistoryWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
        DesignTokens.spacePage,
        0,
      ),
      child: Wrap(
        spacing: DesignTokens.spaceSm,
        children: [
          ChoiceChip(
            label: Text(l10n.historyStatsRange7),
            selected: window == HistoryWindow.week,
            onSelected: (_) => onChanged(HistoryWindow.week),
          ),
          ChoiceChip(
            label: Text(l10n.historyStatsRange4Weeks),
            selected: window == HistoryWindow.month,
            onSelected: (_) => onChanged(HistoryWindow.month),
          ),
        ],
      ),
    );
  }
}

/// Isi panel saat ada data: hero akurasi, grafik, komposisi jenis & validasi.
class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.insights});

  final HistoryInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacePage,
            DesignTokens.spaceMd,
            DesignTokens.spacePage,
            0,
          ),
          child: _AccuracyHero(insights: insights),
        ),
        _SectionTitle(
          label: insights.window.isDaily
              ? l10n.historyStatsChartDaily
              : l10n.historyStatsChartWeekly,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: _ChartCard(insights: insights),
        ),
        _SectionTitle(label: l10n.historyStatsTypesTitle),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: _SplitCard(
            semanticsLabel: l10n.historyStatsTypeSemantics(
              insights.money,
              insights.text,
            ),
            segments: [
              _SplitSegment(
                label: l10n.historyTypeMoney,
                count: insights.money,
                color: Theme.of(context).colorScheme.primary,
              ),
              _SplitSegment(
                label: l10n.historyTypeText,
                count: insights.text,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
            total: insights.total,
          ),
        ),
        _SectionTitle(label: l10n.historyStatsValidationTitle),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacePage,
          ),
          child: _SplitCard(
            semanticsLabel: l10n.historyStatsValidationSemantics(
              insights.matched,
              insights.mismatched,
              insights.pending,
            ),
            segments: [
              _SplitSegment(
                label: l10n.statusMatch,
                count: insights.matched,
                color: StatusColors.of(context).ok.solid,
              ),
              _SplitSegment(
                label: l10n.statusMismatch,
                count: insights.mismatched,
                color: StatusColors.of(context).bad.solid,
              ),
              _SplitSegment(
                label: l10n.statusPending,
                count: insights.pending,
                color: StatusColors.of(context).warn.solid,
              ),
            ],
            total: insights.total,
          ),
        ),
      ],
    );
  }
}

/// Kartu hero: ring akurasi (identitas lensa, sama seperti Beranda) + 3 angka
/// kunci jendela.
class _AccuracyHero extends StatelessWidget {
  const _AccuracyHero({required this.insights});

  final HistoryInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onHero = colorScheme.onPrimaryContainer;
    final accuracy = insights.accuracyPercent;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LensRing(
                diameter: 92,
                value: accuracy == null ? null : accuracy / 100,
                progressColor: StatusColors.of(context).ok.solid,
                semanticsLabel: accuracy == null
                    ? l10n.historyStatsAccuracyTitle
                    : l10n.homeAccuracySemantic('$accuracy%'),
                center: Text(
                  accuracy == null ? '–' : '$accuracy%',
                  style: textTheme.titleLarge?.copyWith(
                    color: onHero,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.historyStatsAccuracyTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: onHero,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      accuracy == null
                          ? l10n.historyStatsNoValidation
                          : l10n.historyStatsAccuracyCaption(insights.decided),
                      style: textTheme.labelMedium?.copyWith(
                        color: onHero.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Container(height: 1, color: onHero.withValues(alpha: 0.25)),
          const SizedBox(height: DesignTokens.spaceMd),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    value: NumberFormatId.integer(insights.total),
                    label: l10n.historyStatsTotalLabel,
                    color: onHero,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: onHero.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _MiniStat(
                    value:
                        '≈${NumberFormatId.integer(insights.averagePerDay.round())}',
                    label: l10n.historyStatsPerDayLabel,
                    color: onHero,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: onHero.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _MiniStat(
                    value: NumberFormatId.integer(insights.pending),
                    label: l10n.historyStatsPendingLabel,
                    color: StatusColors.of(context).warn.content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu angka kunci: nilai besar + label kecil di bawahnya.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// Kartu grafik batang + legenda dua kategori.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.insights});

  final HistoryInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: DesignTokens.spaceLg,
            runSpacing: DesignTokens.spaceXs,
            children: [
              _LegendItem(
                label: l10n.historyTypeMoney,
                color: colorScheme.primary,
              ),
              _LegendItem(
                label: l10n.historyTypeText,
                color: colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          DailyReadingsChart(insights: insights),
        ],
      ),
    );
  }
}

/// Kartu komposisi: satu batang bertumpuk + legenda berangka.
class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.semanticsLabel,
    required this.segments,
    required this.total,
  });

  final String semanticsLabel;
  final List<_SplitSegment> segments;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = segments.where((s) => s.count > 0).toList();

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.spaceSm),
              child: SizedBox(
                height: 12,
                child: Row(
                  // `stretch`: tanpa ini `ColoredBox` tanpa anak runtuh jadi
                  // tinggi nol (segmen berwarna tak terlihat).
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final segment in visible)
                      Expanded(
                        flex: segment.count,
                        child: ColoredBox(color: segment.color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Wrap(
              spacing: DesignTokens.spaceLg,
              runSpacing: DesignTokens.spaceSm,
              children: [
                for (final segment in segments)
                  _LegendItem(
                    label:
                        '${segment.label} · '
                        '${l10n.historyStatsLegendValue(segment.count, total == 0 ? 0 : (segment.count * 100 / total).round())}',
                    color: segment.color,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitSegment {
  const _SplitSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

/// Titik warna + label untuk legenda grafik dan komposisi.
///
/// Warna tidak pernah berdiri sendiri: setiap titik selalu berdampingan
/// dengan label teksnya.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DesignTokens.spaceSm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Judul seksi panel Statistik.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceSection,
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Kartu tonal standar panel: `surfaceContainerLow` + hairline, tanpa shadow.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Empty state jujur: tidak ada pembacaan pada rentang yang dipilih.
class _StatsEmpty extends StatelessWidget {
  const _StatsEmpty({required this.window, required this.onExtend});

  final HistoryWindow window;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        0,
        DesignTokens.spacePage,
        0,
      ),
      child: EmptyView(
        icon: Icons.query_stats_rounded,
        title: l10n.historyStatsEmptyTitle,
        message: l10n.historyStatsEmptyBody,
        action: window == HistoryWindow.week
            ? FilledButton.tonalIcon(
                onPressed: onExtend,
                icon: const Icon(Icons.calendar_view_week_rounded),
                label: Text(l10n.historyStatsEmptyAction),
              )
            : null,
      ),
    );
  }
}

/// Kerangka pemuatan panel: tinggi mendekati isi asli agar tidak melompat.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
        DesignTokens.spacePage,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton(
            height: 210,
            borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
          ),
          const SizedBox(height: DesignTokens.spaceSection),
          Skeleton(
            height: 260,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          ),
          const SizedBox(height: DesignTokens.spaceSection),
          Skeleton(
            height: 96,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          ),
        ],
      ),
    );
  }
}

/// Pesan error siap tampil untuk panel ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}
