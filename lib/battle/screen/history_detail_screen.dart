import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../models/battle.dart';
import 'history_screen.dart';

/// Full detail for a single [Battle]: outcome, when it happened, how hard it
/// felt, and the name/note the user attached.
class HistoryDetailScreen extends StatelessWidget {
  final Battle battle;
  const HistoryDetailScreen({super.key, required this.battle});

  @override
  Widget build(BuildContext context) {
    final isWin = battle.isWin;
    final accent = isWin ? AppColors.win : AppColors.loss;
    final diffColor = difficultyColor(battle.difficulty);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Battle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outcome header.
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isWin
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: accent,
                      size: 40.r,
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      isWin ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: accent,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              if (battle.source != BattleSource.normal) ...[
                Builder(builder: (context) {
                  final badge = sourceBadge(battle.source);
                  return _InfoTile(
                    icon: badge.icon,
                    label: 'TYPE',
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        color: AppColors.win,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
                SizedBox(height: 12.h),
              ],
              _InfoTile(
                icon: Icons.event_rounded,
                label: 'WHEN',
                child: Text(
                  formatBattleDate(battle.ts),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              _InfoTile(
                icon: Icons.whatshot_rounded,
                label: 'DIFFICULTY',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${battle.difficulty}',
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '/ 10',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (battle.values.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _InfoTile(
                  icon: Icons.favorite_rounded,
                  label: 'VALUES',
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final v in battle.values) _ValueChip(label: v),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              _InfoTile(
                icon: Icons.notes_rounded,
                label: 'NOTE',
                child: Text(
                  battle.name.isEmpty ? 'No note' : battle.name,
                  style: TextStyle(
                    color: battle.name.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontStyle: battle.name.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small pill for one value tagged onto the battle.
class _ValueChip extends StatelessWidget {
  final String label;
  const _ValueChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.fire.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.fire.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.fire,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A labelled card showing one piece of battle metadata.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20.r),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
