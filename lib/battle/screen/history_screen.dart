import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../cubit/battle_cubit.dart';
import '../cubit/battle_state.dart';
import '../models/battle.dart';
import 'history_detail_screen.dart';

/// Maps a difficulty (0–10) to a color: red (hardest) → blue (easiest).
Color difficultyColor(num difficulty) {
  if (difficulty > 7) return AppColors.loss; // red
  if (difficulty > 5) return const Color(0xFFEAB308); // yellow
  if (difficulty > 2.5) return AppColors.win; // green
  return const Color(0xFF3B82F6); // blue
}

/// The "History" tab: a reverse-chronological list of every battle, each row
/// showing the outcome (win/loss), how hard it felt, and when it happened.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocBuilder<BattleCubit, BattleState>(
        builder: (context, state) {
          // Newest first — battles are stored oldest-first.
          final battles = state.battles.reversed.toList();
          return CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'HISTORY',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              if (state.loading && battles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (battles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: battles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _BattleRow(battle: battles[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BattleRow extends StatelessWidget {
  final Battle battle;
  const _BattleRow({required this.battle});

  @override
  Widget build(BuildContext context) {
    final isWin = battle.isWin;
    final accent = isWin ? AppColors.win : AppColors.loss;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(battle: battle),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWin ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWin ? 'WIN' : 'LOSS',
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatBattleDate(battle.ts),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _DifficultyChip(difficulty: battle.difficulty),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final int difficulty;
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            '$difficulty',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'diff',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Text(
            'No battles yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Record your first win or loss on the Today tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a timestamp as e.g. "Jul 2, 2026 · 3:07 PM".
String formatBattleDate(DateTime ts) {
  final month = _months[ts.month - 1];
  final hour12 = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
  final minute = ts.minute.toString().padLeft(2, '0');
  final period = ts.hour < 12 ? 'AM' : 'PM';
  return '$month ${ts.day}, ${ts.year} · $hour12:$minute $period';
}
