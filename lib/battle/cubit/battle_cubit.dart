import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/battle.dart';
import '../services/battle_service.dart';
import 'battle_state.dart';

/// Owns all battle state and logic. Subscribes to the Firestore battle stream
/// and exposes intents to record wins/losses and switch the stats window.
class BattleCubit extends Cubit<BattleState> {
  final BattleService _service;
  final String uid;
  StreamSubscription<List<Battle>>? _sub;

  BattleCubit({required BattleService service, required this.uid})
      : _service = service,
        super(const BattleState()) {
    _subscribe();
  }

  void _subscribe() {
    _sub = _service.watchBattles(uid).listen(
      (battles) => emit(state.copyWith(battles: battles, loading: false, error: null)),
      onError: (e, st) {
        debugPrint('[BattleCubit] battle stream error: $e\n$st');
        emit(state.copyWith(loading: false, error: 'Could not load your battles.'));
      },
    );
  }

  /// Records a disciplined win. Firestore's local cache updates the stream
  /// optimistically, so the UI reflects it immediately.
  Future<void> recordWin({int difficulty = 0, String name = ''}) =>
      _record(BattleOutcome.win, difficulty, name);

  /// Records a loss (current streak resets on the next stream emission).
  Future<void> recordLoss({int difficulty = 0, String name = ''}) =>
      _record(BattleOutcome.loss, difficulty, name);

  Future<void> _record(
      BattleOutcome outcome, int difficulty, String name) async {
    try {
      await _service.addBattle(uid, outcome,
          difficulty: difficulty, name: name);
    } catch (e) {
      emit(state.copyWith(error: 'Could not save. Check your connection.'));
    }
  }

  /// Switches the Stats window (7 / 30 / 90 / all).
  void setRange(StatsRange range) => emit(state.copyWith(range: range));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
