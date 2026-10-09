import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Scaffold dengan app bar judul-besar yang menyusut saat scroll.
///
/// Pengganti `GradientHeader` sesuai identitas v3: tanpa gradien, tanpa foto
/// header — judul besar 28/Bold yang menyusut menjadi app bar standar.
/// [avatar] membuka Pengaturan (`/pengaturan`) sesuai arsitektur informasi v3.
class LargeTitleScaffold extends StatelessWidget {
  const LargeTitleScaffold({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.avatar,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget body;

  /// Avatar Pengaturan di kanan app bar. Bila null, tidak ada avatar.
  final Widget? avatar;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            centerTitle: false,
            pinned: true,
            actions: [
              ...actions,
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: DesignTokens.spaceSm),
              ],
            ],
            bottom: bottom,
          ),
          if (subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacePage,
                  0,
                  DesignTokens.spacePage,
                  DesignTokens.spaceMd,
                ),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: body),
        ],
      ),
    );
  }
}
