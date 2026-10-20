import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A multi-layer, physics-inspired animated flickering flame widget.
/// Renders an authentic burning fire with an outer heat glow aura,
/// main flame, hot inner core, and floating micro-spark particles at 60fps.
class FlickeringFlameWidget extends StatefulWidget {
  final double size;
  final int streakCount;
  final bool isInteractive;
  final VoidCallback? onTap;

  const FlickeringFlameWidget({
    super.key,
    this.size = 48.0,
    this.streakCount = 1,
    this.isInteractive = true,
    this.onTap,
  });

  @override
  State<FlickeringFlameWidget> createState() => _FlickeringFlameWidgetState();
}

class _FlickeringFlameWidgetState extends State<FlickeringFlameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FlameSpark> _sparks = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Initialize initial sparks
    for (int i = 0; i < 6; i++) {
      _sparks.add(_FlameSpark.random(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    // Burst extra sparks on tap
    setState(() {
      for (int i = 0; i < 5; i++) {
        _sparks.add(_FlameSpark.burst(_random));
      }
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasStreak = widget.streakCount > 0;

    return GestureDetector(
      onTap: widget.isInteractive ? _onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          // Update sparks life
          for (final spark in _sparks) {
            spark.update();
            if (spark.isDead) {
              spark.reset(_random);
            }
          }

          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _FlamePainter(
              progress: progress,
              hasStreak: hasStreak,
              sparks: _sparks,
              streakTier: widget.streakCount >= 7 ? 2 : (widget.streakCount >= 3 ? 1 : 0),
            ),
          );
        },
      ),
    );
  }
}

class _FlameSpark {
  double x; // -1.0 to 1.0 relative to flame center
  double y; // 0.0 (bottom) to 1.2 (above flame)
  double size;
  double opacity;
  double speedY;
  double speedX;
  bool isDead = false;

  _FlameSpark({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedY,
    required this.speedX,
  });

  factory _FlameSpark.random(math.Random rand) {
    return _FlameSpark(
      x: (rand.nextDouble() - 0.5) * 0.8,
      y: rand.nextDouble() * 0.7 + 0.3,
      size: rand.nextDouble() * 2.5 + 1.2,
      opacity: rand.nextDouble() * 0.8 + 0.2,
      speedY: rand.nextDouble() * 0.02 + 0.015,
      speedX: (rand.nextDouble() - 0.5) * 0.015,
    );
  }

  factory _FlameSpark.burst(math.Random rand) {
    return _FlameSpark(
      x: (rand.nextDouble() - 0.5) * 1.0,
      y: rand.nextDouble() * 0.3 + 0.3,
      size: rand.nextDouble() * 3.2 + 1.8,
      opacity: 1.0,
      speedY: rand.nextDouble() * 0.04 + 0.025,
      speedX: (rand.nextDouble() - 0.5) * 0.03,
    );
  }

  void update() {
    y += speedY;
    x += speedX;
    opacity -= 0.025;
    if (opacity <= 0 || y >= 1.4) {
      isDead = true;
    }
  }

  void reset(math.Random rand) {
    x = (rand.nextDouble() - 0.5) * 0.7;
    y = rand.nextDouble() * 0.3 + 0.2;
    size = rand.nextDouble() * 2.2 + 1.2;
    opacity = rand.nextDouble() * 0.7 + 0.3;
    speedY = rand.nextDouble() * 0.02 + 0.012;
    speedX = (rand.nextDouble() - 0.5) * 0.015;
    isDead = false;
  }
}

class _FlamePainter extends CustomPainter {
  final double progress;
  final bool hasStreak;
  final List<_FlameSpark> sparks;
  final int streakTier; // 0: 1-2 days, 1: 3-6 days, 2: 7+ days

