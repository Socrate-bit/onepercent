import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';

/// A compact labeled metric card used across Home and Stats.
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? caption;

  /// Optional fixed height. When set, the card ignores its content height so
  /// side-by-side cards stay the same size regardless of their values.
  final double? height;

  const StatCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.caption,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18.r),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: 2.h),
            Text(
              caption!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
