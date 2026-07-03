import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A single personal value in the user's ranked list. Values carry an explicit
/// [order] (lower = higher rank) so the list can be dragged into any priority.
class ValueItem extends Equatable {
  final String id;
  final String title;

  /// Position in the ranked list (0-based). Lower comes first.
  final int order;
  final DateTime createdAt;

  const ValueItem({
    required this.id,
    required this.title,
    required this.order,
    required this.createdAt,
  });

  ValueItem copyWith({String? title, int? order}) => ValueItem(
        id: id,
        title: title ?? this.title,
        order: order ?? this.order,
        createdAt: createdAt,
      );

  /// Deserializes a Firestore document into a [ValueItem].
  factory ValueItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ValueItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Serializes to the Firestore map shape.
  Map<String, dynamic> toMap() => {
        'title': title,
        'order': order,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, title, order, createdAt];
}
