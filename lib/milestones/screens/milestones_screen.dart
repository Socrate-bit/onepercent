import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:elevate/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../insights/widgets/hexagon_badge.dart';
import '../cubit/milestones_cubit.dart';
import '../cubit/milestones_state.dart';
import '../models/badge_model.dart';
import 'badge_unlock_screen.dart';

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MilestonesCubit()..load(),
      child: const _MilestonesView(),
    );
  }
}

class _MilestonesView extends StatelessWidget {
  const _MilestonesView();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MilestonesCubit, MilestonesState>(
      builder: (ctx, state) {
        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: withHaptic(() => Navigator.pop(ctx)),
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: c.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18.sp, color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.milestonesTitle,
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              // Header row
                              Container(
                                height: 120.h,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _TopCard(
                                        icon: Icon(
                                            Icons.local_fire_department_rounded,
                                            size: 56.sp,
                                            color: c.primary),
                                        label: l10n.milestonesDayStreak,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: _BadgeTopCard(
                                        earned: state.badgesEarned,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h),
                              // Stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoBox(
                                      icon: Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 20.sp,
                                          color: c.primary),
                                      value: l10n.milestonesLongestStreak(
                                          state.longestStreak),
                                      label: l10n.milestonesLongestStreakLabel,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _BadgeProgressBox(
                                      earned: state.badgesEarned,
                                      total: state.totalBadges,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              // How Streaks Work
                              if (state.showHowStreaksWork) ...[
                                _HowStreaksWork(
                                  onDismiss: () => ctx
                                      .read<MilestonesCubit>()
                                      .dismissHowStreaksWork(),
                                ),
                                SizedBox(height: 20.h),
                              ],
                              // Streak Badges
                              Text(
                                l10n.milestonesStreakBadges,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _BadgeGrid(badges: state.streakBadges),
                              SizedBox(height: 24.h),
                              // Achievement Badges
                              Text(
                                l10n.milestonesAchievementBadges,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _BadgeGrid(badges: state.achievementBadges),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopCard extends StatelessWidget {
  final Widget icon;
  final String label;

  const _TopCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          icon,
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTopCard extends StatelessWidget {
  final int earned;

  const _BadgeTopCard({required this.earned});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          HexagonBadge(
            label: '$earned',
            earned: earned > 0,
            size: 56.w,
            earnedColor: const Color(0xFFB8860B),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.milestonesBadgesEarned,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const _InfoBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          icon,
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeProgressBox extends StatelessWidget {
  final int earned;
  final int total;

  const _BadgeProgressBox({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🏅', style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 6.w),
              Text(
                '$earned / $total',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: total > 0 ? earned / total : 0,
              minHeight: 6.h,
              backgroundColor: c.separator,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFB8860B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStreaksWork extends StatelessWidget {
  final VoidCallback onDismiss;

  const _HowStreaksWork({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18.sp, color: c.textSecondary),
              SizedBox(width: 8.w),
              Text(
                l10n.milestonesHowStreaksWork,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: withHaptic(onDismiss),
                child: Icon(Icons.close,
                    size: 18.sp, color: c.textSecondary),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            l10n.milestonesStreakExplanation,
            style: TextStyle(
              fontSize: 13.sp,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<BadgeModel> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.75,
      ),
      itemCount: badges.length,
      itemBuilder: (ctx, i) => _BadgeCell(badge: badges[i]),
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeCell({required this.badge});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: badge.earned
          ? withHaptic(() => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BadgeUnlockScreen(badge: badge),
                ),
              ))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HexagonBadge(
            label: badge.displayValue,
            earned: badge.earned,
            size: 72.w,
            earnedColor: badge.kind == BadgeKind.streak
                ? const Color(0xFFE05C1A)
                : const Color(0xFF7B61FF),
          ),
          SizedBox(height: 8.h),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10.sp,
              color: c.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
