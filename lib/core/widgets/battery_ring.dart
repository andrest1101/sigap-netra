import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'lens_ring.dart';

/// Indikator baterai: cincin + label, dipakai identik di Beranda (Hero) dan
/// tab Perangkat agar tidak ada lagi dua versi yang divergen.
///
/// [numberColor]/[trackColor]: override untuk konteks background khusus
/// (mis. Hero `primaryContainer` → `onPrimaryContainer`). Bila null memakai
/// warna default tema (angka = warna teks, track = `surfaceContainerHighest`).
class BatteryRing extends StatelessWidget {
  const BatteryRing({
    required this.batteryPct,
    super.key,
    this.diameter = 64,
    this.numberColor,
    this.trackColor,
  });

  final int? batteryPct;
  final double diameter;
  final Color? numberColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final defaultLabelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LensRing.battery(
          diameter: diameter,
          batteryPct: batteryPct,
          availableLabel: l10n.homeBatteryLabel,
          unavailableLabel: l10n.homeBatteryUnavailable,
          color: numberColor,
          trackColor: trackColor,
        ),
        const SizedBox(height: 2),
        Text(
          l10n.homeBatteryLabel,
          style: textTheme.labelSmall?.copyWith(
            color: numberColor ?? defaultLabelColor,
          ),
        ),
      ],
    );
  }
}
