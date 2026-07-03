import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../battle/models/battle.dart';
import '../../battle/util/streaks.dart';
import '../../theme/app_theme.dart';
import '../models/streak_badge.dart';
import '../widget/hexagon_badge.dart';
import 'badge_unlock_screen.dart';

/// The full milestones screen: every streak badge in a grid, with a summary of
/// how many are earned. Badges unlock off the user's best-ever daily streak, so
/// this derives entirely from the passed-in [battles] — no Bloc lookup needed,
/// which keeps it safe to push above the root provider scope.
class MilestonesScreen extends StatelessWidget {
  final List<Battle> battles;

  const MilestonesScreen({super.key, required this.battles});

  @override
  Widget build(BuildContext context) {
    final badges = evaluateStreakBadges(battles);
    final earned = badges.earnedCount;
    final total = badges.length;
    final bestStreak = dailyBestStreak(battles);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: _CloseButton(onTap: () => Navigator.pop(context)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MILESTONES',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Best streak: $bestStreak ${bestStreak == 1 ? 'day' : 'days'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    _ProgressCard(earned: earned, total: total),
                    SizedBox(height: 16.h),
                    const _HowItWorks(),
                    SizedBox(height: 24.h),
                    _BadgeGrid(badges: badges),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: const BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close, size: 18.r, color: AppColors.textPrimary),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int earned;
  final int total;

  const _ProgressCard({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 20.r, color: AppColors.fire),
              SizedBox(width: 8.w),
              Text(
                '$earned of $total badges earned',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: total > 0 ? earned / total : 0,
              minHeight: 6.h,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.fire),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18.r, color: AppColors.textSecondary),
              SizedBox(width: 8.w),
              Text(
                'How streaks work',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Your streak is the number of clean days in a row — days you win at '
            'least one battle and lose none. A day off keeps your streak frozen, '
            'and a loss resets it. Reaching a milestone unlocks its badge for '
            'good — the badges you’ve earned stay yours forever.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<StreakBadge> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.72,
      ),
      itemCount: badges.length,
      itemBuilder: (ctx, i) => _BadgeCell(badge: badges[i]),
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final StreakBadge badge;

  const _BadgeCell({required this.badge});

  @override
  Widget build(BuildContext context) {
    final reqLabel = badge.requiredDays == 1
        ? '1 day'
        : '${badge.requiredDays} days';
    return GestureDetector(
      onTap: badge.earned
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BadgeUnlockScreen(badge: badge),
                ),
              )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HexagonBadge(
            label: '${badge.requiredDays}',
            earned: badge.earned,
            size: 72.r,
          ),
          SizedBox(height: 8.h),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: badge.earned
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            reqLabel,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
