import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';

/// Batas tinggi sheet agar tetap terasa seperti bottom sheet, bukan layar
/// penuh. Isi yang panjang digulir; baris aksi tidak pernah ikut tergulir.
const double _maxSheetHeightFactor = 0.85;

/// Bottom sheet konfirmasi destruktif dengan gaya v3.
///
/// Judul menyebut objek yang dikenai aksi. Tombol destruktif tidak otomatis
/// terfokus — fokus default pada tombol batal/pertahankan (identitas v3 §7).
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    super.key,
    this.icon = Icons.warning_amber_rounded,
    this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;
  final VoidCallback? onConfirm;

  /// Menampilkan sheet dan mengembalikan true bila pengguna mengonfirmasi.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxSheetHeightFactor,
      ),
      builder: (context) => ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        icon: icon,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _SheetFrame(
      title: title,
      message: message,
      icon: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceSm),
        decoration: ShapeDecoration(
          color: colorScheme.errorContainer,
          shape: const StadiumBorder(),
        ),
        child: Icon(icon, color: colorScheme.onErrorContainer),
      ),
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet persetujuan privasi dengan gaya v3.
///
/// Dipakai untuk opt-in thumbnail dan consent berbagi OCR: menjelaskan data
/// apa yang dikirim sebelum pengguna menyetujui.
class ConsentSheet extends StatelessWidget {
  const ConsentSheet({
    required this.title,
    required this.message,
    required this.acceptLabel,
    super.key,
    this.icon = Icons.privacy_tip_outlined,
  });

  final String title;
  final String message;
  final String acceptLabel;
  final IconData icon;

  /// Menampilkan sheet dan mengembalikan true bila pengguna menyetujui.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String acceptLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxSheetHeightFactor,
      ),
      builder: (context) => ConsentSheet(
        title: title,
        message: message,
        acceptLabel: acceptLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _SheetFrame(
      title: title,
      message: message,
      icon: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceSm),
        decoration: ShapeDecoration(
          color: colorScheme.tertiaryContainer,
          shape: const StadiumBorder(),
        ),
        child: Icon(icon, color: colorScheme.onTertiaryContainer),
      ),
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(acceptLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kerangka bersama ConfirmSheet/ConsentSheet.
///
/// Isi (ikon + judul + pesan) berada di dalam [Flexible] +
/// [SingleChildScrollView], sedangkan baris aksi dipaku di bawah dan hanya
/// ikut SafeArea. Dengan begitu teks panjang pada layar 360x640 + 1,3x
/// menggulir di tengah, tetapi tombol Batal/aksi tidak pernah hilang.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  final Widget icon;
  final String title;
  final String message;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacePage,
                0,
                DesignTokens.spacePage,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      icon,
                      const SizedBox(width: DesignTokens.spaceMd),
                      Expanded(child: Text(title, style: textTheme.titleLarge)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacePage,
              DesignTokens.spaceLg,
              DesignTokens.spacePage,
              DesignTokens.spacePage,
            ),
            child: actions,
          ),
        ],
      ),
    );
  }
}

/// Helper snackbar Urungkan: aksi penting tidak hilang sebelum dibaca.
///
/// [onUndo] dijalankan bila pengguna mengetuk aksi. Durasi default 5 detik
/// sesuai identitas v3 (validasi, hapus riwayat).
void showUndoSnackbar(
  BuildContext context, {
  required String message,
  required String actionLabel,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 5),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(label: actionLabel, onPressed: onUndo),
    ),
  );
}