  _FlamePainter({
    required this.progress,
    required this.hasStreak,
    required this.sparks,
    required this.streakTier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.62;

    if (!hasStreak) {
      _paintDormantEmber(canvas, size, cx, cy);
      return;
    }

    // Animation waves
    final wave1 = math.sin(progress * 2 * math.pi);
    final wave2 = math.cos(progress * 4 * math.pi);
    final flickerScaleY = 1.0 + wave1 * 0.08 + wave2 * 0.03;
    final flickerScaleX = 1.0 - wave1 * 0.04;
    final swayX = math.sin(progress * 2 * math.pi + 0.5) * 2.5;

    // ── 1. Outer Glow Aura ───────────────────────────────────────────
    final glowRadius = size.width * (0.45 + (streakTier * 0.08) + wave1 * 0.05);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF97316).withValues(alpha: 0.35 + wave1 * 0.1),
          const Color(0xFFEF4444).withValues(alpha: 0.15 + wave1 * 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx + swayX * 0.5, cy), radius: glowRadius));

    canvas.drawCircle(Offset(cx + swayX * 0.5, cy), glowRadius, glowPaint);

    // ── 2. Outer Flame (Red-Orange) ──────────────────────────────────
    canvas.save();
    canvas.translate(cx + swayX, cy);
    canvas.scale(flickerScaleX, flickerScaleY);

    final outerPath = _createFlamePath(size.width * 0.34, size.height * 0.52, wave1, wave2);
    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFFDC2626), // Deep Crimson base
          Color(0xFFEA580C), // Bright Red-Orange
          Color(0xFFF97316), // Vivid Orange tip
        ],
      ).createShader(Rect.fromCenter(
        center: const Offset(0, -10),
        width: size.width * 0.8,
        height: size.height,
      ));

    canvas.drawPath(outerPath, outerPaint);

    // ── 3. Mid Flame (Warm Amber-Orange) ─────────────────────────────
    final midScaleX = 0.72 + wave2 * 0.03;
    final midScaleY = 0.78 + wave1 * 0.04;
    canvas.save();
    canvas.scale(midScaleX, midScaleY);

    final midPath = _createFlamePath(size.width * 0.30, size.height * 0.48, -wave1, wave2);
    final midPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFFEA580C),
          Color(0xFFF59E0B), // Radiant Amber
          Color(0xFFFBBF24), // Golden Amber
        ],
      ).createShader(Rect.fromCenter(
        center: const Offset(0, -5),
        width: size.width * 0.6,
        height: size.height * 0.8,
      ));

    canvas.drawPath(midPath, midPaint);
    canvas.restore();

    // ── 4. Inner Hot Core (Golden Yellow to White) ────────────────────
    final coreScaleX = 0.45 + wave1 * 0.04;
    final coreScaleY = 0.52 + wave2 * 0.05;
    canvas.save();
    canvas.scale(coreScaleX, coreScaleY);

    final corePath = _createFlamePath(size.width * 0.24, size.height * 0.40, wave2, wave1);
    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFFFBBF24),
          Color(0xFFFEF08A), // Bright Sun Yellow
          Colors.white,      // Pure hot core
        ],
      ).createShader(Rect.fromCenter(
        center: const Offset(0, 0),
        width: size.width * 0.4,
        height: size.height * 0.6,
      ));

    canvas.drawPath(corePath, corePaint);
    canvas.restore();

    canvas.restore(); // Restore root translation

    // ── 5. Sparks / Embers ───────────────────────────────────────────
    for (final spark in sparks) {
      if (spark.isDead || spark.opacity <= 0) continue;
      final sx = cx + spark.x * (size.width * 0.4);
      final sy = cy - spark.y * (size.height * 0.65);
      final sparkPaint = Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: spark.opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);
      canvas.drawCircle(Offset(sx, sy), spark.size, sparkPaint);
    }
  }

  void _paintDormantEmber(Canvas canvas, Size size, double cx, double cy) {
    final emberPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF78716C).withValues(alpha: 0.6),
          const Color(0xFF44403C).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.35));

    canvas.drawCircle(Offset(cx, cy), size.width * 0.3, emberPaint);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: '🔥',
        style: TextStyle(
          fontSize: size.width * 0.5,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(cx - iconPainter.width / 2, cy - iconPainter.height / 2),
    );
  }

  Path _createFlamePath(double width, double height, double waveA, double waveB) {
    final path = Path();
    path.moveTo(0, height * 0.2);

    path.cubicTo(
      -width * 0.95, height * 0.15,
      -width * 1.15, -height * 0.35,
      -width * 0.55 + waveA * 3.0, -height * 0.70,
    );

    path.cubicTo(
      -width * 0.25 + waveB * 2.0, -height * 0.90,
      -width * 0.08 + waveA * 4.0, -height * 1.10,
      0 + waveA * 5.0, -height * 1.18,
    );

    path.cubicTo(
      width * 0.12 - waveB * 3.0, -height * 1.05,
      width * 0.35 - waveA * 2.0, -height * 0.85,
      width * 0.65 - waveA * 2.5, -height * 0.65,
    );

    path.cubicTo(
      width * 1.15, -height * 0.30,
      width * 0.95, height * 0.15,
      0, height * 0.2,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hasStreak != hasStreak ||
        oldDelegate.streakTier != streakTier;
  }
}
