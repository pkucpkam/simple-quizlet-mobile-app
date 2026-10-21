import 'package:flutter/material.dart';

/// Provides a smooth staggered entrance animation (fade in + slight slide up).
class StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Duration delayStep;
  final Offset slideOffset;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delayStep = const Duration(milliseconds: 35),
    this.slideOffset = const Offset(0, 0.12),
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    final delay = widget.delayStep * widget.index.clamp(0, 8);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
