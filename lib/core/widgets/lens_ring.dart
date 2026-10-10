import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/status_colors.dart';

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
    this.unavailableIcon,
    this.batteryAdaptiveLevel,
  });

  /// Cincin baterai siap pakai: warna progres adaptif (ok ≥ 30%, warn 15-29%,
  /// bad < 15% memakai palet status tema), ikon baterai saat tidak tersedia.
  ///
  /// [batteryPct] 0-100, atau null bila perangkat tidak melaporkan baterai.
  /// [color] warna angka tengah; bila null memakai warna teks default tema.
  /// [trackColor] bila null memakai warna track default ([surfaceContainerHighest]).
  factory LensRing.battery({
    required double diameter,
    required int? batteryPct,
    required String availableLabel,
    required String unavailableLabel,
    Key? key,
    Color? color,
    Color? trackColor,
  }) {
    final value = batteryPct == null ? null : batteryPct / 100;
    return LensRing(
      key: key,
      diameter: diameter,
      value: value,
      trackColor: trackColor,
      semanticsLabel: batteryPct == null
          ? unavailableLabel
          : '$availableLabel $batteryPct persen',
      unavailableIcon: Icons.battery_unknown_rounded,
      center: batteryPct == null
          ? null
          : _BatteryNumber(value: '$batteryPct', color: color),
      // Penanda internal: `build` me-resolve warna progres adaptif dari tema.
      batteryAdaptiveLevel: batteryPct == null
          ? null
          : batteryPct >= 30
          ? BatteryAdaptiveLevel.ok
          : batteryPct >= 15
          ? BatteryAdaptiveLevel.warn
          : BatteryAdaptiveLevel.bad,
    );
  }

  /// Diameter luar cincin.
  final double diameter;

  /// Progres 0.0-1.0, atau null bila tidak tersedia.
  ///
  /// Bila null, cincin tampil sebagai 4 segmen penanda mata angin (elegan,
  /// jelas "tidak tersedia") — bukan 24 segmen abu penuh yang terlihat rusak.
  final double? value;

  final LensRingMode mode;

  /// Widget di tengah cincin. Bila null, menampilkan persen/angka bawaan.
  final Widget? center;

  final Color? trackColor;
  final Color? progressColor;

  /// Jumlah segmen diafragma.
  final int segments;

  final String? semanticsLabel;

  /// Ikon tengah saat [value] null. Default ikon lensa netral.
  final IconData? unavailableIcon;

  /// Penanda internal factory baterai: `build` me-resolve warna progres
  /// adaptif dari `StatusColors` tema aktif. Jangan diisi manual.
  final BatteryAdaptiveLevel? batteryAdaptiveLevel;

  @override
  State<LensRing> createState() => _LensRingState();
}

/// Level baterai untuk pewarnaan adaptif factory [LensRing.battery].
///
/// Nilai ini diisi otomatis oleh factory; jangan diisi manual saat memakai
/// konstruktor [LensRing] langsung.
enum BatteryAdaptiveLevel { ok, warn, bad }

/// Angka baterai tabular di tengah cincin.
class _BatteryNumber extends StatelessWidget {
  const _BatteryNumber({required this.value, this.color});

  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _LensRingState extends State<LensRing>
    with SingleTickerProviderStateMixin {
  // Dibuat di initState (bukan lazy): field lazy yang belum pernah dipakai
  // akan diinisialisasi saat dispose() — saat element sudah unmount — dan
  // `createTicker` melempar "deactivated widget's ancestor is unsafe".
  // Ini bug laten yang juga bisa crash di produksi.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
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
    // Factory baterai: warna progres adaptif dari palet status tema aktif.
    final adaptive = widget.batteryAdaptiveLevel;
    final adaptiveColor = adaptive == null
        ? null
        : switch (adaptive) {
            BatteryAdaptiveLevel.ok => StatusColors.of(context).ok.solid,
            BatteryAdaptiveLevel.warn => StatusColors.of(context).warn.solid,
            BatteryAdaptiveLevel.bad => StatusColors.of(context).bad.solid,
          };
    final progress =
        widget.progressColor ?? adaptiveColor ?? colorScheme.primary;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isUnavailable =
        widget.value == null && widget.mode == LensRingMode.value;

    Widget ring = CustomPaint(
      size: Size.square(widget.diameter),
      painter: _LensRingPainter(
        value: widget.value,
        trackColor: track,
        progressColor: progress,
        // State tak tersedia: 4 segmen mata angin, bukan cincin penuh.
        segments: isUnavailable ? 4 : widget.segments,
        unavailable: isUnavailable,
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

    final center =
        widget.center ??
        (isUnavailable
            ? Icon(
                widget.unavailableIcon ?? Icons.lens_blur_rounded,
                size: widget.diameter * 0.32,
                color: track,
              )
            : null);
    if (center != null) {
      return SizedBox.square(
        dimension: widget.diameter,
        child: Stack(alignment: Alignment.center, children: [ring, center]),
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
    this.unavailable = false,
  });

  final double? value;
  final Color trackColor;
  final Color progressColor;
  final int segments;
  final double? focusPulse;
  final double strokeWidth;

  /// State tak tersedia: gambar 4 segmen pendek di arah mata angin saja.
  final bool unavailable;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - strokeWidth / 2;
    // Celah antar-segmen 18% dari sudut tiap segmen; state unavailable memakai
    // segmen pendek (40%) agar terlihat seperti penanda, bukan cincin rusak.
    final ratio = unavailable ? 0.4 : 0.82;
    final sweep = (math.pi * 2 / segments) * ratio;
    final gap = (math.pi * 2 / segments) * (1 - ratio);

    final trackPaint = Paint()
      ..color = unavailable ? trackColor.withValues(alpha: 0.55) : trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = unavailable ? strokeWidth * 0.7 : strokeWidth
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
        oldDelegate.segments != segments ||
        oldDelegate.unavailable != unavailable;
  }
}
