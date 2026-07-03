import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../models/streak_badge.dart';
import 'hexagon_badge.dart';

/// Compact "current rank" card for the top of the Stats tab. Shows the highest
/// badge earned and progress toward the next one. Tapping it opens the full
/// milestones screen (wired by the parent via [onTap]).
class CurrentBadgeCard extends StatelessWidget {
  /// Evaluated badges (see [evaluateStreakBadges]).
  final List<StreakBadge> badges;

  /// The user's best-ever daily streak, used to size the next-milestone progress.
  final int bestStreak;

  final VoidCallback onTap;

  const CurrentBadgeCard({
    super.key,
    required this.badges,
    required this.bestStreak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = badges.highestEarned;
    final next = badges.nextLocked;

    final title = current?.name ?? 'No badge yet';
    final String subtitle;
    double? progress;
    if (next != null) {
      final remaining = (next.requiredDays - bestStreak).clamp(0, next.requiredDays);
      subtitle = '$remaining more '
          '${remaining == 1 ? 'day' : 'days'} to ${next.name}';
      progress = (bestStreak / next.requiredDays).clamp(0.0, 1.0);
    } else {
      subtitle = 'All milestones unlocked';
    }

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              HexagonBadge(
                label: current != null ? '${current.requiredDays}' : '',
                earned: current != null,
                size: 56.r,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT BADGE',
                      style: TextStyle(
                        color: AppColors.fire,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    if (progress != null) ...[
                      SizedBox(height: 8.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5.h,
                          backgroundColor: AppColors.cardBorder,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.fire),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
