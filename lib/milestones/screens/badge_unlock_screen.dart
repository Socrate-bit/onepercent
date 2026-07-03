import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x33FF7A1A), Colors.transparent],
                      ),
                    ),
                    child: Center(
                      child: LargeHexagonBadge(
                        label: '${badge.requiredDays}',
                        size: 140,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'BADGE UNLOCKED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.fire,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Unlocked $dateStr',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.quote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
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
