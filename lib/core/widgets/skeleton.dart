import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Placeholder abu untuk konten yang sedang dimuat.
///
/// Dipakai sebagai pengganti spinner saat struktur data sudah diketahui,
/// misalnya jumlah baris riwayat yang akan datang. Ini menjaga layout agar
/// tidak melompat setelah data tiba.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.borderRadius});

  /// Placeholder dengan tinggi tetap untuk baris teks.
  const Skeleton.line({super.key, this.width = double.infinity})
    : height = 14,
      borderRadius = null;

  /// Placeholder berbentuk lingkaran untuk avatar.
  const Skeleton.circle({super.key})
    : width = DesignTokens.deviceAvatarSize,
      height = DesignTokens.deviceAvatarSize,
      borderRadius = const BorderRadius.all(
        Radius.circular(DesignTokens.deviceAvatarSize / 2),
      );

  /// Placeholder berbentuk kartu.
  const Skeleton.card({super.key})
    : width = double.infinity,
      height = 96,
      borderRadius = const BorderRadius.all(
        Radius.circular(DesignTokens.radiusCard),
      );

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DesignTokens.animationSlow,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainerLow,
              _controller.value,
            ),
            borderRadius:
                widget.borderRadius ??
                const BorderRadius.all(
                  Radius.circular(DesignTokens.radiusBadge),
                ),
          ),
        );
      },
    );
  }
}

/// Daftar skeleton default untuk layar yang memuat daftar.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
      itemBuilder: (context, _) => const Skeleton.card(),
    );
  }
}
