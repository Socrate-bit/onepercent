import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../breathing/breathing_screen.dart';
import '../../milestones/models/streak_badge.dart';
import '../../milestones/screens/milestones_screen.dart';
import '../../milestones/widget/current_badge_card.dart';
import '../../recovery/cubit/recovery_cubit.dart';
import '../../recovery/screen/recovery_screen.dart';
import '../../theme/app_theme.dart';
import '../../value/cubit/value_cubit.dart';
import '../../value/widget/add_value_dialog.dart';
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
  static final double _statCardHeight = 130.h;

  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));

  /// Ticks every minute so the time-gated Validate Day button (unlocks at
  /// 9 PM) refreshes without needing another state change.
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  /// Prompts for a 0–10 difficulty, then records the outcome. A win also fires
  /// the confetti burst. Bailing out of the dialog records nothing.
  Future<void> _record(BattleOutcome outcome) async {
    final cubit = context.read<BattleCubit>();
    final valueCubit = context.read<ValueCubit>();
    final values = valueCubit.state.values.map((v) => v.title).toList();
    final entry = await showDifficultyDialog(
      context,
      outcome,
      values: values,
      onAddValue: () async {
        final title = await showAddValueDialog(
          context,
          presets: valueCubit.state.presets,
        );
        if (title == null) return null;
        valueCubit.addValue(title);
        return title;
      },
    );
    if (entry == null) return;

    if (outcome == BattleOutcome.win) {
      cubit.recordWin(
          difficulty: entry.difficulty, name: entry.name, values: entry.values);
      _confetti.play();
    } else {
      cubit.recordLoss(
          difficulty: entry.difficulty, name: entry.name, values: entry.values);
      if (entry.breathe && mounted) {
        await _startBreathing(context);
      } else if (entry.recover && mounted) {
        _openRecovery(context, openAddOnStart: true);
      }
    }
  }

  /// Opens the Recovery checklist as a full screen, forwarding the ambient
  /// cubits. [openAddOnStart] pops the add-task dialog on entry when the
  /// checklist is empty — set both from a loss and the Recovery shortcut.
  void _openRecovery(BuildContext context, {bool openAddOnStart = false}) {
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
            body: RecoveryScreen(openAddOnStart: openAddOnStart),
          ),
        ),
      ),
    );
  }

  /// Day validation opens at 9 PM (once the day is basically done) and locks
  /// again once used, so it can only happen once per day.
  static const int _validateHour = 21;

  bool _canValidateDay(BattleState state) =>
      DateTime.now().hour >= _validateHour &&
      !state.validatedToday &&
      !state.hasLossToday;

  /// Reason the button is locked, or null when it's tappable.
  String? _validateLockReason(BattleState state) {
    if (state.validatedToday) return 'Already validated today';
    if (state.hasLossToday) return 'You logged a loss today';
    if (DateTime.now().hour < _validateHour) return 'Unlocks at 9:00 PM';
    return null;
  }

  /// Quick "no loss today" action: logs a win worth four and celebrates, no
  /// dialog. A validated day counts as four wins.
  void _validateDay() {
    context.read<BattleCubit>().recordWin(
          name: 'Day validated',
          source: BattleSource.validated,
          weight: 4,
        );
    _confetti.play();
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
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(state.totalWinsAllTime),
                    SizedBox(height: 24.h),
                    Center(child: StreakRing(streak: state.currentStreak)),
                    SizedBox(height: 24.h),
                    CurrentBadgeCard(
                      badges: evaluateStreakBadges(state.battles),
                      bestStreak: state.bestStreak,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MilestonesScreen(battles: state.battles),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
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
                        SizedBox(width: 14.w),
                        Expanded(
                          child: StatCard(
                            height: _statCardHeight,
                            icon: Icons.percent_rounded,
                            accent: AppColors.win,
                            label: 'WIN % THIS WEEK',
                            value:
                                '${state.winRateThisWeek.toStringAsFixed(0)}%',
                            caption:
                                '${state.winsThisWeek} ${state.winsThisWeek == 1 ? 'win' : 'wins'} · '
                                '${state.lossesThisWeek} ${state.lossesThisWeek == 1 ? 'loss' : 'losses'}',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    WinLossButtons(
                      onWin: () => _record(BattleOutcome.win),
                      onLoss: () => _record(BattleOutcome.loss),
                    ),
                    SizedBox(height: 14.h),
                    _ValidateDayButton(
                      enabled: _canValidateDay(state),
                      lockedReason: _validateLockReason(state),
                      onTap: _validateDay,
                    ),
                    SizedBox(height: 24.h),
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
        Expanded(
          child: Column(
            children: [
              Text(
                'ONE PERCENT',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Master your mind, choose your future',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-width "no loss today" shortcut that logs a win in one tap. Opens only
/// after 9 PM and locks once the day is validated; [lockedReason] explains why
/// it's disabled. Styled green when live, greyed out when locked.
class _ValidateDayButton extends StatelessWidget {
  final bool enabled;
  final String? lockedReason;
  final VoidCallback onTap;
  const _ValidateDayButton({
    required this.enabled,
    required this.lockedReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? AppColors.win : AppColors.textSecondary;
    return Material(
      color: enabled
          ? AppColors.win.withValues(alpha: 0.14)
          : AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: enabled
                  ? AppColors.win.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                enabled ? Icons.verified_rounded : Icons.lock_rounded,
                color: accent,
                size: 24.r,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VALIDATE DAY',
                      style: TextStyle(
                        color: accent,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      lockedReason ?? 'No loss today — log a win',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.chevron_right_rounded, color: AppColors.win),
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
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14.sp,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
