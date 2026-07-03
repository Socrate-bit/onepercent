import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../models/streak_badge.dart';
import '../widget/hexagon_badge.dart';

/// Full-screen celebration of a single earned badge: a glowing hexagon, the
/// badge name, the day it unlocked, and its quote — on the app's dark palette.
class BadgeUnlockScreen extends StatelessWidget {
  final StreakBadge badge;

  const BadgeUnlockScreen({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        badge.earnedDate != null ? _formatDate(badge.earnedDate!) : 'Today';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close,
                      size: 18.r, color: AppColors.textPrimary),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 200.r,
                    height: 200.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x33FF7A1A), Colors.transparent],
                      ),
                    ),
                    child: Center(
                      child: LargeHexagonBadge(
                        label: '${badge.requiredDays}',
                        size: 140.r,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'BADGE UNLOCKED',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.sp,
                      color: AppColors.fire,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    badge.name,
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  Text(
                    'Unlocked $dateStr',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    badge.quote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}
