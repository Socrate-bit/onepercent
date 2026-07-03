import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/recovery_task.dart';

/// Firestore access for recovery tasks, stored at
/// `users/{uid}/recovery_tasks/{autoId}`.
///
/// Mirrors [BattleService]: reads are streamed (real-time, offline-cached) so
/// the checklist stays reactive, and writes rely on Firestore's local cache for
/// optimistic UI updates.
class RecoveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _db.collection('users').doc(uid).collection('recovery_tasks');

  /// Streams all recovery tasks for [uid], oldest first.
  Stream<List<RecoveryTask>> watchTasks(String uid) {
    return _tasks(uid).orderBy('createdAt').snapshots().map(
          (snap) => snap.docs.map(RecoveryTask.fromDoc).toList(),
        );
  }

  /// Adds a new task with the given [title] (unchecked).
  Future<void> addTask(String uid, String title) async {
    try {
      final task = RecoveryTask(
        id: '',
        title: title,
        done: false,
        createdAt: DateTime.now(),
      );
      await _tasks(uid).add(task.toMap());
    } catch (e, st) {
      debugPrint('[RecoveryService] addTask failed: $e\n$st');
      rethrow;
    }
  }

  /// Flips the checked state of the task with [id].
  Future<void> setDone(String uid, String id, bool done) async {
    try {
      await _tasks(uid).doc(id).update({'done': done});
    } catch (e, st) {
      debugPrint('[RecoveryService] setDone failed: $e\n$st');
      rethrow;
    }
  }

  /// Permanently removes the task with [id].
  Future<void> deleteTask(String uid, String id) async {
    try {
      await _tasks(uid).doc(id).delete();
    } catch (e, st) {
      debugPrint('[RecoveryService] deleteTask failed: $e\n$st');
      rethrow;
    }
  }
}
