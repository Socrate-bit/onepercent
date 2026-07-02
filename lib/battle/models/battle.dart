import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// The outcome of a single battle against temptation.
enum BattleOutcome {
  win,
  loss;

  static BattleOutcome fromName(String value) =>
      value == 'loss' ? BattleOutcome.loss : BattleOutcome.win;
}

/// A single recorded decision: a win (resisted / disciplined) or a loss
/// (gave in), stamped with the moment it happened.
class Battle extends Equatable {
  final String id;
  final BattleOutcome outcome;
  final DateTime ts;

  const Battle({required this.id, required this.outcome, required this.ts});

  bool get isWin => outcome == BattleOutcome.win;
  bool get isLoss => outcome == BattleOutcome.loss;

  /// Deserializes a Firestore document into a [Battle].
  factory Battle.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Battle(
      id: doc.id,
      outcome: BattleOutcome.fromName(data['outcome'] as String? ?? 'win'),
      ts: DateTime.fromMillisecondsSinceEpoch(
        (data['ts'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Serializes to the Firestore map shape.
  Map<String, dynamic> toMap() => {
        'outcome': outcome.name,
        'ts': ts.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, outcome, ts];
}
