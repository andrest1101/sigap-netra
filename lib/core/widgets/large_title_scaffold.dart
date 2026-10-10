import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Scaffold app bar standar M3 yang rapat + opsional judul-besar.
///
/// Mode default (rapat): `SliverAppBar` biasa tinggi ±64 dengan judul
/// 20/SemiBold — konten naik ~90px dibanding large-title. Mode large-title
/// tetap tersedia lewat [LargeTitleScaffold.large] bila suatu layar
/// menginginkannya.
///
/// Pengaturan dibuka lewat kartu [AccountSettingsCard] di dalam body, bukan
/// avatar menggantung di app bar.
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
    this.compact = true,
  });

  /// Varian judul-besar 28/Bold yang menyusut saat scroll (identitas v3).
  const LargeTitleScaffold.large({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
    this.fillRemaining = false,
  }) : compact = false;

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

  /// Bila true (default), app bar rapat ±64. Bila false, large-title 28/Bold.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          if (compact)
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
            )
          else
            SliverAppBar.large(
              title: Text(title),
              centerTitle: false,
              pinned: true,
              actions: actions,
              bottom: bottom,
            ),
          if (subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.spacePage,
                  0,
                  DesignTokens.spacePage,
                  compact ? DesignTokens.spaceSm : DesignTokens.spaceMd,
                ),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
