import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../utils/motion_policy.dart';

/// Menyimpan seluruh navigator tab, dengan fade-through hanya pada dua cabang
/// yang sedang berganti. Cabang lain tetap offstage dan tidak menerima input.
class FadeThroughBranchContainer extends StatefulWidget {
  const FadeThroughBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  }) : assert(children.length > 0),
       assert(currentIndex >= 0 && currentIndex < children.length);

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranchContainer> createState() =>
      _FadeThroughBranchContainerState();
}

class _FadeThroughBranchContainerState extends State<FadeThroughBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _incomingOpacity;
  late final Animation<double> _outgoingOpacity;
  int? _outgoingIndex;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.animationMedium,
      value: 1,
    )..addStatusListener(_handleStatus);
    _incomingOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: DesignTokens.motionCurve),
    );
    _outgoingOpacity = ReverseAnimation(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.35, curve: Curves.easeInCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MotionPolicy.reduceAnimations(context);
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    _controller.duration = MotionPolicy.duration(
      context,
      DesignTokens.animationMedium,
    );
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 1;
      _outgoingIndex = null;
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FadeThroughBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    if (_reduceMotion == true) {
      _outgoingIndex = null;
      _controller.value = 1;
      return;
    }
    _controller.stop();
    _outgoingIndex = oldWidget.currentIndex;
    _controller
      ..duration = MotionPolicy.duration(context, DesignTokens.animationMedium)
      ..forward(from: 0);
    setState(() {});
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _outgoingIndex == null) return;
    setState(() => _outgoingIndex = null);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.currentIndex;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          _buildBranch(index, active),
      ],
    );
  }

  Widget _buildBranch(int index, int activeIndex) {
    final isActive = index == activeIndex;
    final isOutgoing = _reduceMotion != true && index == _outgoingIndex;
    final isVisible = isActive || isOutgoing;
    final opacity = isOutgoing
        ? _outgoingOpacity
        : isActive && _outgoingIndex != null && _reduceMotion != true
        ? _incomingOpacity
        : const AlwaysStoppedAnimation<double>(1);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isActive,
        child: FadeTransition(
          opacity: isVisible
              ? opacity
              : const AlwaysStoppedAnimation<double>(0),
          child: Offstage(
            offstage: !isVisible,
            child: TickerMode(
              enabled: isActive,
              child: ExcludeSemantics(
                excluding: !isActive,
                child: widget.children[index],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
