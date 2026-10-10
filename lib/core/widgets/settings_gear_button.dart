import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../router/app_router.dart';

/// Tombol gear Pengaturan di app bar tiap tab — satu-satunya pintu masuk
/// Pengaturan dari dalam shell.
///
/// Menggantikan kartu "Akun & Pengaturan" yang dulu disisipkan di body tiap
/// tab (ramai, tidak konsisten, memakan ruang scroll): pola ikon gear di
/// app bar adalah konvensi aplikasi profesional. Dibuka via `push` agar
/// tombol kembali Pengaturan punya stack untuk pulang.
class SettingsGearButton extends StatelessWidget {
  const SettingsGearButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      onPressed: () => const SettingsPath().push(context),
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n.settingsTitle,
    );
  }
}
