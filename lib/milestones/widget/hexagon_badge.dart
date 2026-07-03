import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A flat-top hexagon medallion used for streak badges.
///
/// Earned badges glow in the app's fiery orange; locked badges render muted
/// with a lock icon. Follows the aesthetic of [StreakRing].
class HexagonBadge extends StatelessWidget {
  final String label;
  final bool earned;
  final double size;
  final Color earnedColor;

  const HexagonBadge({
    super.key,
    required this.label,
    required this.earned,
    this.size = 72,
    this.earnedColor = AppColors.fire,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(earned: earned, earnedColor: earnedColor),
        child: Center(
          child: earned
              ? Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                )
              : Icon(
                  Icons.lock_rounded,
                  size: size * 0.3,
                  color: AppColors.textSecondary,
                ),
        ),
      ),
    );
  }
}

/// A larger, brighter hexagon for the unlock/detail screen.
class LargeHexagonBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const LargeHexagonBadge({
    super.key,
    required this.label,
    this.color = AppColors.fire,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(earned: true, earnedColor: color, glow: true),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final bool earned;
  final Color earnedColor;
  final bool glow;

  _HexPainter({
    required this.earned,
    required this.earnedColor,
    this.glow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    final path = _hexPath(center, radius);

    if (earned && glow) {
      final glowPaint = Paint()
        ..color = earnedColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawPath(path, glowPaint);
    }

    // Fill.
    final fill = Paint()..style = PaintingStyle.fill;
    if (earned) {
      fill.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(earnedColor, Colors.white, 0.18)!,
          earnedColor,
          Color.lerp(earnedColor, Colors.black, 0.25)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      fill.color = AppColors.card;
    }
    canvas.drawPath(path, fill);

    // Border.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = earned ? 2 : 1.5
      ..color = earned
          ? Color.lerp(earnedColor, Colors.white, 0.35)!
          : AppColors.cardBorder;
    canvas.drawPath(path, border);
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      // Flat-top hexagon: start at 30° and step by 60°.
      final angle = math.pi / 180 * (60 * i - 30);
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.earned != earned ||
      old.earnedColor != earnedColor ||
      old.glow != glow;
}
