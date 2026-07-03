import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    final cell = 15.r;
    final gap = 4.r;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legend(),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (w) {
              return Padding(
                padding: EdgeInsets.only(right: gap),
                child: Column(
                  children: List.generate(7, (d) {
                    final date = gridStart.add(Duration(days: w * 7 + d));
                    final inRange = !date.isBefore(start) && !date.isAfter(today);
                    return Padding(
                      padding: EdgeInsets.only(bottom: gap),
                      child: Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: _colorFor(inRange ? byDay[date] : null),
                          borderRadius: BorderRadius.circular(3.r),
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
    // Opacity tracks how lopsided the day was: a clean sweep is fully opaque,
    // an even split fades toward transparent. `fraction` is the share held by
    // the dominant side (always in [0.5, 1.0]).
    final winFraction = t.wins / t.total;
    final dominant = t.mostlyWins ? winFraction : 1 - winFraction;
    final intensity = (0.25 + (dominant - 0.5) / 0.5 * 0.75).clamp(0.25, 1.0);
    final base = t.mostlyWins ? AppColors.win : AppColors.loss;
    return base.withValues(alpha: intensity);
  }

  Widget _legend() {
    return Row(
      children: [
        _dot(AppColors.win),
        SizedBox(width: 6.w),
        Text('more wins',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
        SizedBox(width: 16.w),
        _dot(AppColors.loss),
        SizedBox(width: 6.w),
        Text('more losses',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 10.r,
        height: 10.r,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2.r)),
      );

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
