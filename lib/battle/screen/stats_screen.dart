import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../milestones/models/streak_badge.dart';
import '../../milestones/screens/milestones_screen.dart';
import '../../milestones/widget/current_badge_card.dart';
import '../../theme/app_theme.dart';
import '../cubit/battle_cubit.dart';
import '../cubit/battle_state.dart';
import '../widget/calendar_heatmap.dart';
import '../widget/percentile_card.dart';
import '../widget/progress_chart.dart';
import '../widget/stat_card.dart';

/// The "Stats" tab: windowed analytics with a range selector, metric grid,
/// calendar heatmap, and cumulative progress chart.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocBuilder<BattleCubit, BattleState>(
        builder: (context, state) {
          final cubit = context.read<BattleCubit>();
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'STATS',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                CurrentBadgeCard(
                  badges: evaluateStreakBadges(state.battles),
                  bestStreak: state.bestStreak,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MilestonesScreen(battles: state.battles),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                _RangeSelector(
                  selected: state.range,
                  onChanged: cubit.setRange,
                ),
                SizedBox(height: 18.h),
                PercentileCard(
                  percentile: state.disciplinePercentile,
                  winRate: state.winRate,
                  rangeLabel: state.range.label,
                ),
                SizedBox(height: 18.h),
                _grid(state),
                SizedBox(height: 24.h),
                _section('CALENDAR', CalendarHeatmap(
                  tallies: state.dayTallies,
                  days: _heatmapDays(state),
                )),
                SizedBox(height: 24.h),
                _section('PROGRESS OVER TIME',
                    ProgressChart(series: state.cumulativeSeries)),
              ],
            ),
          );
        },
      ),
    );
  }

  int _heatmapDays(BattleState state) {
    final days = state.range.days;
    if (days != null) return days;
    if (state.battles.isEmpty) return 30;
    final first = state.battles.first.ts;
    return DateTime.now().difference(first).inDays + 1;
  }

  Widget _grid(BattleState state) {
    final cards = [
      StatCard(
        icon: Icons.emoji_events_rounded,
        accent: AppColors.fire,
        label: 'BEST STREAK',
        value: '${state.bestStreak}',
        caption: 'days',
      ),
      StatCard(
        icon: Icons.local_fire_department_rounded,
        accent: AppColors.fire,
        label: 'CURRENT STREAK',
        value: '${state.currentStreak}',
        caption: 'days',
      ),
      StatCard(
        icon: Icons.percent_rounded,
        accent: AppColors.win,
        label: 'WIN RATE',
        value: '${state.winRate.toStringAsFixed(1)}%',
        caption: '${state.wins} wins / ${state.battlesFought} total',
      ),
      StatCard(
        icon: Icons.check_circle_rounded,
        accent: AppColors.win,
        label: 'WINS',
        value: '${state.wins}',
      ),
      StatCard(
        icon: Icons.cancel_rounded,
        accent: AppColors.loss,
        label: 'LOSSES',
        value: '${state.losses}',
      ),
      StatCard(
        icon: Icons.sports_kabaddi_rounded,
        accent: const Color(0xFF7B61FF),
        label: 'BATTLES FOUGHT',
        value: '${state.battlesFought}',
        caption: 'Total decisions',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14.h,
      crossAxisSpacing: 14.w,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.sp,
            ),
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: StatsRange.values.map((r) {
          final active = r == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: active ? AppColors.fire : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Text(
                  r.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
