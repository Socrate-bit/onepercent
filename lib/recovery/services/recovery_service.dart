import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/recovery_task.dart';

/// Built-in quick-add suggestions, always available in the add-task sheet.
/// Users can grow this list by bookmarking their own tasks (stored per-user).
const List<String> kDefaultRecoveryPresets = [
  'Clean the dish',
  'Clean your room',
  'Take a shower',
  'Go for a 20min walk',
  'Do sport',
];

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

  CollectionReference<Map<String, dynamic>> _presets(String uid) =>
      _db.collection('users').doc(uid).collection('recovery_presets');

  /// Streams the user's bookmarked quick-add presets, oldest first.
  Stream<List<String>> watchPresets(String uid) {
    return _presets(uid).orderBy('createdAt').snapshots().map(
          (snap) => snap.docs
              .map((d) => d.data()['title'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toList(),
        );
  }

  /// Bookmarks [title] as a preset. No-op for blanks or duplicates.
  Future<void> addPreset(String uid, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      final existing =
          await _presets(uid).where('title', isEqualTo: trimmed).limit(1).get();
      if (existing.docs.isNotEmpty) return;
      await _presets(uid).add({
        'title': trimmed,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e, st) {
      debugPrint('[RecoveryService] addPreset failed: $e\n$st');
      rethrow;
    }
  }

  /// Removes any preset matching [title]. No-op if none exist.
  Future<void> removePreset(String uid, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      final matches =
          await _presets(uid).where('title', isEqualTo: trimmed).get();
      final batch = _db.batch();
      for (final doc in matches.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e, st) {
      debugPrint('[RecoveryService] removePreset failed: $e\n$st');
      rethrow;
    }
  }

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

  /// Removes every recovery task for [uid] in a single batch.
  Future<void> clearTasks(String uid) async {
    try {
      final snap = await _tasks(uid).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e, st) {
      debugPrint('[RecoveryService] clearTasks failed: $e\n$st');
      rethrow;
    }
  }
}
