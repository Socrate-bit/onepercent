import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../cubit/battle_cubit.dart';
import '../cubit/battle_state.dart';
import '../widget/calendar_heatmap.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'STATS',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _RangeSelector(
                  selected: state.range,
                  onChanged: cubit.setRange,
                ),
                const SizedBox(height: 18),
                _grid(state),
                const SizedBox(height: 24),
                _section('CALENDAR', CalendarHeatmap(
                  tallies: state.dayTallies,
                  days: _heatmapDays(state),
                )),
                const SizedBox(height: 24),
                _section('PROGRESS OVER TIME',
                    ProgressChart(series: state.cumulativeSeries)),
                const SizedBox(height: 24),
                _section('INSIGHTS', _Insights(state)),
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
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: StatsRange.values.map((r) {
          final active = r == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.fire : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  r.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
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

/// A few lightweight, always-safe insights derived from the current window.
class _Insights extends StatelessWidget {
  final BattleState state;
  const _Insights(this.state);

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, Color, String)>[];

    if (state.battlesFought == 0) {
      rows.add((
        Icons.info_outline_rounded,
        AppColors.textSecondary,
        'No battles in this range yet. Record your first decision.',
      ));
    } else {
      rows.add((
        Icons.bolt_rounded,
        AppColors.fire,
        state.winRate >= 50
            ? 'You win ${state.winRate.toStringAsFixed(0)}% of your battles — keep it up.'
            : 'Win rate is ${state.winRate.toStringAsFixed(0)}%. One win at a time.',
      ));
      rows.add((
        Icons.emoji_events_rounded,
        AppColors.win,
        'Your best streak ever is ${state.bestStreak} in a row.',
      ));
      if (state.currentStreak > 0) {
        rows.add((
          Icons.local_fire_department_rounded,
          AppColors.fire,
          'You are on a ${state.currentStreak}-win streak right now.',
        ));
      }
    }

    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(r.$1, color: r.$2, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.$3,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
