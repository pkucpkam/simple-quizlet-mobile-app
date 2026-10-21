import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';

class FlipCardWidget extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Function(bool isKnown)? onSwipeComplete;

  const FlipCardWidget({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.onFlip,
    this.onSwipeComplete,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  double _dragDx = 0.0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onFlip();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragDx += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragDx > 90 && widget.onSwipeComplete != null) {
          HapticFeedback.mediumImpact();
          widget.onSwipeComplete!(true); // Right swipe = Known
        } else if (_dragDx < -90 && widget.onSwipeComplete != null) {
          HapticFeedback.mediumImpact();
          widget.onSwipeComplete!(false); // Left swipe = Need review
        }
        setState(() {
          _dragDx = 0;
        });
      },
      child: Transform.translate(
        offset: Offset(_dragDx * 0.4, 0),
        child: Transform.rotate(
          angle: (_dragDx / 900) * (math.pi / 12),
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final isFront = angle < math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: isFront
                  ? _buildCard(context, widget.front, isFront: true)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildCard(context, widget.back, isFront: false),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget content, {required bool isFront}) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final surface = AppTheme.surface(context);
    final surface2 = AppTheme.surface2(context);
    final borderCol = AppTheme.border(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: isFront ? surface : surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: (!isDark)
            ? Border.all(
                color: isFront ? borderCol : accent.withValues(alpha: 0.5),
                width: isFront ? 1.0 : 1.8,
              )
            : null,
        boxShadow: [
          if (isDark) ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            if (!isFront)
              BoxShadow(
                color: accent.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ] else ...[
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            if (!isFront)
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ],
      ),
      child: content,
    );
  }
}
