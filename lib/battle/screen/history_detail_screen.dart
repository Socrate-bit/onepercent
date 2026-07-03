import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/battle.dart';
import 'history_screen.dart';

/// Full detail for a single [Battle]: outcome, when it happened, how hard it
/// felt, and the name/note the user attached.
class HistoryDetailScreen extends StatelessWidget {
  final Battle battle;
  const HistoryDetailScreen({super.key, required this.battle});

  @override
  Widget build(BuildContext context) {
    final isWin = battle.isWin;
    final accent = isWin ? AppColors.win : AppColors.loss;
    final diffColor = difficultyColor(battle.difficulty);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Battle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outcome header.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isWin
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: accent,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isWin ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: accent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.event_rounded,
                label: 'WHEN',
                child: Text(
                  formatBattleDate(battle.ts),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.whatshot_rounded,
                label: 'DIFFICULTY',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${battle.difficulty}',
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/ 10',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.notes_rounded,
                label: 'NOTE',
                child: Text(
                  battle.name.isEmpty ? 'No note' : battle.name,
                  style: TextStyle(
                    color: battle.name.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontStyle: battle.name.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled card showing one piece of battle metadata.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
