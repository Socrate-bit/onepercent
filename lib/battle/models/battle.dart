import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// The outcome of a single battle against temptation.
enum BattleOutcome {
  win,
  loss;

  static BattleOutcome fromName(String value) =>
      value == 'loss' ? BattleOutcome.loss : BattleOutcome.win;
}

/// Where a battle came from: a normal win/loss, a whole-day validation, or a
/// win logged from the Recovery checklist.
enum BattleSource {
  normal,
  validated,
  recovery;

  static BattleSource fromName(String? value) => switch (value) {
        'validated' => BattleSource.validated,
        'recovery' => BattleSource.recovery,
        _ => BattleSource.normal,
      };
}

/// A single recorded decision: a win (resisted / disciplined) or a loss
/// (gave in), stamped with the moment it happened.
class Battle extends Equatable {
  final String id;
  final BattleOutcome outcome;
  final DateTime ts;

  /// How hard the decision felt, on a 0–10 scale (0 if not captured).
  final int difficulty;

  /// Optional label for what the decision was (empty if not captured).
  final String name;

  /// How this battle was logged (normal, day validation, or recovery).
  final BattleSource source;

  /// The user's personal values tagged onto this decision (empty if none).
  final List<String> values;

  const Battle({
    required this.id,
    required this.outcome,
    required this.ts,
    this.difficulty = 0,
    this.name = '',
    this.source = BattleSource.normal,
    this.values = const [],
  });

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
      difficulty: (data['difficulty'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      source: BattleSource.fromName(data['source'] as String?),
      values: (data['values'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// Serializes to the Firestore map shape.
  Map<String, dynamic> toMap() => {
        'outcome': outcome.name,
        'ts': ts.millisecondsSinceEpoch,
        'difficulty': difficulty,
        'name': name,
        'source': source.name,
        'values': values,
      };

  @override
  List<Object?> get props =>
      [id, outcome, ts, difficulty, name, source, values];
}
