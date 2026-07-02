import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../cubit/battle_state.dart';

/// A custom cumulative line chart of wins (green) vs losses (red) over time.
class ProgressChart extends StatelessWidget {
  final List<SeriesPoint> series;

  const ProgressChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legend(AppColors.win, 'Wins'),
            const SizedBox(width: 16),
            _legend(AppColors.loss, 'Losses'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          width: double.infinity,
          child: series.length < 2
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

  @override
  void paint(Canvas canvas, Size size) {
    final maxY = series
        .map((p) => p.cumulativeWins > p.cumulativeLosses
            ? p.cumulativeWins
            : p.cumulativeLosses)
        .fold<int>(1, (a, b) => a > b ? a : b);

    const leftPad = 28.0;
    const bottomPad = 4.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    // Horizontal gridlines + y labels (0, mid, max).
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = chartH - chartH * (i / 2);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _label(canvas, '${(maxY * i / 2).round()}', Offset(0, y - 6));
    }

    Offset pointAt(int index, int value) {
      final x = leftPad +
          (series.length == 1 ? 0 : chartW * index / (series.length - 1));
      final y = chartH - chartH * (value / maxY);
      return Offset(x, y);
    }

    void drawLine(int Function(SeriesPoint) sel, Color color) {
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final p = pointAt(i, sel(series[i]));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }

    drawLine((p) => p.cumulativeLosses, AppColors.loss);
    drawLine((p) => p.cumulativeWins, AppColors.win);
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
