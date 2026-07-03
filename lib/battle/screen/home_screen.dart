import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../breathing/breathing_screen.dart';
import '../../theme/app_theme.dart';
import '../cubit/battle_cubit.dart';
import '../cubit/battle_state.dart';
import '../models/battle.dart';
import '../widget/difficulty_dialog.dart';
import '../widget/stat_card.dart';
import '../widget/streak_ring.dart';
import '../widget/win_loss_buttons.dart';

/// The "Today" tab: current streak, quick stats, and the Win/Loss/Breathe
/// actions. Kept intentionally friction-free — open, record, move on.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Fixed height so BEST STREAK / WIN THIS WEEK cards stay the same size.
  static const double _statCardHeight = 130;

  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Prompts for a 0–10 difficulty, then records the outcome. A win also fires
  /// the confetti burst. Bailing out of the dialog records nothing.
  Future<void> _record(BattleOutcome outcome) async {
    final cubit = context.read<BattleCubit>();
    final entry = await showDifficultyDialog(context, outcome);
    if (entry == null) return;

    if (outcome == BattleOutcome.win) {
      cubit.recordWin(difficulty: entry.difficulty, name: entry.name);
      _confetti.play();
    } else {
      cubit.recordLoss(difficulty: entry.difficulty, name: entry.name);
      if (entry.breathe && mounted) {
        await _startBreathing(context);
      }
    }
  }

  Future<void> _startBreathing(BuildContext context) async {
    final rounds = await showBreathingSetupDialog(context);
    if (rounds == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BreathingScreen(rounds: rounds)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocConsumer<BattleCubit, BattleState>(
        listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(state.totalWinsAllTime),
                    const SizedBox(height: 24),
                    Center(child: StreakRing(streak: state.currentStreak)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            height: _statCardHeight,
                            icon: Icons.emoji_events_rounded,
                            accent: AppColors.fire,
                            label: 'BEST STREAK',
                            value: '${state.bestStreak}',
                            caption: 'days',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: StatCard(
                            height: _statCardHeight,
                            icon: Icons.percent_rounded,
                            accent: AppColors.win,
                            label: 'WIN % THIS WEEK',
                            value:
                                '${state.winRateThisWeek.toStringAsFixed(0)}%',
                            caption: '${state.battlesThisWeek} battles',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    WinLossButtons(
                      onWin: () => _record(BattleOutcome.win),
                      onLoss: () => _record(BattleOutcome.loss),
                    ),
                    const SizedBox(height: 16),
                    _BreatheButton(
                      onTap: () => _startBreathing(context),
                    ),
                    const SizedBox(height: 24),
                    const _Quote(
                        'I choose greatness over short-term comfort.'),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.9,
                  numberOfParticles: 18,
                  maxBlastForce: 50,
                  minBlastForce: 30,
                  gravity: 0.45,
                  shouldLoop: false,
                  colors: const [
                    Color(0xFF6D28D9), // purpleDeep
                    AppColors.fire, // orange
                    Colors.amber,
                    Colors.greenAccent,
                    Colors.lightBlueAccent,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(int totalWins) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            children: [
              Text(
                'ONE PERCENT',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Choose your future',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreatheButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BreatheButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.air_rounded, color: Color(0xFF5AA9FF), size: 24),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BREATHE',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pause. Reset. Refocus.',
                      style:
                          TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final String text;
  const _Quote(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      '“$text”',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
