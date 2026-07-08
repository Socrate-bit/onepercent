import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../battle/cubit/battle_cubit.dart';
import '../../battle/models/battle.dart';
import '../../battle/widget/difficulty_dialog.dart';
import '../../theme/app_theme.dart';
import '../../value/cubit/value_cubit.dart';
import '../cubit/recovery_cubit.dart';
import '../cubit/recovery_state.dart';
import '../models/recovery_task.dart';
import '../widget/add_task_dialog.dart';

/// The "Recovery mode" tab: a small checklist to lean on when getting back on
/// track. Add tasks from a modal, check them off, delete when done. A header
/// counter shows how many are done out of the total (e.g. "2 / 3"). Once every
/// task is checked, the Recover button unlocks: it logs a win, then clears the
/// checklist so the next slump starts clean.
class RecoveryScreen extends StatefulWidget {
  /// When true, the add-task sheet opens automatically once the screen is
  /// shown — but only if there are no tasks yet. Used when arriving here
  /// straight from logging a loss so an empty checklist isn't left blank.
  final bool openAddOnStart;

  const RecoveryScreen({super.key, this.openAddOnStart = false});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    if (widget.openAddOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<RecoveryCubit>().state.tasks.isEmpty) {
          _add(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<RecoveryCubit>();
    final title = await showAddTaskDialog(
      context,
      presets: cubit.state.presets,
    );
    if (title == null) return;
    cubit.addTask(title);
  }

  /// Recovery payoff: open the win pop-up, record the win, celebrate, then wipe
  /// the finished checklist. Cancelling the dialog records nothing and keeps the
  /// tasks intact.
  Future<void> _recover(BuildContext context) async {
    final recovery = context.read<RecoveryCubit>();
    final battle = context.read<BattleCubit>();
    final values =
        context.read<ValueCubit>().state.values.map((v) => v.title).toList();
    final entry =
        await showDifficultyDialog(context, BattleOutcome.win, values: values);
    if (entry == null) return;
    await battle.recordWin(
      difficulty: entry.difficulty,
      name: entry.name,
      source: BattleSource.recovery,
      values: entry.values,
      socialExpansion: entry.socialExpansion,
    );
    _confetti.play();
    await recovery.clearTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        backgroundColor: AppColors.fire,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            BlocConsumer<RecoveryCubit, RecoveryState>(
              listenWhen: (prev, curr) =>
                  prev.error != curr.error && curr.error != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.error!)));
              },
              builder: (context, state) {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                      sliver: SliverToBoxAdapter(
                        child: _Header(
                          state: state,
                          onRecover: () => _recover(context),
                        ),
                      ),
                    ),
                    if (state.loading && state.tasks.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.tasks.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 96.h),
                        sliver: SliverList.separated(
                          itemCount: state.tasks.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10.h),
                          itemBuilder: (_, i) => _TaskRow(task: state.tasks[i]),
                        ),
                      ),
                  ],
                );
              },
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
        ),
      ),
    );
  }
}

/// Title, the "done / total" progress counter, and the Recover button that sits
/// to its right (unlocked once every task is done).
class _Header extends StatelessWidget {
  final RecoveryState state;
  final VoidCallback onRecover;
  const _Header({required this.state, required this.onRecover});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'RECOVERY MODE',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Small steps to build back on track and build momentum',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _Counter(done: state.doneCount, total: state.total)),
            SizedBox(width: 12.w),
            _RecoverButton(enabled: state.allDone, onTap: onRecover),
          ],
        ),
      ],
    );
  }
}

/// The "Recover" call-to-action beside the progress bar. Disabled (greyed out)
/// until all tasks are checked, then lights up green.
class _RecoverButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _RecoverButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(enabled ? Icons.emoji_events_rounded : Icons.lock_rounded,
          size: 18.r),
      label: const Text('RECOVER'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.win,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.card,
        disabledForegroundColor: AppColors.textSecondary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        textStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5.sp,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: enabled
              ? BorderSide.none
              : const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}

/// The big "2 / 3" counter with a progress bar underneath.
class _Counter extends StatelessWidget {
  final int done;
  final int total;
  const _Counter({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && done == total;
    final accent = complete ? AppColors.win : AppColors.fire;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$done',
                  style: TextStyle(
                    color: accent,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / $total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6.h,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            complete ? 'All done' : 'done',
            style: TextStyle(
              color: complete ? AppColors.win : AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: complete ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 0.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final RecoveryTask task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecoveryCubit>();
    final done = task.done;
    final accent = done ? AppColors.win : AppColors.fire;
    final bookmarked = context.select<RecoveryCubit, bool>(
      (c) => c.state.customPresets.contains(task.title.trim()),
    );

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => cubit.toggle(task.id, !done),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: done ? accent : AppColors.textSecondary,
                size: 26.r,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => cubit.toggleBookmark(task.title),
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
                color: bookmarked ? AppColors.fire : AppColors.textSecondary,
                splashRadius: 22.r,
                tooltip: bookmarked
                    ? 'Remove from quick add'
                    : 'Save to quick add',
              ),
              IconButton(
                onPressed: () => cubit.deleteTask(task.id),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textSecondary,
                splashRadius: 22.r,
                tooltip: 'Delete task',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.healing_rounded,
              color: AppColors.textSecondary, size: 48.r),
          SizedBox(height: 12.h),
          Text(
            'No recovery tasks yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap + to line up a few small steps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
