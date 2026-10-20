import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Kebijakan gerak bersama: menghormati preferensi kurangi animasi sistem.
abstract final class MotionPolicy {
  /// Apakah sistem meminta animasi diminimalkan.
  static bool reduceAnimations(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Durasi animasi standar, atau nol saat preferensi kurangi animasi aktif.
  static Duration duration(BuildContext context, Duration standard) =>
      reduceAnimations(context) ? Duration.zero : standard;

  /// Kurva gerak standar desain.
  static Curve curve(BuildContext context) =>
      reduceAnimations(context) ? Curves.linear : DesignTokens.motionCurve;
}
