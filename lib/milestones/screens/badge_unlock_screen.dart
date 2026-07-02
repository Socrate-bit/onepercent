import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/utils/haptic_utils.dart';
import '../../insights/widgets/hexagon_badge.dart';
import '../models/badge_model.dart';

class BadgeUnlockScreen extends StatelessWidget {
  final BadgeModel badge;

  const BadgeUnlockScreen({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final dateStr = badge.earnedDate != null
        ? _formatDate(badge.earnedDate!)
        : 'Today';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Warm gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF8F0), Color(0xFFFFF0DC)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(context)),
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18.sp, color: const Color(0xFF3D2B1F)),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glow effect
                      Container(
                        width: 180.w,
                        height: 180.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.orange.withAlpha(60),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: LargeHexagonBadge(
                            label:
                                badge.requiredDays?.toString() ?? '★',
                            color: const Color(0xFFE05C1A),
                            size: 130.w,
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'BADGE UNLOCKED',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: const Color(0xFFE05C1A),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        badge.name,
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D1B00),
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
                          color: const Color(0xFF8B6E50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        badge.quote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF8B6E50),
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
        ],
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
