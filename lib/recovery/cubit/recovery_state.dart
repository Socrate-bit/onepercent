import 'package:equatable/equatable.dart';

import '../models/recovery_task.dart';

/// Immutable state for the recovery-mode checklist. Holds the full task list
/// plus load/error flags; counts are derived on demand.
class RecoveryState extends Equatable {
  /// All tasks, oldest first.
  final List<RecoveryTask> tasks;
  final bool loading;
  final String? error;

  const RecoveryState({
    this.tasks = const [],
    this.loading = true,
    this.error,
  });

  RecoveryState copyWith({
    List<RecoveryTask>? tasks,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return RecoveryState(
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const Object _sentinel = Object();

  /// Number of checked-off tasks.
  int get doneCount => tasks.where((t) => t.done).length;

  /// Total number of tasks (the denominator of the "done / total" counter).
  int get total => tasks.length;

  /// Whether every task is checked (and there is at least one).
  bool get allDone => total > 0 && doneCount == total;

  @override
  List<Object?> get props => [tasks, loading, error];
}
