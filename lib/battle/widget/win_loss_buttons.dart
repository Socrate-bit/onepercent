import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        const SizedBox(width: 14),
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 130,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
