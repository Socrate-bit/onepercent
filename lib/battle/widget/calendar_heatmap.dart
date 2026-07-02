import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../cubit/battle_state.dart';

/// A GitHub-style heatmap: one column per week, one cell per day. Green cells
/// are days with mostly wins, red cells mostly losses; empty days are muted.
class CalendarHeatmap extends StatelessWidget {
  final List<DayTally> tallies;

  /// Number of days to display, ending today.
  final int days;

  const CalendarHeatmap({super.key, required this.tallies, required this.days});

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    // Align the grid to start on a Monday for clean week columns.
    final gridStart = start.subtract(Duration(days: (start.weekday - 1) % 7));

    final byDay = {for (final t in tallies) t.day: t};
    final totalDays = today.difference(gridStart).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    const cell = 15.0;
    const gap = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legend(),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (w) {
              return Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Column(
                  children: List.generate(7, (d) {
                    final date = gridStart.add(Duration(days: w * 7 + d));
                    final inRange = !date.isBefore(start) && !date.isAfter(today);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: gap),
                      child: Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: _colorFor(inRange ? byDay[date] : null),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Color _colorFor(DayTally? t) {
    if (t == null || t.total == 0) return const Color(0xFF1E2530);
    if (t.mostlyWins) {
      // Deeper green for more wins.
      final intensity = (0.45 + (t.wins.clamp(0, 5)) * 0.11).clamp(0.4, 1.0);
      return AppColors.win.withValues(alpha: intensity);
    }
    final intensity = (0.45 + (t.losses.clamp(0, 5)) * 0.11).clamp(0.4, 1.0);
    return AppColors.loss.withValues(alpha: intensity);
  }

  Widget _legend() {
    return Row(
      children: [
        _dot(AppColors.win),
        const SizedBox(width: 6),
        const Text('more wins',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 16),
        _dot(AppColors.loss),
        const SizedBox(width: 6),
        const Text('more losses',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
      );

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
