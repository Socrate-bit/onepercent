import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The fiery circular indicator for the current daily streak shown on Home.
///
/// Renders a glowing orange ring with the streak number and a "days" caption
/// centered inside it.
class StreakRing extends StatelessWidget {
  final int streak;
  final double size;

  const StreakRing({super.key, required this.streak, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CURRENT STREAK',
                style: TextStyle(
                  color: AppColors.fire,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$streak',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'days',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;

    // Outer glow.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = AppColors.fire.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius, glow);

    // Bright fiery ring (sweep gradient of orange tones).
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFFB020),
          AppColors.fire,
          Color(0xFFFF4D00),
          Color(0xFFFFB020),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}
