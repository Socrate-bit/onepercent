import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TOOLS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Lean on these to stay on track',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            ),
            SizedBox(height: 24.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14.w,
              mainAxisSpacing: 14.h,
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
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: iconColor, size: 26.r),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
