import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../cubit/battle_state.dart';

/// A custom line chart of the cumulative win rate (%) over time. Each point is
/// the running win rate up to that day, so the line shows the overall trend
/// converging toward the user's true discipline rate.
class ProgressChart extends StatelessWidget {
  final List<SeriesPoint> series;

  const ProgressChart({super.key, required this.series});

  /// Latest cumulative win rate as a percentage, or null when there's no data.
  double? get _latestRate {
    if (series.isEmpty) return null;
    final last = series.last;
    final total = last.cumulativeWins + last.cumulativeLosses;
    if (total == 0) return null;
    return last.cumulativeWins / total * 100;
  }

  @override
  Widget build(BuildContext context) {
    final rate = _latestRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _legend(AppColors.win, 'Win rate'),
            const Spacer(),
            if (rate != null)
              Text(
                '${rate.toStringAsFixed(0)}% now',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          width: double.infinity,
          child: series.isEmpty
              ? const Center(
                  child: Text(
                    'Not enough data yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                )
              : CustomPaint(painter: _ChartPainter(series)),
        ),
      ],
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      children: [
        Container(width: 12, height: 3, color: c),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<SeriesPoint> series;
  _ChartPainter(this.series);

  /// Cumulative win rate (0–100) at [index].
  double _rateAt(int index) {
    final p = series[index];
    final total = p.cumulativeWins + p.cumulativeLosses;
    if (total == 0) return 0;
    return p.cumulativeWins / total * 100;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 4.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    // Horizontal gridlines + y labels — a fixed 0–100% scale.
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = chartH - chartH * (i / 2);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _label(canvas, '${(100 * i / 2).round()}%', Offset(0, y - 6));
    }

    Offset pointAt(int index) {
      final x = leftPad +
          (series.length == 1 ? 0 : chartW * index / (series.length - 1));
      final y = chartH - chartH * (_rateAt(index) / 100);
      return Offset(x, y);
    }

    final points = [for (var i = 0; i < series.length; i++) pointAt(i)];

    // Soft area fill under the line.
    if (points.length > 1) {
      final fill = Path()..moveTo(points.first.dx, chartH);
      for (final p in points) {
        fill.lineTo(p.dx, p.dy);
      }
      fill
        ..lineTo(points.last.dx, chartH)
        ..close();
      canvas.drawPath(
        fill,
        Paint()..color = AppColors.win.withValues(alpha: 0.10),
      );
    }

    // The win-rate line.
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.win,
    );

    // Dot markers so a lone point (or endpoints) is always visible.
    final dot = Paint()..color = AppColors.win;
    for (final p in points) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) =>
      oldDelegate.series != series;
}
