import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../cubit/battle_cubit.dart';
import '../cubit/battle_state.dart';
import '../models/battle.dart';
import 'history_detail_screen.dart';

/// Maps a difficulty (0–10) to a color: red (hardest) → blue (easiest).
Color difficultyColor(num difficulty) {
  if (difficulty > 9) return Colors.purple;
  if (difficulty >= 7.5) return AppColors.loss; // red
  if (difficulty >= 5) return const Color(0xFFEAB308); // yellow
  if (difficulty >= 2.5) return AppColors.win; // green
  return const Color(0xFF3B82F6); // blue
}

/// The "History" tab: a reverse-chronological list of every battle, each row
/// showing the outcome (win/loss), how hard it felt, and when it happened.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// When true, list is ordered hardest-first instead of newest-first.
  bool _sortByDifficulty = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocBuilder<BattleCubit, BattleState>(
        builder: (context, state) {
          // Newest first — battles are stored oldest-first.
          final battles = state.battles.reversed.toList();
          if (_sortByDifficulty) {
            // Hardest first; newest breaks ties (list is already newest-first).
            battles.sort((a, b) => b.difficulty.compareTo(a.difficulty));
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'HISTORY',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.sp,
                      ),
                    ),
                  ),
                ),
              ),
              if (battles.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _SortToggle(
                        sortByDifficulty: _sortByDifficulty,
                        onChanged: (v) =>
                            setState(() => _sortByDifficulty = v),
                      ),
                    ),
                  ),
                ),
              if (state.loading && battles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (battles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  sliver: SliverList.separated(
                    itemCount: battles.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) => _BattleRow(battle: battles[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A pill toggle switching the list between newest-first and hardest-first.
class _SortToggle extends StatelessWidget {
  final bool sortByDifficulty;
  final ValueChanged<bool> onChanged;
  const _SortToggle({required this.sortByDifficulty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = sortByDifficulty ? AppColors.fire : AppColors.textSecondary;
    return Material(
      color: sortByDifficulty
          ? AppColors.fire.withValues(alpha: 0.14)
          : AppColors.card,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () => onChanged(!sortByDifficulty),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: sortByDifficulty
                  ? AppColors.fire.withValues(alpha: 0.4)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.whatshot_rounded, color: accent, size: 15.r),
              SizedBox(width: 6.w),
              Text(
                sortByDifficulty ? 'Most difficult' : 'Sort by difficulty',
                style: TextStyle(
                  color: accent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleRow extends StatelessWidget {
  final Battle battle;
  const _BattleRow({required this.battle});

  @override
  Widget build(BuildContext context) {
    final isWin = battle.isWin;
    final accent = isWin ? AppColors.win : AppColors.loss;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(battle: battle),
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isWin ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: accent,
              size: 26.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isWin ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: accent,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.sp,
                      ),
                    ),
                    if (battle.source != BattleSource.normal) ...[
                      SizedBox(width: 8.w),
                      Flexible(child: _SourceChip(source: battle.source)),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  formatBattleDate(battle.ts),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          _DifficultyChip(difficulty: battle.difficulty),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final int difficulty;
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            '$difficulty',
            style: TextStyle(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'diff',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.sp,
              letterSpacing: 1.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Human label + icon for a non-normal battle source.
({String label, IconData icon}) sourceBadge(BattleSource source) =>
    switch (source) {
      BattleSource.validated => (label: 'Validated day', icon: Icons.verified_rounded),
      BattleSource.recovery => (label: 'Recovery', icon: Icons.healing_rounded),
      BattleSource.normal => (label: '', icon: Icons.circle),
    };

/// A small pill marking how a battle was logged (validated day / recovery).
class _SourceChip extends StatelessWidget {
  final BattleSource source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final badge = sourceBadge(source);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.win.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.win.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, color: AppColors.win, size: 13.r),
          SizedBox(width: 5.w),
          Text(
            badge.label,
            style: TextStyle(
              color: AppColors.win,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              color: AppColors.textSecondary, size: 48.r),
          SizedBox(height: 12.h),
          Text(
            'No battles yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Record your first win or loss on the Today tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a timestamp as e.g. "Jul 2, 2026 · 3:07 PM".
String formatBattleDate(DateTime ts) {
  final month = _months[ts.month - 1];
  final hour12 = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
  final minute = ts.minute.toString().padLeft(2, '0');
  final period = ts.hour < 12 ? 'AM' : 'PM';
  return '$month ${ts.day}, ${ts.year} · $hour12:$minute $period';
}
