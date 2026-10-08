import 'package:flutter/material.dart';

import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/device.dart';

/// Pemetaan status konektivitas ke warna dan ikon.
///
/// Satu-satunya tempat yang memutuskan tampilan "Online" dan "Terputus" agar
/// konsisten di Beranda, Perangkat, dan detail.
extension DeviceConnectivityDisplay on DeviceConnectivity {
  StatusPillData toPillData(AppLocalizations l10n) => switch (this) {
    DeviceConnectivity.online => StatusPillData(
      label: l10n.statusOnline,
      tone: AppStatusTone.success,
      icon: Icons.check_circle_outline,
    ),
    DeviceConnectivity.offline => StatusPillData(
      label: l10n.statusOffline,
      tone: AppStatusTone.error,
      icon: Icons.cloud_off,
    ),
    DeviceConnectivity.unknown => StatusPillData(
      label: l10n.statusUnvalidated,
      tone: AppStatusTone.neutral,
      icon: Icons.help_outline,
    ),
  };

  /// Label singkat tanpa ikon, untuk pemakaian non-`StatusPill`.
  String toShortLabel(AppLocalizations l10n) => switch (this) {
    DeviceConnectivity.online => l10n.statusOnline,
    DeviceConnectivity.offline => l10n.statusOffline,
    DeviceConnectivity.unknown => l10n.statusUnvalidated,
  };

  /// Warna solid untuk indikator kecil.
  Color solidColor(StatusColors palette) => switch (this) {
    DeviceConnectivity.online => palette.success.solid,
    DeviceConnectivity.offline => palette.error.solid,
    DeviceConnectivity.unknown => palette.neutral.solid,
  };
}

/// Data yang dibutuhkan `StatusPill` untuk menampilkan sebuah status.
class StatusPillData {
  const StatusPillData({required this.label, required this.tone, this.icon});

  final String label;
  final AppStatusTone tone;
  final IconData? icon;
}
