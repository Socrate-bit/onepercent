import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../cubit/value_cubit.dart';
import '../cubit/value_state.dart';
import '../models/value_item.dart';
import '../widget/add_value_dialog.dart';

/// The "Values" tool: a personal, drag-to-reorder ranked list of the core
/// values the user is fighting for. Add from a modal, delete when they no
/// longer fit, and drag to re-rank. A number badge shows each value's place in
/// the ranking. These values can then be tagged onto wins and losses.
class ValueScreen extends StatelessWidget {
  const ValueScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<ValueCubit>();
    final title = await showAddValueDialog(
      context,
      presets: cubit.state.presets,
    );
    if (title == null) return;
    cubit.addValue(title);
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
        child: BlocConsumer<ValueCubit, ValueState>(
          listenWhen: (prev, curr) =>
              prev.error != curr.error && curr.error != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                  child: const _Header(),
                ),
                if (state.loading && state.values.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.values.isEmpty)
                  const Expanded(child: Center(child: _EmptyState()))
                else
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 96.h),
                      itemCount: state.values.length,
                      onReorder: (oldIndex, newIndex) =>
                          context.read<ValueCubit>().reorder(oldIndex, newIndex),
                      itemBuilder: (context, i) => _ValueRow(
                        key: ValueKey(state.values[i].id),
                        value: state.values[i],
                        rank: i + 1,
                        index: i,
                      ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'YOUR VALUES',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Rank what matters most. Drag to reorder, then tag them on your wins and losses.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  final ValueItem value;
  final int rank;
  final int index;
  const _ValueRow({
    required Key key,
    required this.value,
    required this.rank,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ValueCubit>();

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // Rank badge showing the value's place in the ranking.
              Container(
                width: 30.r,
                height: 30.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.fire.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: AppColors.fire,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  value.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => cubit.deleteValue(value.id),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textSecondary,
                splashRadius: 22.r,
                tooltip: 'Delete value',
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: const Icon(Icons.drag_handle_rounded,
                      color: AppColors.textSecondary),
                ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded,
              color: AppColors.textSecondary, size: 48.r),
          SizedBox(height: 12.h),
          Text(
            'No values yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap + to name what you stand for.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
