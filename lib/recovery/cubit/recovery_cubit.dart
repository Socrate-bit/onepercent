import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/recovery_task.dart';
import '../services/recovery_service.dart';
import 'recovery_state.dart';

/// Owns the recovery-mode checklist state. Subscribes to the Firestore task
/// stream and exposes intents to add, toggle, and delete tasks.
class RecoveryCubit extends Cubit<RecoveryState> {
  final RecoveryService _service;
  final String uid;
  StreamSubscription<List<RecoveryTask>>? _sub;

  RecoveryCubit({required RecoveryService service, required this.uid})
      : _service = service,
        super(const RecoveryState()) {
    _subscribe();
  }

  void _subscribe() {
    _sub = _service.watchTasks(uid).listen(
      (tasks) =>
          emit(state.copyWith(tasks: tasks, loading: false, error: null)),
      onError: (e, st) {
        debugPrint('[RecoveryCubit] task stream error: $e\n$st');
        emit(state.copyWith(loading: false, error: 'Could not load your tasks.'));
      },
    );
  }

  /// Adds a new task. No-op for blank titles.
  Future<void> addTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      await _service.addTask(uid, trimmed);
    } catch (e) {
      emit(state.copyWith(error: 'Could not add task. Check your connection.'));
    }
  }

  /// Checks or unchecks the task with [id].
  Future<void> toggle(String id, bool done) async {
    try {
      await _service.setDone(uid, id, done);
    } catch (e) {
      emit(state.copyWith(error: 'Could not update task. Check your connection.'));
    }
  }

  /// Deletes the task with [id].
  Future<void> deleteTask(String id) async {
    try {
      await _service.deleteTask(uid, id);
    } catch (e) {
      emit(state.copyWith(error: 'Could not delete task. Check your connection.'));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
