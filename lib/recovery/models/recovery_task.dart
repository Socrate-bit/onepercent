import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A single recovery-mode task: a small, concrete action to lean on when
/// getting back on track. Checked off when done, deletable when no longer
/// needed.
class RecoveryTask extends Equatable {
  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  const RecoveryTask({
    required this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
  });

  RecoveryTask copyWith({String? title, bool? done}) => RecoveryTask(
        id: id,
        title: title ?? this.title,
        done: done ?? this.done,
        createdAt: createdAt,
      );

  /// Deserializes a Firestore document into a [RecoveryTask].
  factory RecoveryTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return RecoveryTask(
      id: doc.id,
      title: data['title'] as String? ?? '',
      done: data['done'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Serializes to the Firestore map shape.
  Map<String, dynamic> toMap() => {
        'title': title,
        'done': done,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, title, done, createdAt];
}
