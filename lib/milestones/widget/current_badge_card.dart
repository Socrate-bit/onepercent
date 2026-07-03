import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/streak_badge.dart';
import 'hexagon_badge.dart';

/// Compact "current rank" card for the top of the Stats tab. Shows the highest
/// badge earned and progress toward the next one. Tapping it opens the full
/// milestones screen (wired by the parent via [onTap]).
class CurrentBadgeCard extends StatelessWidget {
  /// Evaluated badges (see [evaluateStreakBadges]).
  final List<StreakBadge> badges;

  /// The user's best-ever win streak, used to size the next-milestone progress.
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
          '${remaining == 1 ? 'win' : 'wins'} to ${next.name}';
      progress = (bestStreak / next.requiredDays).clamp(0.0, 1.0);
    } else {
      subtitle = 'All milestones unlocked';
    }

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              HexagonBadge(
                label: current != null ? '${current.requiredDays}' : '',
                earned: current != null,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT BADGE',
                      style: TextStyle(
                        color: AppColors.fire,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: AppColors.cardBorder,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.fire),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
