import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../cubit/recovery_cubit.dart';
import '../cubit/recovery_state.dart';
import '../models/recovery_task.dart';
import '../widget/add_task_dialog.dart';

/// The "Recovery mode" tab: a small checklist to lean on when getting back on
/// track. Add tasks from a modal, check them off, delete when done. A header
/// counter shows how many are done out of the total (e.g. "2 / 3").
class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<RecoveryCubit>();
    final title = await showAddTaskDialog(context);
    if (title == null) return;
    cubit.addTask(title);
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
        child: BlocConsumer<RecoveryCubit, RecoveryState>(
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverToBoxAdapter(child: _Header(state: state)),
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    sliver: SliverList.separated(
                      itemCount: state.tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _TaskRow(task: state.tasks[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Title plus the "done / total" progress counter.
class _Header extends StatelessWidget {
  final RecoveryState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'RECOVERY MODE',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Small steps to build back on track and build momentum',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _Counter(done: state.doneCount, total: state.total),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / $total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            complete ? 'All done' : 'done',
            style: TextStyle(
              color: complete ? AppColors.win : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: complete ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 0.5,
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

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => cubit.toggle(task.id, !done),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: done ? accent : AppColors.textSecondary,
                size: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => cubit.deleteTask(task.id),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textSecondary,
                splashRadius: 22,
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
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.healing_rounded, color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Text(
            'No recovery tasks yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap + to line up a few small steps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
