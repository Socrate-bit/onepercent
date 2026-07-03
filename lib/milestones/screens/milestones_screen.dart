import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _CloseButton(onTap: () => Navigator.pop(context)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MILESTONES',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Best streak: $bestStreak ${bestStreak == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProgressCard(earned: earned, total: total),
                    const SizedBox(height: 16),
                    const _HowItWorks(),
                    const SizedBox(height: 24),
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 18, color: AppColors.textPrimary),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 20, color: AppColors.fire),
              const SizedBox(width: 8),
              Text(
                '$earned of $total badges earned',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? earned / total : 0,
              minHeight: 6,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'How streaks work',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your streak is the number of clean days in a row — days you win at '
            'least one battle and lose none. A day off keeps your streak frozen, '
            'and a loss resets it. Reaching a milestone unlocks its badge for '
            'good — the badges you’ve earned stay yours forever.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
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
            size: 72,
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badge.earned
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            reqLabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
