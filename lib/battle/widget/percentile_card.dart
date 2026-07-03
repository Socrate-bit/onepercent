import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Hero card for the Stats screen: shows the user where their discipline
/// win-rate places them within the general population.
///
/// [percentile] is 0–100 ("more disciplined than X% of people"), or null when
/// there aren't enough battles yet to say. [winRate] and [rangeLabel] describe
/// the record the estimate is based on.
class PercentileCard extends StatelessWidget {
  final double? percentile;
  final double winRate;
  final String rangeLabel;

  const PercentileCard({
    super.key,
    required this.percentile,
    required this.winRate,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percentile;
    final ready = pct != null;

    return GestureDetector(
      onTap: ready ? () => _showMethodology(context) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2430), AppColors.card],
          ),
        ),
        child: ready ? _ready(context, pct) : _empty(),
      ),
    );
  }

  Widget _ready(BuildContext context, double pct) {
    final rounded = pct.round();
    final topPct = (100 - pct).clamp(1, 99).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public_rounded, color: AppColors.win, size: 18),
            const SizedBox(width: 6),
            const Text(
              'POPULATION RANK',
              style: TextStyle(
                color: AppColors.win,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            if (rounded >= 50) _topBadge(topPct),
            const SizedBox(width: 6),
            const Icon(Icons.info_outline_rounded,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          "You're more disciplined than",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$rounded',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 46,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                '%',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 6),
              child: Text(
                'of the population',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Based on your ${winRate.toStringAsFixed(0)}% win rate · ${rangeLabel.toLowerCase()}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.public_rounded, color: AppColors.textSecondary, size: 18),
            SizedBox(width: 6),
            Text(
              'POPULATION RANK',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Fight a few battles to see where you rank against the population.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _topBadge(int topPct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.win.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'TOP $topPct%',
        style: const TextStyle(
          color: AppColors.win,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showMethodology(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'How your rank is estimated',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'People who actively resist a temptation succeed on about 83% of '
          'occasions (Hofmann, Baumeister & Vohs). We treat the population as a '
          'normal distribution around that average and compare your win rate to '
          'it.\n\nEarly on, your rate is blended toward the average so a handful '
          'of battles can\'t overstate your rank — it sharpens as you log more.\n\n'
          'It\'s a research-grounded estimate, not a precise measurement.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it',
                style: TextStyle(color: AppColors.fire, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
