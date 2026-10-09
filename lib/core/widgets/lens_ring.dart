import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Pengukur melingkar bersegmen seperti diafragma lensa kamera.
///
/// Elemen khas (signature) identitas SIGAP-NETRA. Dipakai untuk % kecocokan,
/// baterai, dan animasi menunggu alat (mode [LensRingMode.focusing] dengan
/// cincin "fokus" berdenyut). Nilai 0.0-1.0; null berarti tidak tersedia
/// (tengah menampilkan [fallbackLabel], mis. "–" untuk baterai).
///
/// Aksesibilitas: selalu bungkus dengan `Semantics(label: ...)` dari pemanggil
/// ("Kecocokan 96 persen") karena cincin saja tidak terbaca screen reader.
enum LensRingMode {
  /// Menampilkan progres statis (kecocokan, baterai).
  value,

  /// Animasi cincin fokus berdenyut untuk status menunggu.
  focusing,
}

class LensRing extends StatefulWidget {
  const LensRing({
    required this.diameter,
    super.key,
    this.value,
    this.mode = LensRingMode.value,
    this.center,
    this.trackColor,
    this.progressColor,
    this.segments = 24,
    this.semanticsLabel,
  });

  /// Diameter luar cincin.
  final double diameter;

  /// Progres 0.0-1.0, atau null bila tidak tersedia.
  final double? value;

  final LensRingMode mode;

  /// Widget di tengah cincin. Bila null, menampilkan persen/angka bawaan.
  final Widget? center;

  final Color? trackColor;
  final Color? progressColor;

  /// Jumlah segmen diafragma.
  final int segments;

  final String? semanticsLabel;

  @override
  State<LensRing> createState() => _LensRingState();
}

class _LensRingState extends State<LensRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.mode == LensRingMode.focusing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LensRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == LensRingMode.focusing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.mode != LensRingMode.focusing &&
        _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final track = widget.trackColor ?? colorScheme.surfaceContainerHighest;
    final progress = widget.progressColor ?? colorScheme.primary;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget ring = CustomPaint(
      size: Size.square(widget.diameter),
      painter: _LensRingPainter(
        value: widget.value,
        trackColor: track,
        progressColor: progress,
        segments: widget.segments,
        focusPulse: widget.mode == LensRingMode.focusing && !reduceMotion
            ? _controller.value
            : null,
        strokeWidth: DesignTokens.lensRingStroke,
      ),
    );

    final label = widget.semanticsLabel;
    if (label != null) {
      ring = Semantics(label: label, value: _semanticsValue(), child: ring);
    }

    if (widget.center != null) {
      return SizedBox.square(
        dimension: widget.diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [ring, widget.center!],
        ),
      );
    }
    return ring;
  }

  String? _semanticsValue() {
    final value = widget.value;
    if (value == null) return null;
    return '${(value * 100).round()} persen';
  }
}

/// Pelukis cincin diafragma bersegmen.
class _LensRingPainter extends CustomPainter {
  _LensRingPainter({
    required this.trackColor,
    required this.progressColor,
    required this.segments,
    this.value,
    this.focusPulse,
    this.strokeWidth = 10,
  });

  final double? value;
  final Color trackColor;
  final Color progressColor;
  final int segments;
  final double? focusPulse;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - strokeWidth / 2;
    // Celah antar-segmen 18% dari sudut tiap segmen.
    final sweep = (math.pi * 2 / segments) * 0.82;
    final gap = (math.pi * 2 / segments) * 0.18;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Mulai dari atas (-90°) seperti pengukur melingkar lazim.
    const startOffset = -math.pi / 2;
    final filled = ((value ?? 0).clamp(0.0, 1.0) * segments).floor();

    for (var i = 0; i < segments; i++) {
      final start = startOffset + i * (sweep + gap);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        i < filled && value != null ? progressPaint : trackPaint,
      );
    }

    // Denyut fokus: lingkaran dalam yang membesar-mengecil.
    if (focusPulse != null) {
      final pulsePaint = Paint()
        ..color = progressColor.withValues(alpha: 0.25 + 0.35 * focusPulse!)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        center,
        radius * (0.55 + 0.12 * focusPulse!),
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LensRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.focusPulse != focusPulse ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.segments != segments;
  }
}
