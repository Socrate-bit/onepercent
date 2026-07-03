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
  StreamSubscription<List<String>>? _presetSub;

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
    _presetSub = _service.watchPresets(uid).listen(
      (presets) => emit(state.copyWith(customPresets: presets)),
      onError: (e, st) {
        debugPrint('[RecoveryCubit] preset stream error: $e\n$st');
      },
    );
  }

  /// Toggles [title] in the user's quick-add presets: removes it when already
  /// bookmarked, otherwise adds it. Applies the change optimistically so the
  /// UI updates instantly, reverting if the write fails.
  Future<void> toggleBookmark(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final previous = state.customPresets;
    final isBookmarked = previous.contains(trimmed);
    final optimistic = isBookmarked
        ? previous.where((t) => t != trimmed).toList()
        : [...previous, trimmed];
    emit(state.copyWith(customPresets: optimistic));
    try {
      if (isBookmarked) {
        await _service.removePreset(uid, trimmed);
      } else {
        await _service.addPreset(uid, trimmed);
      }
    } catch (e) {
      emit(state.copyWith(
        customPresets: previous,
        error: 'Could not save preset. Check your connection.',
      ));
    }
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

  /// Wipes the whole checklist (used after a recovery win is logged).
  Future<void> clearTasks() async {
    try {
      await _service.clearTasks(uid);
    } catch (e) {
      emit(state.copyWith(error: 'Could not clear tasks. Check your connection.'));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _presetSub?.cancel();
    return super.close();
  }
}
