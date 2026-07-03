import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../battle/cubit/battle_cubit.dart';
import '../../breathing/breathing_screen.dart';
import '../../recovery/cubit/recovery_cubit.dart';
import '../../recovery/screen/recovery_screen.dart';
import '../../theme/app_theme.dart';
import '../../value/cubit/value_cubit.dart';
import '../../value/screen/value_screen.dart';

/// The "Tools" tab: a 2-per-row grid of the app's supporting utilities —
/// Breathe, Recovery, and Values. Each card opens its tool full-screen.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  Future<void> _startBreathing(BuildContext context) async {
    final rounds = await showBreathingSetupDialog(context);
    if (rounds == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BreathingScreen(rounds: rounds)),
    );
  }

  void _openRecovery(BuildContext context) {
    final battleCubit = context.read<BattleCubit>();
    final recoveryCubit = context.read<RecoveryCubit>();
    final valueCubit = context.read<ValueCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: battleCubit),
            BlocProvider.value(value: recoveryCubit),
            BlocProvider.value(value: valueCubit),
          ],
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.background,
              title: const Text('Recovery'),
            ),
            body: const RecoveryScreen(openAddOnStart: true),
          ),
        ),
      ),
    );
  }

  void _openValues(BuildContext context) {
    final valueCubit = context.read<ValueCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: valueCubit,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.background,
              title: const Text('Values'),
            ),
            body: const ValueScreen(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'TOOLS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Lean on these to stay on track',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
              children: [
                _ToolCard(
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF5AA9FF),
                  title: 'BREATHE',
                  subtitle: 'Pause. Reset. Refocus.',
                  onTap: () => _startBreathing(context),
                ),
                _ToolCard(
                  icon: Icons.healing_rounded,
                  iconColor: AppColors.win,
                  title: 'RECOVERY',
                  subtitle: 'Small steps to take back momentum.',
                  onTap: () => _openRecovery(context),
                ),
                _ToolCard(
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.fire,
                  title: 'VALUES',
                  subtitle: 'Rank what you stand for.',
                  onTap: () => _openValues(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A square tool tile: a leading icon, a title, and a short subtitle. Styled to
/// match the app's card language (dark surface + subtle border).
class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
