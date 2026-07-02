import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/battle.dart';

/// Firestore access for battles, stored at `users/{uid}/battles/{autoId}`.
///
/// Reads are streamed (real-time, offline-cached) so the UI stays reactive;
/// writes rely on Firestore's local cache for optimistic updates — a local
/// [addBattle] fires the [watchBattles] listener immediately from cache.
class BattleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _battles(String uid) =>
      _db.collection('users').doc(uid).collection('battles');

  /// Streams all battles for [uid], oldest first.
  Stream<List<Battle>> watchBattles(String uid) {
    return _battles(uid).orderBy('ts').snapshots().map(
          (snap) => snap.docs.map(Battle.fromDoc).toList(),
        );
  }

  /// Records a new battle with the given [outcome].
  Future<void> addBattle(String uid, BattleOutcome outcome) async {
    try {
      final battle = Battle(
        id: '',
        outcome: outcome,
        ts: DateTime.now(),
      );
      await _battles(uid).add(battle.toMap());
      debugPrint('[BattleService] Recorded ${outcome.name} for $uid');
    } catch (e, st) {
      debugPrint('[BattleService] addBattle failed: $e\n$st');
      rethrow;
    }
  }
}
