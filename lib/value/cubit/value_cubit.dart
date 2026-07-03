import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/value_item.dart';
import '../services/value_service.dart';
import 'value_state.dart';

/// Owns the ranked values list. Subscribes to the Firestore value stream and
/// exposes intents to add, delete, and reorder values.
class ValueCubit extends Cubit<ValueState> {
  final ValueService _service;
  final String uid;
  StreamSubscription<List<ValueItem>>? _sub;
  StreamSubscription<List<String>>? _presetSub;

  ValueCubit({required ValueService service, required this.uid})
      : _service = service,
        super(const ValueState()) {
    _subscribe();
  }

  void _subscribe() {
    _sub = _service.watchValues(uid).listen(
      (values) =>
          emit(state.copyWith(values: values, loading: false, error: null)),
      onError: (e, st) {
        debugPrint('[ValueCubit] value stream error: $e\n$st');
        emit(state.copyWith(loading: false, error: 'Could not load your values.'));
      },
    );
    _presetSub = _service.watchPresets(uid).listen(
      (presets) => emit(state.copyWith(customPresets: presets)),
      onError: (e, st) {
        debugPrint('[ValueCubit] preset stream error: $e\n$st');
      },
    );
  }

  /// Toggles [title] in the user's quick-add presets, optimistically.
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

  /// Adds a new value at the bottom of the ranking. No-op for blank titles.
  Future<void> addValue(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      await _service.addValue(uid, trimmed, state.values.length);
    } catch (e) {
      emit(state.copyWith(error: 'Could not add value. Check your connection.'));
    }
  }

  /// Deletes the value with [id].
  Future<void> deleteValue(String id) async {
    try {
      await _service.deleteValue(uid, id);
    } catch (e) {
      emit(state.copyWith(error: 'Could not delete value. Check your connection.'));
    }
  }

  /// Moves the value at [oldIndex] to [newIndex], emitting the new ordering
  /// optimistically before persisting the rewritten `order` fields.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = [...state.values];
    if (oldIndex < 0 || oldIndex >= items.length) return;
    // ReorderableListView reports newIndex as the slot *before* removal.
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= items.length) newIndex = items.length - 1;

    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    final previous = state.values;
    // Re-stamp order so the optimistic list matches what we persist.
    final reindexed = [
      for (var i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
    emit(state.copyWith(values: reindexed));

    try {
      await _service.reorder(uid, reindexed.map((v) => v.id).toList());
    } catch (e) {
      emit(state.copyWith(
        values: previous,
        error: 'Could not reorder. Check your connection.',
      ));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _presetSub?.cancel();
    return super.close();
  }
}
