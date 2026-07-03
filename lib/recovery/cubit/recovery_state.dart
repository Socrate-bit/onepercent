import 'package:equatable/equatable.dart';

import '../models/recovery_task.dart';
import '../services/recovery_service.dart';

/// Immutable state for the recovery-mode checklist. Holds the full task list
/// plus load/error flags; counts are derived on demand.
class RecoveryState extends Equatable {
  /// All tasks, oldest first.
  final List<RecoveryTask> tasks;

  /// The user's own bookmarked quick-add presets (defaults are added on top).
  final List<String> customPresets;
  final bool loading;
  final String? error;

  const RecoveryState({
    this.tasks = const [],
    this.customPresets = const [],
    this.loading = true,
    this.error,
  });

  RecoveryState copyWith({
    List<RecoveryTask>? tasks,
    List<String>? customPresets,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return RecoveryState(
      tasks: tasks ?? this.tasks,
      customPresets: customPresets ?? this.customPresets,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const Object _sentinel = Object();

  /// Quick-add suggestions shown in the add-task sheet: built-in defaults
  /// first, then the user's bookmarked ones, de-duplicated.
  List<String> get presets {
    final seen = <String>{};
    return [
      for (final t in [...kDefaultRecoveryPresets, ...customPresets])
        if (seen.add(t)) t,
    ];
  }

  /// Number of checked-off tasks.
  int get doneCount => tasks.where((t) => t.done).length;

  /// Total number of tasks (the denominator of the "done / total" counter).
  int get total => tasks.length;

  /// Whether every task is checked (and there is at least one).
  bool get allDone => total > 0 && doneCount == total;

  @override
  List<Object?> get props => [tasks, customPresets, loading, error];
}
