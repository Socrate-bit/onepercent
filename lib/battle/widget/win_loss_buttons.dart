import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';

/// The paired WIN (green) / LOSS (red) action buttons on Home.
class WinLossButtons extends StatelessWidget {
  final VoidCallback onWin;
  final VoidCallback onLoss;

  const WinLossButtons({super.key, required this.onWin, required this.onLoss});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutcomeButton(
            color: AppColors.win,
            icon: Icons.check_rounded,
            title: 'WIN',
            subtitle: 'I chose discipline',
            onTap: () {
              HapticFeedback.mediumImpact();
              onWin();
            },
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _OutcomeButton(
            color: AppColors.loss,
            icon: Icons.close_rounded,
            title: 'LOSS',
            subtitle: 'I gave in',
            onTap: () {
              HapticFeedback.heavyImpact();
              onLoss();
            },
          ),
        ),
      ],
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OutcomeButton({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 130.h,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28.r),
              ),
              SizedBox(height: 10.h),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
