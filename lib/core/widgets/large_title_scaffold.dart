import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Scaffold app bar rapat untuk empat tab akar.
///
/// Nama class dipertahankan agar pemanggil tidak berubah, tetapi header ini
/// sengaja **bukan** large-title: judul 18/SemiBold duduk sebaris dengan aksi
/// di app bar paling atas, sehingga konten tidak terdorong ke bawah. Subjudul
/// kontekstual (nama perangkat, progres validasi, jumlah riwayat) berada tepat
/// di bawah app bar dan ikut tergulir.
///
/// Layar anak memakai [BackAppBar] dengan judul 18/SemiBold agar hierarki
/// navigasi tetap terbaca.
class LargeTitleScaffold extends StatelessWidget {
  const LargeTitleScaffold({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
    this.fillRemaining = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;

  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;

  /// Bila true, body mengisi sisa viewport dengan tinggi terbatas.
  ///
  /// Wajib dipakai layar yang butuh `Expanded` di dalam body (mis. antrean
  /// Validasi): `Expanded` di dalam `SliverToBoxAdapter` tidak punya batas
  /// tinggi sehingga melempar layout exception dan layar gagal render total.
  final bool fillRemaining;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverAppBar(
            title: Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
            pinned: true,
            actions: actions,
            bottom: bottom,
          ),
          if (subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacePage,
                  0,
                  DesignTokens.spacePage,
                  DesignTokens.spaceSm,
                ),
                child: Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (fillRemaining)
            SliverFillRemaining(hasScrollBody: true, child: body)
          else
            SliverToBoxAdapter(child: body),
        ],
      ),
    );
  }
}
