import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/value_item.dart';

/// Built-in quick-add suggestions, always available in the add-value sheet.
/// Users can grow this list by bookmarking their own values (stored per-user).
const List<String> kDefaultValuePresets = [
  'Discipline',
  'Well-being',
  'Health',
  'Growth',
  'Relationships',
  'Freedom',
  'Integrity',
];

/// Firestore access for the user's ranked values, stored at
/// `users/{uid}/values/{autoId}`.
///
/// Mirrors [RecoveryService], but the list is explicitly ordered: each value
/// carries an `order` field and reordering rewrites those fields in a batch.
class ValueService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _values(String uid) =>
      _db.collection('users').doc(uid).collection('values');

  CollectionReference<Map<String, dynamic>> _presets(String uid) =>
      _db.collection('users').doc(uid).collection('value_presets');

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
      debugPrint('[ValueService] addPreset failed: $e\n$st');
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
      debugPrint('[ValueService] removePreset failed: $e\n$st');
      rethrow;
    }
  }

  /// Streams all values for [uid], highest rank (lowest order) first.
  Stream<List<ValueItem>> watchValues(String uid) {
    return _values(uid).orderBy('order').snapshots().map(
          (snap) => snap.docs.map(ValueItem.fromDoc).toList(),
        );
  }

  /// Appends a new value at the bottom of the ranking. [nextOrder] is the new
  /// item's order (typically the current list length).
  Future<void> addValue(String uid, String title, int nextOrder) async {
    try {
      final value = ValueItem(
        id: '',
        title: title,
        order: nextOrder,
        createdAt: DateTime.now(),
      );
      await _values(uid).add(value.toMap());
    } catch (e, st) {
      debugPrint('[ValueService] addValue failed: $e\n$st');
      rethrow;
    }
  }

  /// Permanently removes the value with [id].
  Future<void> deleteValue(String uid, String id) async {
    try {
      await _values(uid).doc(id).delete();
    } catch (e, st) {
      debugPrint('[ValueService] deleteValue failed: $e\n$st');
      rethrow;
    }
  }

  /// Rewrites the `order` field of every value to match its index in
  /// [orderedIds] (first id → order 0), in a single batch.
  Future<void> reorder(String uid, List<String> orderedIds) async {
    try {
      final batch = _db.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(_values(uid).doc(orderedIds[i]), {'order': i});
      }
      await batch.commit();
    } catch (e, st) {
      debugPrint('[ValueService] reorder failed: $e\n$st');
      rethrow;
    }
  }
}
